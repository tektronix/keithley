"""
This example uses SMU KXCI's user mode to set SMU1 to be a voltage source,
outputting 5 V, and measures one reading of voltage on SMU1.
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
# Map SMU channel 1 to be a Voltage Source, VS1
my4200.query("MP 1, VS1")
# Set voltage source 1 to output 5 V
my4200.query("DS1, 5")
time.sleep(1)
# Trigger a voltage measurement on channel 1
result = my4200.query("TV1")
print("Measured Voltage: ", result, " V")
# Turn off channel 1
my4200.query("DS1")

my4200.disconnect() # Close communications with the 4200A-SCS