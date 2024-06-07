'''
NOTE: THIS EXAMPLE PROGRAM REQUIRES CLARIUS VERSION 1.13 OR LATER!

This is a very simple segarb test.
It outputs a 1 V sequence with configured rise and fall times on channel 1.
This is sent from a 4225-PMU with 4225-RPMs.
Two channels are used, with channel 2 is set to 0 V.
Device used: 1 Mohm scope impedance
'''

from instrcomms import Communications
#Extra commands for plotting
import plotly.express as px
import pandas as pd
import time

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::SOCKET" # instrument resource string, obtained from NI MAX

my4200 = Communications(INST_RESOURCE_STR) # opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" #Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" #Set PyVISA read terminator

#Initalize the PMU, and set to segARB mode
my4200.query(":PMU:INIT 1")

#Configure the RPM input for channel 1 of pulse card 1 to the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU1-1, 0")
#Configure the RPM input for channel 2 of pulse card 1 to the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU1-2, 0")

#Set the measure range of channel 1 to a fixed range of 1 uA
my4200.query(":PMU:MEASURE:RANGE 1, 2, 1e-6")

#Configure an array of timing values for sequence 1 of channel 1 of the pulse card
my4200.query(":PMU:SARB:SEQ:TIME 1, 1, 1e-6, 1e-7, 1e-6, 1e-7, 1e-6")
#Configure an array of starting voltages for sequence 1 of channel 1 of the pulse card
my4200.query(":PMU:SARB:SEQ:STARTV 1, 1, 0, 0, 1, 1, 0")
#Configure an array of stopping voltages for sequence 1 of channel 1 of the pulse card
my4200.query(":PMU:SARB:SEQ:STOPV 1, 1, 0, 1, 1, 0, 0")
#Configure an array of measure type values for sequence 1 of channel 1 of the pulse card
my4200.query(":PMU:SARB:SEQ:MEAS:TYPE 1, 1, 2, 2, 2, 2, 2")
#Configure an array of measure starting values for sequence 1 of channel 1 of the pulse card
my4200.query(":PMU:SARB:SEQ:MEAS:START 1, 1, 0, 0, 0, 0, 0")
#Configure an array of measure stopping values for sequence 1 of channel 1 of the pulse card
my4200.query(":PMU:SARB:SEQ:MEAS:STOP 1, 1, 1e-6, 1e-7, 1e-6, 1e-7, 1e-6")
#Set the sequence list for channel 1
my4200.query(":PMU:SARB:WFM:SEQ:LIST 1, 1, 1")

#Set the output states for channel 1 to on
my4200.query(":PMU:OUTPUT:STATE 1, 1")

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

# Get the total number of data points
data_points_str = my4200.query(":PMU:DATA:COUNT? 1")
data_points = int(data_points_str)
print(data_points)

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

#Scatter plot 1 with line
fig = px.scatter(df_all_channels, x='Timestamp', y='Voltage',
                      labels={'Timestamp': 'Time Output (s)', 'Voltage': 'Voltage (V)'},
                      hover_data=["Timestamp", "Voltage"])
line = px.line(df_all_channels, x='Timestamp', y='Voltage').data[0]
fig.add_trace(line)
# Update layout
fig.update_layout(title='1 Channel SegARB Test',
                  xaxis_title='Time Output (s)',
                  yaxis_title='Voltage (V)')

fig.show()

my4200.disconnect()  # close communications with the 4200A-SCS