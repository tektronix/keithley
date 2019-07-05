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

KEI2380.Set_DisplayMode(KEI2380.DisplayMode.NORMAL)
KEI2380.Set_Function(KEI2380.Function.CC)
KEI2380.Set_Level(0.001)
KEI2380.Set_Range(1.5)
KEI2380.Set_TransientMode(KEI2380.TransientMode.TOGGLE)
KEI2380.Set_TransientLevels(0.9, 0.001)
KEI2380.Set_CC_SlewRatePositive(0.005)
KEI2380.Set_CC_SlewRateNegative(0.005)
KEI2380.Set_CC_SlewSlowRateState(KEI2380.State.OFF)
KEI2380.Set_OutputState(KEI2380.State.ON)
KEI2380.Set_TransientState(KEI2380.State.ON)
KEI2380.Set_TriggerSource(KEI2380.TrigSrc.BUS)
# delay to settle...
time.sleep(1.0)

# Now loop to capture discharge current and voltage
j = 1000
while(j > 1.0):
    myCurr = float(KEI2380.Get_Current())
    myVolt = float(KEI2380.Get_Voltage())
    print("Current {:6.6f}; Voltage {:6.6f}".format(myCurr, myVolt))
    writeToInitialState(myCurr, myVolt)
    
    KEI2380.Bus_TrigCurrent()
    time.sleep(3.0)
    KEI2380.Bus_TrigCurrent()
    time.sleep(27.0)
    j = myVolt
    
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


