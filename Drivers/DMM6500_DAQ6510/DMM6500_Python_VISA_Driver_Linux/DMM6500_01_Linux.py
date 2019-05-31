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

DMM6500 = kei.DMM6500()
myID = DMM6500.Connect(rm, DAQ_Inst_1, timeout, 1, 1, 1)
t1 = time.time()

#DMM6500.LoadScriptFile(myFile)
#DMM6500.SendCmd("do_beep(1.0, 3500)")

stuff = DMM6500.MeasFunc.DCV.value
print(stuff)
DMM6500.SetMeasure_Function(DMM6500.MeasFunc.DCV)
DMM6500.SetMeasure_Range(10)
DMM6500.SetMeasure_NPLC(1.0)
DMM6500.SetMeasure_InputImpedance(DMM6500.InputZ.Z_10M)
DMM6500.SetMeasure_AutoZero(DMM6500.DmmState.ON)
DMM6500.SetMeasure_FilterType(DMM6500.FilterType.REP)
DMM6500.SetMeasure_FilterCount(100)
DMM6500.SetMeasure_FilterState(DMM6500.DmmState.ON)
print(DMM6500.Measure(1))
time.sleep(1.0)

DMM6500.Disconnect()
rm.close()

t2 = time.time()

# Notify the user of completion and the test time achieved. 
print("done")
print("{0:.6f} s".format(t2-t1))
input("Press Enter to continue...")
exit()


