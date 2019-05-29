#--------------------------------------------------------------------------------
#   DESCRIPTION:
#       a. This example uses the Keithley DAQ6510 to perform temperature
#          scanning 
#--------------------------------------------------------------------------------
import socket
import struct
import math
import time
import Keithley_DMM6500_Sockets_Driver as kei


#===== MAIN PROGRAM STARTS HERE =====
ipAddress1 = "192.168.1.165"
port = 5025
timeout = 20.0
myFile = "dmm_functions.tsp"

DAQ6510 = kei.DMM6500()
myID = DAQ6510.Connect(ipAddress1, 5025, 20000, 1, 1)
DAQ6510.echoCmd = 1
scanCount = 10
scanInterval = 1.0  # for this setup, limit to no less than 5s intervals

print(myID)
t1 = time.time()

DAQ6510.LoadScriptFile(myFile)
DAQ6510.SendCmd("do_beep(1.0, 3500)")

DAQ6510.Reset()
DAQ6510.SetFunction_4W_Resistance("107:109", DAQ6510.OCOMP.ON, DAQ6510.OLeadDetect.ON)
DAQ6510.SetMeasure_Range("107:109", DAQ6510.AutoRange.ON)
DAQ6510.SetMeasure_NPLC("107:109", 1.0)
DAQ6510.SetMeasure_AutoDelay("107:109", DAQ6510.DmmState.ON)
DAQ6510.SetMeasure_AutoZero("107:109", DAQ6510.DmmState.ON)
DAQ6510.SetMeasure_Count("107:109", 1)

DAQ6510.SetScan_BasicAttributes("107:109", scanCount, scanInterval)
DAQ6510.Init()
startIndex = 1
endIndex = 3
chanCnt = 3
targetCnt = scanCount * chanCnt
loopCnt = 1
accumCnt = DAQ6510.QueryCmd("print(defbuffer1.n)", 8)
while(endIndex < (targetCnt+1)):
    myData = DAQ6510.GetScan_Data(chanCnt, startIndex, endIndex)
    print("Scan {}: {}".format(loopCnt, myData))
    myDataList = myData.split(",")
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


