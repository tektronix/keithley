'''
NOTE: THIS EXAMPLE PROGRAM REQUIRES CLARIUS VERSION 1.13 OR LATER!

This is a segarb test that outputs a 1 V sequence with configured rise and fall times on channel 1.
This is sent from a 4225-PMU with 4225-RPMs.
Only one channel is used.
Device used: N/A
'''

from instrcomms import Communications
import time

INST_RESOURCE_STR = "TCPIP0::192.0.2.0:1225::SOCKET" # instrument resource string, obtained from NI MAX

my4200 = Communications(INST_RESOURCE_STR) # opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" #Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" #Set PyVISA read terminator

#Initalize to segARB mode
my4200.query(":PMU:INIT 1")
#Configure the RPM input for channel 1 of pulse card 1 to the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU1-1, 0")
#Set the measure range of channel 1 to a fixed 200 mA range
my4200.query(":PMU:MEASURE:RANGE 1, 2, 0.2")
#Configure an array of starting voltages for sequence 1 of channel 1 of the pulse card
my4200.query(":PMU:SARB:SEQ:STARTV 1, 1, 0, 1, 1, 1.5, 1.5, 0, 0")
#Configure an array of stopping voltages for sequence 1 of channel 1 of the pulse card
my4200.query(":PMU:SARB:SEQ:STOPV 1, 1, 1, 1, 1.5, 1.5, 0, 0, 0")
#Configure an array of timing values for sequence 1 of channel 1 of the pulse card
my4200.query(":PMU:SARB:SEQ:TIME 1, 1, 50e-9, 100e-9, 20e-9, 150e-9, 50e-9, 500e-9, 130e-9")
#Configure an array of measure types for sequence 1 of channel 1 of the pulse card
my4200.query(":PMU:SARB:SEQ:MEAS:TYPE 1, 1, 0, 1, 0, 1, 0, 0, 0")
#Configure an array of measure starting values for sequence 1 of channel 1 of the pulse card
my4200.query(":PMU:SARB:SEQ:MEAS:START 1, 1, 0, 25e-9, 0, 50e-9, 0, 0, 0")
#Configure an array of measure stopping values for sequence 1 of channel 1 of the pulse card
my4200.query(":PMU:SARB:SEQ:MEAS:STOP 1, 1, 0, 75e-9, 0, 100e-9, 0, 0, 0")
#Define the sequence list for channel 1 of the pulse card, executing seq1 one time
my4200.query(":PMU:SARB:WFM:SEQ:LIST 1, 1, 1")
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
print(my4200.query(":PMU:DATA:COUNT? 1"))        
# Get all of the data as a string, using a variable number of data points
response = my4200.query(":PMU:DATA:GET 1")
print("Response from 4200A: ", response)  # Print the response to the console

#Set the output state of channel 1 to off - always turn off the output at the end of a test
my4200.query(":PMU:OUTPUT:STATE 1, 0")

my4200.disconnect()  # close communications with the 4200A-SCS