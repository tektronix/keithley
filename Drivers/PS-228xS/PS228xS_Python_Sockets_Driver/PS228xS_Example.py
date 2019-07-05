#!/usr/bin/python
import socket
import struct
import math
import time
import Keithley_PS228xS_Sockets_Driver as ps
echoCmd = 1



#===== MAIN PROGRAM STARTS HERE =====
ipAddress1 = "134.63.78.214"
ipAddress2 = "134.63.74.152"
ipAddress3 = "134.63.78.214"
port = 5025
timeout = 20.0

t1 = time.time()


#ps.instrConnect(s1, ipAddress1, port, timeout, 0, 0)
s1 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s1, idStr = ps.PowerSupply_Connect(s1, ipAddress1, port, timeout, echoCmd, 1, 1)
print(idStr)
ps.PowerSupply_SetVoltage(s1, 10.0)
ps.PowerSupply_SetCurrent(s1, 1.5)

ps.PowerSupply_SetVoltageProtection(s1, 33.0)
ps.PowerSupply_SetCurrentProtection(s1, 2.0)

print(ps.PowerSupply_GetVoltage(s1))
print(ps.PowerSupply_GetCurrent(s1))

ps.PowerSupply_SetDataFormat(s1, 1, 0, 0)

ps.PowerSupply_SetOutputState(s1, 1)
ps.PowerSupply_SetDisplayText(s1, "Powering On DUT...")
print(ps.PowerSupply_GetOutputState(s1))
time.sleep(3.0)

print(ps.PowerSupply_MeasureCurrent(s1))
print(ps.PowerSupply_MeasureVoltage(s1))
time.sleep(1.0)

ps.PowerSupply_SetOutputState(s1, 0)
ps.PowerSupply_SetDisplayText(s1, "Powering Off DUT...")
ps.PowerSupply_Disconnect(s1)

t2 = time.time()

# Notify the user of completion and the test time achieved. 
print("done")
print("{0:.6f} s".format(t2-t1))
raw_input("Press Enter to continue...")
exit()

exit()


