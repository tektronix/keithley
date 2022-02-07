"""***********************************************************

*** Copyright Tektronix, Inc.                           ***
*** See www.tek.com/sample-license for licensing terms. ***

Title:      2281S-20-6 system speeds sample code

Purpose:    The following sample code connects to a 2281S-20-6
            and demonstrates its current measurement speed
            capabilities. The speed and current readings are
            written to a csv file for easy viewing.

Revisions:  2022-02-07, Initial Revision.

***********************************************************"""


import pyvisa as visa
import time

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


# writes readings to a .csv file
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
    Function: get_current_buffer(output_path)

    Purpose: retrieves readings in the data buffer and outputs them to a .csv file

    Parameters:
        output_path (string) - file output path

    Returns:
        <<<reply>>> readings from the data buffer

    Revisions:
        2022-1-28   Initial Revision    JEI
*********************************************************************************"""


def get_current_buffer(output_path):
    """
    Get only the current data from the buffer and find the average current
    """
    print("get current buffer")
    # collect_time = 0.1
    # time.sleep(collect_time)  # Wait that amount of time
    buff = instrument_query(BS2281S, ":TRAC:DATA? \"READ, UNIT\"").rstrip()  # Read the whole buffer
    data = buff.replace(",", "\n") + "\n"
    write_readings_to_file(output_path, data)

    return data


"""*********************************************************************************
    Function: speed_test(voltage, current, nplc_val, sample_count, num_of_runs)

    Purpose: Measures current with speed optimized read settings. Once the buffer is
             full, it exports the readings to a .csv file, clears the buffer, and
             restarts the loop (until the num_of_runs limit is reached).  The average
             speed is written to the last row in the .csv file.  

    Parameters:
        voltage (float or int) - set voltage for power supply
        
        current (float or int) - set current for power supply
        
        nplc_val (float) - set nplc_val, which affects the reading speed
        
        sample_count - number of samples taken during a trigger event
                       (do not change)
        
        num_of_runs - number of loop runs 

    Returns:
        <<<reply>>> n/a

    Revisions:
        2022-1-28   Initial Revision    JEI
*********************************************************************************"""


def speed_test(voltage, current, nplc_val, sample_count, num_of_runs):
    v = "{:.2f}".format(voltage)
    c = "{:.2f}".format(current)
    nplc = "{:.3f}".format(nplc_val)
    sc = "{:.0f}".format(sample_count)
    points = 0

    # setting up speed test in power supply mode
    instrument_write(BS2281S, "*RST")  # RESET
    instrument_write(BS2281S, ":ENTRy:FUNC POW")  # power supply mode
    instrument_write(BS2281S, ":TRAC:CLE")  # clear the data buffer
    instrument_write(BS2281S, ":TRAC:FEED:CONT ALW")  # set to a circular buffer
    instrument_write(BS2281S, ":TRAC:POIN 2500")  # set the number of points in the buffer
    instrument_write(BS2281S, ":VOLT " + str(v))  # set voltage
    instrument_write(BS2281S, ":CURR " + str(c))  # set current
    instrument_write(BS2281S, ":SENSe:FUNC \"CURR\"")  # sense current setting
    instrument_write(BS2281S, ":SENSe:CURR:NPLC " + str(nplc))  # set nplc
    instrument_write(BS2281S, ":SENSe:CURR:RANGe:AUTO OFF")  # display and measurement settings -->
    instrument_write(BS2281S, ":SENSe:CURR:RANGe 10")  # -->
    instrument_write(BS2281S, ":SYST:AZER OFF")  # -->
    instrument_write(BS2281S, ":CONF:CURR 0.1, 4")  # -->
    instrument_write(BS2281S, ":SENSe:CURR:RES 4")  # -->
    instrument_write(BS2281S, ":SENSe:CURR:DIG 4")  # -->
    instrument_write(BS2281S, ":DIG:LINE1:FUNC AUTO")  # -->
    instrument_write(BS2281S, ":INIT:CONT OFF")  # keep off otherwise error 213 occurs
    instrument_write(BS2281S, ":TRIG:SOUR IMM")  # IMM trigger source
    instrument_write(BS2281S, ":TRIG:COUN 1")  # only one trigger event occurs
    instrument_write(BS2281S, ":TRIG:SAMP:COUN " + str(sc))  # setting the number of samples during a trigger event
    instrument_write(BS2281S, ":OUTP ON")  # set output high

    t3 = time.time()
    # Loop reads buffer when full and writes data to a .csv file.
    # Once all runs are complete, it writes the average speed to the file
    for x in range(num_of_runs):

        # clearing the buffer
        instrument_write(BS2281S, ":TRAC:CLE")  # clear the buffer once full
        points = "0"
        instrument_write(BS2281S, ":INIT")  # Init
        t5 = time.time()

        while points != "2500":
            points = instrument_query(BS2281S, ":TRAC:POINts:ACTUAL?").rstrip()
            # print(points)
        get_current_buffer(output_data_path)
        t6 = time.time()
        speed1 = ("Speed for this loop: {:.2f} readings/sec".format(1 / ((t6 - t5) / int(sc))))
        print(speed1)

    t4 = time.time()
    speed = ("Speed: {:.2f} readings/sec".format(1 / ((t4 - t3) / (int(sc) * int(num_of_runs))))) + "\n"
    print(speed)
    write_readings_to_file(output_data_path, speed)

    return


# ================================================================================
#
#    MAIN CODE STARTS HERE
#
# ================================================================================


t1 = time.time()  # Start the timer...
resource_manager = visa.ResourceManager()  # Opens the resource manager
# print(resource_manager.list_resources())

BS2281S = None

inst_resource_string = "USB0::0x05E6::0x2281::4305749::INSTR"  # your instrument resource string goes here!
resource_manager, BS2281S = instrument_connect(resource_manager, BS2281S, inst_resource_string, 20000, 1, 1, 1)

file_name = time.strftime("2281S_data_%Y-%m-%d_%H-%M-%S.csv")  # setting up .csv file
output_data_path = file_name  # This is the output file that is created which

# -------------------------------------------------------------
# change values as needed.  Do not change sample_count
# -------------------------------------------------------------
speed_test(5, 3, 0.002, 2500, 10)

instrument_write(BS2281S, ":OUTP OFF")  # turn the output off
instrument_disconnect(BS2281S)  # disconnect the instrument
resource_manager.close()

t2 = time.time()  # Stop the timer...
print("Complete")

# note: look for the generated .csv file in the project folder

exit()
