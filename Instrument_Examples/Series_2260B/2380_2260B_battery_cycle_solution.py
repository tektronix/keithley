"""*********************************************************************************
    Copyright Tektronix, Inc.
    See www.tek.com/sample-license for licensing terms.

    Title: SMU_Battery_Cycling_Solution

    Overview: This script can be used to perform battery cycling (charge/discharge
              testing using both the Keithley Series 2260B Power Supply and Keithley
              Series 2380 Electronic Load.

              This work can be used for cycling high current (> 1 A) or high voltage
              batteries and battery packs.

              The operator will need to pass in (specify) the cell full voltage,
              the discharge voltage, discharge current, charge voltage, charge current,
              end current, and sample frequency.

              There is an option for the operator to acquire temperature readings
              throughout the cycling process. The operator would need to have a
              Keithley DAQ6510 data acquisition system connnected to the PC and
              pass in its VISA instrument resource string.

              The script will output a *.csv file including all test data.

    WARNING:         A properly rated diode must be connected to the 2260B's output to
                     prevent the power supply from being damaged. Please check the 2260B
                     user manual for reference, as well as safety conditions for the diode.
                     The user will have to account for the voltage drop across the diode
                     when setting up the discharge/charge cycle tests.

    INSTRUCTIONS:    Make changes to function calls as needed. User will need to adjust
                     the following settings:
                     1) instrument resource strings starting on line 522
                     2) setup() arguments as needed on lines: 535 and 537
*********************************************************************************"""

import pyvisa as visa
import time
import sys
import select
import os

echo_commands = 0
t3 = time.time()

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


"""*********************************************************************************
    Function: instrument_query(instrument_object, my_command, number_of_data_points)

    Purpose: Used to send commands to the instrument  and obtain a list of floating
             point (single) data items from the instrument.
             Note that the information received will depend on the command sent. 

    Parameters:
        instrument_object (object) - Instance of an instrument object.

        my_command (string) - The command issued to the instrument to make it 
                      perform some action or service. 
    Returns:
        <<<reply>>> (list float) - The requested information returned from the 
                    target instrument. Obtained by way of a caller
                    to instrument_query_binary_data.

    Revisions:
        2021-03-02    JJB    Initial revision.
*********************************************************************************"""


def instrument_query_binary_to_single_float(instrument_object, my_command, number_of_data_points):
    if echo_commands == 1:
        print(my_command)
    return instrument_object.query_binary_values(my_command, datatype='f',
                                                 is_big_endian=False, data_points=number_of_data_points)


"""*********************************************************************************
    Function: write_readings_to_file(file_path, data)

    Purpose: open, write to, and close a file

    Parameters:
        file_path (string) - path for writeable file

        data (string) - data to write to file
    Returns:
        <<<reply>>> None

    Revisions:
        2022-06-16    JEI    Initial revision.
*********************************************************************************"""


def write_readings_to_file(file_path, data):
    ofile = open(file_path, "a")  # open file
    ofile.write(data)  # write to file
    ofile.close()  # close the file
    return


"""*********************************************************************************
    Function: discharge_cycle(loop, sink, daq, fullV, dischargeV, dischargeI, sample_freq, file_path)

    Purpose: Perform one discharge cycle. This function will discharge a battery
             at a constant rate to dischargeV. Once this voltage threshold has been
             crossed, the cycle ends. Measurements will be written to a specified
             .csv file.

    Parameters:
        loop (int) - loop index number

        sink (object) - instance of an instrument object (2380)

        daq (object) - instance of an instrument object (DAQ6510/DMM6500)

        fullV (float) - nominal voltage of the battery

        dischargeV (float) - empty voltage of the battery

        dischargeI (float) - desired discharge current

        sample_freq (float) - desired measurement frequency

        file_path (string) - desired writeable file location

    Returns:
        <<<reply>>> None

    Revisions:
        2022-06-16    JEI    Initial revision.
*********************************************************************************"""


