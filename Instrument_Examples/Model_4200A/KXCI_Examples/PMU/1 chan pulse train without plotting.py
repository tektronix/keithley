'''
NOTE: THIS EXAMPLE PROGRAM REQUIRES CLARIUS VERSION 1.13 OR LATER!

This example creates a 5V amplitude pulse train on channel 1 outputted from a 4225-PMU with the 4225-RPMs.
Returns the current, voltage, time, and status measurements on channel 1 using waveform capture mode.
Two channels are used, with channel 2 set to 0V, and the load set to 1M ohm.
Device used: 1Mohm oscilloscope impedance.
'''

from instrcomms import Communications
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
#Set channel 1 pulse timing to a period of 100 us, 50 us width, and 5 us rise and fall times.
my4200.query(":PMU:PULSE:TIMES 1, 100e-6, 50e-6, 5e-6, 5e-6")
#Set the pulse burst count to 1
my4200.query(":PMU:PULSE:BURST:COUNT 1")
#Set the output state of channel 1 to on
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

#Set the output state of channel 1 to off - always turn off the output at the end of a test
my4200.query(":PMU:OUTPUT:STATE 1, 0")

my4200.disconnect() # close communications with the 4200A-SCS