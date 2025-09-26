"""
This example performs a C-V sweep on a capacitor using the
4200A-SCS CVU via an ethernet connection. It will output a csv
file containing the C-V measurements such that they may
be plotted.
Device used: 10 pF Capacitor 4-Wire
"""

from instrcomms import Communications
import pandas as pd
import time


INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # Instrument resource string, obtained from NI MAX
my4200 = Communications(INST_RESOURCE_STR) # Opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # Opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" # Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" # Set PyVISA read terminator

my4200.query("BC") # Clear all readings from the buffer
my4200.query(":CVU:RESET") # Resets the CVU card
my4200.query(":CVU:MODE 1") # Sets the mode to System Mode
my4200.query(":CVU:MODEL 2") # Sets the measurement model to Cp, Gp
my4200.query(":CVU:SPEED 1") # Sets the measurement speed to normal
my4200.query(":CVU:ACZ:RANGE 0") # Sets the ac measurement range to autorange
my4200.query(":CVU:FREQ 1E6") # Set the frequency to 1 MHz
# Create a DC sweep, from 5 V to -5 V in 0.2 V steps, sample z measurements
my4200.query(":CVU:SWEEP:DCV 5, -5, -0.2")
my4200.query(":CVU:TEST:RUN") # Starts the CVU test

# This is a loop to check the status of the test
# The SP command returns 0 or 1 when the test is done running
while True:
    status = my4200.query("SP")

    # Continues loop until the test is complete
    # Casting the status string to int makes the comparison simpler since it ignores the termination characters
    if int(status) in [0, 1]:
        print("Measurement Complete.")
        break

    # Continously prints the status of the test every second to the terminal
    print(f"Status: {status}")
    time.sleep(1)

CpGp = my4200.query(":CVU:DATA:Z?") # Queries readings of Cp-Gp
Volt = my4200.query(":CVU:DATA:VOLT?") # Queries readings of Voltage

# Assume CpGp and Volt are the raw strings returned from the instrument
CpGpList = CpGp.strip().split("\n") # Split by newline
VoltList = Volt.strip().split("\n") # Split by newline

# Extract only Cp values (before the semicolon)
CapList = [line.split(";")[0] for line in CpGpList]

# Convert to float
VoltList = [float(v) for v in VoltList]
CapList = [float(c) for c in CapList]

df = pd.DataFrame({"Voltage": VoltList, "Capacitance": CapList})
df.to_csv("cv-cap.csv", index=False)
print("Data saved to CSV file")

my4200.disconnect() # Close communications with the 4200A-SCS
