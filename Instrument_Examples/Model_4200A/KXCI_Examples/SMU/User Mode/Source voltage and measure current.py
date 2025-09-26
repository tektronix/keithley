"""
This example uses SMU KXCI's user mode to set SMU1 to source voltage,
outputting 5 V and measures one reading of current on SMU1.
Device used: N/A
"""

from instrcomms import Communications
import time

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # Instrument resource string, obtained from NI MAX
my4200 = Communications(INST_RESOURCE_STR) # Opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # Opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" # Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" # Set PyVISA read terminator

my4200.query("BC") # Clear all readings from the buffer
my4200.query("*RST") # Reset instruments to default settings
my4200.query("US") # Enter SMU user mode
# Set SMU channel 1 to 20 V range, source 5V, with 10mA compliance
my4200.query("DV1, 1, 5, 10e-3")
time.sleep(1)
# Trigger a current measurement on channel 1
result = my4200.query("TI1")
print("Measured Current: ", result, " A")
# Turn off channel 1
my4200.query("DV1")

my4200.disconnect() # Close communications with the 4200A-SCS