'''
    DETAILS
    
'''
import visa
import time

rm = 0
myDmm = 0

def KEIDMM6500_Connect(rsrcString, getIdStr, timeout, doRst):
    myDmm = rm.open_resource(rsrcString)	#opens desired resource and sets it variable my_instrument
    myDmm.write_termination = '\n'
    myDmm.read_termination = '\n'
    myDmm.send_end = True
    if getIdStr == 1:
        print(myDmm.query("*IDN?"))
    myDmm.timeout = timeout
    if doRst == 1:
        myDmm.write('*RST')
        #time.sleep(0.1)
    return myDmm

def KEIDMM6500_Disconnect():
    myDmm.close
    return

def KEIDMM6500_Send(sndBuffer):
    myDmm.write(sndBuffer)
    return

def KEIDMM6500_Query(sndBuffer):
    return myDmm.query(sndBuffer)

#================================================================================
#    MAIN CODE GOES HERE
#================================================================================
t1 = time.time()    # Capture start time....
#rm = visa.ResourceManager()	# Opens the resource manager and sets it to variable rm
rm = visa.ResourceManager('@py')

myDmm = KEIDMM6500_Connect("TCPIP0::192.168.1.165::inst0::INSTR", 1, 20000, 1)
# Instrument ID String examples...
#       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
#       GPIB -> GPIB0::16::INSTR
#       Serial -> ASRL4::INSTR
KEIDMM6500_Send("*RST")
KEIDMM6500_Send(":SENS:FUNC \"FRES\"") 
KEIDMM6500_Send(":SENS:FRES:RANG: AUTO ON") 
KEIDMM6500_Send(":SENS:FRES:OCOM ON") 
KEIDMM6500_Send(":SENS:FRES:AZER ON") 
KEIDMM6500_Send(":SENS:FRES:NPLC 1")
print(KEIDMM6500_Query("READ?"))

KEIDMM6500_Disconnect()

rm.close

t2 = time.time() # Capture stop time...
print("{0:.3f} s".format((t2-t1)))
