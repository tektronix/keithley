'''
NOTE: THIS EXAMPLE PROGRAM REQUIRES CLARIUS VERSION 1.13 OR LATER!

This example is a KXCI recreation of the Clarius pmu SegARB B test.
It utilizes two channels with a 82 segment waveform sequence from a 4225-PMU with the 4225-RPMs.
Relies on plotly for creating side-by-side graphs.
Device used: 1 Kohm resistor
'''

from instrcomms import Communications
#Extra commands for plotting
import plotly.express as px
import pandas as pd
import time
import plotly.graph_objects as go
from plotly.subplots import make_subplots

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # instrument resource string, obtained from NI MAX

my4200 = Communications(INST_RESOURCE_STR) # opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" #Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" #Set PyVISA read terminator

#Initalize to segARB mode
my4200.query(":PMU:INIT 1")

ch1 = 1
ch2 = 2
seq_num = 1

#Configure the RPM input for channel 1 of pulse card 1 to the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU1-1, 0")
#Set channel 1 to a fixed 200 mA current range
my4200.query(f":PMU:MEASURE:RANGE {ch1}, 2, 200e-3")

#Configure an array of timing values for channel 1
SEGTIME = (
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07'
)
my4200.query(f":PMU:SARB:SEQ:TIME {ch1}, {seq_num}, {SEGTIME}")

#Configure an array of starting voltage values for channel 1
STARTV_1= (
    '0.0, 0.0, 0.1, 0.1, 0.2, 0.2, 0.3, 0.3, 0.4, 0.4, '
    '0.5, 0.5, 0.6, 0.6, 0.7, 0.7, 0.8, 0.8, 0.9, 0.9, '
    '1.0, 1.0, 1.1, 1.1, 1.2, 1.2, 1.3, 1.3, 1.4, 1.4, '
    '1.5, 1.5, 1.6, 1.6, 1.7, 1.7, 1.8, 1.8, 1.9, 1.9, '
    '2.0, 2.0, 1.9, 1.9, 1.8, 1.8, 1.7, 1.7, 1.6, 1.6, '
    '1.5, 1.5, 1.4, 1.4, 1.3, 1.3, 1.2, 1.2, 1.1, 1.1, '
    '1.0, 1.0, 0.9, 0.9, 0.8, 0.8, 0.7, 0.7, 0.6, 0.6, '
    '0.5, 0.5, 0.4, 0.4, 0.3, 0.3, 0.2, 0.2, 0.1, 0.1, '
    '0.0, 0.0'
)
my4200.query(f":PMU:SARB:SEQ:STARTV {ch1}, {seq_num}, {STARTV_1}")

#Configure an array of stopping voltage values for channel 1
STOPV_1 = (
    '0.0, 0.1, 0.1, 0.2, 0.2, 0.3, 0.3, 0.4, 0.4, 0.5, '
    '0.5, 0.6, 0.6, 0.7, 0.7, 0.8, 0.8, 0.9, 0.9, 1.0, '
    '1.0, 1.1, 1.1, 1.2, 1.2, 1.3, 1.3, 1.4, 1.4, 1.5, '
    '1.5, 1.6, 1.6, 1.7, 1.7, 1.8, 1.8, 1.9, 1.9, 2.0, '
    '2.0, 1.9, 1.9, 1.8, 1.8, 1.7, 1.7, 1.6, 1.6, 1.5, '
    '1.5, 1.4, 1.4, 1.3, 1.3, 1.2, 1.2, 1.1, 1.1, 1.0, '
    '1.0, 0.9, 0.9, 0.8, 0.8, 0.7, 0.7, 0.6, 0.6, 0.5, '
    '0.5, 0.4, 0.4, 0.3, 0.3, 0.2, 0.2, 0.1, 0.1, 0.0, '
    '0.0, 0.0'
)
my4200.query(f":PMU:SARB:SEQ:STOPV {ch1}, {seq_num}, {STOPV_1}")

#Configure an array of measurement types for channel 1
MEASTYPE = (
    '1, 0, 1, 0, 1, 0, 1, 0, 1, 0, '
    '1, 0, 1, 0, 1, 0, 1, 0, 1, 0, '
    '1, 0, 1, 0, 1, 0, 1, 0, 1, 0, '
    '1, 0, 1, 0, 1, 0, 1, 0, 1, 0, '
    '1, 0, 1, 0, 1, 0, 1, 0, 1, 0, '
    '1, 0, 1, 0, 1, 0, 1, 0, 1, 0, '
    '1, 0, 1, 0, 1, 0, 1, 0, 1, 0, '
    '1, 0, 1, 0, 1, 0, 1, 0, 1, 0, '
    '1, 0'
)
my4200.query(f":PMU:SARB:SEQ:MEAS:TYPE {ch1}, {seq_num}, {MEASTYPE}")

