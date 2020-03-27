"""***********************************************************
*** Copyright Tektronix, Inc.                           ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************"""
import socket
import struct
import math
import time
import sys

echo_cmd = 0

"""*********************************************************************************
	Function: instrument_connect(my_socket, ip_address string, my_port int, timeout
                                     do_reset, do_id_query) 

	Purpose: Open an instance of an instrument object for remote communication
		 over LAN/Ethernet.

    Parameters:
    my_socket - Instance of a socket object.

		ip_address (string) - The TCP/IP address string associated with the
                                      target instrument. 
		my_port (int) - The instrument connection port.

		timeout (int) - The timeout limit for query/communication exchanges.

		do_reset (int) - Determines whether the instrument is to be reset
		                 upon connection to the instrument. Setting to 1
                         will perform the reset; setting to zero avoids it.

		do_clear (int) - Determines whether the instrument is to be cleared


        do_id_query (int) - Deterines when the instrument is to echho its
                            identification string after it is initialized. 

	Returns:
		my_socket - Updated instance of a socket object that includes
                            attributes of a valid connection. 

	Revisions:
		2019-07-30    JJB    Initial revision.
*********************************************************************************"""


def instrument_connect(my_socket, my_address, my_port, timeout, do_reset, do_clear, do_id_query):
    my_socket.connect((my_address, my_port))  # input to connect must be a tuple
    my_socket.settimeout(timeout)
    my_socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    if do_reset == 1:
        instrument_write(my_socket, "*RST")
    if do_clear == 1:
        instrument_write(my_socket, "*CLS")
    if do_id_query == 1:
        tmp_id = instrument_query(my_socket, "*IDN?", 100)
        print(tmp_id)
    return my_socket


"""*********************************************************************************
	Function: instrument_disconnect(my_socket)

	Purpose: Break the LAN/Ethernet connection between the controlling computer
			 and the target instrument.

	Parameters:
		my_socket - The TCP instrument connection object used for sending
							  and receiving data.

	Returns:
		None

	Revisions:
		2019-07-30    JJB    Initial revision.
*********************************************************************************"""


def instrument_disconnect(my_socket):
    my_socket.close()
    return


"""*********************************************************************************
	Function: instrument_write(my_socket, my_command)

	Purpose: This function issues control commands to the target instrument.

	Parameters:
		my_socket - The TCP instrument connection object used for sending
			    and receiving data.
		my_command (string) - The command issued to the instrument to make it 
				      perform some action or service. 
	Returns:
		None

	Revisions:
		2019-07-30    JJB    Initial revision.
*********************************************************************************"""


def instrument_write(my_socket, my_command):
    if echo_cmd == 1:
        print(my_command)
    cmd = "{0}\n".format(my_command)
    my_socket.send(cmd.encode())
    return


"""*********************************************************************************
	Function: instrument_read(my_socket, receive_size)

	Purpose: This function asks the connected instrument to reply with some
                 previously requested information, typically queued up from a call
                 to instrument_write().

	Parameters:
		my_socket - The TCP instrument connection object used for sending
			    and receiving data.
		receive_size (int) - Size of the data/string to be returned to
                                     the caller. 

	Returns:
		reply_string (string) - The requested information returned from the 
					target instrument.

	Revisions:
		2019-07-30    JJB    Initial revision.
*********************************************************************************"""


def instrument_read(my_socket, receive_size):
    return my_socket.recv(receive_size).decode()


"""*********************************************************************************
	Function: instrument_query(my_socket, my_command, receive_size)

	Purpose: This function issues control commands to the target instrument with
                 the expectation that data will be returned. For this function
                 instance, the returned data is (typically) in string format. 

	Parameters:
		my_socket - The TCP instrument connection object used for sending
			    and receiving data.
		my_command (string) - The command issued to the instrument to make it 
				      perform some action or service.
		receive_size (int) - The approximate number of bytes of data the caller
                                     expects to be returned in the response from the
                                     instrument. 
	Returns:
		reply_string (string) - The requested information returned from the 
					target instrument. Obtained by way of a caller
					to instrument_read().

	Revisions:
		2019-07-30    JJB    Initial revision.
*********************************************************************************"""


def instrument_query(my_socket, my_command, receive_size):
    instrument_write(my_socket, my_command)
    return instrument_read(my_socket, receive_size)


"""*********************************************************************************
	Function: write_data(output_data_path, data_str)

	Purpose: This function issues control commands to the target instrument.

	Parameters:
		output_data_path (string) - The file name and path of the file to be written
                                   to. Note that the file is opened in append mode
                                   and no previously existing data will be over-
                                   written.
		data_str (string) - The data to be written to file. It is up to the
                                    user to format this data external to this
                                    function prior to using it. 
	Returns:
		None

	Revisions:
		2020-01-03    JJB    Initial revision.
*********************************************************************************"""


def write_data(output_data_path, data_str):
    # This function writes the floating point data to the
    # target file.
    # for f in floats:
    ofile = open(output_data_path, "a")  # append the target data
    dataStr = "{0}\n".format(data_str)
    ofile.write(dataStr)

    ofile.close()  # Close the data file.

    return

"""*********************************************************************************

	This example shows how the user of a Keithley touchscreen instrument (SMU 2450, 
	2460, 2461, or 2470, or DMM7510, DMM6500, or DAQ6510) can load a TSP script file
	and execute embedded functions. 

*********************************************************************************"""
my_ip_address = "192.168.1.104"  # Define your instrument's IP address here.
my_port = 5025  # Define your instrument's port number here.

do_instr_reset = 1
do_instr_clear = 1
do_instr_id_query = 1

t1 = time.time()

# Open the socket connections...
my_instr = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  # Establish a TCP/IP socket object
instrument_connect(my_instr, my_ip_address, my_port, 20000, do_instr_reset, do_instr_clear, do_instr_id_query)

# Ready the instrument to receive the target file contents
file = "functions2.tsp"
func_file = open(file, "r")
contents = func_file.read()
func_file.close()
instrument_write(my_instr, "if loadfuncs ~= nil then script.delete('loadfuncs') end")

# Load the script file in one large chunk then close out the loadfuncs wrapper script.
instrument_write(my_instr, "loadscript loadfuncs\n{0}\nendscript\n".format(contents))
# Call loadfuncs to load the contents of the script file into active memory
print(instrument_query(my_instr, "loadfuncs()", 32))        # Note that we are echoing a queried function here.
                                                            # You will note that the final line in the functions.tsp
                                                            # script file is a print() command that will push its
                                                            # contents to the output data queue.

instrument_write(my_instr, "do_beep(0.250, 1000, 3)")

instrument_disconnect(my_instr)

t2 = time.time()  # Stop the timer...
# Notify the user of completion and the data streaming rate achieved.
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2 - t1))

input("Press Enter to continue...")
exit()