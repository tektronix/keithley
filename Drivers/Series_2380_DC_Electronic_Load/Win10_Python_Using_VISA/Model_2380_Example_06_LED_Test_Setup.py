import visa
import struct
import math
import time
import Keithley_Model_2380_VISA_Driver as kei2380

#===== MAIN PROGRAM STARTS HERE =====
rm = visa.ResourceManager()	# Opens the resource manager and sets it to variabl
Inst_1 = "GPIB0::6::INSTR"
# Instrument ID String examples...
#       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
#       USB -> USB0::0x05E6::0x2450::01419962::INSTR
#       GPIB -> GPIB0::16::INSTR
#       Serial -> ASRL4::INSTR
timeout = 20000

KEI2380 = kei2380.LOAD2380()
myID = KEI2380.Connect(rm, Inst_1, timeout, 1, 1, 1)
KEI2380.echoCmd = 1
t1 = time.time()

#KEI2380.Set_DisplayMode(KEI2380.DisplayMode.NORMAL)
KEI2380.Set_Function(KEI2380.Function.CR)
KEI2380.Set_LEDTest_State(KEI2380.State.ON)
KEI2380.Set_Level(150)
KEI2380.Set_Range(1500.0)
KEI2380.Set_HighLow(120.0, 1.9)
KEI2380.Set_LEDTest_Vd(43.0)
KEI2380.Set_OutputState(KEI2380.State.ON)
time.sleep(5.0)
KEI2380.Set_OutputState(KEI2380.State.OFF)

KEI2380.Disconnect()
rm.close()

t2 = time.time()

# Notify the user of completion and the test time achieved. 
print("done")
print("{0:.6f} s".format(t2-t1))
raw_input("Press Enter to continue...")
exit()


