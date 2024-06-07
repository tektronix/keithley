'''
NOTE: THIS EXAMPLE PROGRAM REQUIRES CLARIUS VERSION 1.13 OR LATER!

This example is a KXCI recreation of the pulse-vds-id Clarius test.
It creates a pulse amplitude step on channel 1 from 2 to 4 V in 0.5 V steps,
and a pulse amplitude sweep on channel 2 from 0 to 5 V in 0.2 V steps.
This is send from a 4225-PMU with the 4225-RPMs.
Two channels are used.
Device used: 4 terminal nMosfet in 8101-PIV fixture
'''

from instrcomms import Communications 
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
#Configure the RPM input for channel 2 of pulse card 1 to the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU1-2, 0")

#Set the measure mode to 1, Spot Mean discrete
my4200.query(":PMU:MEASURE:MODE 1")
#Configure LLEC for channel 1 and 2 of the pulse card
my4200.query(":PMU:LLEC:CONFIGURE 2, 1")

#Configure for a pulse amplitude step for channel 1 of the PMU starting at 2 V,
#Stopping at 4 V, stepping in 0.5 V steps setting the base to 0 V and leaving dual sweep off
my4200.query(":PMU:STEP:PULSE:AMPLITUDE 1, 2, 4, 0.5, 0")
#Configure the current measure range to a fixed range of 10 mA
my4200.query(":PMU:MEASURE:RANGE 1, 2, 0.01")

#Configure for a pulse amplitude sweep for channel 1 of the PMU starting at 0 V,
#Stopping at 5 V, stepping in 0.2 V steps setting the base to 0 V and leaving dual sweep off
my4200.query(":PMU:SWEEP:PULSE:AMPLITUDE 2, 0, 5, 0.2, 0, 0")
#Configure timing for channel 1 of the PMU with a 1 us period,
#100 us width, 50 us rise and fall times, and 0 second delay
my4200.query(":PMU:PULSE:TIMES 2, 1e-6, 5e-7, 1e-7, 1e-7, 0")
#Configure the current measure range to a fixed range of 200 mA
my4200.query(":PMU:MEASURE:RANGE 2, 2, 0.2")

#Set the output state of channels 1 and 2 to on
my4200.query(":PMU:OUTPUT:STATE 1, 1")
my4200.query(":PMU:OUTPUT:STATE 2, 1")

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
#Ask for the number of data points from both channels
count_1 = my4200.query(":PMU:DATA:COUNT? 1")
print(f"Data count from Channel 1: {count_1}")
count_2 = my4200.query(":PMU:DATA:COUNT? 1")
print(f"Data count from Channel 1: {count_2}")
# Get all of the data back as a string
datachan1 = my4200.query(f":PMU:DATA:GET 1")
print("Response from 4200A Channel 1: ", datachan1)  # Print the response to the console
datachan2 = my4200.query(f":PMU:DATA:GET 2")
print("Response from 4200A Channel 2: ", datachan2)  # Print the response to the console

#Set the output state of channels 1 and 2 to off - always turn off the output at the end of a test
my4200.query(":PMU:OUTPUT:STATE 1, 0")
my4200.query(":PMU:OUTPUT:STATE 2, 0")

my4200.disconnect()