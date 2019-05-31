import visa
import struct
import math
import time
import Keithley_Model_2380_VISA_Driver as kei2380
from ISStreamer.Streamer import Streamer

def writeToInitialState(myCurr, myVolt):
    streamer.log("CURR", myCurr)
    streamer.log("VOLT", myVolt)
    return

#===== MAIN PROGRAM STARTS HERE =====
rm = visa.ResourceManager()	# Opens the resource manager and sets it to variabl
Inst_1 = "GPIB0::6::INSTR"
# Instrument ID String examples...
#       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
#       USB -> USB0::0x05E6::0x2450::01419962::INSTR
#       GPIB -> GPIB0::16::INSTR
#       Serial -> ASRL4::INSTR
timeout = 20000
bucketName = time.strftime("CR123A_Discharge_%Y-%m-%d_%H-%M-%S")
myAccessKey = "ist_nQyQRT8qhhCZ3mOlVDfxsqVaX4QJLzLd"
streamer = Streamer(bucket_name=bucketName,
                    access_key=myAccessKey)

KEI2380 = kei2380.LOAD2380()
myID = KEI2380.Connect(rm, Inst_1, timeout, 1, 1, 1)
KEI2380.echoCmd = 0
t1 = time.time()

# set up for CC of a CR123A Lithium Battery
KEI2380.Set_DisplayMode(KEI2380.DisplayMode.TEXT)
KEI2380.Set_DisplayText(0, "Dischrg Batt in 3                    ")
time.sleep(1.0)
KEI2380.Set_DisplayText(0, "Dischrg Batt in 2                    ")
time.sleep(1.0)
KEI2380.Set_DisplayText(0, "Dischrg Batt in 1                    ")
time.sleep(1.0)
KEI2380.Set_DisplayMode(KEI2380.DisplayMode.NORMAL)
KEI2380.Set_Function(KEI2380.Function.CC)
KEI2380.Set_Level(0.5)
KEI2380.Set_Range(1.5)
KEI2380.Set_OutputState(KEI2380.State.ON)
# delay to settle...
time.sleep(1.0)

# Now loop to capture discharge current and voltage
j = 1000
while(j > 1.0):
    myCurr = float(KEI2380.Get_Current())
    myVolt = float(KEI2380.Get_Voltage())
    print("Current {:6.6f}; Voltage {:6.6f}".format(myCurr, myVolt))
    writeToInitialState(myCurr, myVolt)
    time.sleep(1.0)
    j = myVolt
    
time.sleep(5.0)
KEI2380.Set_OutputState(KEI2380.State.OFF)
#KEI2380.SetMeasure_FilterState(DMM6500.DmmState.ON)

#time.sleep(1.0)

KEI2380.Disconnect()
rm.close()

t2 = time.time()

# Notify the user of completion and the test time achieved. 
print("done")
print("{0:.6f} s".format(t2-t1))
input("Press Enter to continue...")
exit()


