'''
NOTE: THIS EXAMPLE PROGRAM REQUIRES CLARIUS VERSION 1.13 OR LATER!

This example is a KXCI recreation of the Clarius pmu SegARB complete test.
It utilizes two channels with a 82 segment waveform sequence from a 4225-PMU with the 4225-RPMs.
Relies on plotly for creating side-by-side graphs.
Device used: 1 Kohm resistor
'''

from instrcomms import Communications
import time

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # instrument resource string, obtained from NI MAX

my4200 = Communications(INST_RESOURCE_STR) # opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" #Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" #Set PyVISA read terminator


#Initalize the PMU and set to segARB mode
my4200.query(":PMU:INIT 1")

ch1 = 1
ch2 = 2
seq1 = 1
seq2 = 2

#Configure the RPM input for channel 1 of pulse card 1 to the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU1-1, 0")
#Set channel 1 for a fixed 1 mA current range
my4200.query(f":PMU:MEASURE:RANGE {ch1}, 2, 1e-3")

#Configure an array of segment times for sequence 1 of channel 1
SEGTIME = (
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07'
)
my4200.query(f":PMU:SARB:SEQ:TIME {ch1}, {seq1}, {SEGTIME}")

#Configure an array of starting voltage values for sequence 1 of channel 1
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
my4200.query(f":PMU:SARB:SEQ:STARTV {ch1}, {seq1}, {STARTV_1}")

#Configure an array of stopping voltage values for sequence 1 of channel 1
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
my4200.query(f":PMU:SARB:SEQ:STOPV {ch1}, {seq1}, {STOPV_1}")

#Configure an array of measurement types for sequence 1 of channel 1
MEASTYPE = (
    '2, 0, 2, 0, 2, 0, 2, 0, 2, 0, '
    '2, 0, 2, 0, 2, 0, 2, 0, 2, 0, '
    '2, 0, 2, 0, 2, 0, 2, 0, 2, 0, '
    '2, 0, 2, 0, 2, 0, 2, 0, 2, 0, '
    '2, 0, 2, 0, 2, 0, 2, 0, 2, 0, '
    '2, 0, 2, 0, 2, 0, 2, 0, 2, 0, '
    '2, 0, 2, 0, 2, 0, 2, 0, 2, 0, '
    '2, 0, 2, 0, 2, 0, 2, 0, 2, 0, '
    '2, 0'
)
my4200.query(f":PMU:SARB:SEQ:MEAS:TYPE {ch1}, {seq1}, {MEASTYPE}")

#Configure an array of measurement starting values for sequence 1 of channel 1
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
my4200.query(f":PMU:SARB:SEQ:MEAS:START {ch1}, {seq1}, {MEASSTART}")

#Configure an array of measurement stopping values for channel 1
MEASSTOP = (
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, 1E-05, 2E-07, '
    '1E-05, 2E-07'
)
my4200.query(f":PMU:SARB:SEQ:MEAS:STOP {ch1}, {seq1}, {MEASSTOP}")

#Configure an array of segment times for sequence 2 of channel 1
my4200.query(f":PMU:SARB:SEQ:TIME {ch1}, {seq2}, 1e-5, 1e-6, 1e-5, 1e-6, 1e-6")
#Configure an array of starting voltage values for sequence 2 of channel 1
my4200.query(f":PMU:SARB:SEQ:STARTV {ch1}, {seq2}, 0, 0, 2.5, 2.5, 0")
#Configure an array of stopping voltage values for sequence 2 of channel 1
my4200.query(f":PMU:SARB:SEQ:STOPV {ch1}, {seq2}, 0, 2.5, 2.5, 0, 0")
#Configure an array of measurement types for sequence 2 of channel 1
my4200.query(f":PMU:SARB:SEQ:MEAS:TYPE {ch1}, {seq2}, 2, 0, 2, 0, 0")
#Configure an array of measurement starting values for sequence 2 of channel 1
my4200.query(f":PMU:SARB:SEQ:MEAS:START {ch1}, {seq2}, 0, 0, 0, 0, 0")
#Configure an array of measurement stopping values for sequence 2 of channel 1
my4200.query(f":PMU:SARB:SEQ:MEAS:STOP {ch1}, {seq2}, 1e-5, 1e-6, 1e-5, 1e-6, 1e-6")

