"""
This example performs a C-V sweep on a nMOSFET using the
4200A-SCS CVU via a GPIB connection. It will output a csv
file containing the C-V measurements.
Relies on plotly to output a Capacitance vs Voltage graph.
Device used: 4-terminal DUT (e.g., nMOSFET) in 8101-PIV fixture
with Drain/Source/Bulk tied together.
"""

from instrcomms import Communications
import pandas as pd

# Extra commands for plotting
import plotly.express as px

INST_RESOURCE_STR = ("GPIB0::17::INSTR") # Instrument resource string, obtained from NI-VISA Interactive
my4200 = Communications(INST_RESOURCE_STR) # Opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # Opens connections to the 4200A-SCS

my4200.write("BC") # Clear all readings from the buffer
my4200.write(":CVU:RESET") # Resets the CVU card
my4200.write("DR1") # Enable the Data Ready Bit
my4200.write(":CVU:MODE 1") # Sets the mode to System Mode
my4200.write(":CVU:MODEL 2") # Sets the measurement model to Cp, Gp
my4200.write(":CVU:SPEED 2") # Sets the measurement speed to quiet
my4200.write(":CVU:ACZ:RANGE 0") # Sets the ac measurement range to autorange
my4200.write(":CVU:FREQ 1E6") # Set the frequency to 1 MHz
# Create a DC sweep, from 5 V to - 5 V in 0.2 V steps, sample z measurements
my4200.write(":CVU:SWEEP:DCV 5, -5, -0.2")
my4200.write(":CVU:DELAY:SWEEP 0.1") # Set the sweep delay to 100 m
my4200.write(":CVU:TEST:RUN") # Starts the CVU test

my4200._instrument_object.wait_for_srq() # Waits until data is ready by waiting for serial request coming from the 4200A-SCS

CpGp = my4200.query(":CVU:DATA:Z?") # Queries readings of Cp-Gp
Volt = my4200.query(":CVU:DATA:VOLT?") # Queries readings of Voltage

# Assume CpGp and Volt are the raw strings returned from the instrument
CpGpList = CpGp.split(",") # Split by comma
VoltList = Volt.split(",") # Split by comma

# Trim the last value (returns None)
VoltList = VoltList[:-1]
CpGpList = CpGpList[:-1]

# Extract only Cp values (before the semicolon)
CapList = [line.split(";")[0] for line in CpGpList]

# Convert to float
VoltList = [float(v) for v in VoltList]
CapList = [float(c) for c in CapList]

df = pd.DataFrame({"Voltage": VoltList, "Capacitance": CapList})
df.to_csv("cv-nmosfet.csv", index=False)
print("Data saved to CSV file")

# PLOTLY COMMANDS
# Create a capacitance vs voltage graph
fig = px.scatter(
    df,
    x="Voltage",
    y="Capacitance",
    title="N-MOSFET CV Sweep Gate to Drain/Source/Bulk",
    labels={"Voltage": "DCV_GB", "Capacitance": "Cp_GB"},
    hover_data=df.columns,
)

# Add line trace
fig.add_trace(px.line(df, x="Voltage", y="Capacitance").data[0])
fig.show()

my4200.disconnect() # Close communications with the 4200A-SCS
