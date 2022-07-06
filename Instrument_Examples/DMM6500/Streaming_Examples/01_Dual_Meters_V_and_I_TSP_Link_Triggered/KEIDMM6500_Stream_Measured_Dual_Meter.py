import pyvisa as visa
import pyvisa.constants as pyconst
import time
from datetime import datetime
import sys
import os
import time
import random

echo_commands = 0
pure_sockets = 0

"""*********************************************************************************
    Function: instrument_connect(resource_mgr, instrument_object, instrument_resource_string, 
                                 timeout, do_id_query, do_reset, do_clear) 

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


def instrument_connect(resource_mgr,
                       instrument_object,
                       instrument_resource_string,
                       timeout, do_id_query,
                       do_reset,
                       do_clear,
                       baud_rate=9600,
                       data_bits=8,
                       parity=pyconst.Parity.none,
                       stop_bits=pyconst.StopBits.one,
                       flow_control=0,
                       read_terminator="\n"):

    instrument_object = resource_mgr.open_resource(instrument_resource_string)

    # Check for the SOCKET as part of the instrument ID string and set the following accordingly...
    if "SOCKET" in instrument_resource_string:
        instrument_object.write_termination = "\n"
        instrument_object.read_termination = "\n"
        instrument_object.send_end = True
    elif "ASRL" in instrument_resource_string:
        instrument_object.baud_rate = baud_rate
        instrument_object.data_bits = data_bits
        instrument_object.parity = parity   #pyconst.Parity.odd
        instrument_object.stop_bits = stop_bits     #pyconst.StopBits.one
        instrument_object.flow_control = flow_control
        instrument_object.write_termination = "\n"
        instrument_object.read_termination = read_terminator
        instrument_object.send_end = True
    elif "GPIB" in instrument_resource_string:
        # do nothing or something...
        #print("GPIB")
        pure_sockets = 0
    elif "USB" in instrument_resource_string:
        # do nothing or something...
        #print("USB")
        pure_sockets = 0
    else:
        # Assume a sockets connection; set the flag
        pure_sockets = 1

    if do_id_query == 1:
        print(instrument_query(instrument_object, "*IDN?"))
    if do_reset == 1:
        instrument_write(instrument_object, "reset()")
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
        print(my_command + "\n")
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
                                                 is_big_endian=False,
                                                 data_points=number_of_data_points)


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
	Function: load_script_file_onto_keithley_instrument(my_script_file, my_socket)

	Purpose: Copy the contents of a specific script file off of the computer 
	         and upload onto the target instrument. 

	Parameters:
		my_script_file (string) - The script file/path (ASCII text format) that 
					  will be read from the computer and sent to the
					  instrument. 
		my_socket - The TCP instrument connection object used for 
				      sending and receiving data. 
	Returns:
		None

	Revisions:
		2019-07-30    JJB    Initial revision.
*********************************************************************************"""


def load_script_file(my_script_file, instrument_object):
    # This function opens the functions.lua file in the same directory as
    # the Python script and trasfers its contents to the DMM7510's internal
    # memory. All the functions defined in the file are callable by the
    # controlling program.
    func_file = open(my_script_file, "r")
    contents = func_file.read()
    func_file.close()

    send_buffer = "if loadfuncs ~= nil then script.delete('loadfuncs') end"
    instrument_write(instrument_object, send_buffer)

    send_buffer = f"loadscript loadfuncs\n{contents}\nendscript"
    instrument_write(instrument_object, send_buffer)

    send_buffer = "loadfuncs()"
    print(instrument_query(instrument_object, send_buffer))
    return


def write_readings_to_file(file_path, floats):
    # This function writes the floating point data to the
    # target file.

    ofile = open(file_path, "a")  # Open/create the target data for DMM1
    tmp = 0
    for f in floats:
        if tmp % 2 == 0:    # indices divisible by 2 will hold the reading value; odd indices hold timestamp
            ofile.write("{0:.6e},".format(f))
        else:
            ofile.write("{0:.8e}\n".format(f))
        tmp += 1

    ofile.close()
    return

# ================================================================================
#
#    MAIN CODE STARTS HERE
#
# ================================================================================
t1 = time.time()  # Start the timer...
resource_manager = visa.ResourceManager()  # Opens the resource manager
#print(resource_manager.list_resources())

