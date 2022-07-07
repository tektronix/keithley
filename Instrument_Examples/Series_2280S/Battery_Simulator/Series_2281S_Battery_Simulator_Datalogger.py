"""***********************************************************

*** Copyright Tektronix, Inc.                           ***
*** See www.tek.com/sample-license for licensing terms. ***

Title:      2281S-20-6 battery simulator datalogger sample code

Purpose:    The following sample code connects to a 2281S-20-6
            and logs data from the battery simulator mode over
            extended periods of time. This allows the instrument
            to take measurements, even after the data buffer
            reaches its maximum capacity.

Revisions:  2022-02-07, Initial Revision.

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
    Function: write_readings_to_file(file_path, floats)

    Purpose: Write the contents of a reading from an instrument to a
             .csv file.

    Parameters:
        file_path (string) - File path for desired .csv file
        
        floats (float) - float or float array to be written to the .csv file

    Returns:
        <<<reply>>> .csv file with instrument readings

    Revisions:
        2019-07-30    JJB    Initial revision.
*********************************************************************************"""


# writes readings from the data buffer to a file
def write_readings_to_file(file_path, floats):
    # This function writes the floating point data to the
    # target file.

    ofile = open(file_path, "a")  # Open/create the target data for DMM1
    # tmp = 0
    # for f in floats:
    #     if tmp % 2 == 0:  # indices divisible by 2 will hold the reading value; odd indices hold timestamp
    #         ofile.write("{0:.6e},".format(f))
    #     else:
    #         ofile.write("{0:.8e}\n".format(f))
    #     tmp += 1

    ofile.write(floats)
    ofile.close()
    return


"""*********************************************************************************
    Function: cleanup_csv(file)

    Purpose: Used to cleanup a .csv file, eliminating empty rows and reordering
             the columns to a desired format

    Parameters:
        file (string) - full file name for the .csv file, including ".csv" in the
                        name
    Returns:
        <<<reply>>> (.csv file) - returns the reordered .csv

    Revisions:
        2022-1-28   Initial Revision    JEI
*********************************************************************************"""


def cleanup_csv(file):
    # OPTIONAL CODE for reordering the data buffer columns:
    # this function reorders the .csv file into the desired order.
    # it also cleans up empty rows.


    # # deleting empty rows
    # with open(file) as input, open('cleared_' + file, 'w', newline='') as output:
    #     writer = csv.writer(output)
    #     for row in csv.reader(input):
    #         if any(field.strip() for field in row):
    #             writer.writerow(row)
    #
    # # reordering
    # with open('cleared_' + file, 'r') as in_file_handle:
    #     reader = csv.reader(in_file_handle)
    #     content = []
    #     for row in reader:
    #         content.append([row[0]] + [row[3]] + [row[1]] + [row[2]] + [row[4]] + [row[5]])
    #     with open('mid_' + file, 'a') as out_file_handle:
    #         writer = csv.writer(out_file_handle)
    #         writer.writerows(content)

    # deleting empty rows
    # change open(file, 'r') to open('mid_' + file, 'r') if using optional code
    with open(file, 'r') as input, open('FINAL' + file, 'a', newline='') as output:
        writer = csv.writer(output)
        for row in csv.reader(input):
            if any(field.strip() for field in row):
                writer.writerow(row)

    # removing middle conversion files...
    os.remove(file)
    # remove other files here if needed...


"""*********************************************************************************
    Function: CV_or_CC(lst)

    Purpose: This function takes the most used mode over the (~12s) period and uses it as the
             averaged mode value.  The function is called by write_current_buffer().

    Parameters:
        lst (list) - list of mode values.
        
    Returns:
        <<<reply>>> (string) - returns the highest occurring mode in the list

    Revisions:
        2022-1-28   Initial Revision    JEI
*********************************************************************************"""


def CV_or_CC(lst):
    x = 0
    CV = 0
    CC = 0
    while x < len(lst):
        if str(lst[x]) == "CV":
            CV = CV + 1
        elif str(lst[x]) == "CC":
            CC = CC + 1
        else:
            CV = CV + 1
        x = x + 1

    if CV == CC:
        return "CV"
    elif CC < CV:
        return "CV"
    else:
        return "CC"


"""*********************************************************************************
    Function: write_current_buffer(time_val, x, output_path)

    Purpose: This function queries the instrument for information from the data buffer, organizes the information,
             then exports it to a .csv file.  The function calls CV_or_CC().

    Parameters:
        time_val (time) - initial time when starting the battery simulator
        
        x (int) - index for averaged reading
        
        output_path () - output file path

    Returns:
        <<<reply>>> (.csv file) - returns the organized .csv file

    Revisions:
        2022-1-28   Initial Revision    JEI
*********************************************************************************"""


def write_current_buffer(time_val, x, output_path):
    """
    Get only the current data from the buffer and find the average current
    """
    print("get current buffer")

    # Finding CC or CV Mode
    Mode = instrument_query(BS2281S, ":BATT:DATA:DATA? \"MODE\"").rstrip()
    Mode = list(Mode)
    mode_data = CV_or_CC(Mode)

    # Obtaining for data buffer information
    EVOC = instrument_query(BS2281S, ":BATT:SIM:RES?").rstrip()
    AH = instrument_query(BS2281S, ":BATT:SIM:CAP?").rstrip()
    buff = instrument_query(BS2281S,
                            ":BATT:DATA:DATA? \"VOLTage,CURRent,RELative\"").rstrip()  # Read the whole buffer (no unit)

    # for debug:
    # print(buff)

    # isolating data
    float_buffer = map(float, buff.split(","))
    float_buffer = list(float_buffer)
    data = float_buffer[0::3], float_buffer[1::3], float_buffer[2::3]

    voltage_data = np.asarray(data[0])
    current_data = np.asarray(data[1])
    time_data = time.time() - time_val
    # print(time_data)

    # finding averages
    v_av = np.average(voltage_data)
    c_av = np.average(current_data)

    # preparing data for writing
    vals_av = (str(x), str(mode_data).rstrip(), str(v_av).rstrip(), str(c_av).rstrip(), str(EVOC).rstrip(), str(AH).rstrip(), str(time_data).rstrip() + "\n")
    exportv = ",".join(vals_av)
    print("EXPORT: " + exportv)

    # writing data into .csv file
    write_readings_to_file(output_path, exportv)
    return exportv


