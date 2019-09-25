import socket
import struct
import math
import time

echoCmd = 0
 
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

# --------------------------------------------------------------------------------
#   MAIN CODE STARTS HERE
# --------------------------------------------------------------------------------
ip_address = "192.168.1.37"     # Place your instrument's IP address here.
# Instrument ID String examples...
#       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
#       USB -> USB0::0x05E6::0x2450::01419962::INSTR
#       GPIB -> GPIB0::16::INSTR
#       Serial -> ASRL4::INSTR
my_port = 5025
s = socket.socket()                 # Establish a TCP/IP socket object
# Open the socket connection
instrConnect(s, ip_address, my_port, 20000, 1, 1)

t1 = time.time()                    # Start the timer...
instrSend(s, "reset()")
instrSend(s, "channel.open('allslots')")
instrSend(s, "errorqueue.clear()")
instrSend(s, "eventlog.clear()")
instrSend(s, "dataqueue.clear()")

# Configure the scan channel for the slot 1 card
# Enable common-side ohms
instrSend(s, "dmm.func = dmm.COMMON_SIDE_OHMS")
instrSend(s, "dmm.autorange = dmm.OFF")
instrSend(s, "dmm.range = 10")
instrSend(s, "dmm.nplc = 1.0")
# Enable offset compensation (though on by
#   default when using common-side ohms
instrSend(s, "dmm.offsetcompensation = dmm.ON")
# Ensure autodelay and autozero are active
instrSend(s, "dmm.autodelay = dmm.ON")
instrSend(s, "dmm.autozero = dmm.ON")
# Enable averaging and adjust settings
instrSend(s, "dmm.filter.type = dmm.FILTER_REPEAT_AVG")
instrSend(s, "dmm.filter.count = 10")
instrSend(s, "dmm.filter.window = 0.0")
instrSend(s, "dmm.filter.enable = dmm.ON")
# Define the settings above as a configuration
instrSend(s, "dmm.configure.set('commonside4w')")
# ...and apply the configuration to the channels
# of interest. 
instrSend(s, "dmm.setconfig('1001:1005', 'commonside4w')")

# Define a custom buffer
instrSend(s, "mybuffer = dmm.makebuffer(500)")
instrSend(s, "mybuffer.clear()")
instrSend(s, "mybuffer.appendmode = 1")

# Configure the scan attributes
instrSend(s, "scan.mode = scan.MODE_FIXED_ABR")
instrSend(s, "scan.measurecount = 1")
instrSend(s, "scan.scancount = 10")
instrSend(s, "scan.create('1001:1005')")
# Start the scan
instrSend(s, "scan.background(mybuffer)")

# The following loop determines if a scan iteration has completed
# then outputs the readings and channel numbers.
rdgsCnt = 0
extractSize = 5
startIndex = 1
endIndex = 5

while endIndex <= 50:
    rdgsCnt = int(float(instrQuery(s, "print(mybuffer.n)", 32)))
    if (rdgsCnt >= endIndex):
        print(instrQuery(s, "printbuffer({}, {}, mybuffer, mybuffer.channels)".format(startIndex, endIndex), 512))
        startIndex += extractSize
        endIndex += extractSize
    else:
        time.sleep(0.5)

# NOTE: Printing of statistical information (mean and peak-to-peak)
#       are omitted in this example since the 3706A does not have
#       the built-in statistics functions. However, we can create
#       a script function on the instrument that performs the
#       calculations for us. We leave that for a separate exercise
#       in which we can go into more detail about scripting, loading
#       a script onto the instrument, and calling functions that
#       are local to the instrument.

t2 = time.time()                    # Stop the timer...

# Close the socket connection
instrDisconnect(s)

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
