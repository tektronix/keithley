""" ================================================================================
*** Copyright 2023 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
================================================================================ """

"""
====================================================================================================
    This example code tests the shunt bars or shorting clips of the airbag. The first shunt is 
    tested without dry circuit and the second is tested with dry circuit. Also, selecting S1I ohms
    function automatically sets the measurement function to DC Volts and measure range to 1 V.
    
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

#dmm2790.write("ROUT:OPEN:ALL")  # USE TO ENSURE DEVICE COMPLETELY DISCONNECTED BEFORE BEGINNING

# ========================================================
# SETTINGS
# ========================================================
maxResisance = 1  # Pass/Fail Value, demo assumes shorting bars are < 1 ohm
resRange = 100  # Resistance measure range
NPLC = 1  # Measurement speed
nonDryCircuitSource = 0.05  # Current source without dry circuit
dryCircuitSource = 0.001  # Current source with dry circuit

# Configure Test
dmm2790.write("ROUT:MULT:CLOS (@103,106)")  # Connect internal shunts across DUT
dmm2790.write("ROUT:MULT:OPEN (@122)")  # Select I source, default setting
dmm2790.write(f"SOUR:CURR {nonDryCircuitSource} (@127)")  # Set current source level to 50 mA
dmm2790.write("CALC1:FORM S1I")  # Use low ohms (source I, meas V) math function to calculate resistance
dmm2790.write(f"SENS:VOLT:NPLC {NPLC}")  # NPLC Value
dmm2790.write("CALC1:STAT ON")  # Enable the math function

# Test shunt bar A - no dry circuit
dmm2790.write("ROUT:MULT:CLOS (@101,102,117,118,121)")  # Connect shunt bar A to current source and DMM
dmm2790.write("ROUT:MULT:OPEN (@103)")  # Disconnect internal shunt from shunt bar A
reading = float(dmm2790.query("READ?"))  # Take a reading
dmm2790.write("ROUT:MULT:CLOS (@103)")  # Connect internal short to shunt bar A
print(f"Shorting Bar A: {reading}")

if reading > maxResisance:  # Shorting bar A resistance too high
    print("SHORT BAR A FAILED!!!")
    dmm2790.write("ROUT:MULT:OPEN (@121,101,102,117,118)")  # Disconnect bridgewire, I-source and DMM
    dmm2790.disconnect()
    print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
    quit()

# Test shunt bar B - with dry circuit
dmm2790.write("ROUT:MULT:OPEN (@101,102)")  # Disconnect shunt bar A
dmm2790.write(f"SOUR:CURR {dryCircuitSource}, (@127)")  # Set current source for dry circuit
dmm2790.write("ROUT:MULT:CLOS (@104,105,124)")  # Connect shunt bar B to current source, enable dry circuit
dmm2790.write("ROUT:MULT:OPEN (@106)")  # Disconnect internal shunt from shunt bar A
reading = float(dmm2790.query("READ?"))  # Take a reading
dmm2790.write("ROUT:MULT:CLOS (@106)")  # Connect internal short to shunt bar A
print(f"Shorting Bar A: {reading}")

if reading > maxResisance:  # Shorting bar B resistance too high
    print("SHORT BAR B FAILED!!!")
    dmm2790.write("ROUT:MULT:OPEN (@121,104,105,117,118,124)")  # Disconnect bridgewire, I-source and DMM, disable dry circuit
    dmm2790.disconnect()
    print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
    quit()

dmm2790.write("ROUT:MULT:OPEN (@121,104,105,117,118,124)")  # Disconnect bridgewire, I-source and DMM, disable dry circuit

# Internal shunts are still connected
#dmm2790.write("ROUT:OPEN:ALL")  # USE THIS TO DISCONNECT AT END

print("TEST PASSED")

dmm2790.disconnect()  # Close test

print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
