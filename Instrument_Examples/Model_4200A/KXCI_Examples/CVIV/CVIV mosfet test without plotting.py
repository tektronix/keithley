"""
This example performs both I-V and C-V measurements on an n-MOSFET using the 4200A-SCS.
It uses the SMUs, CVU, and CVIV by calling the EX command. 

1. CVIV Configure for SMU Measurements:
Calls the cviv_configure user module by using the EX command. It configures the CVIV
for connection to the SMUs.

2. Vds-Id (Family of Curves):
This example performs a family of curves measurement using the 4200A-SCS.
It sweeps drain voltage (0-5 V) and steps gate voltage (1-4 V) using SMU2 and SMU3,
while SMU1 holds source at 0 V. Data is segmented and saved in a Clarius-like format.

3. CVIV Configure for CVU Measurements:
Calls the cviv_configure user module by using the EX command. It configures the CVIV
for connection to the CVU.

4. cv-nmosfet:
This example performs a C-V sweep on a nMOSFET from 5 V to -5 V using the 4200A-SCS CVU. It will output a
csv file containing the C-V measurements.
Relies on plotly to plot the capacitance and voltage measurements.

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

my4200.query("UL")
# Call the cviv_configure user module for SMU measurements
my4200.query("EX cvivulib cviv_configure (CVIV1, 1, 1, 1, 1, 1, Source, Drain, Gate, Bulk, IV, )")

# This is a loop to check the status of the test
# The SP command returns 0 or 1 when the test is done running
while True:
    status = my4200.query("SP")

    # Continues loop until the test is complete
    # Casting the status string to int makes the comparison simpler since it ignores the termination characters
    if int(status) in [0, 1]:
        print("Setup Complete.")
        break

    # Continously prints the status of the test every second to the terminal
    print(f"Status: {status}")
    time.sleep(1)

# Start SMU family of curves measurement
my4200.query("BC") # Clear all readings from the buffer
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
my4200.query("DM2") # Selects the list display mode
my4200.query("LI 'ID', 'VD','VG'") # Enable current function ID and voltage functions VD & VG in list display mode
my4200.query("MD") # Access the measurement control page
my4200.query("ME 1") # Maps channel 1

while True:
    status = my4200.query("SP")

    if int(status) in [0, 1]:
        print("Measurement Complete.")
        break

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
df_smu = pd.DataFrame(seg_measurements)

# Reorder the DataFrame
df_smu = df_smu[clarius_order]

# Save the DataFrame into a CSV file
df_smu.to_csv("vds-id.csv", index=False)
print("Data saved to CSV file")

# Set the CVIV to CVU Measurements

my4200.query("UL")
# Call the cviv_configure user module for CVU measurements
my4200.query("EX cvivulib cviv_configure (CVIV1, 1, 3, 3, 2, 3, Source, Drain, Gate, Bulk, CV, )")

while True:
    status = my4200.query("SP")

    if int(status) in [0, 1]:
        print("Setup Complete.")
        break

    print(f"Status: {status}")
    time.sleep(1)

my4200.query(":CVU:RESET") # Resets the CVU card
my4200.query(":CVU:MODE 1") # Sets the mode to System Mode
my4200.query(":CVU:MODEL 2") # Sets the measurement model to Cp, Gp
my4200.query(":CVU:SPEED 2") # Sets the measurement speed to quiet
my4200.query(":CVU:ACZ:RANGE 0") # Sets the ac measurement range to autorange
my4200.query(":CVU:FREQ 1E6") # Set the frequency to 1 MHz
# Create a DC sweep, from 5 V to -5 V in 0.2 V steps, sample z measurements
my4200.query(":CVU:SWEEP:DCV 5, -5, -0.2")
my4200.query(":CVU:DELAY:SWEEP 0.1") # Set the delay sweep for 100 ms
my4200.query(":CVU:TEST:RUN") # Starts the CVU test

while True:
    status = my4200.query("SP")

    if int(status) in [0, 1]:
        print("Measurement Complete.")
        break

    print(f"Status: {status}")
    time.sleep(1)

CpGp = my4200.query(":CVU:DATA:Z?") # Queries readings of Cp-Gp
Volt = my4200.query(":CVU:DATA:VOLT?") # Queries readings of Voltage

# Assume CpGp and Volt are the raw strings returned from the instrument
CpGpList = CpGp.strip().split("\n")  # Split by newline
VoltList = Volt.strip().split("\n")  # Split by newline

# Extract only Cp values (before the semicolon)
CapList = [line.split(";")[0] for line in CpGpList]

# Convert to float
VoltList = [float(v) for v in VoltList]
CapList = [float(c) for c in CapList]

df_cvu = pd.DataFrame({"Voltage (V)": VoltList, "Capacitance (F)": CapList})
df_cvu.to_csv("cv-nmosfet.csv", index=False)
print("Data saved to CSV file")

my4200.disconnect() # Close communications with the 4200A-SCS