"""*********************************************************************************
    Function: battery_sim_read(output_path, num_of_runs, BM, LV, HV, CurrL, CapL, Method, VOC, SOC)

    Purpose: Sets up battery simulator running a specific model.  It averages readings over a ~12 sec
             period and writes them to a .csv file.

    Parameters:
        output_path - output file path

        num_of_runs - number of desired loop runs.  (simulator also ends if a
                      limit condition is met)

        BM - battery model number for a battery model stored on the instrument

        LV - V Empty

        HV - V Full

        CurrL - Current Limit

        CapL - Battery Capacity Limit

        Method - simulation mode (hard set to Dynamic "DYN")

        VOC - The VOC value

        SOC - SOC value changes according to the VOC input


    Returns:
        <<<reply>>> (.csv file) an organized .csv file of the averaged readings

    Revisions:
        2022-1-28   Initial Revision    JEI
*********************************************************************************"""


def battery_sim_read(output_path, num_of_runs, BM, LV, HV, CurrL, CapL, Method, VOC, SOC):

    file_header = ("Index:", "Mode:", "Voltage:", "Current:", "ESR:", "AH:", "Relative time:\n")
    file_header = ",".join(file_header)
    write_readings_to_file(output_path, file_header)  # writing header to file

    lv_input = "{:.1f}".format(LV)
    hv_input = "{:.1f}".format(HV)
    data_extract_size = 100

    # Battery Simulator setup:
    instrument_write(BS2281S, "*RST")  # reset
    instrument_write(BS2281S, ":BATT:DATA:CLE")  # clear the battery simulator/test data buffer
    instrument_write(BS2281S, ":ENTRy:FUNC SIM")  # select battery simulator
    instrument_write(BS2281S, ":BATT:SIM:SAMP:INT 0.003")  # turn output on
    instrument_write(BS2281S, ":BATT:SIM:METH " + Method)  # select method
    instrument_write(BS2281S, ":BATT:MOD:RCL " + str(BM))  # Set model to BM
    instrument_write(BS2281S, ":BATT:SIM:VOC:FULL " + str(hv_input))  # Set VOC full to HV
    instrument_write(BS2281S, ":BATT:SIM:VOC:EMPTy " + str(lv_input))  # Set VOC empty to LV
    instrument_write(BS2281S, ":BATT:SIM:CURR:LIM " + str(CurrL))  # Set current limit to CurrL
    instrument_write(BS2281S, ":BATT:SIM:CAP:LIM " + str(CapL))  # Set capacity limit to CapL
    instrument_write(BS2281S, ":BATT:SIM:VOC " + str(VOC))  # Set VOC
    instrument_write(BS2281S, ":BATT:SIM:SOC DEF")  # Set SOC // to set: + str(SOC)
    instrument_write(BS2281S, ":BATT:OUTP ON")  # turn output on

    print("setup commands complete")

    totalt1 = time.time()
    for x in range(num_of_runs):
        print("in for loop: " + str(x))

        # RESET (does not clear while performing battery simulator or test)
        # instrument_write(BS2281S, ":BATT:TRAC:CLE")

        points = 0
        tt1 = time.time()
        while points < 2500:
            q = instrument_query(BS2281S, ":TRAC:POINts:ACTUAL?").rstrip()
            print(str(q) + " actual points")
            print(str(points) + " points")
            points = points + 1
            # print(str(points) + " loop run")

        write_current_buffer(totalt1, x, output_path)
        tt2 = time.time()
        print("Time: {:.3f}s".format(tt2 - tt1))

    totalt2 = time.time()
    print("average time: {:.3f}s".format((totalt2 - totalt1)/num_of_runs))


# ================================================================================
#
#    MAIN CODE STARTS HERE
#
# ================================================================================


t1 = time.time()  # Start the timer...
resource_manager = visa.ResourceManager()  # Opens the resource manager
# print(resource_manager.list_resources())

BS2281S = None

inst_resource_string = "USB0::0x05E6::0x2281::4305749::INSTR"  # instrument resource string
resource_manager, BS2281S = instrument_connect(resource_manager, BS2281S, inst_resource_string, 20000, 1, 1, 1)

file_name = time.strftime("2281S_data_%Y-%m-%d_%H-%M-%S.csv")

output_data_path = file_name  # This is the output file that is created which

instrument_write(BS2281S, "*RST")

# ---------------------------------------------------------------------------
# change all values in this function call accordingly
# ---------------------------------------------------------------------------
battery_sim_read(output_data_path, 3, 2, 3.0, 4.2, 0.5, 3.4, "DYN", 3.7, 50)

instrument_write(BS2281S, ":BATT:OUTP OFF")  # stop the measurement
instrument_write(BS2281S, ":BATT:DATA:CLEar")  # clear the data buffer

cleanup_csv(file_name)  # .csv cleanup

instrument_disconnect(BS2281S)  # disconnect the instrument
resource_manager.close()

t2 = time.time()  # Stop the timer...
print("Complete")
input("Press Enter to Continue...")

# note: look for the generated .csv file in the project folder

exit()
