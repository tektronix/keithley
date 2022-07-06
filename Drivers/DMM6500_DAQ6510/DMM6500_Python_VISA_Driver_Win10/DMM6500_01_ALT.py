import visa
import struct
import math
import time
import DMM6500_VISA_Driver as kei



#===== MAIN PROGRAM STARTS HERE =====
rm = visa.ResourceManager()	# Opens the resource manager and sets it to variable rm
DAQ_Inst_1 = "USB0::0x05E6::0x6500::04340541::INSTR"
# DAQ_Inst_1 = "TCPIP0::192.168.1.2::inst0::INSTR"
# Instrument ID String examples...
#       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
#       USB -> USB0::0x05E6::0x2450::01419962::INSTR
#       GPIB -> GPIB0::16::INSTR
#       Serial -> ASRL4::INSTR
timeout = 20000
myFile = "dmm_functions.tsp"

DMM6500 = kei.DMM6500()
myID = DMM6500.Connect(rm, DAQ_Inst_1, timeout, 1, 1, 1)
t1 = time.time()

DMM6500.LoadScriptFile(myFile)
DMM6500.SendCmd("do_beep(1.0, 3500)")
time.sleep(4.5)
DMM6500.Disconnect()
rm.close()

t2 = time.time()

# Notify the user of completion and the test time achieved. 
print("done")
print("{0:.6f} s".format(t2-t1))
input("Press Enter to continue...")
exit()