#Configure the RPM input for channel 2 of pulse card 1 to the PMU
my4200.query(":PMU:RPM:CONFIGURE PMU1-2, 0")
#Set channel 2 for a fixed 1 mA current range
my4200.query(f":PMU:MEASURE:RANGE {ch2}, 2, 1e-3")

#Use the same segment time as sequence 1 of channel 1 for sequence 1 of channel 2
my4200.query(f":PMU:SARB:SEQ:TIME {ch2}, {seq1}, {SEGTIME}")
#Configure an array of starting voltage values for sequence 1 of channel 2
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
my4200.query(f":PMU:SARB:SEQ:STARTV {ch2}, {seq1}, {STARTV_2}")

#Configure an array of stopping voltage values for sequence 1 of channel 2
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
my4200.query(f":PMU:SARB:SEQ:STOPV {ch2}, {seq1}, {STOPV_2}")

#Use the same measurement types, starting, and stopping values
#as sequence 1 of channel 1 for sequence 1 of channel 2
my4200.query(f":PMU:SARB:SEQ:MEAS:TYPE {ch2}, {seq1}, {MEASTYPE}")
my4200.query(f":PMU:SARB:SEQ:MEAS:START {ch2}, {seq1}, {MEASSTART}")
my4200.query(f":PMU:SARB:SEQ:MEAS:STOP {ch2}, {seq1}, {MEASSTOP}")

#Configure an array of segment times for sequence 2 of channel 2
my4200.query(f":PMU:SARB:SEQ:TIME {ch2}, {seq2}, 1e-5, 1e-6, 1e-5, 1e-6, 1e-6")
#Configure an array of starting voltage values for sequence 2 of channel 2
my4200.query(f":PMU:SARB:SEQ:STARTV {ch2}, {seq2}, 0, 0, 0.1, 0.1, 0")
#Configure an array of stopping voltage values for sequence 2 of channel 2
my4200.query(f":PMU:SARB:SEQ:STOPV {ch2}, {seq2}, 0, 0.1, 0.1, 0, 0")
#Configure an array of measurement types for sequence 2 of channel 2
my4200.query(f":PMU:SARB:SEQ:MEAS:TYPE {ch2}, {seq2}, 2, 0, 2, 0, 0")
#Configure an array of starting measurement values for sequence 2 of channel 2
my4200.query(f":PMU:SARB:SEQ:MEAS:START {ch2}, {seq2}, 0, 0, 0, 0, 0")
#Configure an array of stopping measurement values for sequence 2 of channel 2
my4200.query(f":PMU:SARB:SEQ:MEAS:STOP {ch2}, {seq2}, 1e-5, 1e-6, 1e-5, 1e-6, 1e-6")

#Set the waveform sequence lists for channels 1 and 2
my4200.query(f":PMU:SARB:WFM:SEQ:LIST {ch1}, {seq1}, 1, {seq2}, 1, {seq1}, 1, {seq2}, 2, {seq1}, 1, {seq2}, 3")
my4200.query(f":PMU:SARB:WFM:SEQ:LIST {ch2}, {seq1}, 1, {seq2}, 1, {seq1}, 1, {seq2}, 2, {seq1}, 1, {seq2}, 3")

#Set the output state for channels 1 and 2 to on
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

# Get the total number of data points
data_points_str = my4200.query(":PMU:DATA:COUNT? 1")
data_points = int(data_points_str)

# Loop through the data points in chunks
for start_point in range(0, data_points, 2048):
    # Get data for the current chunk
    response = my4200.query(f":PMU:DATA:GET 1, {start_point}, 2048")

#Set the output state of channels 1 and 2 to off - always turn off the output at the end of a test
my4200.query(f":PMU:OUTPUT:STATE {ch1}, 0")
my4200.query(f":PMU:OUTPUT:STATE {ch2}, 0")

my4200.disconnect()  # close communications with the 4200A-SCS
