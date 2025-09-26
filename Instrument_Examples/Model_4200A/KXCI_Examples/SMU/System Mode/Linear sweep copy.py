"""
This example performs a VAR1 linear sweep using the 4200A-SCS in list display mode.
SMU2 sweeps from 1 V to 5 V in 0.1 V steps while SMU1 holds 0 V.
It measures voltage and current on both SMUs and logs the data to CSV.
Relies on plotly to output a Drain Current vs Drain Voltage graph.
Device used: 4-terminal DUT (e.g., nMOSFET) in 8101-PIV fixture
"""

from instrcomms import Communications
import pandas as pd
import time

# Extra commands for plotting
import plotly.express as px

INST_RESOURCE_STR = "TCPIP0::134.63.72.115::1225::SOCKET" # Instrument resource string, obtained from NI MAX
my4200 = Communications(INST_RESOURCE_STR) # Opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # Opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" # Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" # Set PyVISA read terminator

my4200.query("BC") # Clear all readings from the buffer
my4200.query("*RST") # Reset instruments to default settings
my4200.query("DE") # Access the SMU channel definition page
start_time_system_mode = time.time()
my4200.query("CH1, 'V1','I1',1,1")
my4200.query("CH2, 'V2','I2',3,3")
my4200.query("LI 'I2', 'I1'")  # Measure currents
my4200.query("MD")
my4200.query("ME1")

end_time_system_mode = time.time()
#my4200.query("DCL")
print("time system mode :", end_time_system_mode - start_time_system_mode)

start_time_user_mode = time.time()

my4200.query("US")
my4200.query("CH1, 'V1','I1',1,1")
my4200.query("CH2, 'V2','I2',3,3")
my4200.query("DI 'I2', 'I1'")  # Measure currents
my4200.query("TI1")

end_time_user_mode = time.time()
print("time user mode   :", end_time_user_mode - start_time_user_mode)

my4200.disconnect() # Close communications with the 4200A-SCS