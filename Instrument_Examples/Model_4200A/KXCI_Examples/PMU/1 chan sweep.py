'''
NOTE: THIS EXAMPLE PROGRAM REQUIRES CLARIUS VERSION 1.13 OR LATER!

This code runs a sweep on RPM 1-1 (PMU 1, channel 1), starting from 0 to 5 V in 0.1 V steps, and performs a measurement in spot mean (pulse IV) mode.
This pulse is done 10 times, averaging out the data to 1 sweep.
Channel 2 is set to a 0V pulse train with no RPM configured.
Device used: 1 Kohm resistor
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

#Initalize to standard pulse mode
my4200.query(":PMU:INIT 0")
#Configure the RPM input for channel 1 of pulse card 1 to the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU1-1, 0")
#Turn off short connection comp
my4200.query(":PMU:CONNECTION:COMP 1, 1, 0")
#Configure for a 1k ohm load
my4200.query(":PMU:LOAD 1, 1e3")
#Turn on pulse averaging in spot mean mode
my4200.query(":PMU:MEASURE:MODE 3")
#Turn on load line compensation
my4200.query(":PMU:LLEC:CONFIGURE 1, 1")
#Configure for a pulse amplitude sweep for channel 1 of the PMU starting at 0 V,
#Stopping at 5 V, stepping in 0.1 V steps setting the base to 0 V and leaving dual sweep off
my4200.query(":PMU:SWEEP:PULSE:AMPLITUDE 1, 0, 5, 0.1, 0, 0")
#Configure timing for channel 1 of the PMU with a 10 us period,
#500 ns width, 20 ns rise and fall times, and 0 second delay
my4200.query(":PMU:PULSE:TIMES 1, 1e-5, 500e-9, 2e-8, 2e-8, 0")
#Set the voltage for channel 2 of the PMU for a pulse train for a 0V amplitude
my4200.query(":PMU:PULSE:TRAIN 2, 0, 0")
#Configure the measuring range for channel 1 of the PMU for a fixed 10 mA current range
my4200.query(":PMU:MEASURE:RANGE 1, 2, 0.01")
#Set the average burst count to 10
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

#Optional commands from this point to graph using the plotly tool and pandas to handle the data
#Ask for the number of data points and return that as a variable
data_points = my4200.query(":PMU:DATA:COUNT? 1")
print(f"Total data points for channel 1: {data_points}")
# Get all of the data as a string
response = my4200.query(":PMU:DATA:GET 1")
print("Response from 4200A: ", response)  # Print the response to the console

#Set the output state of channel 1 to off - always turn off the output at the end of a test
my4200.query(":PMU:OUTPUT:STATE 1, 0")

# Split the response using semicolon as the delimiter for each point
coords = response.split(";")
#Spilt into 8 seperate values for each point
coords2d = [value.split(",") for value in coords]

#PLOTLY COMMANDS
# Create a DataFrame to spilt up each type of data
df = pd.DataFrame(coords2d, columns=['Voltage High', 'Current High', 'Timestamp High', 'Status High',
                                      'Voltage Low', 'Current Low', 'Timestamp Low', 'Status Low'])

# Convert columns to appropriate types, floating point for the voltage and current and a string for the timestamp and status
df = df.astype({'Voltage High': float, 'Current High': float, 'Timestamp High': str, 'Status High': str,
                'Voltage Low': float, 'Current Low': float, 'Timestamp Low': str, 'Status Low': str})

# Save DataFrame to a CSV file
df.to_csv('data_table.csv', index=False)
print("CSV file saved successfully.") #Verify the data was saved

# Scatter plot with Voltage High and Current High on the plot, and all data in hover
fig = px.scatter(df, x='Voltage High', y='Current High',
                 title='Voltage High vs Current High Pulse IV Test',
                 labels={'Voltage High': 'Voltage High (V)', 'Current High': 'Current High (A)'},
                 hover_data=df.columns)

# Add a line trace
fig.add_trace(px.line(df, x='Voltage High', y='Current High').data[0])

# Show the plot
fig.show()

my4200.disconnect()  # close communications with the 4200A-SCS
