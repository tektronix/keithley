# ***********************************************************
#
# *** Copyright Tektronix, Inc.                           ***
# *** See www.tek.com/sample-license for licensing terms. ***
#
# Title:      2380 list/transient mode operation sample code
#
# Purpose:    The following sample code connects to a 2380
#             DC Electronic Load and demonstrates its list
#             and transient modes.
#
# Revisions:  2022-03-02, Initial Revision.

# ***********************************************************

import pyvisa as visa
import time

echo_commands = 0
t3 = time.time()


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
    return instrument_object.read()


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
    return instrument_object.query(my_command)


def instrument_disconnect(instrument_object):
    """
    Break the VISA connection between the controlling computer and the target instrument.
    :param instrument_object: (object) Instance of an instrument object.
    :return: None
    """
    instrument_object.close()
    return


def list_mode_setup(instrument, range_val, count, steps, levels, slew, width):
    """
    Sets up the 2380 in list mode and executes a user generated list

    :param instrument: (object) Instance of a 2380 instrument object.
    :param range_val: (float) Range setting for the list
    :param count: (int) Number of times the list executes
    :param steps: (int) Number of steps in the list
    :param levels: (int) The current levels for each step. List index 1 is the first entry in the array
    :param slew: (float) Slew rate for each step
    :param width: (float) Width of each step
    :return: None
    """
    # setting up list general settings
    instrument_write(instrument, "*RST")  # reset
    instrument_write(instrument, "FUNC:MODE FIX")  # MUST go into fixed mode to edit a list
    instrument_write(instrument, "LIST:RANG " + str(range_val))  # setting range for the list
    instrument_write(instrument, "LIST:COUN " + str(count))  # number of iterations for the list
    instrument_write(instrument, "LIST:STEP " + str(steps))  # number of steps in the list

    # setting level for each step
    for x in range(1, steps + 1):
        print(x)
        instrument_write(instrument, "LIST:LEV " + str(x) + ", " + str(levels[x-1]))

    # setting slew rate for each step
    for x in range(1, steps + 1):
        instrument_write(instrument, "LIST:SLEW " + str(x) + ", " + str(slew[x-1]))

    # setting time for each step
    for x in range(1, steps + 1):
        instrument_write(instrument, "LIST:WID " + str(x) + ", " + str(width[x-1]))

    # saving and starting list
    instrument_write(instrument, "LIST:SAV 3")
    instrument_write(instrument, "LIST:RCL 3")
    instrument_write(instrument, "FUNC:MODE LIST")
    instrument_write(instrument, "INP ON")
    instrument_write(instrument, "FORCe:TRIG")
    time.sleep(1)

    # Checking for list completion
    val = instrument_query(instrument, "STAT:QUES:COND?").rstrip()
    print("first check: " + val)
    while val == ("16512" or "128"):
        print(val == ("16512" or "128"))
        print("check: " + val)  # display ques register status
        val = instrument_query(instrument, "STAT:QUES:COND?").rstrip()  # get val
        time.sleep(0.1)
    else:
        print("last check: " + val)  # show new val
        instrument_write(instrument, "INP OFF")  # once the list is no longer running, turn input off


