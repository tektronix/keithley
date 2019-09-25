import socket
import struct
import math
import time

echoCmd = 0
 
functions_path = "commonside_funcs.tsp" # This file holds the set of TSP (Lua-
                                    # based) functions that are called by
                                    # the Python script to help minimize the
                                    # amount of bytes needed to setup up and
                                    # more importantly, extract readings from
                                    # the instrument. The file is opened and 

def instrConnect(mySocket, myAddress, myPort, timeOut, doReset, doIdQuery):
    mySocket.connect((myAddress, myPort)) # input to connect must be a tuple
    mySocket.settimeout(timeOut)
    if doReset == 1:
        instrSend(mySocket, "reset()")
    if doIdQuery == 1:
        tmpId = instrQuery(mySocket, "*IDN?", 100)
        print(tmpId)
    return mySocket

def instrDisconnect(mySocket):
    mySocket.close()
    return

def instrSend(mySocket, cmd):
    if echoCmd == 1:
        print(cmd)
    cmd = "{0}\n".format(cmd)
    mySocket.send(cmd.encode())
    return

def instrQuery(mySocket, cmd, rcvSize):
    instrSend(mySocket, cmd)
    time.sleep(0.1)
    return mySocket.recv(rcvSize).decode()

def Load_Functions(s):
    # This function opens the functions.lua file in the same directory as
    # the Python script and trasfers its contents to the DMM7510's internal
    # memory. All the functions defined in the file are callable by the
    # controlling program. 
    func_file = open(functions_path, "r")
    contents = func_file.read()
    func_file.close()

    cmd = "loadandrunscript loadfuncs\n{0}\nendscript".format(contents)
    instrSend(s, cmd)
   
    print(s.recv(100).decode())
    return    

ip_address = "192.168.1.37"     # Place your instrument's IP address here.
# Instrument ID String examples...
#       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
#       USB -> USB0::0x05E6::0x2450::01419962::INSTR
#       GPIB -> GPIB0::16::INSTR
#       Serial -> ASRL4::INSTR
my_port = 5025
myRange = 10.0
myNplc = 1.0
filterCnt = 10
channelStr = "1001:1005"
bufferSize = 500
scanCount = 10

s = socket.socket()                 # Establish a TCP/IP socket object
# Open the socket connection
instrConnect(s, ip_address, my_port, 20000, 1, 1)

Load_Functions(s)

t1 = time.time()                    # Start the timer...
instrSend(s, "do_beep(0.5, 4000)")

# Configure channels for commonside-ohms...
instrSend(s, "csohmsSetup({}, {}, {}, \"{}\")".format(myRange, myNplc, filterCnt, channelStr))

# Define a custom buffer
instrSend(s, "setupBuffer({})".format(bufferSize))

# Configure the scan attributes
instrSend(s, "scanSetup({}, \"{}\")".format(scanCount, channelStr))

# Start the scan
instrSend(s, "initScan()")

# The following loop determines if a scan iteration has completed
# then outputs the readings and channel numbers.
rdgsCnt = 0
extractSize = 5
startIndex = 1
endIndex = 5

while endIndex <= 50:
    rdgsCnt = int(float(instrQuery(s, "print(mybuffer.n)", 32)))
    if (rdgsCnt >= endIndex):
        print(instrQuery(s, "printbuffer({}, {}, mybuffer, mybuffer.channels)".format(startIndex, endIndex), 512)[:-1])
        startIndex += extractSize
        endIndex += extractSize
    else:
        time.sleep(0.5)

t2 = time.time()                    # Stop the timer...

instrSend(s, "computeStats()")
print("\n")
print("CH1001 MEAN, PK2PK, MAX, MIN = {}".format(instrQuery(s, "getChanStats(1001)", 128))[:-1])
print("CH1002 MEAN, PK2PK, MAX, MIN = {}".format(instrQuery(s, "getChanStats(1002)", 128))[:-1])
print("CH1003 MEAN, PK2PK, MAX, MIN = {}".format(instrQuery(s, "getChanStats(1003)", 128))[:-1])
print("CH1004 MEAN, PK2PK, MAX, MIN = {}".format(instrQuery(s, "getChanStats(1004)", 128))[:-1])
print("CH1005 MEAN, PK2PK, MAX, MIN = {}".format(instrQuery(s, "getChanStats(1005)", 128))[:-1])
print("\n")

# Close the socket connection
instrDisconnect(s)

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
