"""
This example configures all four SMUs on a 4200A-SCS to source 0 V with 1 µA compliance.
It performs a fixed current measurement (100 nA) on each channel, takes 3 readings,
and saves the results with timestamps to a CSV file.
Device used: N/A
"""

from instrcomms import Communications
import pandas as pd
import time

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # Instrument resource string, obtained from NI MAX
my4200 = Communications(INST_RESOURCE_STR)  # Opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # Opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" # Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" # Set PyVISA read terminator

my4200.query("BC") # Clear all readings from the buffer
my4200.query("*RST") # Reset instruments to default settings
my4200.query("DE") # Access the SMU channel definition page
# Channel 1. Voltage Name = AV, Current Name = AI, Voltage Source Mode, Constant source function
my4200.query("CH 1, 'AV', 'AI', 1, 3")
# Channel 2. Voltage Name = BV, Current Name = BI, Voltage Source Mode, Constant source function
my4200.query("CH 2, 'BV', 'BI', 1, 3")
# Channel 3. Voltage Name = CV, Current Name = CI, Voltage Source Mode, Constant source function
my4200.query("CH 3, 'CV', 'CI', 1, 3")
# Channel 4. Voltage Name = DV, Current Name = DI, Voltage Source Mode, Constant source function
my4200.query("CH 4, 'DV', 'DI', 1, 3")
my4200.query("SS") # Access the source setup page
# Configure constant voltage, SMU channel 1, 0 V output value, 100 mA current compliance
my4200.query("VC 1, 0, 1e-6")
# Configure constant voltage, SMU channel 2, 0 V output value, 1 uA current compliance
my4200.query("VC 2, 0, 1e-6")
# Configure constant voltage, SMU channel 3, 0 V output value, 1 uA current compliance
my4200.query("VC 3, 0, 1e-6")
# Configure constant voltage, SMU channel 4, 0 V output value, 1 uA current compliance
my4200.query("VC 4, 0, 1e-6")
my4200.query("IT2") # Set integration time to 1 PLC
my4200.query("SM") # Access the measurement setup page
my4200.query("SR 1, 100e-9") # Set SMU 1 to a fixed current range of 100 nA
my4200.query("SR 2, 100e-9") # Set SMU 2 to a fixed current range of 100 nA
my4200.query("SR 3, 100e-9") # Set SMU 3 to a fixed current range of 100 nA
my4200.query("SR 4, 100e-9") # Set SMU 4 to a fixed current range of 100 nA
my4200.query("NR 3") # Take 3 readings
my4200.query("DM2") # Selects the graphics display mode
my4200.query("MD") # Access the measurement control page
my4200.query("LI 'AI', 'BI', 'CI', 'DI', 'CH1T'")
my4200.query("LI 'CH2T', 'CH3T', 'CH4T'")
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
var_returned = ["AI", "BI", "CI", "DI", "CH1T", "CH2T", "CH3T", "CH4T"]


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


# Create a DataFrame for the measurements
df = pd.DataFrame(all_measurements)

# Calculate the delta time
df["Delta_CH1T"] = df["CH1T"].diff()
# Calculate the delta time
df["Delta_CH2T"] = df["CH2T"].diff()
# Calculate the delta time
df["Delta_CH3T"] = df["CH3T"].diff()
# Calculate the delta time
df["Delta_CH4T"] = df["CH4T"].diff()
# Save the DataFrame into a CSV file
df.to_csv("4_smus_0V.csv", index=False)
print("Data saved to CSV file")

my4200.disconnect() # Close communications with the 4200A-SCS