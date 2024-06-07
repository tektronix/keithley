'''
NOTE: THIS EXAMPLE PROGRAM REQUIRES CLARIUS VERSION 1.13 OR LATER!

This example creates a 5V amplitude pulse train on channel 1 outputted from a 4225-PMU with the 4225-RPMs.
Returns the current, voltage, time, and status measurements on channel 1 using waveform capture mode.
Two channels are used, with channel 2 set to 0V, and the load set to 1M ohm.
Device used: 1Mohm oscilloscope impedance.
'''

from instrcomms import Communications
#Extra commands for plotting
import plotly.express as px
import pandas as pd
import time

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # instrument resource string, obtained from NI MAX

my4200 = Communications(INST_RESOURCE_STR) # opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" #Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" #Set PyVISA read terminator

#Initialize PMU and set to stnadard pulse mode
my4200.query(":PMU:INIT 0")
#Configure the RPM to channel 1 of the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU1-1, 0")
#Configure channel 1 for a fixed 10 uA current range
my4200.query(":PMU:MEASURE:RANGE 1, 2, 10e-6")
#Set channel 1 of the pulse card for a pulse train with a 0V base and 5V amplitude
my4200.query(":PMU:PULSE:TRAIN 1, 0.0, 5.0") 
#Set the voltage for channel 2 of the PMU for a pulse train for a 0V amplitude
my4200.query(":PMU:PULSE:TRAIN 2, 0, 0")
#Set the measure mode 2, waveform capture discrete
my4200.query(":PMU:MEASURE:MODE 2")
#Set channel 1 pulse timing to a period of 100 us, 50 us width, and 5 us rise and fall times. Delay optional and excluded here.
my4200.query(":PMU:PULSE:TIMES 1, 100e-6, 50e-6, 5e-6, 5e-6")
#Set the pulse burst count to 1
my4200.query(":PMU:PULSE:BURST:COUNT 1")
#Set the output state of channel 1 to on
my4200.query(":PMU:OUTPUT:STATE 1, 1")
#Execute your previous commands
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

# Get the total number of data points
data_points_str = my4200.query(":PMU:DATA:COUNT? 1")
data_points = int(data_points_str)
print(f"Total data points for channel 1: {data_points}")

# Initialize an empty DataFrame to store all data points
df_all_channels = pd.DataFrame(columns=['Voltage', 'Current', 'Timestamp', 'Status'])

# Loop through the data points in chunks
for start_point in range(0, data_points, 2048):
    # Get data for the current chunk
    response = my4200.query(f":PMU:DATA:GET 1, {start_point}, 2048")

    # Split the response using semicolon as the delimiter for each point
    coords = response.split(";")

    # Split into 4 separate values for each point
    coords2d = [value.split(",") for value in coords]

    # Create a DataFrame for the current chunk
    df_chunk = pd.DataFrame(coords2d, columns=['Voltage', 'Current', 'Timestamp', 'Status'])

    # Concatenate the current chunk to the overall DataFrame
    df_all_channels = pd.concat([df_all_channels, df_chunk])

#Set the output state of channel 1 to off - always turn off the output at the end of a test
my4200.query(":PMU:OUTPUT:STATE 1, 0")

# Reset the index of the final DataFrame
df_all_channels.reset_index(drop=True, inplace=True)

# Print the combined DataFrame
print("Combined DataFrame: ", df_all_channels)

# Convert columns to appropriate types, floating point for the voltage and current, and a string for the timestamp and status
df_all_channels = df_all_channels.astype({'Voltage': float, 'Current': float, 'Timestamp': float, 'Status': str})

# Save DataFrame to a CSV file
df_all_channels.to_csv('data_table.csv', index=False)
print("CSV file saved successfully.")  # Verify the data was saved

# Scatter plot 2 with y2 axis for "Current 1" and line
fig = px.scatter(df_all_channels, x='Timestamp', y='Voltage',
                      title='Pulse Train with Waveform Capture Data Return',
                      labels={'Timestamp': 'Time Output (s)', 'Voltage': 'Gate Voltage (V)'},
                      hover_data=["Timestamp", "Voltage"])
line = px.line(df_all_channels, x='Timestamp', y='Voltage').data[0]
fig.add_trace(line)

# Add the hover data to the plot
fig.add_trace(fig.data[0])
fig.show()

my4200.disconnect()  # close communications with the 4200A-SCS
