# tested with
# EA Elektro-Automatik GmbH & Co. KG, PS 9040-20 T
# over RS-232

import pyvisa
#import pyvisa as visa
import pyvisa.constants as pyconst
import time
import numpy as np

#instrument_resource_string = "TCPIP0::192.168.1.176::5025::SOCKET"   
#EA uses port 5025 on LAN
instrument_resource_string = "ASRL2::INSTR"

resource_mgr = pyvisa.ResourceManager()
my_instr = resource_mgr.open_resource(instrument_resource_string)

my_instr.write_termination = '\n'  
my_instr.read_termination = '\n'

my_instr.baud_rate = 9600
my_instr.data_bits = 8
my_instr.parity = pyconst.Parity.none
my_instr.stop_bits = pyconst.StopBits.one
#my_instr.flow_control = flow_control
my_instr.write_termination = "\n"
my_instr.send_end = True

my_instr.timeout = 5000   #timeout in msec
my_instr.VI_ATTR_TCPIP_KEEPALIVE = True

my_instr.write("*IDN?")
print(my_instr.read())

my_instr.write("SYST:LOCK ON")  # enable remote control

#SCPI commands to output 5V with 1.5Amp limit

volts = 5
current_limit = 1.5
current_trip = current_limit * 1.1  # make trip value 10% higher than current limit
max_watts = volts * current_trip    # set power limit

cmd_list = ["*RST",
            "*CLS",
            "SOUR:VOLT %g" %volts,
            "SOUR:CURR %g" %current_limit,
            "CURR:PROT %g" %current_trip,
            "SOUR:POW %g" %max_watts,
            ":OUTP ON"]    

for cmd in cmd_list:
    my_instr.write(cmd)


time.sleep(0.1) 
my_instr.write("SYST:ERR?")
print("Response to error query: %s" %my_instr.read())   #read the response
print("finished setting up")

#output on
my_instr.write("OUTP ON")

time.sleep(0.1)  # allow some settling time

#read the current
print(my_instr.query("MEAS:CURR?"))

#output off
my_instr.write("OUTP OFF")

#put instrument back to local and close connection
my_instr.write("SYST:LOCK OFF")  # disable remote control
my_instr.clear()
my_instr.close()
resource_mgr.close()