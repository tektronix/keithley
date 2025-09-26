"""
This example performs a multi-channel sweep using the 4200A-SCS.
SMU1 performs a linear VAR1 sweep from 0 to 1 V, while SMU2 and SMU3 follow
the same sweep using VAR1' ratio mode. It measures voltage and current on all
three SMUs and logs the data to CSV.
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
# Channel 1. Voltage Name = V1, Current Name = I1, Voltage Source Mode, VAR1 sweep source function
my4200.query("CH1, 'V1', 'I1', 1, 1")
# Channel 1. Voltage Name = V2, Current Name = I2, Voltage Source Mode, VAR1' source function
my4200.query("CH2, 'V2', 'I2', 1, 4")
# Channel 1. Voltage Name = V3, Current Name = I3, Voltage Source Mode, VAR1' source function
my4200.query("CH3, 'V3', 'I3', 1, 4")
my4200.query("SS") # Access the source setup page
# Setup VAR1 source function, linear sweep, 0 V to 1 V, 0.1 V steps, 100 mA current compliance (SMU1)
my4200.query("VR1, 0, 1, 0.1, 100e-3")
my4200.query("RT 1, 2") # VAR1 sweep ratio value 1, apply to SMU2 only
my4200.query("RT 1, 3") # VAR1 sweep ratio value 1, apply to SMU3 only
my4200.query("HT 0") # Set to a 0 second hold time
my4200.query("DT 0.2") # Set to a 200 millisecond delay time
my4200.query("IT1") # Set the integration time to 0.1 PLC
my4200.query("SM DM2") # Access the measurement setup page, select list display mode
my4200.query("LI 'I1','I2','I3','V1','V2','V3'") # Enable current functions I1, I2, and I3 voltage functions V1, V2, and V3 in list display mode
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
var_returned = ["I1", "V1", "I2", "V2", "I3", "V3"]


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
df.to_csv("multi_channel_sweep.csv", index=False)
print("Data saved to CSV file")

my4200.disconnect() # Close communications with the 4200A-SCS