#Configure an array of starting measurement values for channel 1
MEASSTART = (
    '0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '
    '0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '
    '0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '
    '0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '
    '0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '
    '0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '
    '0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '
    '0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '
    '0, 0'
)
my4200.query(f":PMU:SARB:SEQ:MEAS:START {ch1}, {seq_num}, {MEASSTART}")

#Configure an array of stopping measurement values for channel 1
MEASSTOP = (
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, 2E-05, 2E-07, '
    '2E-05, 2E-07'
)
my4200.query(f":PMU:SARB:SEQ:MEAS:STOP {ch1}, {seq_num}, {MEASSTOP}")


#Configure the RPM input for channel 2 of pulse card 1 to the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU1-2, 0")
#Set channel 1 to a fixed 200 mA current range
my4200.query(f":PMU:MEASURE:RANGE {ch2}, 2, 200e-3")

#Configure an array of timing values for channel 2
my4200.query(f":PMU:SARB:SEQ:TIME {ch2}, {seq_num}, {SEGTIME}")

#Configure an array of starting voltage values for channel 2
STARTV_2 = (
    '0, 0, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2'
)
my4200.query(f":PMU:SARB:SEQ:STARTV {ch2}, {seq_num}, {STARTV_2}")

#Configure an array of stopping voltage values for channel 2
STOPV_2 = (
    '0, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, '
    '0.2, 0'
)
my4200.query(f":PMU:SARB:SEQ:STOPV {ch2}, {seq_num}, {STOPV_2}")

#Use the same measurement types, starting, stopping values for channel 2
my4200.query(f":PMU:SARB:SEQ:MEAS:TYPE {ch2}, {seq_num}, {MEASTYPE}")
my4200.query(f":PMU:SARB:SEQ:MEAS:START {ch2}, {seq_num}, {MEASSTART}")
my4200.query(f":PMU:SARB:SEQ:MEAS:STOP {ch2}, {seq_num}, {MEASSTOP}")

#Set the sequence lists for channels 1 and 2
my4200.query(f":PMU:SARB:WFM:SEQ:LIST {ch1}, 1, 1")
my4200.query(f":PMU:SARB:WFM:SEQ:LIST {ch2}, 1, 1")

#Set the output state to on for channels 1 and 2
my4200.query(f":PMU:OUTPUT:STATE {ch1}, 1")
my4200.query(f":PMU:OUTPUT:STATE {ch2}, 1")

#Execute the test
my4200.query(":PMU:EXECUTE")

#This is a loop to check the status of the test
#The :PMU:TEST:STATUS? command returns 1 if it is still running and 0 if it is idle
while True:
    status = my4200.query(":PMU:TEST:STATUS?")
    
    #Continues loop until the test is complete
    #Casting the status string to int makes the comparison simpler since it ignores the termination characters
    if int(status) == 0:
        print("Measurement Complete.")
        break
    
    #Continously prints the status of the test every second to the terminal
    print(f"Status: {status}")
    time.sleep(1)

#Optional commands from this point to graph using the plotly tool and pandas to handle the data
#Ask for the number of data points and return that as a variable
print(f"Data count for channel {ch1}:", my4200.query(f":PMU:DATA:COUNT? {ch1}"))
print(f"Data count for channel {ch2}:", my4200.query(f":PMU:DATA:COUNT? {ch2}"))
# Get all of the data back as a string
datachan1 = my4200.query(f":PMU:DATA:GET {ch1}")
print(f"Response from 4200A channel {ch1}:", datachan1)  # Print the response to the console
datachan2 = my4200.query(f":PMU:DATA:GET {ch2}")
print(f"Response from 4200A channel {ch2}:", datachan2)  # Print the response to the console

#Set the output state of channels 1 and 2 to off - always turn off the output at the end of a test
my4200.query(f":PMU:OUTPUT:STATE {ch1}, 0")
my4200.query(f":PMU:OUTPUT:STATE {ch2}, 0")

