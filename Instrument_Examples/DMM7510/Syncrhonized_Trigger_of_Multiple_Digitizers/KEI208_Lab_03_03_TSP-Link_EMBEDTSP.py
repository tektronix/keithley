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
    myDmm.write("rst()")
    return

def KEIDMM65xx_Configure_Trigger(myDmm, isMaster, tLinkLine):
    myDmm.write("cnfgTrig({0}, {1})".format(isMaster, tLinkLine))
    return

def KEIDMM65xx_SetUpDigitizing(myDmm, doCurrent, sampleRate, myRange):
    myDmm.write("cnfgDigi({0}, {1}, {2})".format(doCurrent, sampleRate, myRange))
    return

def KEIDMM65xx_SetUpBuffers(myDmm, iCapacity, chunkSize):
    myDmm.write("cnfgBuff({0}, {1})".format(iCapacity, chunkSize))
    return

def KEIDMM65xx_SetUpTriggerModel(myDmm, isMaster, myBuffer, iCapacity):
    ## Set up trigger model.
    myDmm.write("cnfgTrigModel({0}, {1})".format(isMaster, iCapacity))
 
    return

def KEIDMM65xx_SetDisplay(myDmm, myScreen, text1, text2):
    myDmm.write("setDisplay({0}, \"{1}\", \"{2}\")".format(myScreen, text1, text2))
    return

def KEIDMM65xx_TriggerInstr(myDmm):
    myDmm.write("trig()")
    print("Running...")
    return

def KEIDMM65xx_SetBinaryDataFormat(myDmm):
    myDmm.write("setDataFmt()")
    return

def KEIDMM65xx_GetBinaryData(myDmm, chunkSize):
    #print("Start getting data...")
    cmdStr = "get_data(%d)" % chunkSize
    values = myDmm.query_binary_values(cmdStr, datatype = 'f', is_big_endian = False)
    #print("End getting data...")
    return

def KEIDMM65xx_GetBinaryDataChunks(myDmm1, myDmm2, iCapacity, chunkSize):
    start_index = 1
    end_index = chunkSize
    readings_captured = 0
    stopCnt = int(iCapacity/chunkSize)
    #print(stopCnt)
    time.sleep(0.1)
    
    for i in range(0, stopCnt):
        #print(myDmm1.resource_name)
        KEIDMM65xx_GetBinaryData(myDmm1, chunkSize)
        if useDmm2 == 1:
            #print(myDmm2.resource_name )
            KEIDMM65xx_GetBinaryData(myDmm2, chunkSize)

    return

def load_functions(myDmm, functions_path):
    # This function opens the functions.lua file in the same directory as
    # the Python script and trasfers its contents to the DMM7510's internal
    # memory. All the functions defined in the file are callable by the
    # controlling program. 
    func_file = open(functions_path, "r")
    contents = func_file.read()
    func_file.close()
    myDmm.write("if loadfuncs ~= nil then "
                "script.delete('loadfuncs') "
           "end\n")
    myDmm.write("loadscript loadfuncs\n{0}\nendscript\n"
        .format(contents))
    myDmm.write("loadfuncs()\n")
    print(myDmm.read())
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

function_file = "functions_03_TLink.lua"

t1 = time.time()    # Capture start time....
rm = visa.ResourceManager()	# Opens the resource manager and sets it to variable rm

myDmm1 = KEIDMM65xx_Connect("USB0::0x05E6::0x6510::04340619::INSTR", 1, 1) # USB0::0x05E6::0x6500::04340538::INSTR  TCPIP0::192.168.1.69::inst0::INSTR
if useDmm2 == 1:
    myDmm2 = KEIDMM65xx_Connect("USB0::0x05E6::0x6500::04340392::INSTR", 1, 1)

load_functions(myDmm1, function_file)
if useDmm2 == 1:
    load_functions(myDmm2, function_file)
#time.sleep(1.0)

t3 = time.time()

# Configure the trigger lines
KEIDMM65xx_Configure_Trigger(myDmm1, 1, 1)
if useDmm2 == 1:
    KEIDMM65xx_Configure_Trigger(myDmm2, 0, 1)

# Configure the digitizing functions....
KEIDMM65xx_SetUpDigitizing(myDmm1, 1, sample_rate, range2)  # digitizing I
if useDmm2 == 1:
    KEIDMM65xx_SetUpDigitizing(myDmm2, 0, sample_rate, range1)  # digitizing V

# Configure buffers...
KEIDMM65xx_SetUpBuffers(myDmm1, myCapacity, chunkSize)
if useDmm2 == 1:
    KEIDMM65xx_SetUpBuffers(myDmm2, myCapacity, chunkSize)

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
    KEIDMM65xx_SetDisplay(myDmm2, 1, "none", "none")

#time.sleep(1.0)

if useDmm2 == 1:
    KEIDMM65xx_TriggerInstr(myDmm2)
KEIDMM65xx_TriggerInstr(myDmm1)

t4 = time.time()

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
print("Functions Load Time: {0:0.3f} s".format(t3-t1))
print("Setup Time: {0:0.3f} s".format(t4-t3))
print("Data Extraction Time: {0:0.3f} s".format(t2-t4))

# Notify the user of completion and the data streaming rate achieved. 
print("done")

input("Press Enter to continue...")
exit()


