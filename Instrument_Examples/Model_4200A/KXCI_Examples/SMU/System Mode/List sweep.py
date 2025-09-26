"""
This example performs a custom list sweep using the 4200A-SCS.
SMU1 sweeps from 0 to 1 V in 100 linear steps (defined via NumPy),
while SMU2 holds 0 V. It measures voltage on both SMUs
and logs the data to CSV.
Device used: 4-terminal DUT (e.g., nMOSFET) in 8101-PIV fixture
"""

from instrcomms import Communications
import pandas as pd
import numpy as np
import time

# Extra commands for plotting
import plotly.express as px

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # Instrument resource string, obtained from NI MAX
my4200 = Communications(INST_RESOURCE_STR) # Opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect()  # Opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" # Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" # Set PyVISA read terminator

SWEEP_NUMPY = np.linspace(0, 1, 100)
SWEEP_LIST = ",".join(["%.5f" % num for num in SWEEP_NUMPY])
print(SWEEP_LIST)

my4200.query("BC") # Clear all readings from the buffer
my4200.query("*RST") # Reset instruments to default settings
my4200.query("DE") # Access the SMU channel definition page
# Channel 3. Voltage Name = VS, Current Name = IS, Voltage Source Mode, Constant Source Function
my4200.query("CH3, 'VS', 'IS', 1, 3")
# Channel 1. Voltage Name = VD, Current Name = ID, Voltage Source Mode, VAR1 sweep source function
my4200.query("CH1, 'VD', 'ID', 1, 1")
my4200.query("SS")  # Access the source setup page
# Configure list sweep, SMU channel 1, 10 mA current compliance, sweep from SWEEP_LIST (0, 1, 100)
my4200.query(f"VL1,1, 0.01,{SWEEP_LIST}")
# Configure constant voltage, SMU channel 2, 0 V output value, 100 mA current compliance
my4200.query("VC3, 0, 100e-3")
my4200.query("HT 0") # Set to a 0 second hold time
my4200.query("DT 0.2") # Set to a 200 millisecond delay time
my4200.query("IT1") # Set the integration time to 0.1 PLC
my4200.query("RS 5") # Sets the measurement resolution to 5 digits
my4200.query("RG 1, 100e-9") # Set the lowest current range to be used on SMU 1 to 100 nA
my4200.query("RG 2, 100e-9") # Set the lowest current range to be used on SMU 2 to 100 nA
my4200.query("RG 3, 100e-9") # Set the lowest current range to be used on SMU 3 to 100 nA
my4200.query("SM DM1") # Access the measurement setup page, select graphics display mode
# Configures the x-axis of the graph to plot time domain values from 0 to 25 seconds
my4200.query("XT 0, 25")
# Configures the y1-axis of the graph to Channel 1 Voltage, minimum value of 0 V, maximum value of 1 V
my4200.query("YA 'VD', 1, 0, 1")
# Configures the y2-axis of the graph to Channel 3 Voltage, minimum value of 0 V, maximum value of 50 uV
my4200.query("YB 'VS', 1, 0, 50e-6")
my4200.query("MD") # Access the measurement control page
my4200.query("ME1") # Maps channel 1
start_time = time.perf_counter()
time.sleep(0.1)

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
var_returned = ["VD", "VS", "CH1T"]


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

end_time = time.perf_counter()
print("Measurement Time", end_time - start_time)

# Save the DataFrame into a CSV file
df.to_csv("list_sweep.csv", index=False)
print("Data saved to CSV file")

my4200.disconnect() # Close communications with the 4200A-SCS