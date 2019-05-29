#--------------------------------------------------------------------------------
#   DESCRIPTION:
#       a. This example uses the Keithley DAQ6510 to perform DC voltage
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

def writeToInitialState(ch111, ch112, ch113, ch114):
    streamer.log("CH111", ch111)
    streamer.log("CH112", ch112)
    streamer.log("CH113", ch113)
    streamer.log("CH114", ch114)
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
DAQ6510.echoCmd = 0
scanCount = 1000
scanInterval = 5  # for this setup, limit to no less than 5s intervals

print(myID)
t1 = time.time()

DAQ6510.LoadScriptFile(myFile)
DAQ6510.SendCmd("do_beep(1.0, 3500)")

DAQ6510.Reset()
DAQ6510.SetFunction_DC_Voltage("111,112,113,114", DAQ6510.InputZ.Z_AUTO)
DAQ6510.SetMeasure_Range("111,113", 10.0)
DAQ6510.SetMeasure_Range("112,114", 1.0)
DAQ6510.SetMeasure_NPLC("111,112,113,114", 10.0)
DAQ6510.SetMeasure_AutoDelay("111,112,113,114", DAQ6510.DmmState.ON)
DAQ6510.SetMeasure_AutoZero("111,112,113,114", DAQ6510.DmmState.ON)
DAQ6510.SetMeasure_Count("111,112,113,114", 1)
DAQ6510.SetMeasure_Filter(DAQ6510.DmmState.ON, DAQ6510.FilterType.MOV, 10)

DAQ6510.SetScan_BasicAttributes("111,112,113,114", scanCount, scanInterval)
DAQ6510.Init()
startIndex = 1
endIndex = 4
chanCnt = 4
targetCnt = scanCount * 4
loopCnt = 1
accumCnt = DAQ6510.QueryCmd("print(defbuffer1.n)", 8)
while(endIndex < (targetCnt+1)):
    myData = DAQ6510.GetScan_Data(chanCnt, startIndex, endIndex)
    print("Scan {}: {}".format(loopCnt, myData))
    myDataList = myData.split(",")
    writeToInitialState(float(myDataList[0]), float(myDataList[1]), float(myDataList[2]), float(myDataList[3]))
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


