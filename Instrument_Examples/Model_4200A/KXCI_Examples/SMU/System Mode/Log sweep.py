"""
This example performs a log-scale VAR1 sweep using the 4200A-SCS in list display mode.
SMU2 sweeps from 1 V to 10 V (log10 scale) while SMU1 holds 0 V.
It measures voltage and current on both SMUs and logs the data to CSV.
Relies on plotly to output a Diode Forward I-V Sweep graph.
Device used: RF-43 Diode
"""

from instrcomms import Communications
import pandas as pd
import time

# Extra commands for plotting
import plotly.express as px

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # Instrument resource string, obtained from NI MAXX
my4200 = Communications(INST_RESOURCE_STR) # Opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # Opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" # Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" # Set PyVISA read terminator

my4200.query("BC") # Clear all readings from the buffer
my4200.query("*RST") # Reset instruments to default settings
my4200.query("DE") # Access the SMU channel definition page
# Channel 1. Voltage Name = V1, Current Name = I1, Voltage Source Mode, VAR1 sweep source Function
my4200.query("CH1, 'V1', 'I1', 1, 1")
# Channel 2. Voltage Name = V2, Current Name I2, Voltage Source Mode, Constant voltage sourcefunction
my4200.query("CH2, 'V2', 'I2', 1, 3")
my4200.query("SS") # Access the source setup page
# Configure constant voltage, SMU channel 1, 0 V output value, 100 mA current compliance
my4200.query("VC2, 0, 100e-3")
# Setup VAR1 source function, log10 sweep, 10 mV to 1 V
my4200.query("VR4, 10e-3, 1")
my4200.query("HT 0") # Set to a 0 second hold time
my4200.query("DT 0.2") # Set to a 200 millisecond delay time
my4200.query("IT1") # Set the integration time to 0.1 PLC
my4200.query("SM DM2") # Access the measurement setup page, select list display mode
my4200.query("LI 'I1','I2','V1','V2'") # Enable current functions I1 & I2 and voltage functions V1 & V2 in list display mode
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
var_returned = ["I1", "V1", "I2", "V2"]


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
df.to_csv("log_sweep.csv", index=False)
print("Data saved to CSV file")

# PLOTLY COMMANDS
# Plot anode voltage vs anode current (V1 vs 1)
fig = px.scatter(
    df,
    x="V1",
    y="I1",
    title="Diode Forward I-V Sweep",
    labels={"V1": "Anode Voltage (V)", "I1": "Anode Current (A)"},
)
fig.add_trace(px.line(df, x="V1", y="I1").data[0])
fig.show()

my4200.disconnect() # Close communications with the 4200A-SCS