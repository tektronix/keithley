import visa
import struct
import math
import time
import PowerAnalyzer_VISA_Driver as pa

def send_configuration_file(my_file, my_pa):
    with open(my_file) as fp:
        line = fp.readline()
        cnt = 1
        while line:
            print("Line {}: {}".format(cnt, line.strip()))
            line = fp.readline()
            my_pa.SendCmd(line)
            cnt += 1
    return

#===== MAIN PROGRAM STARTS HERE =====
rm = visa.ResourceManager()	# Opens the resource manager and sets it to variable rm
pa_instrument_string = "TCPIP0::192.168.1.122::5025::SOCKET"
# DAQ_Inst_1 = "TCPIP0::192.168.1.2::inst0::INSTR"
# Instrument ID String examples...
#       LAN -> TCPIP0::134.63.71.209::inst0::INSTR or
#              TCPIP0::192.168.1.122::5025::SOCKET
#       USB -> USB0::0x05E6::0x2450::01419962::INSTR
#       GPIB -> GPIB0::16::INSTR
#       Serial -> ASRL4::INSTR
timeout = 20000
myFile = "CONFIG04EDIT.CFG"

PA3000 = pa.PowerAnalyzer()
myID = PA3000.Connect(rm, pa_instrument_string, timeout, 1, 1, 1)
t1 = time.time()
send_configuration_file(myFile, PA3000)
PA3000.Disconnect()
rm.close()

t2 = time.time()

# Notify the user of completion and the test time achieved. 
print("done")
print("{0:.6f} s".format(t2-t1))
input("Press Enter to continue...")
exit()


