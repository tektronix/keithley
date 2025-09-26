"""
This example performs a time-based capacitance measurement on a
capacitor using the 4200A-SCS CVU via an ethernet connection.
A fixed DC bias of 1 V is applied while capacitance values
are sampled every 100 ms for 250 total samples.
It will output a csv file containing the C-V measurements.
Relies on plotly to output a Capacitance vs Time graph.
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
my4200.query(":CVU:FREQ 1e6") # Sets the frequency to 1 MHz
my4200.query(":CVU:SAMPLE:INTERVAL 0.1") # Set the time between samples to 0.1 s
my4200.query(":CVU:BIAS:DCV:SAMPLE 1, 250") # Applies a 1 V DC Bias and takes 250 samples
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
Time = my4200.query(":CVU:DATA:TSTAMP?") # Queries readings of Timestamp


# Assume CpGp and Volt are the raw strings returned from the instrument
CpGpList = CpGp.strip().split("\n") # Split by newline
TimeList = Time.strip().split("\n") # Split by newline

# Extract only Cp values (before the semicolon)
CapList = [line.split(";")[0] for line in CpGpList]

# Convert to float
TimeList = [float(t) for t in TimeList]
CapList = [float(c) for c in CapList]

df = pd.DataFrame({"Timestamp": TimeList, "Capacitance": CapList})
df.to_csv("cap vs time.csv", index=False)
print("Data saved to CSV file")

# PLOTLY COMMANDS
# Create a capacitance vs time graph
fig = px.scatter(
    df,
    x="Timestamp",
    y="Capacitance",
    title="Capacitance vs Time Graph",
    labels={"Timestamp": "Time", "Capacitance": "Real"},
    hover_data=df.columns,
)

# Manually set the y-axis range
fig.update_layout(yaxis=dict(range=[465e-12, 466e-12]))

# Add line trace
fig.add_trace(px.line(df, x="Timestamp", y="Capacitance").data[0])
fig.show()

my4200.disconnect() # Close communications with the 4200A-SCS
