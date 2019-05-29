#--------------------------------------------------------------------------------
#   DESCRIPTION:
#       a. This example uses the Keithley DAQ6510 to perform 2W-Resistance
#          scanning
#       b. For storing results to the cloud, we introduce the streaming
#          tools provided by Initial State
#              i. To install the Python driver for the streaming tools
#                 open a command prompt or terminal
#             ii. Issue the following command:
#                     aa. On Win10: pip install ISStreamer
#                     bb. On Linux: sudo pip install ISStreamer
#                                   or sudo pip3 install ISStreamer
#--------------------------------------------------------------------------------
import socket
import struct
import math
import time
import Keithley_DMM6500_Sockets_Driver as kei
from ISStreamer.Streamer import Streamer


def writeToInitialState(ch102, ch103, ch104, ch105, ch106, ch116):
    # NOTE: We do not recommend fast writing fast scanned data to
    # your IS End Point. The tools are not meant for speed and
    # the update rate for the site is limited to a certain number
    # of data items per second. (See the IS documentation for
    # details.
    streamer.log("CH102", ch102)
    streamer.log("CH103", ch103)
    streamer.log("CH104", ch104)
    streamer.log("CH105", ch105)
    streamer.log("CH106", ch106)
    streamer.log("CH116", ch116)
    return

#===== MAIN PROGRAM STARTS HERE =====
ipAddress1 = "192.168.1.165"
port = 5025
timeout = 20.0
myFile = "dmm_functions.tsp"

bucketName = time.strftime("DAQ6510_Data_%Y-%m-%d_%H-%M-%S")
myAccessKey = "YOUR_ACCESS_KEY_GOES_HERE"
streamer = Streamer(bucket_name=bucketName,
                    access_key=myAccessKey)

DAQ6510 = kei.DMM6500()
myID = DAQ6510.Connect(ipAddress1, 5025, 20000, 1, 1)
DAQ6510.echoCmd = 1
scanCount = 100
scanInterval = 10  # for this setup, limit to no less than 5s intervals

print(myID)
t1 = time.time()

DAQ6510.LoadScriptFile(myFile)
DAQ6510.SendCmd("do_beep(1.0, 3500)")

DAQ6510.Reset()
DAQ6510.SetFunction_2W_Resistance("102:106,116")
DAQ6510.SetMeasure_Range("102:106,116", DAQ6510.AutoRange.ON)
DAQ6510.SetMeasure_NPLC("102:106,116", 1.0)
DAQ6510.SetMeasure_AutoDelay("102:106,116", DAQ6510.DmmState.ON)
DAQ6510.SetMeasure_AutoZero("102:106,116", DAQ6510.DmmState.ON)
DAQ6510.SetMeasure_Count("102:106,116", 1)

DAQ6510.SetScan_BasicAttributes("102:106,116", scanCount, scanInterval)
DAQ6510.Init()
startIndex = 1
endIndex = 6
chanCnt = 6
targetCnt = scanCount * chanCnt
loopCnt = 1
accumCnt = DAQ6510.QueryCmd("print(defbuffer1.n)", 8)
while(endIndex < (targetCnt+1)):
    myData = DAQ6510.GetScan_Data(chanCnt, startIndex, endIndex)
    print("Scan {}: {}".format(loopCnt, myData))
    myDataList = myData.split(",")
    writeToInitialState(float(myDataList[0]), float(myDataList[1]), float(myDataList[2]),
                        float(myDataList[3]), float(myDataList[4]), float(myDataList[5]))
    startIndex += chanCnt
    endIndex += chanCnt
    loopCnt += 1
        
DAQ6510.Disconnect()

t2 = time.time()

# Notify the user of completion and the test time achieved. 
print("done")
print("{0:.6f} s".format(t2-t1))
input("Press Enter to continue...")
exit()

exit()


