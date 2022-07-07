""" ================================================================================

*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***

================================================================================ """

"""
====================================================================================================

    This example configures a series of channels within the 3706A mainframe for
    DCV measurement scanning. Additionally, a log file is created on a USB drive
    connected to the front port of the meter and writes the measurement information
    after each scan. 

====================================================================================================
"""

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

def Write_Header(ofile):
    # This function writes the floating point data to the
    # target file. 
    #for f in floats:
    myStr = ""
    #for j in range(1, 21, 1):
    #    if j == 1:
    #        myStr = "{0}".format(str(j+100))
    #    else:
    #        myStr = "{0},{1}".format(myStr, str(j+100))
    #        
    #for j in range(1, 21, 1):
    #    myStr = "{0},{1}".format(myStr, str(j+200))
    myStr = "Date-Time,CH1001,CH1002,CH1003,CH1004,CH1005,CH1006,CH1007,CH1008,CH1009,CH1010\n"
    #print(myStr)
    ofile.write(myStr)
    return
    
def Write_Data(output_data_path, dataStr):
    # This function writes the floating point data to the
    # target file. 
    #for f in floats:
    ofile = open(output_data_path, "a") # append the target data
    dataStr = "{0}".format(dataStr)
    ofile.write(dataStr)

    ofile.close()                       # Close the data file.
    
    return

def Configure_DCV_Scan(s, scan_channels, dcv_range, use_input_divider, scan_count, scan_interval):
    instrSend(s, "reset()")     				# Reset
    instrSend(s, "dmm.func = dmm.DC_VOLTS") 			# Set measurement function
    instrSend(s, "dmm.nplc=1") 					# Set NPLC
    if dcv_range < 0.001:					# Set Range
            instrSend(s, "dmm.autorange = dmm.ON") 
    else:
            instrSend(s, "dmm.autorange = dmm.OFF") 
            instrSend(s, "dmm.range = {0}".format(dcv_range)) 								
    
    instrSend(s, "dmm.autodelay = dmm.ON") 			# Ensure Auto Delay is enabled
    instrSend(s, "dmm.autozero = dmm.ON") 			# Enable Auto Zero
    if use_input_divider == 1:			                # Apply the 10M input divider as needed
            instrSend(s, "dmm.inputdivider = dmm.ON") 					
    else:
            instrSend(s, "dmm.inputdivider = dmm.OFF") 

    instrSend(s, "dmm.configure.set(\"mydcvolts\")") 	                        # Save Configuration
    instrSend(s, "dmm.setconfig(\"{0}\",\"mydcvolts\")".format(scan_channels)) 	# Assign configuration to channels
    
    instrSend(s, "channel.connectrule = channel.BREAK_BEFORE_MAKE") 
    
    if scan_interval > 0.1:
            # Establish the settings that will apply the interval between the start of scans
            instrSend(s, "trigger.timer[1].reset()") 					# Ensure the timer gets to a known relative time start point
            instrSend(s, "trigger.timer[1].count = 0") 					# No reapeating timer events
            instrSend(s, "trigger.timer[1].delay = {0}".format(scan_interval)) 		# Apply the anticipated scan interval 
            instrSend(s, "trigger.timer[1].stimulus = scan.trigger.EVENT_MEASURE_COMP") # 
            instrSend(s, "trigger.timer[1].passthrough = false") 			# Trigger only initiates the delay
            instrSend(s, "trigger.blender[1].reset()") 					# Configure the blender stimulus...
            instrSend(s, "trigger.blender[1].orenable = true") 				# ... for OR'ing operation
            instrSend(s, "trigger.blender[1].stimulus[1] = trigger.timer[1].EVENT_ID") 	# ... to respond/notify upon a timer event
            instrSend(s, "trigger.blender[1].stimulus[2] = scan.trigger.EVENT_SCAN_READY") 	# ... or when then scan is ready (configured)
            instrSend(s, "scan.trigger.arm.stimulus = trigger.blender[1].EVENT_ID") 	# Key triggering off of the blender event
    
    
    instrSend(s, "scan.create(\"{0}\")".format(scan_channels)) 				# Create the scan 
    instrSend(s, "scan.scancount = {0}".format(scan_count)) 				# Set the Scan Count
    instrSend(s, "reading_buffer = dmm.makebuffer(scan.scancount * scan.stepcount)") 	# Configure Buffer
    instrSend(s, "scan.background(reading_buffer)") 				        # Execute Scan and save to buffer
    return

""" ==============================================================================================================
        MAIN CODE STARTS HERE
============================================================================================================== """
ip_address = "192.168.1.37"     # Place your instrument's IP address here.
my_port = 5025

output_data_path = time.strftime("data_%Y-%m-%d_%H-%M-%S.csv")   # This is the output file that is created which
                                                                        # will hold your readings provided in ASCII
                                                                        # format in a text file.


s = socket.socket()                 # Establish a TCP/IP socket object
# Open the socket connection
instrConnect(s, ip_address, my_port, 20000, 1, 1)

t1 = time.time()                    # Start the timer...

scanchannels = "1001:1060"          # Define the channels to scan here. Note the following format possibilities...
                                    #   1001:10060 - All channels starting with 1001 and ending with 1060
                                    #   1001,1002,1004 - Just channels 1001, 1002, and 1004
                                    #   1007:1010,1021,1031:1040 - Channels 1007 through 1010, channel 1021, and channels 1031 through 1040
rangedcv = 10                       # Define the DCV range. If auto-ranging is desired, pass 0
useinputdivider = 1                 # 1 = True; 0 = False
scancount = 10                     # Number of times to run the scan
scaninterval = 5                    # Delay between the start of each scan (if needed)

Configure_DCV_Scan(s, scanchannels, rangedcv, useinputdivider, scancount, scaninterval)


expectedCnt = 30
channelcount = int(float(instrQuery(s, "print(scan.stepcount)", 64)))
startindex = 1
endindex = channelcount
total_readings_count = 0
target = channelcount * scancount
cntr = 1

# Extract readings while the scan is running....
while(total_readings_count < target):
    vals = int(float(instrQuery(s, "print(reading_buffer.n)", 16)))
    
    while(vals < endindex):
        time.sleep(0.1)
        vals = int(float(instrQuery(s, "print(reading_buffer.n)", 16)))
      
    data_string = instrQuery(s, "printbuffer({},{}, reading_buffer.readings)".format(startindex, endindex), 2048)
    print("Scan {0:4} : {1}".format(cntr, data_string))
    Write_Data(output_data_path, data_string)
    startindex += channelcount
    endindex += channelcount
    total_readings_count += channelcount
    cntr += 1
        

# Close the socket connection
instrDisconnect(s)
t2 = time.time()

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
