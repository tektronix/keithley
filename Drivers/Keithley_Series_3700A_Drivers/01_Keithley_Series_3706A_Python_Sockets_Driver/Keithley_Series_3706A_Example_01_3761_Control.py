import struct
import math
import time
import Keithley_Series_3706A_Sockets_Driver as kei
echoCmd = 1

#===== MAIN PROGRAM STARTS HERE =====
ipAddress1 = "192.168.1.37"
port = 5025
timeout = 20.0
myFile = "switch_functions.tsp"

KEI3706 = kei.KEI3706A()
myID = KEI3706.Connect(ipAddress1, 5025, 20000, 1, 1)
print(myID)
t1 = time.time()

#KEI3706.LoadScriptFile(myFile)
#KEI3706.SendCmd("do_beep(1.0, 3500)")

KEI3706.Set_3761_Switch_Mode(1, 0) # set card to amps mode
for j in range (1, 11):
    chan = 1000 + j
    KEI3706.Close(str(chan))
    time.sleep(0.5)
    KEI3706.Open(str(chan))
    time.sleep(0.5)

#time.sleep(1.0)
KEI3706.Disconnect()

t2 = time.time()

# Notify the user of completion and the test time achieved. 
print("done")
print("{0:.6f} s".format(t2-t1))
input("Press Enter to continue...")
exit()

exit()


