"""
This program outputs five square wave pulses (2V, 50e-6s) from 
a 4225-PMU without the 4225-RPMs. This code uses ethernet to 
communicate to the 4200A.
"""

import time
from instrcomms import Communications

INST_RESOURCE_STR = "TCPIP0::134.63.74.187::1225::SOCKET" #establish ethernet connection with the 4200A - change address based your IP address
pmuWave = Communications(INST_RESOURCE_STR)
pmuWave.connect()
pmuWave._instrument_object.write_termination = "\0"
pmuWave._instrument_object.read_termination = "\0"


pmuWave.query("PS1") #reset pmu, directed to channel 1
pmuWave.query("PD1, 1e6") # sets output impedence to 10e6
pmuWave.query("PT1, 100e-6, 50e-6, 1e-6, 1e-6") #timing parameters: "channel, pulse period, pulse width, rise time, fall time"
pmuWave.query("PV1, 2, 0, 5, 0.01") #voltage source and current limit: "channel, pulse high, pulse low, pulse range, current limit"
pmuWave.query("TS1, 0") #software trigger source
pmuWave.query("PO1, 1, 0") #set output in normal mode
pmuWave.query("PG1, 0, 5") #Trigger mode, 5 pulse burst
pmuWave.query("PO1, 0, 0") #set output off 
##send as a single wave on the MSO before executing the code
