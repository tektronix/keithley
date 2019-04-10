'''
    DETAILS
    
'''
import visa
import time

rm = 0
my_PS = 0

def KEI2231_Connect(rsrcString, getIdStr, timeout, doRst):
    my_PS = rm.open_resource(rsrcString, baud_rate = 9600, data_bits = 8)	#opens desired resource and sets it variable my_instrument
    my_PS.write_termination = '\n'
    my_PS.read_termination = '\n'
    my_PS.send_end = True
    my_PS.StopBits = 1
    # my_PS.flow_control =      # only available in PyVisa 1.9
    #my_PS.baud_rate = 9600
    if getIdStr == 1:
        print(my_PS.query("*IDN?"))
        #time.sleep(0.1)
    my_PS.write('SYST:REM')
    #print(my_PS.timeout)
    my_PS.timeout = timeout
    #print(my_PS.timeout)
    if doRst == 1:
        my_PS.write('*RST')
        #time.sleep(0.1)
    return my_PS

def KEI2231A_Disconnect():
    my_PS.write('SYST:LOC')
    my_PS.close
    return

def KEI2231A_SelectChannel(myChan):
    my_PS.write("INST:NSEL %d" % myChan)
    #time.sleep(0.25)
    return

def KEI2231A_SetVoltage(myV):
    my_PS.write("VOLT %f" % myV)
    #time.sleep(0.24)
    return

def KEI2231A_SetCurrent(myI):
    my_PS.write("CURR %f" % myI)
    #time.sleep(0.24)
    return

def KEI2231A_OutputState(myState):
    if myState == 0:
        my_PS.write("OUTP 0")
        #time.sleep(0.25)
        #my_PS.write("OUT:ENAB 0")
    else:
        my_PS.write("OUTP 1")
        #time.sleep(0.25)
        #my_PS.write("OUT:ENAB 1")
    #time.sleep(0.25)
    return

def KEI2231_Send(sndBuffer):
    my_PS.write(sndBuffer)
    return

def KEI2231_Query(sndBuffer):
    return my_PS.query(sndBuffer)

    


#================================================================================
#    MAIN CODE GOES HERE
#================================================================================
t1 = time.time()    # Capture start time....
rm = visa.ResourceManager()	# Opens the resource manager and sets it to variable rm

my_PS = KEI2231_Connect("ASRL3::INSTR", 1, 20000, 1)

KEI2231A_SelectChannel(1)
KEI2231A_SetVoltage(1.0)
KEI2231A_SetCurrent(1.0)
KEI2231A_OutputState(1)

time.sleep(0.25)


KEI2231A_OutputState(0)

KEI2231A_Disconnect()

rm.close

t2 = time.time() # Capture stop time...
print("{0:.3f} s".format((t2-t1)))
