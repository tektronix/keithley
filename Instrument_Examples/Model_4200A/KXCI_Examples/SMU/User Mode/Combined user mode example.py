"""
This example uses the SMU KXCI's user mode to source a 100 nA
current on SMU1, and sets SMU2 to be a voltage source, sourcing 5 volts.
50 voltage readings are then taken on channel 1.
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
# Set SMU channel 1 to autorange, set to source 100e-9 A, with 20 V compliance
my4200.query("DI1, 0, 100e-9, 20")
# Map SMU channel 2 to be a Voltage Source, VS2
my4200.query("MP 2, VS2")
# Set voltage source 2 to output 5 V
my4200.query("DS2, 5")
time.sleep(1)

# Trigger 50 voltage measurements on channel 1
num_points = 50
delay = 0.05  # Delay in seconds
voltages = []

for i in range(num_points):
    v = my4200.query("TV1")
    voltages.append(v)
    print("Point ", i, " Measured Voltage: ", v, " V")
    time.sleep(delay)

# Turn off channel 1
my4200.query("DI1")
# Turn off channel 2
my4200.query("DS2")

my4200.disconnect()  # Close communications with the 4200A-SCS