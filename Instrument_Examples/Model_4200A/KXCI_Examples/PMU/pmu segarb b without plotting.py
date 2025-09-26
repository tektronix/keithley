'''
NOTE: THIS EXAMPLE PROGRAM REQUIRES CLARIUS VERSION 1.13 OR LATER!

This example is a KXCI recreation of the Clarius pmu SegARB B test.
It utilizes two channels with a 82 segment waveform sequence from a 4225-PMU with the 4225-RPMs.
Device used: 1 Kohm resistor
'''

from instrcomms import Communications
import time

INST_RESOURCE_STR = "TCPIP0::134.63.74.151::1225::SOCKET" # instrument resource string, obtained from NI MAX

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

my4200.disconnect()  # close communications with the 4200A-SCS
