import visa 
import struct
import math
import time
from enum import Enum

# ======================================================================
#      DEFINE THE DMM CLASS INSTANCE HERE
# ======================================================================
class DMM6500:
    def __init__(self):
        self.echoCmd = 1
        self.myInstr = 0
    # ======================================================================
    #      DEFINE INSTRUMENT CONNECTION AND COMMUNICATIONS FUNCTIONS HERE
    # ======================================================================     
    def Connect(self, rsrcMgr, rsrcString, timeout, doIdQuery, doReset, doClear):
        self.myInstr = rsrcMgr.open_resource(rsrcString)
        if doIdQuery == 1:
            print(self.QueryCmd("*IDN?"))
        if doReset == 1:
            self.SendCmd("reset()")
        if doClear == 1:
            self.myInstr.clear()
        #self.myInstr.read_termination = '\n'
        #self.myInstr.write_termination = '\n'    

        self.myInstr.timeout = timeout
        return

    def Disconnect(self):
        self.myInstr.close()
        return

    def SendCmd(self, cmd):
        if self.echoCmd == 1:
            print(cmd)
        self.myInstr.write(cmd)
        return

    def QueryCmd(self, cmd):
        if self.echoCmd == 1:
            print(cmd)
        return self.myInstr.query(cmd)

    # ======================================================================
    #      DEFINE BASIC FUNCTIONS HERE
    # ======================================================================        
    def Reset(self):
        sndBuffer = "reset()"
        self.SendCmd(sndBuffer)
        
    def IDQuery(self):
        sndBuffer = "*IDN?"
        return self.QueryCmd(sndBuffer)

    def LoadScriptFile(self, filePathAndName):
        # This function opens the functions.lua file in the same directory as
        # the Python script and trasfers its contents to the DMM's internal
        # memory. All the functions defined in the file are callable by the
        # controlling program. 
        func_file = open(filePathAndName, "r")
        contents = func_file.read()
        func_file.close()

        cmd = "if loadfuncs ~= nil then script.delete('loadfuncs') end"
        self.SendCmd(cmd)

        cmd = "loadscript loadfuncs\n{0}\nendscript".format(contents)
        self.SendCmd(cmd)
        
        print(self.QueryCmd("loadfuncs()"))
        return

    # ======================================================================
    #      DEFINE MEASUREMENT FUNCTIONS HERE
    # ======================================================================
    def SetMeasure_Function(self, myFunc):
        if myFunc == self.MeasFunc.DCV:
            funcStr = "dmm.FUNC_DC_VOLTAGE"
        elif myFunc == self.MeasFunc.DCI:
            funcStr = "dmm.FUNC_DC_CURRENT"
        sndBuffer = "dmm.measure.func =  {}".format(funcStr)
        self.SendCmd(sndBuffer)
        return

    def SetMeasure_Range(self, rng):
        sndBuffer = "dmm.measure.range = {}".format(rng)
        self.SendCmd(sndBuffer)
        return

    def SetMeasure_NPLC(self, nplc):
        sndBuffer = "dmm.measure.nplc = {}".format(nplc)
        self.SendCmd(sndBuffer)
        return

    def SetMeasure_InputImpedance(self, myZ):
        if myZ == self.InputZ.Z_AUTO:
            funcStr = "dmm.IMPEDANCE_AUTO"
        elif myZ == self.InputZ.Z_10M:
            funcStr = "dmm.IMPEDANCE_10M"
            
        sndBuffer = "dmm.measure.inputimpedance = {}".format(funcStr)
        self.SendCmd(sndBuffer)
        return

    def SetMeasure_AutoZero(self, myState):
        if myState == self.DmmState.OFF:
            funcStr = "dmm.OFF"
        elif myState == self.DmmState.ON:
            funcStr = "dmm.ON"
            
        sndBuffer = "dmm.measure.autozero.enable = {}".format(funcStr)
        self.SendCmd(sndBuffer)
        return

    def SetMeasure_FilterType(self, myFilter):
        if myFilter == self.FilterType.REP:
            funcStr = "dmm.FILTER_REPEAT_AVG"
        elif myFilter == self.FilterType.MOV:
            funcStr = "dmm.FILTER_MOVING_AVG"
            
        sndBuffer = "dmm.measure.filter.type = {}".format(funcStr)
        self.SendCmd(sndBuffer)
        return

    def SetMeasure_FilterCount(self, count):
        sndBuffer = "dmm.measure.filter.count = {}".format(count)
        self.SendCmd(sndBuffer)
        return

    def SetMeasure_FilterState(self, myState):
        if myState == self.DmmState.OFF:
            funcStr = "dmm.OFF"
        elif myState == self.DmmState.ON:
            funcStr = "dmm.ON"
            
        sndBuffer = "dmm.measure.filter.enable = {}".format(funcStr)
        self.SendCmd(sndBuffer)
        return
    
    def Measure(self, count):
        sndBuffer = "print(dmm.measure.read())"
        return self.QueryCmd(sndBuffer)

    def SetFunction_Temperature(self, *args):
        # This function can be used to set up to three different measurement
        # function attributes, but they are expected to be in a certain
        # order....
        #   For simple front/rear terminal measurements:
        #       1. Transducer (TC/RTD/Thermistor)
        #       2. Transducer type
        #   For channel scan measurements:
        #       1. Channel string
        #       2. Transducer
        #       3. Transducer type
        if (len(args) == 0):
            self.SendCmd("dmm.measure.func = dmm.FUNC_TEMPERATURE")
        else:
            if (type(args[0]) != str):
                self.SendCmd("dmm.measure.func = dmm.FUNC_TEMPERATURE")
                if(len(args) > 0):
                    xStr = "dmm.measure.transducer"
                    if(args[0] == self.Transducer.TC):
                       xStr2 = "dmm.TRANS_THERMOCOUPLE"
                    elif(args[0] == self.Transducer.RTD4):
                       xStr2 = "dmm.TRANS_FOURRTD"
                    elif(args[0] == self.Transducer.RTD3):
                       xStr2 = "dmm.TRANS_THREERTD"
                    elif(args[0] == self.Transducer.THERM):
                       xStr2 = "dmm.TRANS_THERMISTOR"
                    sndBuffer = "{} = {}".format(xStr, xStr2)
                    self.SendCmd(sndBuffer)
                if(len(args) > 1):
                    if(args[0] == self.Transducer.TC):
                        xStr = "dmm.measure.thermocouple"
                        if(args[1] == self.TCType.K):
                           xType = "dmm.THERMOCOUPLE_K"
                        elif(args[1] == self.TCType.J):
                           xType = "dmm.THERMOCOUPLE_J"
                        elif(args[1] == self.TCType.N):
                           xType = "dmm.THERMOCOUPLE_N" 
                        sndBuffer = "{} = {}".format(xStr, xType)
                        self.SendCmd(sndBuffer)
                    elif((args[0] == self.Transducer.RTD4) or (args[1] == self.Transducer.RTD3)):
                        if(args[0] == self.Transducer.RTD4):
                            xStr = "dmm.measure.fourrtd"
                        if(args[0] == self.Transducer.RTD3):
                            xStr = "dmm.measure.threertd"

                        if(args[1] == self.RTDType.PT100):
                           rtdType = "dmm.RTD_PT100"
                        elif(args[1] == self.RTDType.PT385):
                           rtdType = "dmm.RTD_PT385"
                        elif(args[1] == self.RTDType.PT3916):
                           rtdType = "dmm.RTD_PT3916"
                        elif(args[1] == self.RTDType.D100):
                           rtdType = "dmm.RTD_D100"
                        elif(args[1] == self.RTDType.F100):
                           rtdType = "dmm.RTD_F100"
                        elif(args[1] == self.RTDType.USER):
                           rtdType = "dmm.RTD_USER"
                           
                        sndBuffer = "{} = {}".format(xStr, rtdType)
                        self.SendCmd(sndBuffer)
                    elif(args[0] == self.Transducer.THERM):
                        xStr = "dmm.measure.thermistor"
                        if(args[1] == self.ThermType.TH2252):
                           thrmType = "dmm.THERM_2252"
                        elif(args[1] == self.ThermType.TH5K):
                           thrmType = "dmm.THERM_5000"
                        elif(args[1] == self.ThermType.TH10K):
                           thrmType = "dmm.THERM_10000"
                        sndBuffer = "{} = {}".format(xStr, thrmType)
                        self.SendCmd(sndBuffer)
            else:
                setStr = "channel.setdmm(\"{}\", ".format(args[0])
                self.SendCmd("{}dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE)".format(setStr))
                if(len(args) > 1):
                    if(args[1] == self.Transducer.TC):
                       xStr = "dmm.TRANS_THERMOCOUPLE"
                       xStr2 = "dmm.ATTR_MEAS_THERMOCOUPLE"
                    elif(args[1] == self.Transducer.RTD4):
                       xStr = "dmm.TRANS_FOURRTD"
                       xStr2 = "dmm.ATTR_MEAS_FOUR_RTD"
                    elif(args[1] == self.Transducer.RTD3):
                       xStr = "dmm.TRANS_THREERTD"
                       xStr2 = "dmm.ATTR_MEAS_THREE_RTD"
                    elif(args[1] == self.Transducer.THERM):
                       xStr = "dmm.TRANS_THERMISTOR"
                       xStr2 = "dmm.ATTR_MEAS_THERMISTOR"
                    sndBuffer = "{}dmm.ATTR_MEAS_TRANSDUCER, {})".format(setStr, xStr)
                    self.SendCmd(sndBuffer)
                if(len(args) > 2):
                    if(args[1] == self.Transducer.TC):
                        if(args[2] == self.TCType.K):
                           xType = "dmm.THERMOCOUPLE_K"
                        elif(args[2] == self.TCType.J):
                           xType = "dmm.THERMOCOUPLE_J"
                        elif(args[2] == self.TCType.N):
                           xType = "dmm.THERMOCOUPLE_N" 
                        #print("{}dmm.ATTR_MEAS_THERMOCOUPLE, {})".format(setStr, xType))
                        sndBuffer = "{}dmm.ATTR_MEAS_THERMOCOUPLE, {})".format(setStr, xType)
                        self.SendCmd(sndBuffer)
                    elif((args[1] == self.Transducer.RTD4) or (args[1] == self.Transducer.RTD3)):
                        if(args[2] == self.RTDType.PT100):
                           rtdType = "dmm.RTD_PT100"
                        elif(args[2] == self.RTDType.PT385):
                           rtdType = "dmm.RTD_PT385"
                        elif(args[2] == self.RTDType.PT3916):
                           rtdType = "dmm.RTD_PT3916"
                        elif(args[2] == self.RTDType.D100):
                           rtdType = "dmm.RTD_F100"
                        elif(args[2] == self.RTDType.F100):
                           rtdType = "dmm.RTD_D100"
                        elif(args[2] == self.RTDType.USER):
                           rtdType = "dmm.RTD_USER"
                        sndBuffer = "{}{}, {})".format(setStr, xStr2, rtdType)
                        self.SendCmd(sndBuffer)
                    if(args[1] == self.Transducer.THERM):
                        if(args[2] == self.ThermType.TH2252):
                           thrmType = "dmm.THERM_2252"
                        elif(args[2] == self.ThermType.TH5K):
                           thrmType = "dmm.THERM_5000"
                        elif(args[2] == self.ThermType.TH10K):
                           thrmType = "dmm.THERM_10000"
                        sndBuffer = "{}{}, {})".format(setStr, xStr2, thrmType)
                        self.SendCmd(sndBuffer)
        return
    
    class MeasFunc(Enum):
        DCV = 0
        DCI = 1

    class InputZ(Enum):
        Z_AUTO = 0
        Z_10M = 1

    class DmmState(Enum):
        OFF = 0
        ON = 1

    class FilterType(Enum):
        REP = 0
        MOV = 1

    class Transducer(Enum):
        TC = 0
        RTD4 = 1
        RTD3 = 2
        THERM = 3

    class TCType(Enum):
        K = 0
        J = 1
        N = 2
        
    class RTDType(Enum):
        PT100 = 0
        PT385 = 1
        PT3916 = 2
        D100 = 3
        F100 = 4
        USER = 5

    class ThermType(Enum):
        TH2252 = 0
        TH5K = 1
        TH10K = 2

    def SetScan_BasicAttributes(self, *args):
        self.SendCmd("scan.create(\"{}\")".format(args[0]))

        # Set the scan count
        if(len(args) > 1):
            self.SendCmd("scan.scancount = {}".format(args[1]))

        # Set the time between scans
        if(len(args) > 2):
            self.SendCmd("scan.scaninterval = {}".format(args[2]))
        return
    
    def Init(self):
        self.SendCmd("waitcomplete()")
        self.SendCmd("trigger.model.initiate()")
        return

    def GetScan_Status(self):
        return self.QueryCmd("print(trigger.model.state())")

    def GetScan_Data(self, dataCount, startIndex, endIndex):
        #charCnt = 24 * dataCount
        accumCnt = int(self.QueryCmd("print(defbuffer1.n)")[0:-1])
        while(accumCnt < endIndex):
            accumCnt = int(self.QueryCmd("print(defbuffer1.n)")[0:-1])
        rcvBuffer = self.QueryCmd("printbuffer({}, {}, defbuffer1)".format(startIndex, endIndex))[0:-1]
        return rcvBuffer
        
