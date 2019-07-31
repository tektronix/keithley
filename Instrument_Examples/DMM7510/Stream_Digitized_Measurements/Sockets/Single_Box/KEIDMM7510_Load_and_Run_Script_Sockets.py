import socket
import struct
import math
import time


def load_functions(my_socket, script_file_path_and_name):
    # This function opens the functions.lua file in the same directory as
    # the Python script and trasfers its contents to the DMM7510's internal
    # memory. All the functions defined in the file are callable by the
    # controlling program. 
    func_file = open(script_file_path_and_name, "r")
    contents = func_file.read()
    func_file.close()
    my_socket.send("if loadfuncs ~= nil then script.delete('loadfuncs') end\n".encode())
    my_socket.send("loadscript loadfuncs\n{0}\nendscript\n"
                   .format(contents).encode())
    my_socket.send("loadfuncs()\n".encode())
    print(s.recv(100).decode())


def send_setup(my_socket, measure_range, my_sample_rate, reading_buffer_size):
    # This function sends a string that includes the function
    # call and arguments that set up the DMM7510 for digitizing
    # current for the requested time and sample rate.
    my_socket.send("do_setup({0}, {1}, {2})\n"
                   .format(measure_range, my_sample_rate, reading_buffer_size)
                   .encode())
    my_socket.recv(10)


def send_trigger(my_socket):
    # This function sends a string that calls the function
    # to trigger the instrument. 
    my_socket.send("trig()\n".encode())
    my_socket.recv(10)


def write_block(ofile, floats):
    # This function writes the floating point data to the
    # target file. 
    for f in floats:
        ofile.write("{0:.4e}\n".format(f))


def get_block(my_socket, chunk_size, buffer_size):
    # This function extracts the binaray floating point data
    # from the DMM7510.
    sndStr = "get_data({0})\n".format(buffer_size)
    my_socket.send(sndStr.encode())
    response = my_socket.recv(1024)
    # New content....
    fmtStr = '%df' % chunk_size
    altResp = struct.unpack(fmtStr, response[2:-1])
    return altResp


def change_screen(my_socket, my_screen):
    my_socket.send("chng_scrn({0})\n"
        .format(my_screen)
        .encode())
    my_socket.recv(10)
    return


""" ================================================================================
    This example copies the contents of a script file on the host computer and
    sends to the LAN-connected instrument. The instrument is then triggered to
    perform digitized readings while also extracting the readings from the buffer
    and writing to local disk. 
================================================================================="""
# settings
seconds_to_capture = 10  # Modify this value to adjust your run time.

sample_rate = 60000
""" 
    NOTE: 60kS/s is the max rate we have observed under  
    certain conditions/circumstances. To attain
    higher sampling and data transfer rates, use
    USB.
"""

chunkSize = 249
""""
    This value is the max binary format transfer value we can implement for data transfer, and is limited
    by the ethernet protocol where the max frame size is < 1500 bytes, and this includes header/trailer
    information for each of the networking layers involved in the TCP/IP (physical, data link, network,
    and transport). The "chunkSize" variable defines how many readings to to transfer for a given poll of the
    instrument.
"""
ip_address = "192.168.1.2"  # Place your instrument's IP address here.
output_data_path = time.strftime("data_%Y-%m-%d_%H-%M-%S.csv")
"""
    This is the output file that is created which will hold your readings provided in ASCII format in a text file.
    Note that we apply the date/time stamp so we are not accidentally overwriting previous data. 
"""
functions_path = "functions_V3.lua"
""" 
    This file holds the set of TSP (Lua-based) functions that are called by the Python script to help minimize the
    amount of bytes needed to setup up and, more importantly, extract readings from the instrument. The file is 
"""
# helpers...
chunks = math.floor((seconds_to_capture * sample_rate) / chunkSize)  # implement "chunkSize" instead of a fixed value

t3 = time.time()                    # Start the timer...
myRange = 1
buffSize = int(sample_rate * seconds_to_capture)
s = socket.socket()                  # Establish a TCP/IP socket object
s.connect((ip_address, 5025))        # Connect to the instrument
ofile = open(output_data_path, "w")  # Open/create the target data

load_functions(s, functions_path)
send_setup(s, myRange, sample_rate, buffSize)
change_screen(s, 1)
send_trigger(s)

t1 = time.time()                    # Start the timer...
for i in range(0, int(chunks)):     # Loop to collect the digitized data
    write_block(ofile, get_block(s, chunkSize, buffSize))  # Write the data to file
    # This is here for debug purposes, printing
    # out the % of run time elapsed
    # and technically it could be commented out.
    if i % 10 == 0:
        print("{0:.1f}%".format(i/chunks * 100))

change_screen(s, 0)
t2 = time.time()                    # Stop the timer...

ofile.close()                       # Close the data file.
s.close()                           # Close the socket. 

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("{0:.3f} rdgs/s".format((chunks * chunkSize)/(t2-t1)))
print("Total Run Time = {0:.3f} s".format(t2-t3))
input("Press Enter to continue...")
exit()
