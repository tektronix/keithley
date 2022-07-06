"""***********************************************************

*** Copyright Tektronix, Inc.                           ***

Title:      2281S-20-6 battery model generation script

Purpose:    The following sample code generates a battery model
	    and stores it in an internal memory location

Revisions:  2022-03-22, Initial Revision.

*** See www.tek.com/sample-license for licensing terms. ***

***********************************************************"""

import numpy as np
import pyvisa as visa
import pyvisa.constants as pyconst
import time
from datetime import datetime
import sys
import select
import os
import csv
import numpy

echo_commands = 0

def instrument_connect(resource_mgr, instrument_object, instrument_resource_string, timeout, do_id_query, do_reset,
                       do_clear):
    """
    Open an instance of an instrument object for remote communication.

    :param resource_mgr: (object) Instance of a resource manager object.
    :param instrument_object: (object) Instance of an instrument object to be initialized within this function.
    :param instrument_resource_string: (string) The VISA resource string associated with a specific instrument defining
     its connection characteristics (communications type, model, serial number, etc.)
    :param timeout: (int) Time in milliseconds to wait before the communication transaction with the target instrument
     is considered failed (timed out)
    :param do_id_query: (int) A flag that determines whether or not to query and print the instrument ID string.
    :param do_reset: (int) A flag that determines whether or not to issue a reset command to the instrument during this
    connection.
    :param do_clear: (int) A flag that determines whether or not to issue a clear command to the instrument during this
    connection.
    :return: (object) resource_mgr, (object) instrument_object
    """
    instrument_object = resource_mgr.open_resource(instrument_resource_string)
    # Check the comms type and apply termination as needed
    if "ASRL" in instrument_resource_string:
        instrument_object.send_end = True
        instrument_object.write_termination = '\n'
        instrument_object.read_termination = '\n'
        instrument_object.baud_rate = 9600
        instrument_object.data_bits = 8
        instrument_object.flow_control = constants.VI_ASRL_FLOW_NONE
        instrument_object.parity = constants.VI_ASRL_PAR_NONE
        instrument_object.stop_bits = constants.VI_ASRL_STOP_ONE
    elif "SOCKET" in instrument_resource_string:
        instrument_object.write_termination = '\n'
        instrument_object.read_termination = '\n'
    if do_id_query == 1:
        print(instrument_query(instrument_object, "*IDN?"))
    if do_reset == 1:
        instrument_write(instrument_object, "*RST")
    if do_clear == 1:
        instrument_object.clear()
    instrument_object.timeout = timeout
    return resource_mgr, instrument_object


def instrument_write(instrument_object, my_command):
    """
    Issue controlling commands to the target instrument.

    :param instrument_object: (object) Instance of an instrument object.
    :param my_command: (string) The command issued to the instrument to make it perform some action or service.
    :return: None
    """
    if echo_commands == 1:
        print(my_command)
    instrument_object.write(my_command)
    return


def instrument_read(instrument_object):
    """
    Used to read commands from the instrument.

    :param instrument_object: (object) Instance of an instrument object.
    :return: <reply> (string), The requested information returned from the target instrument. Obtained by way of a
    caller to instrument_read().
    """
    return instrument_object.read().rstrip()


def instrument_query(instrument_object, my_command):
    """
    Used to send commands to the instrument  and obtain an information string from the instrument. Note that
    the information received will depend on the command sent and will be in string format.

    :param instrument_object: (object) Instance of an instrument object.
    :param my_command: (string) The command issued to the instrument to make it perform some action or service.
    :return: <reply> (string) - The requested information returned from the target instrument. Obtained
    by way of a caller to instrument_read().
    """
    if echo_commands == 1:
        print(my_command)
    return instrument_object.query(my_command).rstrip()


def instrument_disconnect(instrument_object):
    """
    Break the VISA connection between the controlling computer and the target instrument.
    :param instrument_object: (object) Instance of an instrument object.
    :return: None
    """
    instrument_object.close()
    return