# Split the response using semicolon as the delimiter for each point
coordschan1 = datachan1.split(";")
coordschan2 = datachan2.split(";")
#Spilt into 8 seperate values for each point
coords2dchan1 = [value.split(",") for value in coordschan1]
coords2dchan2 = [value.split(",") for value in coordschan2]


#PLOTLY COMMANDS
# Create a DataFrame to split up each type of data
dfchan1 = pd.DataFrame(coords2dchan1, columns=['Voltage 1', 'Current 1', 'Timestamp 1', 'Status 1'])
dfchan2 = pd.DataFrame(coords2dchan2, columns=['Voltage 2', 'Current 2', 'Timestamp 2', 'Status 2'])

# Concatenate DataFrames for all channels
dfallchan = pd.concat([dfchan1, dfchan2], axis=1)

# Save DataFrame to a CSV file
dfallchan.to_csv('data_table.csv', index=False)
print("CSV file saved successfully.") #Verify the data was saved

# Convert columns to appropriate types
dfallchan = dfallchan.astype({'Voltage 1': float, 'Current 1': float, 'Timestamp 1': str, 'Status 1': str,
                          'Voltage 2': float, 'Current 2': float, 'Timestamp 2': str, 'Status 2': str})

# Create two scatter plots
fig = make_subplots(rows=1, cols=2, subplot_titles=['Vgs-Id from Staircase Pulse - Plot 1', 'Measurements vs Time Segment Arb Staricase - Plot 2'])

# Scatter plot 1 with line
scatter1 = px.scatter(dfallchan, x='Voltage 1', y='Current 2',
                      labels={'Voltage 1': 'Gate Voltage (V)', 'Current 2': 'Drain Current (A)'},
                      hover_data=["Voltage 1", "Current 2"])
line_trace1 = go.Scatter(x=dfallchan['Voltage 1'], y=dfallchan['Current 2'], mode='lines', name='Voltage vs Current',
                         line=dict(color='blue', width=2))  # Customize line color and width
scatter1.add_trace(line_trace1)

# Scatter plot 2 with line
scatter2 = px.scatter(dfallchan, x='Timestamp 1', y='Voltage 1',
                      labels={'Timestamp 1': 'Time Output (s)', 'Voltage 1': 'Gate Voltage (V)'},
                      hover_data=["Timestamp 1", "Voltage 1"])
line_trace2 = go.Scatter(x=dfallchan['Timestamp 1'], y=dfallchan['Voltage 1'], mode='lines', name='Time vs Voltage',
                         line=dict(color='red', width=2))  # Customize line color and width
scatter2_2 = px.scatter(dfallchan, x='Timestamp 1', y='Current 2',
                      labels={'Timestamp 1': 'Time Output (s)', 'Current 2': 'Drain Current (A)'},
                      hover_data=["Timestamp 1", "Current 2"])
line_trace2_2 = go.Scatter(x=dfallchan['Timestamp 1'], y=dfallchan['Current 2'], mode='lines', name='Time vs Current',
                         line=dict(color='blue', width=2))  # Customize line color and width
scatter2.add_trace(line_trace2)
scatter2.add_trace(line_trace2_2)

# Add 'Current 2' to the scatter plot associated with the second subplot
scatter2.add_scatter(x=dfallchan['Timestamp 1'], y=dfallchan['Current 2'], mode='lines', name='Current 2', yaxis='y2')

# Update marker color to red for Scatter Plot 2
scatter2.update_traces(marker=dict(color='red'))

# Add the scatter plots and line traces to the subplots
fig.add_trace(scatter1.data[0], row=1, col=1)
fig.add_trace(line_trace1, row=1, col=1)  # Add line trace to subplot 1
fig.add_trace(scatter2.data[0], row=1, col=2)
fig.add_trace(line_trace2, row=1, col=2)  # Add line trace to subplot 2
fig.add_trace(scatter2_2.data[0], row=1, col=2)
fig.add_trace(line_trace2_2, row=1, col=2)  # Add line trace to subplot 2

# Manually set axis labels for subplot 1
fig.update_xaxes(title_text='Gate Voltage (V)', row=1, col=1)
fig.update_yaxes(title_text='Drain Current (A)', row=1, col=1)
fig.update_xaxes(title_text='Time Output (s)', row=1, col=2)
fig.update_yaxes(title_text='Gate Voltage (V)', row=1, col=2)
fig.update_yaxes(title_text='Drain Current (A)', row=1, col=2)

# Show the plot
fig.show()

my4200.disconnect()  # close communications with the 4200A-SCS
