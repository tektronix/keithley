'''
Modified version of Stream_DMM6500.py from
https://github.com/tektronix/keithley/tree/main/Instrument_Examples/DMM6500/Streaming_Examples/00_Stream_Data_from_DMM6500

Modified for use with Touch Screen SourceMeter model:  2450, 2460, 2461, 2470
Tested with 2450, firmware 1.7.16a

Place the Stream_TTI_SMU.py and functions_smu.lua into same directory
Adjust path vars below (functions_path and output_data_path)
Streamed data will be written to smu_data.txt in same working directory

This example configures the SMU to do a ramp from start_v to stop_v and back to start_v.
The pts_in_ramp is used for each half ramp.
repeat_count to perform the ramps more than once.

'''

from pydoc import doc
import socket
import struct
import math
import time
import os

print("Current Working Directory: ")
print(os.getcwd())

#print("***** Files in Dir *****")
#print(os.listdir())
#print("***** End Files in Dir *****")

#settings
start_v = -1
stop_v = 1
pts_in_ramp = 21
repeat_count = 10

#sample_rate = 20  # NOTE: 60kS/s is the max rate we have observed under
                    #       certain conditions/circumstances. To attain
                    #       higher sampling and data transfer rates, use
                    #       USB.

chunkSize = 25 * 3  # three elements for each buffer reading (time, src value, reading)           
#chunkSize = 249    # This value is the max binary format transfer value
                    # we can implement for data transfer, and is limited
                    # by the ethernet protocol where the max frame size
                    # is < 1500 bytes, and this includes header/trailer
                    # information for each of the networking layers
                    # involved in the TCP/IP (physical, data link, network,
                    # and transport). The "chunkSize" variable defines how
                    # many readings to to transfer for a given poll of the
                    # instrument.
                    
ip_address = "192.168.0.50"     # Place your instrument's IP address here.
output_data_path = "KI_2450/streaming/smu_data.txt"   # This is the output file that is created which
                                    # will hold your readings provided in ASCII
                                    # format in a text file. 
functions_path = "KI_2450/streaming/functions_smu.lua"    # This file holds the set of TSP (Lua-
                                    # based) functions that are called by
                                    # the Python script to help minimize the
                                    # amount of bytes needed to setup up and
                                    # more importantly, extract readings from
                                    # the instrument. 

#chunks = math.floor((seconds_to_capture * sample_rate) / chunkSize) # implement "chunkSize" instead of a fixed value
appx_number_readings = repeat_count * (2* pts_in_ramp + 15)
elements_per_reading = 3  #timestamp, src level, measurement
chunks = math.floor((elements_per_reading * appx_number_readings)/chunkSize)  # rounding issue - leaving data behind
print(elements_per_reading * appx_number_readings)
print(chunks)
print(chunkSize)
print(appx_number_readings/ chunks)



def load_functions(s):
    # This function opens the functions.lua file in the same directory as
    # the Python script and trasfers its contents to the instrument internal
    # memory. All the functions defined in the file are callable by the
    # controlling program. 
    func_file = open(functions_path, "r")
    contents = func_file.read()
    func_file.close()
    s.send("if loadfuncs ~= nil then "
                "script.delete('loadfuncs') "
           "end\n".encode())
    s.send("loadscript loadfuncs\n{0}\nendscript\n"
        .format(contents)
        .encode())
    s.send("loadfuncs()\n".encode())
    print(s.recv(100).decode())



def send_setup(s, start, stop, ramp_pts, repeat):
    # This function sends a string that includes the function
    # call and arguments that set up the touch screen SMU for measuring
    # current for each sourced voltage in ramp.
    s.send("do_setup({0}, {1}, {2}, {3})\n"
        .format(start_v, stop_v, pts_in_ramp, repeat_count)
        .encode())
    s.recv(10)
    
def send_trigger(s):
    # This function sends a string that calls the function
    # to trigger the instrument. 
    s.send("trig()\n".encode())
    s.recv(10)

def write_block(ofile, floats):
    # This function writes the floating point data to the
    # target file. 
    for i in range(0, len(floats) - 2, 3):
            #line = f"{floats[i]},{floats[i+1]},{floats[i+2]}\n"
            #line = f"{floats[i]:.3f},{floats[i+1]:.3f},{floats[i+2]:.3f}\n"
            line = f"{floats[i]:.3e},{floats[i+1]:.3e},{floats[i+2]:.3e}\n"
            ofile.write(line)

    #for f in floats:
    #    ofile.write("{0:.4e}\n".format(f))
    
def write_header(ofile):
    line = "Time,Volts,Current"
    ofile.write(line)
    ofile.write("\n")

def get_block(s, chunkSize, buffSize):
    # This function extracts the binaray floating point data
    # from the DMM7510.
    sndStr = "get_data({0})\n".format(buffSize)
    s.send(sndStr.encode())
    response = s.recv(1024)
    # New content....
    #print("***********")
    #print(response)
    #print("***********")
    #print(len(response))
    #print("***********")
    fmtStr = '%df' % (chunkSize)
    altResp = struct.unpack(fmtStr, response[2:-1])
    return altResp

def change_screen(s, my_screen):
    s.send("chng_scrn({0})\n"
        .format(my_screen)
        .encode())
    s.recv(10)
    return

#configure, trigger, transfer
#myRange = 10.0
buffSize = 25  # xfer this many reading for each write_block
s = socket.socket()                 # Establish a TCP/IP socket object
s.connect((ip_address, 5025))       # Connect to the instrument
ofile = open(output_data_path, "w") # Open/create the target data
write_header(ofile)


load_functions(s)
send_setup(s, start_v, stop_v, pts_in_ramp, repeat_count)
change_screen(s, 2)
send_trigger(s)

# add some delay after trigger to allow some data to accumulate
#time.sleep(0.5) #allow some data to accumulate
#getting an error:  struct.error: unpack requires a buffer of 100 bytes

t1 = time.time()                    # Start the timer...
for i in range(0, int(chunks)):     # Loop to collect the digitized data
    write_block(ofile, get_block(s, chunkSize, buffSize))# Write the data to file
    #write_block(ofile, get_block(s, chunkSize, chunkSize))# Write the data to file
    if i % 10 == 0 and 1==1:                 # This is here for debug purposes, printing
        print("{0:.1f}%".format(i/chunks * 100)) # out the % of run time elapsed
                                    # and technically it could be commented out.
#change_screen(s, 0)
t2 = time.time()                    # Stop the timer...

ofile.close()                       # Close the data file.
s.close()                           # Close the socket. 


# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("{0:.0f} rdgs/s".format((chunks * chunkSize)/(t2-t1)))

#input("Press Enter to continue...")
       
exit()
