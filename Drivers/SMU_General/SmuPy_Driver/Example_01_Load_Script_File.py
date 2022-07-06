import visa
import time
import SmuPy_20190807 as kei

# ===== MAIN PROGRAM STARTS HERE =====
t1 = time.time()

rm = visa.ResourceManager() 	# Opens the resource manager and sets it to variable rm
smu_id_1 = "USB0::0x05E6::0x2602::4132104::INSTR"
# Instrument ID String examples...
#       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
#       USB -> USB0::0x05E6::0x2450::01419962::INSTR
#       GPIB -> GPIB0::16::INSTR
#       Serial -> ASRL4::INSTR
timeout = 20000
my_file = "DiodeTestFunctions_12Jun2019.tsp"

my_smu = kei.SmuPy()
myID = my_smu.instrument_connect(rm, smu_id_1, timeout, 1, 1, 1)
my_smu.load_script_file(my_file)
my_smu.instrument_write("do_beep(0.1, 3500, 3)")
my_smu.instrument_disconnect()
t2 = time.time()
