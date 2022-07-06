import visa
import time

doDebug = 1
rm = 0
myDmm1 = 0
myDmm2 = 0
useDmm2 = 0

def KEIDMM65xx_Connect(rsrcString, doIdQuery, doReset):
    myDmm = rm.open_resource(rsrcString)
    if doIdQuery == 1:
        print(myDmm.query("*IDN?"))
    if doReset == 1:
        myDmm.write("reset()")
    #print(myDmm.timeout)
    myDmm.timeout = 10000
    return myDmm

def KEIDMM65xx_Disconnect(myDmm):
    myDmm.close()
    return

def KEIDMM65xx_Reset(myDmm):
    myDmm.write("reset()")
    return

def KEIDMM65xx_Configure_Trigger(myDmm, isMaster, tLinkLine):
    myDmm.write("tsplink.line[%d].mode = tsplink.MODE_TRIGGER_OPEN_DRAIN" % tLinkLine)

    if isMaster == 1:
        myDmm.write("trigger.tsplinkout[%d].stimulus = trigger.EVENT_NOTIFY1" % tLinkLine)

def KEIDMM65xx_SetUpDigitizing(myDmm, doCurrent, sampleRate, myRange):
    if doCurrent == 0:
        myDmm.write("dmm.digitize.func = dmm.FUNC_DIGITIZE_VOLTAGE")
    else:
        myDmm.write("dmm.digitize.func = dmm.FUNC_DIGITIZE_CURRENT")

    myDmm.write("dmm.digitize.samplerate = %d" % sampleRate)

    myDmm.write("dmm.digitize.range = %d" % myRange)
    
    return

def KEIDMM65xx_SetUpBuffers(myDmm, iCapacity):
    myDmm.write("defbuffer2.capacity = 10")
    myDmm.write("defbuffer1.capacity = %d" % iCapacity)

    return

def KEIDMM65xx_SetUpTriggerModel(myDmm, isMaster, myBuffer, iCapacity):
    ## Set up trigger model.
    if (isMaster == 1):
        myDmm.write("trigger.model.setblock(1, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1)")
        myDmm.write("trigger.model.setblock(2, trigger.BLOCK_WAIT, trigger.EVENT_TSPLINK1)")
        myDmm.write("trigger.model.setblock(3, trigger.BLOCK_MEASURE_DIGITIZE, {0}, {1})".format(myBuffer, iCapacity))
    else:
        myDmm.write("trigger.model.setblock(1, trigger.BLOCK_WAIT, trigger.EVENT_TSPLINK1)")
        myDmm.write("trigger.model.setblock(2, trigger.BLOCK_MEASURE_DIGITIZE, {0}, {1})".format(myBuffer, iCapacity))
        
    myDmm.write("waitcomplete()")
    return

def KEIDMM65xx_SetDisplay(myDmm, myScreen, text1, text2):
    if (myScreen == 0):	## HOME 
        myDmm.write("display.changescreen(display.SCREEN_HOME)")
    elif (myScreen == 1): ## PROCESSING
        myDmm.write("display.changescreen(display.SCREEN_PROCESSING)")
    elif (myScreen == 2):	## USER with text
        myDmm.write("display.changescreen(display.SCREEN_USER_SWIPE)")
        myDmm.write("display.settext(display.TEXT1, \"%s\")" % text1)
        myDmm.write("display.settext(display.TEXT2, \"%s\")" % text2)

    return

def KEIDMM65xx_TriggerInstr(myDmm):
    myDmm.write("trigger.model.initiate()")
    print("Running...")
    return

def KEIDMM65xx_SetBinaryDataFormat(myDmm):
    myDmm.write("format.data = " + "format.SREAL")
    myDmm.write("format.byteorder = " + "format.LITTLEENDIAN")

    return

def KEIDMM65xx_GetBinaryData(myDmm, startIndex, endIndex):
    #print("Start getting data...")
    cmdStr = "printbuffer({0}, {1}, defbuffer1.readings, defbuffer1.relativetimestamps)".format(startIndex, endIndex)
    values = myDmm.query_binary_values(cmdStr, datatype = 'f', is_big_endian = False)
    #print(len(values))
    #print("End getting data...")
    return

