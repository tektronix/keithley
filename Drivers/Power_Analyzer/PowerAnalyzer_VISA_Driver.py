import visa 
import struct
import math
import time
from enum import Enum

# ======================================================================
#      DEFINE THE DMM CLASS INSTANCE HERE
# ======================================================================
class PowerAnalyzer:
    def __init__(self):
        self.echoCmd = 1
        self.myInstr = 0
    # ======================================================================
    #      DEFINE INSTRUMENT CONNECTION AND COMMUNICATIONS FUNCTIONS HERE
    # ======================================================================     
    def Connect(self, rsrcMgr, rsrcString, timeout, doIdQuery, doReset, doClear):
        self.myInstr = rsrcMgr.open_resource(rsrcString)

        infc_type = "{0}".format(self.myInstr.interface_type)
        if infc_type.find("usb") < 0:
            # The sockets connection to the instrument needs the following.
            self.myInstr.read_termination = '\n'
            self.myInstr.write_termination = '\n'
            self.myInstr.send_end = True
        
        if doIdQuery == 1:
            print(self.QueryCmd("*IDN?"))
        if doReset == 1:
            self.SendCmd("*RST")
        if doClear == 1:
            if infc_type.find("usb") < 0:
                self.myInstr.clear() # Does not play well w/ USB        

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
        sndBuffer = "*RST"
        self.SendCmd(sndBuffer)
        
    def IDQuery(self):
        sndBuffer = "*IDN?"
        return self.QueryCmd(sndBuffer)

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
    
    class MeasFunc(Enum):
        DCV = 0
        DCI = 1

    class InputZ(Enum):
        Z_AUTO = 0
        Z_10M = 1

    
