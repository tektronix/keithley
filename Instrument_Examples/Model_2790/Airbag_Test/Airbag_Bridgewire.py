""" ================================================================================
*** Copyright 2023 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
================================================================================ """

"""
====================================================================================================
	This example code verifies the current source then measures the resistance of each bridgewire.
    
    See Application Note "Testing Dual Airbag Inflators and Modules with the Model 2790 SourceMeter 
    Switch System" for more information. 

    NOTE: The internal shunts remain connected at the end of this code. Use ROUT:MULT:OPEN ALL to 
    open all channels.
====================================================================================================
"""

from instrcomms import Communications
import time

start_time = time.time()  # Start a timer

# Connect to the Keithley 2790 Airbag and Electrical Device Test System
dmm2790 = Communications("GPIB0::26::INSTR")
dmm2790.connect()

dmm2790.write("*RST")  # Reset the unit to defaults
print(dmm2790.query("*IDN?"))  # Identify the unit
dmm2790.write("FORM:ELEM READ")  # Return only the reading

# ==============================================================
# SETTINGS
# ==============================================================
sourceI = 0.05
minVoltage = 0.04  # Current source checked over 1 ohm resistor so measured voltage = sourced current
maxResistance = 2  # pass/fail value for bridgewire resistance, demo assumes bridgewires are 1 ohm
nplc = 1

# Set up current source and measurement
dmm2790.write("ROUT:MULT:CLOS (@103,106)")  # Connect internal shunts across bridgewires
dmm2790.write("ROUT:MULT:OPEN (@122)")  # Select I-Source, default setting
dmm2790.write(f"SOUR:CURR {sourceI}, (@127)")  # Set current source to 50 mA
dmm2790.write("CALC1:STAT OFF")  # Disable any math functions
dmm2790.write("SENS:FUNC 'VOLT'")  # Set DMM to DCV Function
dmm2790.write("SENS:VOLT:RANG 0.1")  # Set voltage range to 100 mV
dmm2790.write(f"SENS:VOLT:NPLC {nplc}")  # Set NPLC to 1

# Verify current source
dmm2790.write("ROUT:MULT:CLOS (@101,102,118,125,121)")  # Connect bridgewire A to I-source, I-source sense resistor (1 ohm) to DMM
dmm2790.write("ROUT:MULT:OPEN (@103)")  # Open internal shunt to bridgewire A
reading = float(dmm2790.query("READ?"))  # Take a reading to verify I-source (should be voltage value = to sourceI)
dmm2790.write("ROUT:MULT:CLOS (@103)")  # Connect internal short to bridgewire A
print(f"Voltage on bridgewire A: {reading}")

if reading < minVoltage:  # I-source too low
    print("CURRENT SOURCE TEST FAILED!!!")
    dmm2790.write("ROUT:MULT:OPEN (@121,101,102,118,125)")  # Disconnect bridgewire, I-source, sense resistor and DMM
    dmm2790.disconnect()
    print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
    quit()

# Test bridgewire A
dmm2790.write("ROUT:MULT:OPEN (@125)")  # Disconnect I-Source sense resistor from DMM
dmm2790.write("CALC1:FORM S1I")  # Use low ohms (source I, meas V) math function to calculate resistance
dmm2790.write("CALC:STAT ON")  # Enable math function
dmm2790.write("ROUT:MULT:CLOS (@117)")  # Connect bridgewire A to DMM
dmm2790.write("ROUT:MULT:OPEN (@103)")  # Open internal shunt to bridgewire A
reading = float(dmm2790.query("READ?"))  # Take a reading
dmm2790.write("ROUT:MULT:CLOS (@103)")  # Connect internal short to bridgewire A
print(f"Resistance of bridgewire A: {reading}")

if reading > maxResistance:  # Bridgewire A resistance too high
    print("TEST A FAILED!!!")
    dmm2790.write("ROUT:MULT:OPEN (@121,101,102,117,118)")  # Disconnect current source, bridgewire A and DMM
    dmm2790.disconnect()
    print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
    quit()

# Test bridgewire B
dmm2790.write("ROUT:MULT:OPEN (@101,102)")  # Disconnect bridgewire A
dmm2790.write("ROUT:MULT:CLOS (@104,105)")  # Connect bridgewire B to DMM
dmm2790.write("ROUT:MULT:OPEN (@106)")  # Open internal shunt to bridgewire B
reading = float(dmm2790.query("READ?"))  # Take a reading
dmm2790.write("ROUT:MULT:CLOS (@106)")  # Connect internal short to bridgewire B
print(f"Resistance of bridgewire B: {reading}")

if reading > maxResistance:  # Bridgewire B resistance too high
    print("TEST B FAILED!!!")
    dmm2790.write("ROUT:MULT:OPEN (@121,104,105,117,118)")  # Disconnect I-Source and and bridgewire B from DMM
    dmm2790.disconnect()
    print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
    quit()

dmm2790.write("ROUT:MULT:OPEN (@121,104,105,117,118)")  # Disconnect I-Source and and bridgewire B from DMM

# Internal shunts are still connected
#dmm2790.write("ROUT:OPEN:ALL")  # USE THIS TO DISCONNECT AT END

print("TEST PASSED")

dmm2790.disconnect()  # Close test

print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")