"""*********************************************************************************
    Function: charge_test_and_create_model(dischargeVolt, dischargeCurr, vFul, currLimit, lowerRange, 
                                            upperRange, modelSelect)

    Purpose: Discharges a battery then performs a charge test. Once the charge test is complete, the
             script generates a battery model in a specified internal memory location
             
             note: once the script is complete, you may access the generated battery model at the specified
             internal memory location.  Manually change the Capacity value as needed.

    Parameters:
        dischargeVolt (float) - Desired discharged battery voltage level

        dischargeCurr (float) - Desired discharged battery current cutoff level
        
        vFul (float) - Battery's voltage at full charge
        
        currLimit - maximum current charge limit
        
        lowerRange - lowest voltage value for the battery model
        
        upperRange - highest voltage value for the battery model
        
        modelSelect - desired internal memory location to store the battery

    Returns:
        <<<reply>>> (none)

    Revisions:
        2022-3-22   Initial Revision    JEI
*********************************************************************************"""


def charge_test_and_create_model(endCurr, vFul, currLimit, lowerRange, upperRange, modelSelect):
    """
    Discharges a battery then performs a charge test. Once the charge test is complete, the
    script generates a battery model in a specified internal memory location
    
    Note: once the script is complete, you may access the generated battery model at the specified
    internal memory location.  Manually change the Capacity value as needed.

    :param dischargeVolt: (float) Desired discharged battery voltage level
    :param dischargeCurr: (float) Desired discharged battery current cutoff level
    :param vFul: (float) Battery's voltage at full charge
    :param currLimit: (float) Maximum current charge limit
    :param lowerRange: (float) Lowest voltage value for the battery model
    :param upperRange: (float) Highest voltage value for the battery model
    :param modelSelect: (float) Desired internal memory location to store the battery
    :return: None
    """

    # -------------------------------------------------------------------------------------
    # TEST MODE
    # -------------------------------------------------------------------------------------
    instrument_write(BS2281S, "*RST")  # reset
    instrument_write(BS2281S, ":BATT:DATA:CLE")  # clear the battery simulator/test data buffer
    instrument_write(BS2281S, ":ENTRy:FUNC TEST")  # select battery test

    # -------------------------------------------------------------------------------------
    # CHARGE
    # -------------------------------------------------------------------------------------
    instrument_write(BS2281S, ":BATT:TEST:CURR:END " + str(endCurr))
    instrument_write(BS2281S, ":BATT:TEST:SENS:AH:VFUL " + str(vFul))
    instrument_write(BS2281S, ":BATT:TEST:SENS:AH:ILIM " + str(currLimit))
    instrument_write(BS2281S, ":BATT:TEST:SENS:AH:ESRI S30")
    instrument_write(BS2281S, ":BATT:TEST:SENS:AH:EXEC STAR")
    time.sleep(5)

    # checking when measurements are complete...
    # register bit index[4] is high when instrument is performing a measurement
    registerBit = int(instrument_query(BS2281S, ":STAT:OPER:INST:ISUM:COND?")) & 16
    print(registerBit)
    while registerBit == 16:
        time.sleep(5)
        registerBit = int(instrument_query(BS2281S, ":STAT:OPER:INST:ISUM:COND?")) & 16
        print("register bit: " + str(registerBit))
    # # measurements are complete...generate battery model
    instrument_write(BS2281S, ":BATT:TEST:SENS:AH:GMOD:RANG " + str(lowerRange) + ", " + str(upperRange))
    instrument_write(BS2281S, ":BATT:TEST:SENS:AH:GMOD:SAVE:INTE " + str(modelSelect))




# ================================================================================
#
#    MAIN CODE STARTS HERE
#
# ================================================================================


resource_manager = visa.ResourceManager()  # Opens the resource manager
# print(resource_manager.list_resources())

BS2281S = None

inst_resource_string = "USB0::0x05E6::0x2281::4305749::INSTR"  # instrument resource string
resource_manager, BS2281S = instrument_connect(resource_manager, BS2281S, inst_resource_string, 20000, 1, 1, 1)

# ---------------------------------------------------------------------------
# change all values in this function call accordingly
# ---------------------------------------------------------------------------
charge_test_and_create_model(0.05, 3.7, 0.4, 2.75, 3.7, 5)

instrument_disconnect(BS2281S)  # disconnect the instrument
resource_manager.close()

print("Complete")

exit()
