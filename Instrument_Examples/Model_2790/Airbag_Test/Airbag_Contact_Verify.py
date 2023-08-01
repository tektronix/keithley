""" ================================================================================
*** Copyright 2023 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
================================================================================ """

"""
====================================================================================================
    This example code checks the contacts to a dual inflator airbag connected to banks 1 and 2
    on a Keithley 2790. See Application Note "Testing Dual Airbag Inflators and Modules with the 
    Model 2790 SourceMeter Switch System" for more information. 

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

# =================================================================
# SETTINGS
# =================================================================
maxResisance = 10  # Pass/Fail Value, looking for contact resistance to be < x ohms
NPLC = 1  # Measurement speed

# Configure Test
dmm2790.write("ROUT:MULT:CLOS (@103,106)")  # Connect internal shunts across DUT
dmm2790.write("SENS:FUNC 'RES'")  # Set DMM to 2-wire ohms
dmm2790.write(f"SENS:RES:RANG 100")  # Resistance range = 100 ohms
dmm2790.write(f"SENS:RES:NPLC {NPLC}")  # NPLC Value
dmm2790.write("ROUT:MULT:CLOS (@101,114,118)")  # Connect bridgewire A HI leads to DMM
reading = float(dmm2790.query("READ?"))  # Take a reading
print(f"Contact Resistance A HI: {reading}")

if reading > maxResisance:  # Contact resistance too high
    print("CONTACT A HI FAILED!!!")
    dmm2790.write("ROUT:MULT:OPEN (@101,114,118)")  # Disconnect bridgewire A HI and DMM
    dmm2790.disconnect()
    print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
    quit()

# Test bridgewire B HI
dmm2790.write("ROUT:MULT:OPEN (@101)")  # Disconnect bridgewire A HI
dmm2790.write("ROUT:MULT:CLOS (@104)")  # Connect bridgewire B HI
reading = float(dmm2790.query("READ?"))  # Take a reading
print(f"Contact Resistance B HI: {reading}")

if reading > maxResisance:  # Contact resistance too high
    print("CONTACT B HI FAILED!!!")
    dmm2790.write("ROUT:MULT:OPEN (@104,114,118)")  # Disconnect bridgewire B HI and DMM
    dmm2790.disconnect()
    print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
    quit()

# Test bridgewire A LO
dmm2790.write("ROUT:MULT:OPEN (@104, 114)")  # Disconnect bridgewire B HI
dmm2790.write("ROUT:MULT:CLOS (@102, 115)")  # Connect bridgewire A LO
reading = float(dmm2790.query("READ?"))  # Take a reading
print(f"Contact Resistance A LO: {reading}")

if reading > maxResisance:  # Contact resistance too high
    print("CONTACT A LO FAILED!!!")
    dmm2790.write("ROUT:MULT:OPEN (@102,115,118)")  # Disconnect bridgewire A LO and DMM
    dmm2790.disconnect()
    print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
    quit()


# Test bridgewire B LO
dmm2790.write("ROUT:MULT:OPEN (@102)")  # Disconnect bridgewire A LO
dmm2790.write("ROUT:MULT:CLOS (@105)")  # Connect bridgewire B LO
reading = float(dmm2790.query("READ?"))  # Take a reading
print(f"Contact Resistance B LO: {reading}")

if reading > maxResisance:  # Contact resistance too high
    print("CONTACT B LO FAILED!!!")
    dmm2790.write("ROUT:MULT:OPEN (@105,115,118)")  # Disconnect bridgewire B LO and DMM
    dmm2790.disconnect()
    print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
    quit()

dmm2790.write("ROUT:MULT:OPEN (@108,115,118)")  # Disconnect Housing LO leads from DMM, internal shunts still connected

# Internal shunts are still connected
#dmm2790.write("ROUT:OPEN:ALL")  # USE THIS TO DISCONNECT AT ENDND

print("TEST PASSED")

dmm2790.disconnect()  # Close test

print(f"Elapsed Time: {(time.time()-start_time):0.3f}s")
