"""
***********************************************************
*** Copyright 2022 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Original by: forum.tek.com user Soren_Marodoren 
Revised by: Keithley Applications Engineering (Andrea Clary)

"""

import pyvisa as visa
import math
import time

rm = visa.ResourceManager()

# Define test constants
# SMU1 will be a voltage source to input of DC-DC converter
START_VOLT = 4.0 # The start voltage
STOP_VOLT = 4.6 # The stop voltage
STEP_VOLT = 0.2 # The voltage step size
VSRC_ILIMIT = 0.1  # max current from voltage source

# SMU2 will be a current load on output of DC-DC converter
START_CURR = -0.003 # The start current
STOP_CURR = -0.012 # The stop current
STEP_CURR = -0.003 # The current step size
ILOAD_VLIMIT = 10  # max output voltage of the DC-DC converter

SET_TIME = 1 # Time (in seconds) for the measurement to stabilize

def frange(start, stop=None, step=None):
# Use float number in range() function
# if stop and step argument is null set start=0.0 and step = 1.0
    if stop == None:
        stop = start + 0.0
        start = 0.0
    if step == None:
        step = 1.0
    while True:
        if step > 0 and start >= stop:
            break
        elif step < 0 and start <= stop:
            break
        yield ("%g" % start) # return float number
        start = start + step

try:
    # Initiate the output file
    print('*************** Test started ********************') # Printed on the screen
    filename = input('Enter file name for data to be stored in or skip to auto generate: ')
    if filename == '':
        time_now = int(time.time()) # Integer representing time in seconds since 1970-01-01
        filename = "Result_file_" + str(time_now) + ".csv" # Creates a filename that changes with time
    else:
        filename = filename + ".csv" # Creates a filename that has been entered
        f = open(filename, "w")
        f.write("Volt in, Curr out, SMU1 Curr, SMU2 Volt, Eff \n") # Header info to the file
        print('Volt in, Curr out, SMU1 Curr, SMU2 Volt, Eff') # Header info to the screen

except:
    print("whoops")

# Initiate Instruments
# SMU1 = voltage source for the input to DC-DC converter
# Initiate the SMU used as power source
SMU1 = rm.open_resource("TCPIP0::192.168.1.68::inst0::INSTR")     
SMU1.write_termination = '\n'
SMU1.write('*RST') # Reset instrument
SMU1.write("SOUR:FUNC VOLT") # Source voltage to the DUT
SMU1.write("SOUR:VOLT:RANG 20")
SMU1.write("SOUR:VOLT:ILIM " + str(VSRC_ILIMIT))
SMU1.write("SOUR:VOLT:LEVEL " + str(START_VOLT))
SMU1.write('SENS:FUNC "CURR"') # Measure current that the DUT drains
SMU1.write(":SENS:CURR:RANG " + str(VSRC_ILIMIT))  #put it on high range to avoid range compliance
SMU1.write(":SENS:CURR:RANG:AUTO:REB ON")  #use auto range rebound to avoid range compliance
SMU1.write(":SENS:CURR:RANG:AUTO ON")  #restore auto range
SMU1.write("OUTP ON")

# SMU2 = current source/load (negative values = sinking current) at output of DC-DC converter
# Initiate the SMU used as a load
SMU2 = rm.open_resource("TCPIP0::192.168.1.51::inst0::INSTR")
SMU2.write('*RST') # Reset instrument
SMU2.write("SOUR:FUNC CURR") # Source current from the DUT
SMU2.write("SOUR:CURR:VLIM " + str(ILOAD_VLIMIT)) # Limit the load voltage
SMU2.write('SENS:FUNC "VOLT"') # Measure the voltage that the DUT delivers
SMU2.write("SENS:VOLT:RANG:AUTO ON") # Set the range to be set automatically.
SMU2.write("SENS:VOLT:NPLC 1") # Measure during 1 power line cycles = 20 ms for 50Hz power
SMU2.write("SOUR:CURR " + str(START_CURR)) # Set an initial load current for test
SMU2.write("OUTP ON")

# Main loops for the program
for Source_Voltage in frange (START_VOLT, STOP_VOLT + STEP_VOLT, STEP_VOLT):
    SMU1.write("SOUR:VOLT:LEVEL " + str(Source_Voltage)) # Set the voltage to the DUT 

    for Load_Curr in frange (START_CURR, STOP_CURR + STEP_CURR, STEP_CURR):
        SMU2.write("SOUR:CURR " + str(Load_Curr)) # Set the load current from the DUT
        time.sleep(SET_TIME) # Wait for the measurement to get stable
        SMU1_Current = float(SMU1.query('MEAS:CURR?')) # Fetch the current level
        SMU2_Voltage = float(SMU2.query('MEAS:VOLT?')) # Fetch the voltage level
        Eff = (float(Load_Curr) * (-1) * SMU2_Voltage) / (SMU1_Current * float(Source_Voltage)) * 100

        # Store and print the result before the next loop
        f.write("%5.2f, %5.2f, %5.3f, %5.3f, %5.2f" %(float(Source_Voltage), float(Load_Curr)*1000, float(SMU1_Current)*1000, float(SMU2_Voltage), float(Eff)) + "\n")
        print("%5.2f, %5.2f, %5.3f, %5.3f, %5.2f" %(float(Source_Voltage), float(Load_Curr)*1000, float(SMU1_Current)*1000, float(SMU2_Voltage), float(Eff)))
        print("")

# Clean up if test complete or in case of failure
# finally:
SMU1.write('OUTP OFF') # Turn the output Off
SMU2.write('OUTP OFF') # Turn the output Off
SMU1.write('*RST') # Reset SMU1
SMU2.write('*RST') # Reset SMU2
print('Output data stored in: ', filename)
print('*************** Done ********************')
print('')