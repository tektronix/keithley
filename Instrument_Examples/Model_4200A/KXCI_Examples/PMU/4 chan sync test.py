'''
NOTE: THIS EXAMPLE PROGRAM REQUIRES CLARIUS VERSION 1.13 OR LATER!

This example synchronizes the pulse output of 4 PMU channels.
It utilizes pulse train commands to generate
1V, 2V, 3V, and 4V on channels 1 through 4 respectively from a 4225-PMU with the 4225-RPMS.
Four channels are used.
Device used: 1Mohm scope impedance on all 4 channels
'''

from instrcomms import Communications
#Extra commands for plotting
import plotly.express as px
import pandas as pd
import time
import plotly.graph_objects as go

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # instrument resource string, obtained from NI MAX
my4200 = Communications(INST_RESOURCE_STR) # opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" #Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" #Set PyVISA read terminator

ch1 = 1
ch2 = 2
ch3 = 3
ch4 = 4
all_channels = [ch1, ch2, ch3, ch4]
seq_num = 1

#Reset and initilize, seting the mode to pulse mode
my4200.query(":PMU:INIT 0")

#Configure the RPM to channel 1 of the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU1-1, 0")
#Configure the RPM to channel 2 of the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU1-2, 0")
#Configure the RPM to channel 3 of the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU2-1, 0")
#Configure the RPM to channel 4 of the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU2-2, 0")

#Set the measure mode to waveform capture discrete
my4200.query(":PMU:MEASURE:MODE 2")

#Set channel 1 of the pulse card for a pulse train with a 0V base and 1V amplitude
my4200.query(f":PMU:PULSE:TRAIN {ch1}, 0.0, 1.0")
#Set channel 2 of the pulse card for a pulse train with a 0V base and 2V amplitude
my4200.query(f":PMU:PULSE:TRAIN {ch2}, 0.0, 2.0")
#Set channel 3 of the pulse card for a pulse train with a 0V base and 3V amplitude
my4200.query(f":PMU:PULSE:TRAIN {ch3}, 0.0, 3.0")
#Set channel 4 of the pulse card for a pulse train with a 0V base and 4V amplitude
my4200.query(f":PMU:PULSE:TRAIN {ch4}, 0.0, 4.0")

#Set channel 1 pulse timing to a period of 1 ms, 500 us width, and 5 us rise and fall times.
my4200.query(f":PMU:PULSE:TIMES {ch1}, 10e-6, 5e-6, 500e-9, 500e-9")
#Set channel 2 pulse timing to a period of 1 ms, 500 us width, and 5 us rise and fall times.
my4200.query(f":PMU:PULSE:TIMES {ch2}, 10e-6, 5e-6, 500e-9, 500e-9")
#Set channel 3 pulse timing to a period of 1 ms, 500 us width, and 5 us rise and fall times.
my4200.query(f":PMU:PULSE:TIMES {ch3}, 10e-6, 5e-6, 500e-9, 500e-9")
#Set channel 4 pulse timing to a period of 1 ms, 500 us width, and 5 us rise and fall times.
my4200.query(f":PMU:PULSE:TIMES {ch4}, 10e-6, 5e-6, 500e-9, 500e-9")

#Set the pulse burst count to 1
my4200.query(":PMU:PULSE:BURST:COUNT 1")

#Set the output state of channel 1, 2, 3, and 4 to on
for channel in all_channels:
    my4200.query(f":PMU:OUTPUT:STATE {channel}, 1")

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
count_1 = my4200.query(f":PMU:DATA:COUNT? {ch1}")
print(f"Data count from Channel {ch1}: {count_1}")
count_2 = my4200.query(f":PMU:DATA:COUNT? {ch2}")
print(f"Data count from Channel {ch2}: {count_2}")
count_3 = my4200.query(f":PMU:DATA:COUNT? {ch3}")
print(f"Data count from Channel {ch3}: {count_3}")
count_4 = my4200.query(f":PMU:DATA:COUNT? {ch4}")
print(f"Data count from Channel {ch4}: {count_4}")

# Get all of the data back as a string
datachan1 = my4200.query(f":PMU:DATA:GET {ch1}")
print(f"Response from 4200A for Channel {ch1}: {datachan1}")  # Print the response to the console
datachan2 = my4200.query(f":PMU:DATA:GET {ch2}")
print(f"Response from 4200A for Channel {ch2}: {datachan2}")  # Print the response to the console
datachan3 = my4200.query(f":PMU:DATA:GET {ch3}")
print(f"Response from 4200A for Channel {ch3}: {datachan3}")  # Print the response to the console
datachan4 = my4200.query(f":PMU:DATA:GET {ch4}")
print(f"Response from 4200A for Channel {ch4}: {datachan4}")  # Print the response to the console

#Set the output state of channel 1, 2, 3, and 4 to off - always turn off the output at the end of a test
for channel in all_channels:
    my4200.query(f":PMU:OUTPUT:STATE {channel}, 0")

# Initialize an empty DataFrame to store all data points
df_all_channels = pd.DataFrame()

# Loop through each channel
for channel in all_channels:
    # Get the total number of data points for the current channel
    data_points_str = my4200.query(f":PMU:DATA:COUNT? {channel}")
    data_points = int(data_points_str)

    # Initialize an empty DataFrame to store data for the current channel
    df_channel = pd.DataFrame()

    # Loop through the data points in chunks
    for start_point in range(0, data_points, 2048):
        # Get data for the current chunk and channel
        response = my4200.query(f":PMU:DATA:GET {channel}, {start_point}, 2048")

        # Split the response using semicolon as the delimiter for each point
        coords = response.split(";")

        # Split into 4 separate values for each point
        coords2d = [value.split(",") for value in coords]

        # Create a DataFrame for the current chunk
        df_chunk = pd.DataFrame(coords2d, columns=[f'Voltage {channel}', f'Current {channel}', f'Timestamp {channel}', f'Status {channel}'])

        # Convert columns to appropriate types
        df_chunk = df_chunk.astype({f'Voltage {channel}': float, f'Current {channel}': float})

        # Concatenate the current chunk to the overall DataFrame for the current channel
        df_channel = pd.concat([df_channel, df_chunk])

    # Concatenate the data for the current channel to the overall DataFrame
    df_all_channels = pd.concat([df_all_channels, df_channel], axis=1)

# Save DataFrame to a CSV file
df_all_channels.to_csv('data_table.csv', index=False)
print("CSV file saved successfully.")

# Scatter plot with lines
scatter = px.scatter(df_all_channels, x='Timestamp 1', y='Voltage 1',
                     labels={'Timestamp 1': 'Time Output (s)', 'Voltage 1': 'Gate Voltage (V)'},
                     hover_data=["Timestamp 1", "Voltage 1"],
                      color_discrete_sequence=['red'])

# Add lines for each channel
colors = {ch1: 'red', ch2: 'blue', ch3: 'green', ch4: 'orange'}
for channel in all_channels:
    line_trace = go.Scatter(x=df_all_channels[f'Timestamp {channel}'], y=df_all_channels[f'Voltage {channel}'],
                            mode='lines', name=f'Channel {channel}', line=dict(color=colors[channel], width=2))
    scatter.add_trace(line_trace)

# Update layout
scatter.update_layout(title='Voltage vs. Time for all Channels: Pulse Train',
                  xaxis_title='Time Output (s)',
                  yaxis_title='Voltage (V)')

# Set a linear x-axis
scatter.update_xaxes(type='linear')

# Show plot
scatter.show()

my4200.disconnect() # close communications with the 4200A-SCS