def discharge_cycle(loop, sink, daq, fullV, dischargeV, dischargeI, sample_freq, file_path):
    sample_freq = (1 / sample_freq) - 0.035
    try:
        instrument_write(sink, "SOUR:INP OFF")  # high z if OFF

        # 1) DAQ SETUP
        # Change transducer and temperature measurement settings here (if needed)
        if daq != 0:
            instrument_write(daq, "SENS:FUNC \"TEMP\"")
            instrument_write(daq, "TEMP:TRAN THER")
            instrument_write(daq, "TEMP:THER 10000")

            instrument_write(daq, "TRAC:CLEAR")
            instrument_write(daq, "COUN 1")

        # 2) SOURCE AND TEST SETUP
        instrument_write(sink, "SOUR:FUNC CURR")
        instrument_write(sink, "SOUR:FUNC:MODE FIXed")
        instrument_write(sink, "CURR " + str(dischargeI))
        instrument_write(sink, "VOLT:RANG:AUTO OFF")
        instrument_write(sink, "VOLT:RANG " + str(fullV))
        instrument_write(sink, "CURR:LOW 0")

        voltLimit = dischargeV + 0.001  # set the voltage limit for the battery to stop discharging
        iteration = 1  # loop counter
    except:
        print("Setup Error...")

    instrument_write(sink, "SOUR:INP ON")  # setup complete...turn output ON
    time.sleep(1)

    while True:
        volt = float(instrument_query(sink, "MEAS:VOLT?"))  # measure voltage
        curr = float(instrument_query(sink, "MEAS:CURR?"))  # measure current
        if daq != 0:
            temp = float(instrument_query(daq, "MEAS?"))  # measure temperature
        else:
            temp = -1
        t2 = time.time()  # get time
        timeData = ("{:.2f}".format((t2 - t1)))  # find relative time

        reading = "{LOOP}, {CYCLE}, {VOLT:.4f}, {CURR:.4f}, {TEMP:.4f}, {TIME}\n".format(LOOP=loop, CYCLE="discharge",
                                                                                         VOLT=volt, CURR=curr,
                                                                                         TEMP=temp, TIME=timeData)
        write_readings_to_file(file_path, reading)  # write readings to .csv file

        print("LOOP, CYCLE, VOLT, CURR, TEMP, TIME: " + reading)  # for viewing in python

        if volt <= voltLimit:
            break  # if battery is discharged, leave the loop
        time.sleep(sample_freq)  # sample frequency
        iteration = iteration + 1

    instrument_write(sink, "SOUR:INP OFF")  # discharge cycle complete...turn output OFF
    return


"""*********************************************************************************
    Function: charge_cycle(loop, sink, ps, daq, chargeV, chargeCurr, endCurr, sample_freq, file_path)

    Purpose: Perform one charge cycle. This function will charge a battery
             to chargeV. Once the end current condition has been met, the
             battery will be at chargeV. Measurements will be written to a
             specified .csv file.

    Parameters:
        loop (int) - loop index number

        sink (object) - instance of an instrument object (2380)

        ps (object) - instance of an instrument object (2260B)

        daq (object) - instance of an instrument object (DAQ6510/DMM6500)

        chargeV (float) - desired charge voltage

        chargeCurr (float) - maximum charging current

        endCurr (float) - desired end condition current

        sample_freq (float) - desired measurement frequency

        file_path (string) - desired writeable file location

    Returns:
        <<<reply>>> None

    Revisions:
        2022-06-16    JEI    Initial revision.
*********************************************************************************"""


def charge_cycle(loop, sink, ps, daq, chargeV, chargeCurr, endCurr, sample_freq, file_path):
    sample_freq = (1 / sample_freq) - 0.035
    try:
        # 1) DAQ SETUP
        # Change transducer and temperature measurement settings here (if needed)
        if daq != 0:
            instrument_write(daq, "SENS:FUNC \"TEMP\"")
            instrument_write(daq, "TEMP:TRAN THER")
            instrument_write(daq, "TEMP:THER 10000")

            instrument_write(daq, "TRAC:CLEAR")
            instrument_write(daq, "COUN 1")

        # 1) POWER SUPPLY SETTINGS
        instrument_write(ps, "OUTP:MODE 2")  # high speed voltage priority
        instrument_write(ps, "OUTP OFF")  # turn the output off

        instrument_write(ps, "RES MIN")
        instrument_write(ps, "OUTP:PROT:CLE")

        # 2) SOURCE SETTINGS
        instrument_write(ps, "VOLT:LEV " + str(chargeV))
        instrument_write(ps, "VOLT:SLEW:RIS MAX")
        instrument_write(ps, "VOLT:SLEW:FALL MAX")
        instrument_write(ps, "CURR:LEV " + str(chargeCurr))  # setting up ilimit
        instrument_write(ps, "SOUR:CURR:PROT:LEV " + str(chargeCurr + 0.1))  # current protection settings
        instrument_write(ps, "SOUR:CURR:PROT:STAT ON")

        iteration = 1  # loop counter
    except:
        print("Setup Error...")

    instrument_write(ps, "OUTP ON")  # setup complete...turn output ON
    time.sleep(1)

    while True:
        volt = float(instrument_query(sink, "MEAS:VOLT?"))  # measure voltage
        curr = float(instrument_query(ps, "MEAS:CURR?"))  # measure current
        if daq != 0:
            temp = float(instrument_query(daq, "MEAS?"))  # measure temperature
        else:
            temp = -1
        t2 = time.time()  # get time
        timeData = ("{:.2f}".format((t2 - t1)))  # find relative time

        reading = "{LOOP}, {CYCLE}, {VOLT:.4f}, {CURR:.4f}, {TEMP:.4f}, {TIME}\n".format(LOOP=loop, CYCLE="charge",
                                                                                         VOLT=volt, CURR=curr,
                                                                                         TEMP=temp, TIME=timeData)
        write_readings_to_file(file_path, reading)  # write readings to .csv file

        print("LOOP, CYCLE, VOLT, CURR, TEMP, TIME: " + reading)  # for viewing in python

        if curr <= endCurr:
            break  # if the current is less than current threshold, the battery is charged
        time.sleep(sample_freq)
        iteration = iteration + 1

    instrument_write(ps, "OUTP OFF")  # charge cycle complete...turn output OFF
    return


