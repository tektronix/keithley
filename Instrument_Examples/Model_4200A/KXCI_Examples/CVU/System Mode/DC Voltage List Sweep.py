"""
This example performs a DC voltage list sweep on a capacitor using the
4200A-SCS CVU via an ethernet connection. It applies a fixed AC bias of
30 mV and steps through a custom list of DC bias voltages (0 V, 0.5 V, 1 V,
-0.5 V, -1 V), measuring the impedance at each point. It will output a csv
file containing the C-V measurements.
Relies on plotly to output a Capacitance vs Voltage graph.
Device used: 465 pF Capacitor 4-wire
"""

from instrcomms import Communications
import pandas as pd
import time

# Extra commands for plotting
import plotly.express as px

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # Instrument resource string, obtained from NI MAX
my4200 = Communications(INST_RESOURCE_STR) # Opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # Opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" # Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" # Set PyVISA read terminator

my4200.query("BC") # Clear all readings from the buffer
my4200.query(":CVU:RESET") # Resets the CVU card
my4200.query(":CVU:MODE 1") # Sets the mode to System Mode
my4200.query(":CVU:MODEL 2") # Sets the measurement model to Cp, Gp
my4200.query(":CVU:SPEED 2") # Sets the measurement speed to quiet
my4200.query(":CVU:ACZ:RANGE 0") # Sets the ac measurement range to autorange
my4200.query(":CVU:ACV 1") # Set AC bias to 30 mV
my4200.query(":CVU:SWEEP:LISTDCV 1, 0.5, 0, -0.5, -1") # Sweep an arbitrary list of DC voltage points
my4200.query(":CVU:DELAY:SWEEP 0.1") # Set the sweep delay to 100 ms
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
df.to_csv("DC voltage list sweep.csv", index=False)
print("Data saved to CSV file")

# PLOTLY COMMANDS
# Create a capacitance vs voltage graph
fig = px.scatter(
    df,
    x="Voltage",
    y="Capacitance",
    title="DC Voltage List Sweep of Capacitor",
    labels={"Voltage": "DCV_GB", "Capacitance": "Cp_GB"},
    hover_data=df.columns,
)

# Add line trace
fig.add_trace(px.line(df, x="Voltage", y="Capacitance").data[0])
fig.show()

my4200.disconnect()  # Close communications with the 4200A-SCS
