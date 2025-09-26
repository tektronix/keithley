"""
This example performs a family of curves measurement using the 4200A-SCS.
It sweeps drain voltage (0-5 V) and steps gate voltage (1-4 V) using SMU2 and SMU3,
while SMU1 holds source at 0 V. Data is segmented and saved in a Clarius-like format.
Device used: 4-terminal DUT (e.g., nMOSFET) in 8101-PIV fixture
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
# Channel 1. Voltage Name = VS, Current Name = IS, Voltage Source Mode, Constant source function
my4200.query("CH 1, 'VS', 'IS', 1, 3")
# Channel 2. Voltage Name = VD, Current Name = ID, Voltage Source Mode, VAR1 sweep source function
my4200.query("CH 2, 'VD', 'ID', 1, 1")
# Channel 3. Voltage Name = VG, Current Name = IG, Voltage Source Mode, VAR2 sweep source function
my4200.query("CH 3, 'VG', 'IG', 1, 2")
my4200.query("SS") # Access the source setup page
# Setup VAR1 source function, linear sweep, 0 V to 5 V, 0.1 V steps, 100 mA current compliance (SMU2)
my4200.query("VR 1, 0, 5, 0.1, 100e-3")
# Setup VAR2 step sweep, 1 V to 4 V, 4 total steps (step size 1 V), 100 mA current compliance (SMU3)
my4200.query("VP 2, 1, 4, 100e-3")
# Configure constant voltage, SMU channel 1, 0 V output value, 100 mA current compliance
my4200.query("VC 1, 0, 100e-3")
my4200.query("HT 0") # Set to a 0 second hold time
my4200.query("DT 0.001") # Set to a 1 millisecond delay time
my4200.query("IT2") # Set integration time to 1 PLC
my4200.query("RS 5") # Sets the measurement resolution to 5 digits
my4200.query("RG 1, 100e-9") # Set the lowest current range to be used on SMU 1 to 100 nA
my4200.query("RG 2, 100e-9") # Set the lowest current range to be used on SMU 2 to 100 nA
my4200.query("RG 3, 100e-9") # Set the lowest current range to be used on SMU 3 to 100 nA
my4200.query("SM") # Access the measurement setup page
my4200.query("DM1") # Selects the graphics display mode
# Configures the x-axis of the graph to Channel 1 Voltage, minimum value of 0 V, maximum value of 5 V
my4200.query("XN 'VD', 1, 0, 5")
# Configures the y-axis of the graph to Channel 1 Current, minimum value of 0 A, maximum value of 40 mA
my4200.query("YA 'ID', 1, 0, 0.04")
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
var_returned = ["ID", "VD", "VG"]

# Define the number of segments for each measurements
num_segments = 4 # Total number of lines
readings_per_seg = (51) # Divide total number of readings by segments to get the readings per segment


# Set custom data names
custom_data_names = {"VD": "DrainV", "ID": "DrainI", "VG": "GateV"}


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

# Split the measurements into segments
seg_measurements = {} # Initalize segment measurements
for (variables, meas) in all_measurements.items():
    seg_var_measurements = {} # Initialize segments for variable measurements
    for segment in range(1, num_segments + 1):
        start_index = (segment - 1) * readings_per_seg # Set start index
        end_index = segment * readings_per_seg  # Set end index
        seg_name = custom_data_names.get(variables, f"{variables}({segment})") # Set custom data names
        seg_var_measurements[f"{seg_name}({segment})"] = meas[start_index:end_index] # Set the measurements to return
    seg_measurements.update(seg_var_measurements) # Append array for measurements

# Sort the columns in the order as shown in Clarius
clarius_order = [
    "DrainI(1)",
    "DrainV(1)",
    "GateV(1)",
    "DrainI(2)",
    "DrainV(2)",
    "GateV(2)",
    "DrainI(3)",
    "DrainV(3)",
    "GateV(3)",
    "DrainI(4)",
    "DrainV(4)",
    "GateV(4)",
]

# Create a DataFrame from the segmented measurements
df = pd.DataFrame(seg_measurements)

# Reorder the DataFrame
df = df[clarius_order]

# Save the DataFrame into a CSV file
df.to_csv("family_of_curves.csv", index=False)

print("Data saved to CSV file")

my4200.disconnect() # Close communications with the 4200A-SCS