"""*********************************************************************************
    Function: setup(dischargeTest, chargeTest, loopCount, elString, psString, daqString)

    Purpose: The following function sets up a battery cycle test. A user can run
             individual discharge/charge cycles or run the process with a loop.

    WARNING: A properly rated diode must be connected to the 2260B's output to
             prevent the power supply from being damaged. Please check the 2260B
             user manual for reference, as well as safety conditions for the diode.
             The user will have to account for the voltage drop across the diode
             when setting up the discharge/charge cycle tests.

    Parameters:
        loop (int) - loop index number

        dischargeTest (int) - discharge cycle selection bit.  Set to 1 to enable discharge testing
                              / 0 to disable

        chargeTest (int) - charge cycle selection bit. Set to 1 to enable charge testing    
                           / 0 to disable

        loopCount (int) - ONLY applies when dischargeTest AND chargeTest are set to 1. It is the
                          number of times to discharge and charge the battery.  Note that each
                          loop will perform a discharge cycle test followed by a charge cycle test.

        elString (string) - instrument resource string for the electronic load (2380)

        psString (string) - instrument resource string for the power supply (2260B)

        daqString (string) - instrument resource string for the daq/dmm (DAQ6510 used in script)

    Returns:
        <<<reply>>> None

    Revisions:
        2022-06-16    JEI    Initial revision.
*********************************************************************************"""


def setup(dischargeTest, chargeTest, loopCount, elString, psString, daqString, settings):
    # -----------------------------------------------------
    # 1) INSTRUMENTS CONNECTION HANDLER
    # -----------------------------------------------------
    resource_manager = visa.ResourceManager()  # Opens the resource manager
    print(resource_manager.list_resources())

    EL2380 = None
    PS2260B = None

    resource_manager, EL2380 = instrument_connect(resource_manager, EL2380, elString, 20000, 1, 1, 1)
    resource_manager, PS2260B = instrument_connect(resource_manager, PS2260B, psString, 20000, 1, 1, 0)

    if daqString != 0:
        DAQ = None
        resource_manager, DAQ = instrument_connect(resource_manager, DAQ, daqString, 20000, 1, 1, 1)
    else:
        DAQ = 0

    # -----------------------------------------------------
    # 2) DISCHARGE/CHARGE CYCLE TEST HANDLER
    # -----------------------------------------------------
    file_name = time.strftime("battery_cycle_test_data%Y-%m-%d_%H-%M-%S.csv")
    output_data_path = file_name
    file_header = ("LOOP:", "CYCLE:", "VOLT (V):", "CURR (A):", "TEMP (*C):", "TIME (s):\n")
    file_header = ",".join(file_header)
    write_readings_to_file(output_data_path, file_header)  # writing header to file

    if (dischargeTest == 1) and (chargeTest == 1):
        for x in range(loopCount):
            discharge_cycle(x, EL2380, DAQ, settings[0], settings[1], settings[2], settings[6], output_data_path)
            charge_cycle(x, EL2380, PS2260B, DAQ, settings[3], settings[4], settings[5], settings[6], output_data_path)

    elif (dischargeTest == 1) and (chargeTest == 0):
        discharge_cycle(1, EL2380, DAQ, settings[0], settings[1], settings[2], settings[6], output_data_path)

    elif (dischargeTest == 0) and (chargeTest == 1):
        charge_cycle(1, EL2380, PS2260B, DAQ, settings[3], settings[4], settings[5], settings[6], output_data_path)

    # disconnect all instruments
    instrument_disconnect(EL2380)
    instrument_disconnect(PS2260B)
    if daqString != 0:
        instrument_disconnect(DAQ)

    resource_manager.close()
    print("\n\n----------------\nCOMPLETE\n----------------")
    return


# ================================================================================
#
#    MAIN CODE STARTS HERE
#
# ================================================================================

t1 = time.time()

# connect to the instruments (USER INPUT NEEDED)
inst_resource_string_el2380 = ""
inst_resource_string_ps2260B = ""
inst_resource_string_daq = 0

# --------------------------------------------
# USER INPUT NEEDED
# --------------------------------------------
#
# Please read function descriptions for more information about each term
#
# settings order = [fullV, dischargeV, dischargeI, chargeV, chargeCurr, endCurr, sample_freq]

# Example settings are filled-in
test_settings = [3.7, 3.0, 0.2, 4.45, 0.2, 0.01, 1]

setup(1, 1, 1, inst_resource_string_el2380, inst_resource_string_ps2260B, inst_resource_string_daq, test_settings)

exit()
