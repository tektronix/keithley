#!/usr/bin/python
import socket
import struct
import math
import time

echoCmd = 1

# ======================================================================
#      DEFINE FOUNDATION SOCKETS COMMUNICATION FUNCTIONS HERE
# ======================================================================
def instrConnect(mySocket, myAddress, myPort, timeOut, doReset, doIdQuery):
    mySocket.connect((myAddress, myPort)) # input to connect must be a tuple
    mySocket.settimeout(timeOut)
    if doReset == 1:
        instrSend(mySocket, "*RST")
    if doIdQuery == 1:
        tmpId = instrQuery(mySocket, "*IDN?", 100)
    return mySocket, tmpId

def instrDisconnect(mySocket):
    mySocket.close()
    return

def instrSend(mySocket, cmd):
    if echoCmd == 1:
        print(cmd)
    cmd = "{0}\n".format(cmd)
    mySocket.send(cmd.encode())
    return

def instrQuery(mySocket, cmd, rcvSize):
    instrSend(mySocket, cmd)
    time.sleep(0.1)
    return mySocket.recv(rcvSize).decode()

# ======================================================================
#      DEFINE BASIC INSTRUMENT CONNECTION FUNCTIONS HERE
# ======================================================================
def PowerSupply_Connect(mySocket, myAddress, myPort, timeOut, doEcho, doReset, doIdQuery):
    mySocket, myId = instrConnect(mySocket, myAddress, myPort, timeOut, doReset, doIdQuery)
    return mySocket, myId

def PowerSupply_Disconnect(mySocket):
    instrDisconnect(mySocket)

# ======================================================================
#      DEFINE BASIC INSTRUMENT SOURCE FUNCTIONS HERE
# ======================================================================        
def PowerSupply_SetVoltage(mySocket, vLevel):
    sndBuffer = "SOUR1:VOLT {}".format(vLevel)
    instrSend(mySocket, sndBuffer)

def PowerSupply_GetVoltage(mySocket):
    sndBuffer = "SOUR1:VOLT?"
    return instrQuery(mySocket, sndBuffer, 32)

def PowerSupply_SetVoltageProtection(mySocket, vLimit):
    sndBuffer = "SOUR1:VOLT:PROT {}".format(vLimit)
    instrSend(mySocket, sndBuffer)

def PowerSupply_SetCurrent(mySocket, iLevel):
    sndBuffer = "SOUR1:CURR {}".format(iLevel)
    instrSend(mySocket, sndBuffer)

def PowerSupply_GetCurrent(mySocket):
    sndBuffer = "SOUR1:CURR?"
    return instrQuery(mySocket, sndBuffer, 32)

def PowerSupply_SetCurrentProtection(mySocket, iLimit):
    sndBuffer = "SOUR1:CURR:PROT {}".format(iLimit)
    instrSend(mySocket, sndBuffer)

# ======================================================================
#      DEFINE BASIC INSTRUMENT MEASURE FUNCTIONS HERE
# ======================================================================
def PowerSupply_MeasureVoltage(mySocket):
    sndBuffer = "MEAS:VOLT?"
    return instrQuery(mySocket, sndBuffer, 32)

def PowerSupply_MeasureCurrent(mySocket):
    sndBuffer = "MEAS:CURR?"
    return instrQuery(mySocket, sndBuffer, 32)

def PowerSupply_SetDataFormat(mySocket, doRead, doUnit, doTime):
    tmpStr = ""
    if doRead == 1:
        tmpStr = tmpStr + "READ,"
    if doUnit == 1:
        tmpStr = tmpStr + "UNIT,"
    if doTime == 1:
        tmpStr = tmpStr + "TST,"
    
    sndBuffer = "FORM:ELEM \"{}\"".format(tmpStr[:-1])
    instrSend(mySocket, sndBuffer)
    
# ======================================================================
#      DEFINE BASIC OUTPUT FUNCTIONS HERE
# ======================================================================
def PowerSupply_SetOutputState(mySocket, myState):
    if myState == 0:
        instrSend(mySocket, "OUTP:STAT OFF")
    else:
        instrSend(mySocket, "OUTP:STAT ON")

def PowerSupply_GetOutputState(mySocket):
    return instrQuery(mySocket, "OUTP:STAT?", 16)

# ======================================================================
#      DEFINE DISPLAY FUNCTIONS HERE
# ======================================================================
def PowerSupply_SetDisplayText(mySocket, myText):
    sndBuffer = "DISP:USER:TEXT \"{}\"".format(myText)
    instrSend(mySocket, sndBuffer)

def PowerSupply_GetDisplayText(mySocket):
    return instrQuery(mySocket, "DISP:USER:TEXT?", 42)

# ======================================================================
#      DEFINE SYSTEM FUNCTIONS HERE
# ======================================================================
def PowerSupply_SetFunction(activeFunc):
    if activeFunc == 0:
        # Set to Power Supply
        instrSend(mySocket, ":ENTR:FUNC POW")
    else if activeFunc == 1:
        # Set to Battery Test
        instrSend(mySocket, ":ENTRFUNC TEST")
    else if activeFunc == 2:
        # Set to Battery Simulator
        instrSend(mySocket, ":ENTR:FUNC SIM")
    else
        # What should be done if the input value is invalid?
    return

# ======================================================================
#      DEFINE BATTERY SIMULATOR FUNCTIONS HERE
#
#           NOTE: These functions are only applicable to the
#                 following models:
#
#                 1. 2281S
# ======================================================================
def BatterySimulator_SetOverVoltageProtection(mySocket, vLevel):
    sndBuffer = ":BATT:SIM:TVOL:PROT {}".format(vLevel)
    instrSend(mySocket, sndBuffer)
    
def BatterySimulato_GetOverVoltageProtection(mySocket):
    return instrQuery(mySocket, ":BATT:SIM:TVOL:PROT?", 16)

def BatterySimulator_SetOverCurrentProtection(mySocket, vLevel):
    sndBuffer = ":BATT:SIM:CURR:PROT {}".format(vLevel)
    instrSend(mySocket, sndBuffer)
    
def BatterySimulato_GetOverCurrentProtection(mySocket):
    return instrQuery(mySocket, ":BATT:SIM:CURR:PROT?", 16)

# ======================================================================
#      DEFINE BATTERY TEST FUNCTIONS HERE
#
#           NOTE: These functions are only applicable to the
#                 following models:
#
#                 1. 2281S
# ======================================================================
