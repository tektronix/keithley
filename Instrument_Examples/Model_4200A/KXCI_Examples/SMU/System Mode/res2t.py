"""
This example recreates the Clarius res2t test by performing
a 2-terminal resistance sweep using the 4200A-SCS.
It sweeps voltage from -1 V to 1 V on SMU1 while SMU2 holds 0 V,
measures current, and calculates average resistance.
Device used: 1 Gohm resistor
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
my4200.query("*RST") # Reset instruments to default settings
my4200.query("DE") # Access the SMU channel definition page
# Channel 1. Voltage Name = AV, Current Name = AI, Voltage Source Mode, VAR1 sweep source function
my4200.query("CH 1, 'AV', 'AI', 1, 1")
# Channel 2. Voltage Name = BV, Current Name = BI, Voltage Source Mode, Constant source function
my4200.query("CH 2, 'BV', 'BI', 1, 3")
my4200.query("SS")  # Access the source setup page
# Setup VAR1 source function, linear sweep, -1 V to 1 V, 40 mV steps, 100 mA current compliance
my4200.query("VR 1, -1, 1, 40e-3, 100e-3")
# Configure constant voltage, SMU channel 2, 0 V output value, 100 mA current compliance
my4200.query("VC 2, 0, 100e-3")
my4200.query("HT 0") # Set to a 0 second hold time
my4200.query("DT 0") # Set to a 0 delay time
my4200.query("IT2") # Set integration time to 1 PLC
my4200.query("RS 5") # Sets the measurement resolution to 5 digits
my4200.query("RG 1, 100e-9") # Set the lowest current range to be used on SMU 1 to 100 nA
my4200.query("RG 2, 100e-9") # Set the lowest current range to be used on SMU 2 to 100 nA
my4200.query("SM") # Access the measurement setup page
my4200.query("DM1") # Selects the graphics display mode
# Configures x-axis of the graph to Channel 1 Voltage, minimum value of -1 V, maximum value of 1 V
my4200.query("XN 'AV', 1, -1, 1")
# Configures y-axis of the graph to Channel 1 Current, minimum value of -100 nA, maximum value of 100 nA
my4200.query("YA 'AI', 1, -100e-9, 100e-9")
my4200.query("MD") # Access the measurement control page
my4200.query("ME 1") # Maps channel 1

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

# Specify what measurements to return
var_returned = ["AI", "AV"]


# Function to retrieve measurements for each variable
def retrieve_measurements(variable):
    index = 1
    measurements = []
    while True:
        data = my4200.query(f"RD '{variable}', {index}")
        if data == "0":
            break
        measurements.append(float(data))
        index += 1
    return measurements


# Store all measurements in a dictionary
all_measurements = {}
for variable in var_returned:
    all_measurements[variable] = retrieve_measurements(variable)

# Calculate the average resistance
avg_res = sum(all_measurements["AV"]) / sum(all_measurements["AI"])

# Create a DataFrame for the measurements
df = pd.DataFrame(all_measurements)

# Insert the average resistance at the top of the 'Average Resistance' column
df.insert(2, "RES", "")

# Set the average resistance value only in the first row
df.iloc[0, 2] = avg_res
# Save the DataFrame into a CSV file
df.to_csv("res2t.csv", index=False)
print("Data saved to CSV file")

my4200.disconnect() # Close communications with the 4200A-SCS