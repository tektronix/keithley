""" ================================================================================
*** Copyright 2023 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
================================================================================ """

"""
====================================================================================================
    This example code tests the insulation resistance between the bridgewires and the housing. The 
    voltage source value is tested prior to the resistances. Selecting S1I ohms function 
    automatically sets the measurement function to DC Volts and measure range to 1 V.
    
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

#dmm2790.write("ROUT:OPEN:ALL")  # USE TO ENSURE DEVICE COMPLETELY DISCONNECTED

# ==============================================================
# SETTINGS FOR TEST
# ==============================================================
minVoltage = 490  # Minimum voltage for source otherwise fail
minResistance = 90000000  # Minimum resistance for insulation, otherwise fail (Demo expecting ~100 Mohms)
soakTime = 2  # Soak time in seconds from when initialized to measure
nplc = 1  # Reading NPLC

# Set up V source and measurement
dmm2790.write("ROUT:MULT:CLOS (@103,106)")  # Connect internal shunts across DUT
dmm2790.write("SOUR:VOLT 500,(@128)")  # Set voltage source level to 500 V
time.sleep(0.25)  # Settling time for voltage source
dmm2790.write("CALC1:STAT OFF")  # Disable math functions
dmm2790.write("SENS:FUNC 'VOLT'")  # Set DMM to DC Voltage
dmm2790.write("SENS:VOLT:RANG 1000")  # Voltage range of 1000 V
dmm2790.write(f"SENS:VOLT:NPLC {nplc}")  # 1 NPLC

# Verify V-Source
dmm2790.write("ROUT:MULT:CLOS (@122,113,118,123,121)")  # Select the V source and connect DMM across it. V source Lo connected through I-V converter
time.sleep(0.05)  # Settling time for step change in load
reading = float(dmm2790.query("READ?"))  # Take the reading
print(f"V Source: {reading}")

if(reading < minVoltage):  # Source Voltage too low
    print("V-SOURCE VERIFY FAILED!!!")
    dmm2790.write("ROUT:MULT:OPEN (@121,122,113)")  # Deselect V-source, discharge module, disconnect V-source from DMM
    dmm2790.disconnect()
    print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
    quit()

# Test insulation resistance A
dmm2790.write("ROUT:MULT:OPEN (@121,122,113)")  # Deselect V-source, discharge module, disconnect V-source from DMM
dmm2790.write("CALC1:FORM S1V")  # Use high ohwm (source V meas I) math function to calculate resistance
dmm2790.write("CALC1:STAT ON")  # Enable math
dmm2790.write(f"TRIG:DEL {soakTime}")  # Set soak time from when initialized to measure
dmm2790.write("ROUT:MULT:CLOS (@101,108,116,122,121)")  # Connect bridgewire A HI to V source and housing LO to I-V converter, converter output to DMM
dmm2790.write("READ?")  # Send the command to start the reading
time.sleep(soakTime)  # Wait for the soak time
reading = float(dmm2790.read())  # Request the reading
print(f"Insulation Resistance A: {reading}")

if(reading < minResistance):  # Insulation resistance too low
    print("INSULATION RESITANCE A FAILED!!!")
    dmm2790.write("ROUT:MULT:OPEN (@121,122,101,108,116,118)")  # Discharge module, disconnect V-source, bridgewire A HI, I-V Converter and DMM
    dmm2790.disconnect()
    print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
    quit()

# Test insulation resistance B
dmm2790.write("ROUT:MULT:OPEN (@121,122,101)")  # Discharge module and cables, disconnect V-source and Bridgewire A
dmm2790.write("ROUT:MULT:CLOS (@104,122,121)")  # Select V-Source, connect source to bridgewire B HI
dmm2790.write("READ?")  # Send the command to start the reading
time.sleep(soakTime)  # Wait for the soak time
reading = float(dmm2790.read())  # Request the reading
print(f"Insulation Resistance B: {reading}")

if(reading < minResistance):  # Insulation resistance too low
    print("INSULATION RESISTANCE B FAILED!!!")
    dmm2790.write("ROUT:MULT:OPEN (@121,122,104,108,116,118)")  # Discharge module, disconnect V-source, bridgewire B HI, I-V Converter and DMM
    dmm2790.disconnect()
    print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
    quit()

dmm2790.write("ROUT:MULT:OPEN (@121,122,104,108,116,118)")  # Discharge module, disconnect V-source, bridgewire B HI, I-V Converter and DMM

# Internal shunts are still connected
#dmm2790.write("ROUT:OPEN:ALL")  # USE THIS TO DISCONNECT AT END

print("TEST PASSED")

dmm2790.disconnect()  # Close test

print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