dmm6500_1 = None
dmm6500_2 = None

inst_resource_string_1 = "USB0::0x05E6::0x6510::04340543::INSTR"
inst_resource_string_2 = "USB0::0x05E6::0x6500::04397619::INSTR"
resource_manager, dmm6500_1 = instrument_connect(resource_manager, dmm6500_1, inst_resource_string_1, 20000, 1, 1, 1)
resource_manager, dmm6500_2 = instrument_connect(resource_manager, dmm6500_2, inst_resource_string_2, 20000, 1, 1, 1)

load_script_file("functions_2021-03-06.lua", dmm6500_1)
load_script_file("functions_2021-03-06.lua", dmm6500_2)

# Create the file that will house our data
output_data_path_1 = time.strftime("dmm_1_data_%Y-%m-%d_%H-%M-%S.csv")   # This is the output file that is created which
                                                                         # will hold your readings provided in ASCII
                                                                         # format in a text file.
output_data_path_2 = time.strftime("dmm_2_data_%Y-%m-%d_%H-%M-%S.csv")

is_master_1 = 1
is_master_2 = 0
tsp_line = 1
do_voltage_1 = 1
do_voltage_2 = 0
dcv_measure_range = 10
dci_measure_range = 10e-3
aperture_time = 0.001
data_extract_size = 1000
buffer_capacity = 5000000

# configure the master for DCV measure
instrument_write(dmm6500_1, f"chunk_size = {data_extract_size}")
instrument_write(dmm6500_1, f"configure_tsp_link_trigger({is_master_1}, {tsp_line})")
instrument_write(dmm6500_1, f"configure_measure({do_voltage_1}, {dcv_measure_range}, {aperture_time})")
instrument_write(dmm6500_1, f"configure_buffer({buffer_capacity})")
instrument_write(dmm6500_1, f"configure_trigger_model({is_master_1}, {data_extract_size})")
instrument_write(dmm6500_1, "set_display(1)")

# configure the subordinate for DCI measure
instrument_write(dmm6500_2, f"chunk_size = {data_extract_size}")
instrument_write(dmm6500_2, f"configure_tsp_link_trigger({is_master_2}, {tsp_line})")
instrument_write(dmm6500_2, f"configure_measure({do_voltage_2}, {dci_measure_range}, {aperture_time})")
instrument_write(dmm6500_2, f"configure_buffer({buffer_capacity})")
instrument_write(dmm6500_2, f"configure_trigger_model({is_master_2}, {data_extract_size})")
instrument_write(dmm6500_2, "set_display(1)")

# first start the subordinate, then the master
instrument_write(dmm6500_2, "trigger.model.initiate()")
instrument_write(dmm6500_1, "trigger.model.initiate()")

t3 = time.time()
j = 1
seconds_to_run = 3600 * 11
accumulated_readings = 0
start_index = 1
end_index = data_extract_size
while j == 1:
    t4 = time.time()
    if (t4-t3) > seconds_to_run:
        j = 0
        instrument_write(dmm6500_1, "trigger.model.abort()")
        instrument_write(dmm6500_2, "trigger.model.abort()")
    else:
        # get a chunk of data
        data_list_1 = instrument_query_binary_to_single_float(dmm6500_1, "get_data()", data_extract_size)
        data_list_2 = instrument_query_binary_to_single_float(dmm6500_2, "get_data()", data_extract_size)
        # write it to file
        write_readings_to_file(output_data_path_1, data_list_1)
        write_readings_to_file(output_data_path_2, data_list_2)

# cleanup after test completion
instrument_write(dmm6500_1, "set_display(0)")
instrument_write(dmm6500_1, "buffer.delete(samplebuff)")
instrument_write(dmm6500_2, "set_display(0)")
instrument_write(dmm6500_2, "buffer.delete(samplebuff)")

instrument_disconnect(dmm6500_1)
instrument_disconnect(dmm6500_2)
resource_manager.close()

t2 = time.time()  # Stop the timer...

# Notify the user of completion and the data streaming rate achieved.
print("done")
print("Elapsed Time: {0:0.3f}s".format(t2 - t1))

input("Press Enter to continue...")
exit()

