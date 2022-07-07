# ***********************************************************
#
# *** Copyright Tektronix, Inc.                           ***
# *** See www.tek.com/sample-license for licensing terms. ***
#
# Title:      Solar Cell I-V Sweep
#
# Purpose:   This example sequence of SCPI commands generates an I-V sweep on a solar cell. You may need to
# make changes so that this code will run in your programming environment.
# 
# In this example, the voltage is swept from 0 V to 0.55 V in 56 steps. The resulting solar cell current is
# measured. The current and voltage measurements are stored in default buffer 1 (defbuffer1).
#
# Revisions:  2022-03-02, Initial Revision.
#
# ***********************************************************

from operator import contains
import pyvisa as visa
from visa import constants
import time
from datetime import datetime

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


def instrument_read_binary(instrument_object, extract_size):
    """
    Used to read binary data from the instrument and return as a list of floating point values.

    :param instrument_object: (object) Instance of an instrument object.
    :param extract_size: (int) The number of readings the operator is expecting to be returned. 
    :return: <reply> (string), The requested information returned from the target instrument. 
    Obtained by way of a caller to instrument_read().
    """
    return instrument_object.read_binary_values(datatype='f', is_big_endian=False, chunk_size=extract_size)


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


def instrument_query_binary(instrument_object, my_command, extract_size):
    """
    Used to send commands to the instrument and obtain an information from the 
    instrument, anticipated to be in binary format then converted to a list of 
    floating point values. Note that this type of functionality is associated 
    with readings transfer and not general command or error checking queries 
    which are ASCII-based.

    :param instrument_object: (object) Instance of an instrument object.
    :param my_command: (string) The command issued to the instrument to make it perform some action or service.
    :param extract_size: (int) The number of readings the operator is expecting to be returned.
    :return: <reply> (string) - The requested information returned from the target instrument. Obtained
    by way of a caller to instrument_read().
    """
    if echo_commands == 1:
        print(my_command)
    return instrument_object.query_binary_values(my_command, datatype = 'f', is_big_endian = False) # , chunk_size=extract_size, expect_termination=False


def instrument_disconnect(instrument_object):
    """
    Break the VISA connection between the controlling computer and the target instrument.
    :param instrument_object: (object) Instance of an instrument object.
    :return: None
    """
    instrument_object.close()
    return


# ================================================================================
#
#    MAIN CODE STARTS HERE
#
# ================================================================================
t1 = time.time()  # Start the timer...
resource_manager = visa.ResourceManager()  # Opens the resource manager
print(resource_manager.list_resources())

# connect to and configure the load
my_smu = None
date_time = datetime.now()
date_actual = date_time.strftime('%d/%m/%Y %H:%M')
do_idn = 1
do_reset = 1
do_clear = 0
                                                        # Example resource IDs...
resource_string = "TCPIP0::134.63.74.24::inst0::INSTR"  # GPIB0::11::INSTR   
                                                        # TCPIP0::192.168.1.65::inst0::INSTR   
                                                        # "USB0::0x05E6::0x2461::04351584::INSTR
resource_manager, my_smu = instrument_connect(resource_manager, my_smu, resource_string, 20000, do_idn, do_reset, do_clear)

# Define the number of points
num = 56
instrument_write(my_smu, "reset()")

# Set the source and measure functions.
instrument_write(my_smu, "smu.measure.func = smu.FUNC_DC_CURRENT")
instrument_write(my_smu, "smu.source.func = smu.FUNC_DC_VOLTAGE")

# Measurement settings.
instrument_write(my_smu, "smu.terminals = smu.TERMINALS_FRONT")
instrument_write(my_smu, "smu.measure.sense = smu.SENSE_4WIRE")
instrument_write(my_smu, "smu.measure.autorange = smu.ON")
instrument_write(my_smu, "smu.measure.nplc = 1")

# Source settings.
instrument_write(my_smu, "smu.source.highc = smu.OFF")
instrument_write(my_smu, "smu.source.range = 2")
instrument_write(my_smu, "smu.source.readback = smu.ON")
instrument_write(my_smu, "smu.source.ilimit.level = 1")
start_volts = 0.0
stop_volts = 0.53
sweep_limit = 0.1
instrument_write(my_smu, f"smu.source.sweeplinear(\"SolarCell\", {start_volts}, {stop_volts}, {num}, {sweep_limit})")

# Start the trigger model and wait for it to complete.
instrument_write(my_smu, "trigger.model.initiate()")
# instrument_write(my_smu, "waitcomplete()")
trigger_model_state = instrument_query(my_smu, "print(trigger.model.state())")
while "RUNNING" in trigger_model_state:
    time.sleep(0.1)
    trigger_model_state = instrument_query(my_smu, "print(trigger.model.state())")

print("#\tREADING\tTIMESTAMP")
print("=============================")
reading_count = int(instrument_query(my_smu, "print(defbuffer1.n)"))
for i in range(1, reading_count+1):
    rdg = float(instrument_query(my_smu, f"print(defbuffer1[{i}])"))
    ts = float(instrument_query(my_smu, f"print(defbuffer1.relativetimestamps[{i}])"))
    print(f"{i}\t{rdg}\t{ts}")
print(instrument_query(my_smu, "printbuffer(1, defbuffer1.n, defbuffer1.readings, defbuffer1.relativetimestamps)"))

instrument_disconnect(my_smu)
resource_manager.close()

t2 = time.time()  # Stop the timer...

# Notify the user of completion and the duration time.
print("done")
print("Elapsed Time: {0:0.3f}s".format(t2 - t1))
input("Press Enter to continue...")
exit()
