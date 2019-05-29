#!/usr/bin/python
import visa
import struct
import math
import time
import Keithley_DMM6500_VISA_Driver as kei

#===== MAIN PROGRAM STARTS HERE =====
rm = visa.ResourceManager()	# Opens the resource manager and sets it to variable rm
DAQ_Inst_1 = "TCPIP0::192.168.1.165::inst0::INSTR"
# Instrument ID String examples...
#       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
#       USB -> USB0::0x05E6::0x2450::01419962::INSTR
#       GPIB -> GPIB0::16::INSTR
#       Serial -> ASRL4::INSTR
timeout = 20000
myFile = "dmm_functions.tsp"

DAQ6510 = kei.DMM6500()
myID = DAQ6510.Connect(rm, DAQ_Inst_1, timeout, 1, 1, 1)
DAQ6510.echoCmd = 0
scanCount = 20
scanInterval = 0.5

print(myID)
t1 = time.time()

#DAQ6510.LoadScriptFile(myFile)
#DAQ6510.SendCmd("do_beep(1.0, 3500)")

DAQ6510.Reset()
DAQ6510.SetFunction_Temperature("101,110,115,120", DAQ6510.Transducer.TC, DAQ6510.TCType.K)
DAQ6510.SetScan_BasicAttributes("101,110,115,120", scanCount, scanInterval)
DAQ6510.Init()

startIndex = 1
endIndex = 4
chanCnt = 4
targetCnt = scanCount * 4
loopCnt = 1
accumCnt = DAQ6510.QueryCmd("print(defbuffer1.n)")
while(endIndex < (targetCnt+1)):
    print("Scan {}: {}".format(loopCnt, DAQ6510.GetScan_Data(chanCnt, startIndex, endIndex)))
    startIndex += chanCnt
    endIndex += chanCnt
    loopCnt += 1

DAQ6510.Disconnect()
rm.close()
t2 = time.time()

# Notify the user of completion and the test time achieved. 
print("done")
print("{0:.6f} s".format(t2-t1))
input("Press Enter to continue...")
exit()