def transient_mode_setup(instrument, volt_or_curr, tran_mode, a, b, wid_a, wid_b, p_slew, n_slew, runtime):
    """
    Sets up the 2380 in transient mode and executes with user generated settings.
    :param instrument: (object) Instance of a 2380 instrument object.
    :param volt_or_curr: (char) "V" or "C" to select voltage or current mode.
    :param tran_mode: (int) Use 1, 2, or 3 to select Continuous, Pulse, and Toggle respectively. Default is set
    to Continuous.
    :param a: (float) Voltage/current level A
    :param b: (float) Voltage/current level B
    :param wid_a: (float) Width for level A
    :param wid_b: (float) Width for level B
    :param p_slew: (float) Positive slew rate setting
    :param n_slew: (float) Negative slew rate setting
    :param runtime: (float) Duration of time transient mode spends running
    :return:
    """
    # general setup
    instrument_write(instrument, "INPUT:SHORT OFF")
    instrument_write(instrument, "FUNC:MODE FIX")
    instrument_write(instrument, "TRAN ON")

    if volt_or_curr == "C":
        # handling transient mode
        if tran_mode == 2:
            instrument_write(instrument, "CURR:TRAN:MODE PULS")  # setting transient mode to pulse
        elif tran_mode == 3:
            instrument_write(instrument, "CURR:TRAN:MODE TOGG")  # setting transient mode to toggle
        else:
            instrument_write(instrument, "CURR:TRAN:MODE CONT")  # setting transient mode to continuous

        # setting slew rates
        if p_slew:
            instrument_write(instrument, "CURR:SLEW:POS " + str(p_slew))  # setting positive slew rate
        else:
            instrument_write(instrument, "CURR:SLEW:POS MAX")  # default setting is MAX
        if n_slew:
            instrument_write(instrument, "CURR:SLEW:NEG " + str(n_slew))  # setting negative slew rate
        else:
            instrument_write(instrument, "CURR:SLEW:NEG MAX")  # default setting is MAX

        instrument_write(instrument, "CURR:TRAN:ALEV " + str(a))  # setting A Level
        instrument_write(instrument, "CURR:TRAN:BLEV " + str(b))  # setting B level

        instrument_write(instrument, "CURR:TRAN:AWID " + str(wid_a))  # setting A width
        instrument_write(instrument, "CURR:TRAN:BWID " + str(wid_b))  # setting B width

        # note: use the following equations to find widA and widB from frequency and duty ratio
        # awidth = 1/freq*duty
        # bwidth = 1/freq*(1-duty)

        instrument_write(instrument, "INP ON")
        instrument_write(instrument, "FORCe:TRIG")
        time.sleep(runtime)
        instrument_write(instrument, "INP OFF")
        instrument_write(instrument, "TRAN OFF")

    if volt_or_curr == "V":
        # handling transient mode
        if tran_mode == 2:
            instrument_write(instrument, "VOLT:TRAN:MODE PULS")  # setting transient mode to pulse
        elif tran_mode == 3:
            instrument_write(instrument, "VOLT:TRAN:MODE TOGG")  # setting transient mode to toggle
        else:
            instrument_write(instrument, "VOLT:TRAN:MODE CONT")  # setting transient mode to continuous

        instrument_write(instrument, "CURR:TRAN:ALEV " + str(a))  # setting A Level
        instrument_write(instrument, "CURR:TRAN:BLEV " + str(b))  # setting B level

        instrument_write(instrument, "CURR:TRAN:AWID " + str(wid_a))  # setting A width
        instrument_write(instrument, "CURR:TRAN:BWID " + str(wid_b))  # setting B width

        # note: use the following equations to find widA and widB from frequency and duty ratio
        # awidth = 1/freq*duty
        # bwidth = 1/freq*(1-duty)

        instrument_write(instrument, "INP ON")
        instrument_write(instrument, "FORCe:TRIG")
        time.sleep(runtime)
        instrument_write(instrument, "INP OFF")
        instrument_write(instrument, "TRAN OFF")


# ================================================================================
#
#    MAIN CODE STARTS HERE
#
# ================================================================================

#  NOTE:
#  the following script allows a user to use list and/or transient mode. The user
#  may call the functions as necessary.  Delete or comment out list_mode_setup or
#  transient_mode_setup calls if you do not wish to perform them.

t1 = time.time()  # Start the timer...
resource_manager = visa.ResourceManager()  # Opens the resource manager
# print(resource_manager.list_resources())

EL2380 = None

inst_resource_string = ""  # your instrument resource string goes here!
resource_manager, EL2380 = instrument_connect(resource_manager, EL2380, inst_resource_string, 20000, 1, 1, 1)


# function call to list_mode_setup (comment or delete if undesired)
list_mode_setup(EL2380, 10, 2, 3, [0, 0.5, 1], [100, 100, 100], [1, 1, 1])

# time between modes
time.sleep(3)

# function call to transient_mode_setup (comment or delete if undesired)
transient_mode_setup(EL2380, "V", 1, 0.2, 1, 1, 1, "MAX", "MAX", 10)

instrument_disconnect(EL2380)  # disconnect the instrument
resource_manager.close()

t2 = time.time()  # Stop the timer...
print("Time: {:.3f}s".format(t2 - t1))
print("Complete")

exit()
