#!/usr/bin/python
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
DAQ6510.echoCmd = 0
scanCount = 360
scanInterval = 10.0

print(myID)
t1 = time.time()

DAQ6510.LoadScriptFile(myFile)
DAQ6510.SendCmd("do_beep(1.0, 3500)")

DAQ6510.Reset()
DAQ6510.SetFunction_Temperature("101,110,115,120", DAQ6510.Transducer.TC, DAQ6510.TCType.K)
DAQ6510.SetScan_BasicAttributes("101,110,115,120", scanCount, scanInterval)
DAQ6510.Init()

startIndex = 1
endIndex = 4
chanCnt = 4
targetCnt = scanCount * 4
loopCnt = 1
accumCnt = DAQ6510.QueryCmd("print(defbuffer1.n)", 8)
while(endIndex < (targetCnt+1)):
    print("Scan {}: {}".format(loopCnt, DAQ6510.GetScan_Data(chanCnt, startIndex, endIndex)))
    startIndex += chanCnt
    endIndex += chanCnt
    loopCnt += 1
        
time.sleep(1.0)

DAQ6510.Disconnect()

t2 = time.time()

# Notify the user of completion and the test time achieved. 
print("done")
print("{0:.6f} s".format(t2-t1))
input("Press Enter to continue...")
exit()

exit()


