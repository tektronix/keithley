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

	This example shows how the user of a Keithley Series 2260B Multi-range DC
	Power Supply can make use of the instrument's transient function to mimic
	quick, controlled level changes representative of what might be observed 
	on the output of a power controller connected to a battery or some other 
	load. 

*********************************************************************************"""
my_ip_address = "192.168.1.113"  # Define your instrument's IP address here.
my_port = 2268  # Define your instrument's port number here.

do_instr_reset = 1
do_instr_clear = 1
do_instr_id_query = 1

t1 = time.time()

# Open the socket connections...
my_instr = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  # Establish a TCP/IP socket object
instrument_connect(my_instr, my_ip_address, my_port, 20000, do_instr_reset, do_instr_clear, do_instr_id_query)

#instrument_write(my_instr, "*RST")
instrument_write(my_instr, "SOUR:VOLT:LEV 13")       # SOUR:VOLT:LEV 0
instrument_write(my_instr, "SOUR:VOLT:LEV:TRIG 6.5")  #
instrument_write(my_instr, "SOUR:VOLT:SLEW:RISE 40.0")  # Pre-set the rising slew rate to 40V/s when the mode is enabled
instrument_write(my_instr, "SOUR:CURR:LEV MAX")  #
instrument_write(my_instr, "SOUR:CURR:LEV:TRIG MAX")
instrument_write(my_instr, "SOUR:CURR:PROT MAX")

instrument_write(my_instr, "OUTP:MODE CVHS")    # Give the voltage output mode high-speed priority
instrument_write(my_instr, "TRIG:TRAN:SOUR IMM")    # BUS|IMM

dwell_time = 0.5
instrument_write(my_instr, "OUTP ON")
t3 = time.time()
t4 = time.time()
while((t4-t3) < dwell_time):
    time.sleep(0.005)
    t4 = time.time()
instrument_write(my_instr, "INIT:NAME TRAN") # This will transition as quickly as possible to 6.5V

# prepare for t2 raise time of 50ms; control the rate of change by using slew rate control - previously set for 40V/s
instrument_write(my_instr, "OUTP:MODE CVLS")    # Give the voltage output mode slew rate priority
instrument_write(my_instr, "SOUR:VOLT:LEV:TRIG 8")  # Set the new transient level
# first apply t1 dwell time which can range from 15ms to 100ms
dwell_time = 0.015
t3 = time.time()
t4 = time.time()
while((t4-t3) < dwell_time):
    time.sleep(0.001)
    t4 = time.time()

# trigger the t2 transient which should last 50ms with applied settings
instrument_write(my_instr, "INIT:NAME TRAN")
dwell_time = 0.05
t3 = time.time()
t4 = time.time()
while((t4-t3) < dwell_time):
    time.sleep(0.001)
    t4 = time.time()

# prepare for t4 by setting the slew rate depending on the dwell time
#       - the 8-13V transition can be as little as 90ms: 5/0.09 = 55.5V/s
#       - the 8-13V transition can be as much as 100ms: 5/0.1 = 50V/s
instrument_write(my_instr, "SOUR:VOLT:LEV:TRIG 13")  # Set the new transient level
instrument_write(my_instr, "SOUR:VOLT:SLEW:RISE 55.5")
# after the level is reached, dwell for t3 which can last from 500ms to 2s
dwell_time = 0.5
t3 = time.time()
t4 = time.time()
while((t4-t3) < dwell_time):
    time.sleep(0.001)
    t4 = time.time()
# trigger the t4 transient that could range from 90ms to 100ms
instrument_write(my_instr, "INIT:NAME TRAN")
dwell_time = 0.09
t3 = time.time()
t4 = time.time()
while((t4-t3) < dwell_time):
    time.sleep(0.001)
    t4 = time.time()

# put the output mode back to high-speed priority
instrument_write(my_instr, "OUTP:MODE CVHS")

# after the level is reached, dwell for t5 which is undefined and is dependent on the voltage adjustment
dwell_time = 0.5
t3 = time.time()
t4 = time.time()
while((t4-t3) < dwell_time):
    time.sleep(0.010)
    t4 = time.time()

# end of test; turn the output off
instrument_write(my_instr, "OUTP OFF")

instrument_disconnect(my_instr)

t2 = time.time()  # Stop the timer...
# Notify the user of completion and the data streaming rate achieved.
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2 - t1))

input("Press Enter to continue...")
exit()