def KEIDMM65xx_GetBinaryDataChunks(myDmm1, myDmm2, iCapacity, chunkSize):
    start_index = 1
    end_index = chunkSize
    readings_captured = 0
    time.sleep(0.1)
    # Check for enough readings available in the buffer to extract: does count_size > chunkSize
    myVal = int(myDmm1.query("print(defbuffer1.n)"))
    #print(myVal)
    while readings_captured < iCapacity:
        while ((myVal - readings_captured) < chunkSize) and (myVal != 0):
            #print(myVal)
            time.sleep(0.1)
            myVal = int(myDmm1.query("print(defbuffer1.n)"))
        #print(myDmm1.resource_name)
        KEIDMM65xx_GetBinaryData(myDmm1, start_index, end_index)
        if useDmm2 == 1:
            #print(myDmm2.resource_name )
            KEIDMM65xx_GetBinaryData(myDmm2, start_index, end_index)
        readings_captured += chunkSize
        start_index += chunkSize
        end_index += chunkSize
        #print(end_index)
    return
    
#================================================================================
#
#    MAIN CODE STARTS HERE
#
#================================================================================
sample_rate = 1000000
myCapacity = 1000000
range1 = 10.0
range2 = 1.0

chunkSize = 10000
ticker = 0

t1 = time.time()    # Capture start time....
rm = visa.ResourceManager()	# Opens the resource manager and sets it to variable rm

myDmm1 = KEIDMM65xx_Connect("USB0::0x05E6::0x6510::04340619::INSTR", 1, 1) # USB0::0x05E6::0x6500::04340538::INSTR  TCPIP0::192.168.1.69::inst0::INSTR
if useDmm2 == 1:
    myDmm2 = KEIDMM65xx_Connect("USB0::0x05E6::0x6500::04340392::INSTR", 1, 1)

# Configure the trigger lines
KEIDMM65xx_Configure_Trigger(myDmm1, 1, 1)
if useDmm2 == 1:
    KEIDMM65xx_Configure_Trigger(myDmm2, 0, 1)

# Configure the digitizing functions....
KEIDMM65xx_SetUpDigitizing(myDmm1, 1, sample_rate, range2)  # digitizing I
if useDmm2 == 1:
    KEIDMM65xx_SetUpDigitizing(myDmm2, 0, sample_rate, range1)  # digitizing V

# Configure buffers...
KEIDMM65xx_SetUpBuffers(myDmm1, myCapacity)
if useDmm2 == 1:
    KEIDMM65xx_SetUpBuffers(myDmm2, myCapacity)

# Configure trigger models....
KEIDMM65xx_SetUpTriggerModel (myDmm1, 1, "defbuffer1", myCapacity)
if useDmm2 == 1:
    KEIDMM65xx_SetUpTriggerModel (myDmm2, 0, "defbuffer1", myCapacity)

# Configure for binary data transfer...
KEIDMM65xx_SetBinaryDataFormat(myDmm1)
if useDmm2 == 1:
    KEIDMM65xx_SetBinaryDataFormat(myDmm2)

# Set the display...
KEIDMM65xx_SetDisplay(myDmm1, 1, "", "")
if useDmm2 == 1:
    KEIDMM65xx_SetDisplay(myDmm2, 1, "", "")

#time.sleep(1.0)

if useDmm2 == 1:
    KEIDMM65xx_TriggerInstr(myDmm2)
KEIDMM65xx_TriggerInstr(myDmm1)

t3 = time.time()

# Get the data back from the instruments...
KEIDMM65xx_GetBinaryDataChunks(myDmm1, myDmm2, myCapacity, chunkSize)

# Set the display...
KEIDMM65xx_SetDisplay(myDmm1, 2, "Digitize Amps", "")
if useDmm2 == 1:
    KEIDMM65xx_SetDisplay(myDmm2, 2, "Digitize Volts", "")

# Close the instrument sessions...
KEIDMM65xx_Disconnect(myDmm1)
if useDmm2 == 1:
    KEIDMM65xx_Disconnect(myDmm2)

rm.close

t2 = time.time() # Capture stop time...
print("Total Run Time: {0:0.3f} s".format((t2-t1)))
print("Setup Time: {0:0.3f} s".format((t3-t1)))
print("Data Extraction Time: {0:0.3f} s".format(t2-t3))
# Notify the user of completion and the data streaming rate achieved. 
print("done")

input("Press Enter to continue...")
exit()


