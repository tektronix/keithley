import visa 
import struct
import math
import time
from enum import Enum

# ======================================================================
#      DEFINE THE DMM CLASS INSTANCE HERE
# ======================================================================
class LOAD2380:
    def __init__(self):
        self.echoCmd = 1
        self.myInstr = 0
        self.stubComms = 0
        self.activeFunction = self.Function.CC
        self.activeFunctionStr = "CURR"
    # ======================================================================
    #      DEFINE INSTRUMENT CONNECTION AND COMMUNICATIONS FUNCTIONS HERE
    # ======================================================================     
    def Connect(self, rsrcMgr, rsrcString, timeout, doIdQuery, doReset, doClear):
        if(self.stubComms == 0):
            self.myInstr = rsrcMgr.open_resource(rsrcString)
        self.Write("SYST:REM")
        if doIdQuery == 1:
            print(self.Query("*IDN?"))
        if doReset == 1:
            self.Write("*RST")
        if doClear == 1:
            if(self.stubComms == 0):
                self.myInstr.clear()
        if(self.stubComms == 0):
            self.myInstr.timeout = timeout
        return

    def Disconnect(self):
        if(self.stubComms == 0):
            self.Write("SYST:LOC")
            self.myInstr.close()
        return

    def Write(self, cmd):
        if self.echoCmd == 1:
            print(cmd)
        if(self.stubComms == 0):
            self.myInstr.write(cmd)
        return

    def Query(self, cmd):
        rcvBuffer = ""
        if self.echoCmd == 1:
            print(cmd)
        if(self.stubComms == 0):
            rcvBuffer = self.myInstr.query(cmd)
        return rcvBuffer

    # ======================================================================
    #      DEFINE BASIC FUNCTIONS HERE
    # ======================================================================        
    def Reset(self):
        sndBuffer = "*RST"
        self.Write(sndBuffer)
        
    def IDQuery(self):
        sndBuffer = "*IDN?"
        return self.Query(sndBuffer)

    # ======================================================================
    #      DEFINE MEASUREMENT FUNCTIONS HERE
    # ======================================================================
    def Set_DisplayText(self, myIndex, myText):
        # Write up to 48 characters (starting index 0) on
        # the front panel of the instrument.
        sndBuffer = "DISP:TEXT {}, \"{}\"".format(myIndex, myText)
        self.Write(sndBuffer)
        return

    def Set_DisplayMode(self, myMode):
        if(myMode == self.DisplayMode.NORMAL):
            modeStr = "NORM"
        elif(myMode == self.DisplayMode.TEXT):
            modeStr = "TEXT"
        sndBuffer = "DISP:MODE {}".format(modeStr)
        self.Write(sndBuffer)
        return

    def Set_Function(self, myFnc):
        if(myFnc == self.Function.CC):
            myFunc = "CURR"
            self.activeFunction = self.Function.CC
            self.activeFunctionStr = myFunc
        elif(myFnc == self.Function.CV):
            myFunc = "VOLT"
            self.activeFunction = self.Function.CV
            self.activeFunctionStr = myFunc
        elif(myFnc == self.Function.CR):
            myFunc = "RES"
            self.activeFunction = self.Function.CR
            self.activeFunctionStr = myFunc
        elif(myFnc == self.Function.CP):
            myFunc = "POW"
            self.activeFunction = self.Function.CP
            self.activeFunctionStr = myFunc
        sndBuffer = "SOUR:FUNC {}".format(myFunc)
        self.Write(sndBuffer)
        return

    def Set_Level(self, myCurr):
        sndBuffer = "{} {}".format(self.activeFunctionStr, myCurr)
        self.Write(sndBuffer)
        return

    def Set_Range(self, myRng):
        sndBuffer = "{}:RANG {}".format(self.activeFunctionStr, myRng)
        self.Write(sndBuffer)
        return

    def Set_CC_SlewRate(self, mySlew):
        sndBuffer = "CURR:SLEW {}".format(mySlew)
        self.Write(sndBuffer)
        return

    def Set_CC_SlewRatePositive(self, mySlew):
        sndBuffer = "{}:SLEW:POS {}".format(self.activeFunctionStr, mySlew)
        self.Write(sndBuffer)
        return

    def Set_CC_SlewRateNegative(self, mySlew):
        sndBuffer = "{}:SLEW:NEG {}".format(self.activeFunctionStr, mySlew)
        self.Write(sndBuffer)
        return
    
    def Set_CC_SlewSlowRateState(self, myState):
        if(myState == self.State.OFF):
            mStat = "OFF"
        else:
            mStat = "ON"
        sndBuffer = "{}:SLOW:STAT {}".format(self.activeFunctionStr, mStat)
        self.Write(sndBuffer)
        return
    
    def Set_CC_ProtectionState(self, myState):
        sndBuffer = "CURR:PROT:STAT {}".format(myState)
        self.Write(sndBuffer)
        return

    def Set_CC_ProtectionLevel(self, myLevel):
        sndBuffer = "CURR:PROT:LEV {}".format(myLevel)
        self.Write(sndBuffer)
        return

    def Set_CC_ProtectionDelay(self, myDelay):
        sndBuffer = "CURR:PROT:DEL {}".format(myDelay)
        self.Write(sndBuffer)
        return
    
    def Set_TransientMode(self, myMode):
        if(myMode == self.TransientMode.CONT):
            modeStr = "CONT"
        elif(myMode == self.TransientMode.PULSE):
            modeStr = "PULS"
        elif(myMode == self.TransientMode.TOGGLE):
            modeStr = "TOGG"
            
        sndBuffer = "{}:TRAN:MODE {}".format(self.activeFunctionStr, modeStr)
        self.Write(sndBuffer)
        return

    def Set_TransientLevels(self, levelA, levelB):
        sndBuffer = "{}:TRAN:ALEV {}".format(self.activeFunctionStr, levelA)
        self.Write(sndBuffer)

        sndBuffer = "{}:TRAN:BLEV {}".format(self.activeFunctionStr, levelB)
        self.Write(sndBuffer)
        return

    def Set_TransientWidths(self, widthA, widthB):
        # Note that widths can range from 0.0002 to 3600 seconds
        sndBuffer = "{}:TRAN:AWID {}".format(self.activeFunctionStr, widthA)
        self.Write(sndBuffer)

        sndBuffer = "{}:TRAN:BWID {}".format(self.activeFunctionStr, widthB)
        self.Write(sndBuffer)
        return

    def Set_HighLow(self, myHigh, myLow):
        sndBuffer = "{}:HIGH {}".format(self.activeFunctionStr, myHigh)
        self.Write(sndBuffer)

        sndBuffer = "{}:LOW {}".format(self.activeFunctionStr, myLow)
        self.Write(sndBuffer)
        return

    def Set_TransientState(self, myState):
        if(myState == self.State.OFF):
            mStat = "OFF"
        else:
            mStat = "ON"
        sndBuffer = "TRAN {}".format(mStat)
        self.Write(sndBuffer)
        return

    def Set_LEDTest_State(self, myState):
        if(myState == self.State.OFF):
            mStat = "OFF"
        else:
            mStat = "ON"
        sndBuffer = "{}:LED {}".format(self.activeFunctionStr, mStat)
        self.Write(sndBuffer)
        return

    def Set_LEDTest_Vd(self, myVd):
        sndBuffer = "{}:VDR {}".format(self.activeFunctionStr, myVd)
        self.Write(sndBuffer)
        return
    
    def Set_OutputState(self, myState):
        if(myState == self.State.OFF):
            mStat = "OFF"
        else:
            mStat = "ON"
        sndBuffer = "INP {}".format(mStat)
        self.Write(sndBuffer)
        return

    def Get_Current(self):
        return self.Query("FETC:CURR?")

    def Get_Voltage(self):
        return self.Query("FETC:VOLT?")

    def Bus_TrigCurrent(self):
        return self.Write("*TRIG")

    def Set_TriggerSource(self, mySrc):
        if(mySrc == self.TrigSrc.BUS):
            src = "BUS"
        elif(mySrc == self.TrigSrc.EXT):
            src = "EXT"
        elif(mySrc == self.TrigSrc.HOLD):
            src = "HOLD"
        elif(mySrc == self.TrigSrc.MAN):
            src = "MANU"
        elif(mySrc == self.TrigSrc.TIMER):
            src = "TIM"
        sndBuffer = "TRIG:SOUR {}".format(src)
        self.Write(sndBuffer)
        return
    
    class Function(Enum):
        CC = 0
        CV = 1
        CR = 2
        CP = 3

    class DisplayMode(Enum):
        NORMAL = 0
        TEXT = 1

    class TransientMode(Enum):
        CONT = 0
        PULSE = 1
        TOGGLE = 2

    class State(Enum):
        OFF = 0
        ON = 1

    class TrigSrc(Enum):
        BUS = 0
        EXT = 1
        HOLD = 2
        MAN = 3
        TIMER = 4
