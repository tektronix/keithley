"""
This example performs a static bias test using the 4200A-SCS.
Both SMU1 and SMU2 are set to 0 V to monitor baseline current behavior.
It measures current on both SMUs over time and logs the data to CSV.
Device used: N/A
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
# Channel 2. Voltage Name = VS, Current Name = IS, Voltage Source Mode, Constant Source Function
my4200.query("CH2, 'VS', 'IS', 1, 3")
# Channel 1. Voltage Name = VD, Current Name = ID, Voltage Source Mode, Constant Source Function
my4200.query("CH1, 'VD', 'ID', 1, 3")
my4200.query("SS") # Access the source setup page
# Configure constant voltage, SMU channel 1, 0 V output value, 100 mA current compliance
my4200.query("VC1, 0, 100e-3")
# Configure constant voltage, SMU channel 2, 0 V output value, 100 mA current compliance
my4200.query("VC2, 0, 100e-3")
my4200.query("HT 0") # Set to a 0 second hold time
my4200.query("DT 0.2") # Set to a 200 millisecond delay time
my4200.query("IT1") # Set the integration time to 0.1 PLC
my4200.query("RS 5") # Sets the measurement resolution to 5 digits
my4200.query("RG 1, 100e-9") # Set the lowest current range to be used on SMU 1 to 100 nA
my4200.query("RG 2, 100e-9") # Set the lowest current range to be used on SMU 2 to 100 nA
my4200.query("SM") # Access the measurement setup page
my4200.query("NR 500") # Take 500 readings
my4200.query("DM1") # Select graphics display mode
# Configures the x-axis of the graph to plot time domain values from 0 to 10 seconds
my4200.query("XT 0, 10")
# Configures the y1-axis of the graph to Channel 1 Voltage, minimum value of 0 V, maximum value of 15 mV
my4200.query("YA 'ID', 1, 0, 10e-12")
# Configures the y2-axis of the graph to Channel 2 Voltage, minimum value of 0 V, maximum value of 15 mV
my4200.query("YB 'IS', 1, 0, 10e-12")
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
var_returned = ["ID", "IS", "CH2T"]


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
df.to_csv("2_smus_0V.csv", index=False)
print("Data saved to CSV file")

my4200.disconnect() # Close communications with the 4200A-SCS