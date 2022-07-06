#!/usr/bin/python

from pydoc import doc
import socket
import struct
import math
import time

#settings
seconds_to_capture = 10 # Modify this value to adjust your run time. 
#minutes_to_capture = seconds_to_capture * 60

sample_rate = 10000 # NOTE: 60kS/s is the max rate we have observed under
                    #       certain conditions/circumstances. To attain
                    #       higher sampling and data transfer rates, use
                    #       USB.
                    
chunkSize = 249     # This value is the max binary format transfer value
                    # we can implement for data transfer, and is limited
                    # by the ethernet protocol where the max frame size
                    # is < 1500 bytes, and this includes header/trailer
                    # information for each of the networking layers
                    # involved in the TCP/IP (physical, data link, network,
                    # and transport). The "chunkSize" variable defines how
                    # many readings to to transfer for a given poll of the
                    # instrument.
                    
ip_address = "134.63.74.21"     # Place your instrument's IP address here.
output_data_path = "data.txt"   # This is the output file that is created which
                                # will hold your readings provided in ASCII
                                # format in a text file. 
functions_path = "functions_V3.lua"    # This file holds the set of TSP (Lua-
                                    # based) functions that are called by
                                    # the Python script to help minimize the
                                    # amount of bytes needed to setup up and
                                    # more importantly, extract readings from
                                    # the instrument. The file is opened and 

#helpers
chunks = math.floor((seconds_to_capture * sample_rate) / chunkSize) # implement "chunkSize" instead of a fixed value

def load_functions(s):
    # This function opens the functions.lua file in the same directory as
    # the Python script and trasfers its contents to the DMM7510's internal
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

def send_setup(s, rng, sampRate, buffSize, doCurrent):
    # This function sends a string that includes the function
    # call and arguments that set up the DMM7510 for digitizing
    # current for the requested time and sample rate.
    s.send("do_setup({0}, {1}, {2}, {3})\n"
        .format(rng, sampRate, buffSize, doCurrent)
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
    for f in floats:
        ofile.write("{0:.4e}\n".format(f))
    
def get_block(s, chunkSize, buffSize):
    # This function extracts the binaray floating point data
    # from the DMM7510.
    sndStr = "get_data({0})\n".format(buffSize)
    s.send(sndStr.encode())
    response = s.recv(1024)
    # New content....
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
myRange = 10.0
buffSize = int(sample_rate * seconds_to_capture)
s = socket.socket()                 # Establish a TCP/IP socket object
s.connect((ip_address, 5025))       # Connect to the instrument
ofile = open(output_data_path, "w") # Open/create the target data

load_functions(s)
send_setup(s, myRange, sample_rate, buffSize, 0)
change_screen(s, 1)
send_trigger(s)

t1 = time.time()                    # Start the timer...
for i in range(0, int(chunks)):     # Loop to collect the digitized data
    write_block(ofile, get_block(s, chunkSize, buffSize))# Write the data to file
    if i % 10 == 0:                 # This is here for debug purposes, printing
        print("{0:.1f}%".format(i/chunks * 100)) # out the % of run time elapsed
                                    # and technically it could be commented out.
change_screen(s, 0)
t2 = time.time()                    # Stop the timer...

ofile.close()                       # Close the data file.
s.close()                           # Close the socket. 

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("{0:.0f} rdgs/s".format((chunks * chunkSize)/(t2-t1)))

input("Press Enter to continue...")
exit()
