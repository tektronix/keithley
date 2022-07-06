""" ================================================================================

*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***

================================================================================ """

"""
====================================================================================================
	The example code given shows how take voltage and current readings & increase 
        the voltage through trials
====================================================================================================
"""

import pyvisa as visa
import time


echo_commands = 0

"""*********************************************************************************
    Function: instrument_connect(resource_mgr, instrument_resource_string, timeout,
                                 do_id_query, do_reset, do_clear) 
    Purpose: Open an instance of an instrument object for remote communication.
    Parameters:
        resource_mgr (object) - Instance of a resource manager object.
        instrument_object (object) - Instance of an instrument object to be initialized
                                     within this function. 

        instrument_resource_string (string) - The VISA resource string associated with
                                              a specific instrument defining its connection
                                              characteristics (communications type, model,
                                              serial number, etc.)
        timeout (int) - Time in milliseconds to wait before the communication transaction
                        with the target instrument is considered failed (timed out)
        do_id_query (int) - A flag that determines whether or not to query and print the 
                            instrument ID string. 
        do_reset (int) - A flag that determines whether or not to issue a reset command to
                         the instrument during this connection. 
        do_clear (int) - A flag that determines whether or not to issue a clear command to 
                         the instrument during this connection. 

    Returns:
        None

    Revisions:
        2019-08-07    JJB    Initial revision.
*********************************************************************************"""


def instrument_connect(resource_mgr, instrument_object, instrument_resource_string, timeout, do_id_query, do_reset,
                       do_clear):
    instrument_object = resource_mgr.open_resource(instrument_resource_string)
    if do_id_query == 1:
        print(instrument_query(instrument_object, "*IDN?"))
    if do_reset == 1:
        instrument_write(instrument_object, "*RST")
    if do_clear == 1:
        instrument_object.clear()
    instrument_object.timeout = timeout
    return resource_mgr, instrument_object


"""*********************************************************************************
    Function: instrument_write(instrument_object, my_command)
    Purpose: Issue controlling commands to the target instrument.
    Parameters:
        instrument_object (object) - Instance of an instrument object.

        my_command (string) - The command issued to the instrument to make it 
                              perform some action or service. 
    Returns:
        None
    Revisions:
        2019-08-21    JJB    Initial revision.
*********************************************************************************"""


def instrument_write(instrument_object, my_command):
    if echo_commands == 1:
        print(my_command)
    instrument_object.write(my_command)
    return


"""*********************************************************************************
    Function: instrument_read(instrument_object)
    Purpose: Used to read commands from the instrument.
    Parameters:
        instrument_object (object) - Instance of an instrument object.

    Returns:
        <<<reply>>> (string) - The requested information returned from the 
                    target instrument. Obtained by way of a caller
                    to instrument_read().
    Revisions:
        2019-08-21    JJB    Initial revision.
*********************************************************************************"""


def instrument_read(instrument_object):
    return instrument_object.read()


"""*********************************************************************************
    Function: instrument_query(instrument_object, my_command)
    Purpose: Used to send commands to the instrument  and obtain an information string from the instrument.
             Note that the information received will depend on the command sent and will be in string
             format.
    Parameters:
        instrument_object (object) - Instance of an instrument object.

        my_command (string) - The command issued to the instrument to make it 
                      perform some action or service. 
    Returns:
        <<<reply>>> (string) - The requested information returned from the 
                    target instrument. Obtained by way of a caller
                    to instrument_read().
    Revisions:
        2019-08-21    JJB    Initial revision.
*********************************************************************************"""


def instrument_query(instrument_object, my_command):
    if echo_commands == 1:
        print(my_command)
    return instrument_object.query(my_command)


"""*********************************************************************************
    Function: instrument_disconnect(instrument_object)
    Purpose: Break the VISA connection between the controlling computer
             and the target instrument.
    Parameters:
        instrument_object (object) - Instance of an instrument object.
    Returns:
        None
    Revisions:
        2019-08-21    JJB    Initial revision.
*********************************************************************************"""


def instrument_disconnect(instrument_object):
    instrument_object.close()
    return


# ================================================================================
#
#    MAIN CODE STARTS HERE
#
# ===============================================================================
######

t1 = time.time()  # Start the timer...
instrument_resource_string = "USB0::0x05E6::0x2230::9010101::INSTR"
resource_manager = visa.ResourceManager()  #Opens the resource manager
print(resource_manager.list_resources())
my_instr = None
resource_manager, my_instr = instrument_connect(resource_manager, my_instr, instrument_resource_string, 20000, 1, 1, 1)

#Loop example for reading 2230


power_supply_1 = None
resource_manager, power_supply_1 = instrument_connect(resource_manager,
 power_supply_1,
instrument_resource_string,
 20000, 0, 1, 1)
instrument_write(power_supply_1, "*RST")
instrument_write(power_supply_1, "SYST:REM")
instrument_write(power_supply_1, "INST:NSEL 1")  # Use for Connecting One Channel,Selects Channel 1
instrument_write(power_supply_1, "VOLT 1.0")  # Set output level
instrument_write(power_supply_1, "CURR 0.01")   # Set limit
instrument_write(power_supply_1, "OUTP 1")  # Turn On
measured_voltage = float(instrument_query(power_supply_1, "MEAS:VOLT?").rstrip('\n'))
measured_current = float(instrument_query(power_supply_1, "MEAS:CURR?").rstrip('\n'))
instrument_write(power_supply_1, "OUTP 0")  # Turn Off

########################################################################################################
# https://download.tek.com/manual/2230G-900-01A_Jun_2018_User.pdf
instrument_write(power_supply_1, "INSTrument:NSELect 1")  # Selects channel 1
instrument_write(power_supply_1, "CURR 0.35")  # Remains same value
instrument_write(power_supply_1, "OUTP 1")  # Turns output on
set_voltage = .5

# Loop example for reading increased voltage levels
for i in range(1, 10):
    # .rstrip removes any characters specified in the parameters
    # fstring allows a variable name
    instrument_write(power_supply_1, f"VOLT {set_voltage}")
    set_voltage = float(instrument_query(power_supply_1, "VOLT?").rstrip('\n'))
    set_current = float(instrument_query(power_supply_1, "CURR?").rstrip('\n'))
    print("Set Voltage:", set_voltage, "Set Current:", set_current)
    measured_voltage = float(instrument_query(power_supply_1, "MEAS:VOLT?").rstrip('\n'))
    measured_current = float(instrument_query(power_supply_1, "MEAS:CURR?").rstrip('\n'))
    print("Measured Volts:", measured_voltage, "Measured Current:", measured_current)
    set_voltage += .5

instrument_write(power_supply_1, "OUTP 0")  # Turns output off
instrument_write(power_supply_1, "SYST:LOC")  # Switches power supply to front panel
instrument_disconnect(power_supply_1)
resource_manager.close()  # ***Always have an open and close function

instrument_disconnect(my_instr)

t2 = time.time()  # Stop the timer...

# Notify the user of completion and the data streaming rate achieved.
print("done")
print("Elapsed Time: {0:0.3f}s".format(t2 - t1))

input("Press Enter to continue...")
exit()
