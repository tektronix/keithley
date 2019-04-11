import visa 
import struct
import math
import time

doDebug = 1
rm = 0
myDaq = 0
printCmds = 0

# ============================================================                               
# DEFINE FUNCTIONS BELOW...
# ============================================================
def KEI_Connect(rsrcString, doIdQuery, doReset, doClear):
    myInstr = rm.open_resource(rsrcString)
    if doIdQuery == 1:
        print(KEI_Query(myInstr, "*IDN?"))
    if doReset == 1:
        KEI_Write(myInstr, "*RST")
    if doClear == 1:
        myInstr.clear()
    myInstr.timeout = 10000
    return myInstr

def KEI_Write(myInstr, cmd):
    if printCmds == 1:
        print(cmd)
    myInstr.write(cmd)
    return

def KEI_Query(myInstr, cmd):
    if printCmds == 1:
        print(cmd)
    return myInstr.query(cmd)

def KEI_Query_Binary_Values(myInstr, cmd):
    if printCmds == 1:
        print(cmd)
    return myInstr.query_binary_values(cmd, datatype = 'f', is_big_endian = False)

def KEI_Disconnect(myInstr):
    myInstr.close()
    return


#================================================================================
#
#    MAIN CODE STARTS HERE
#
#================================================================================
DAQ_Inst_1 = "USB0::0x05E6::0x6510::04340543::INSTR"
# Instrument ID String examples...
#       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
#       USB -> USB0::0x05E6::0x2450::01419962::INSTR
#       GPIB -> GPIB0::16::INSTR
#       Serial -> ASRL4::INSTR

# Capture the program start time...
t1 = time.time()                    

# Opens the resource manager and sets it to variable rm then
#    connect to the DAQ6510
rm = visa.ResourceManager()	
myDaq = KEI_Connect(DAQ_Inst_1, 1, 1, 1)

# Reset and start from known conditions
KEI_Write(myDaq, "*RST")

# Set up the reading buffer
KEI_Write(myDaq, "TRACe:MAKE 'mybuf', 1000")
KEI_Write(myDaq, "TRACe:CLEar 'mybuf'")
KEI_Write(myDaq, "FORM:ASC:PREC 0")

# Configure the channel measurement settings to optimize for speed
#    a. Setting a fixed range
#    b. Disabling auto zero
#    c. Disabling auto delay
#    d. Turn line sync off
#    e. Disable filtering and limits
#    f. Decreasing the power line cycles (PLC) to the minimum
KEI_Write(myDaq, "SENS:FUNC 'VOLT', (@101:110)")
KEI_Write(myDaq, "SENS:VOLT:RANG 1, (@101:110)")
KEI_Write(myDaq, "SENS:VOLT:RANG:AUTO 0, (@101:110)")
KEI_Write(myDaq, "SENS:VOLT:AZER OFF, (@101:110)")
KEI_Write(myDaq, "DISP:VOLT:DIG 4, (@101:110)")
KEI_Write(myDaq, "SENS:VOLT:NPLC 0.0005, (@101:110)")
KEI_Write(myDaq, "SENS:VOLT:LINE:SYNC OFF, (@101:110)")
KEI_Write(myDaq, "CALC2:VOLT:LIM1:STAT OFF, (@101:110)")
KEI_Write(myDaq, "CALC2:VOLT:LIM2:STAT OFF, (@101:110)")

# Configure the scanning attributes
KEI_Write(myDaq, "ROUT:SCAN:COUN:SCAN 100")
KEI_Write(myDaq, "ROUT:SCAN:BUFF 'mybuf'")
KEI_Write(myDaq, "ROUT:SCAN:INT 0.0")
KEI_Write(myDaq, "ROUT:SCAN:CRE (@101:110)")

# Change to processing the screen
KEI_Write(myDaq, "DISP:SCR PROC")

# Start the scan...
t2 = time.time()                    # Capture the time when the scan begins...
KEI_Write(myDaq, "INIT")

# Check the state of the scan (via the trigger model), if running 
#    or waiting, then continue to hold; if idle then exit the 
#    loop and extract the data. 
rcvBuffer = KEI_Query(myDaq, "TRIG:STAT?")
while (("RUNNING" in rcvBuffer) or ("WAITING" in rcvBuffer)):
    time.sleep(0.01)
    rcvBuffer = KEI_Query(myDaq, "TRIG:STAT?")
t3 = time.time()                    # Captured the time when the scan ends...

# Change to HOME the screen
KEI_Write(myDaq, "DISP:SCR HOME")

# Extract the data
print(KEI_Query(myDaq, "TRACe:DATA? 1, 1000, 'mybuf'"))

t4 = time.time()                    # Capture the time when the test is complete...

# Terminate the instrument and resource sessions
KEI_Disconnect(myDaq)
rm.close

# Notify the user of completion and the data streaming rate achieved. 
print("done\n")
print("Elapsed Total Test Time: {0:0.3f} s".format(t4-t1))
print("Elapsed Test Configuration Time: {0:0.3f} s".format(t2-t1))
print("Elapsed Scan Time: {0:0.3f} s".format(t3-t2))
print("Elapsed Data Extraction Time: {0:0.3f} s".format(t4-t3))
print("Calculated Scan Rate: {0:0.3f} chan/s".format(1000/(t3-t2)))
print("Calculated Scan Rate with Data Extraction: {0:0.3f} chan/s".format(1000/(t4-t2)))

input("\nPress Enter to continue...")
exit()
