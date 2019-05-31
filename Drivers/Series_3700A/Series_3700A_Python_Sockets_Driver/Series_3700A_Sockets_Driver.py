import socket
import struct
import math
import time
from enum import Enum

# ======================================================================
#      DEFINE THE DMM CLASS INSTANCE HERE
# ======================================================================
class KEI3706A:
    def __init__(self):
        self.echoCmd = 1
        self.mySocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.stubComms = 0
        
    # ======================================================================
    #      DEFINE INSTRUMENT CONNECTION AND COMMUNICATIONS FUNCTIONS HERE
    # ======================================================================
    def Connect(self, myAddress, myPort, timeOut, doReset, doIdQuery):
        if (self.stubComms == 0):
            self.mySocket.connect((myAddress, myPort)) # input to connect must be a tuple
            self.mySocket.settimeout(timeOut)
        if doReset == 1:
            self.Reset()
            self.SendCmd("waitcomplete()")
        if doIdQuery == 1:
            tmpId = self.IDQuery()
        if doIdQuery == 1:
            return tmpId
        else:
            return

    def Disconnect(self):
        if (self.stubComms == 0):
            self.mySocket.close()
        return

    def SendCmd(self, cmd):
        if self.echoCmd == 1:
            print(cmd)
        cmd = "{0}\n".format(cmd)
        if (self.stubComms == 0):
            self.mySocket.send(cmd.encode())
        return

    def QueryCmd(self, cmd, rcvSize):
        self.SendCmd(cmd)
        time.sleep(0.1)
        rcvString = ""
        if (self.stubComms == 0):
            rcvString = self.mySocket.recv(rcvSize).decode()
        return rcvString

    # ======================================================================
    #      DEFINE BASIC FUNCTIONS HERE
    # ======================================================================        
    def Reset(self):
        sndBuffer = "reset()"
        self.SendCmd(sndBuffer)
        
    def IDQuery(self):
        sndBuffer = "*IDN?"
        return self.QueryCmd(sndBuffer, 64)

    def LoadScriptFile(self, filePathAndName):
        # This function opens the functions.lua file in the same directory as
        # the Python script and trasfers its contents to the DMM's internal
        # memory. All the functions defined in the file are callable by the
        # controlling program. 
        func_file = open(filePathAndName, "r")
        contents = func_file.read()
        func_file.close()

        #cmd = "if loadfuncs ~= nil then script.delete('loadfuncs') end"
        #self.SendCmd(cmd)

        cmd = "loadscript loadfuncs\n{0}\nendscript".format(contents)
        self.SendCmd(cmd)
        cmd = "loadfuncs()"
        print(self.QueryCmd(cmd, 32))
        return

    # ======================================================================
    #      DEFINE FUNCTIONS HERE
    # ======================================================================
    def Close(self, *args):
        # first parameter is always a channel list string
        self.SendCmd("channel.close(\"{}\")".format(args[0]))
        return

    def Open(self, *args):
        # first parameter is always a channel list string
        self.SendCmd("channel.open(\"{}\")".format(args[0]))
        return
        
    def Set_3761_Switch_Mode(self, mySlot, myMode):
        sndBuffer = "slot[{}].voltsampsmode = {}".format(mySlot, myMode)
        self.SendCmd(sndBuffer)
        return
