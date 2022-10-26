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

source_i_range = None
bias_i = 0.075
source_v_limit = 11
settle_time = 1.0
nplc = 1
measure_v_range = None

measured_bias_current, measured_rev_voltage = my_smu.diode_test_measure_reverse_voltage("smua", source_i_range, bias_i,
                                                                                        source_v_limit, settle_time,
                                                                                        nplc, measure_v_range,
                                                                                        my_smu.SmuOutputState.OFF)

print("Measured bias current = {0} A".format(measured_bias_current))
print("Measured reverse voltage = {0} V".format(measured_rev_voltage))

my_smu.instrument_disconnect()
rm.close()

t2 = time.time()

print("done")
print("Elapsed Time: {0:0.3f}s".format(t2-t1))

