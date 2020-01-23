"""***********************************************************
*** Copyright Tektronix, Inc.                           ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************"""
import socket
import struct
import math
import time

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

	This example application demonstrates the use of the DAQ6510 in a switching
	only application. The channel control reflects the use of the Model 7701 
	multiplexer card. The setup assumes the following:
	    A. A power source is applied to MUX2 and routed to any of three devices
	       connected to channels 117, 118, and 119.
	    B. A measurement device is applied to MUX1 and routed to any of six possible
	       test points connected to channels 101, 102, 103, 104, 105, and 106. 
	    C. The jumpers between MUX1 and the DMM Input terminals and those between 
	       MUX2 and the DMM Sense terminals have been removed from the Model 7701. 
	       However, relays 34 and 35 are forced to their open state to help ensure
	       isolation.
	    D. For each MUX2 source connection to the device, each of the six MUX1
	       channels will be closed to allow for a measurement to occur then
	       open to allow for subsequent channel measurements. 

*********************************************************************************"""
my_ip_address = "192.168.1.165"  # Define your instrument's IP address here.
my_port = 5025  # Define your instrument's port number here.

do_instr_reset = 1
do_instr_clear = 0
do_instr_id_query = 1

t1 = time.time()

# Open the socket connections...
my_daq = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  # Establish a TCP/IP socket object
my_daq.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
instrument_connect(my_daq, my_ip_address, my_port, 20000, do_instr_reset, do_instr_clear, do_instr_id_query)

source_channel_list = (["117", "118", "119"])
measure_channel_list = (["101", "102", "103", "104", "105", "106"])

# open channels 134 and 135 to supplement isolation from the DAQ6510
# internal input and sense terminals
instrument_write("channel.multiple.open(\"134,135\")")

# close channel 133 to ensure the disconnect between the MUX1 and MUX2
# multiplexer banks
instrument_write("channel.multiple.close(\"133\")")

for s_chan in source_channel_list:
    # close the source channel
    instrument_write("channel.multiple.close(\"{0}\"".format(s_chan))
    for m_chan in measure_channel_list:
        # close the test point measurement channel
        instrument_write("channel.multiple.close(\"{0}\")".format(m_chan))

        # insert a delay representative of the measurement activity performed
        # by the external instrument
        time.sleep(0.5)

        # open the test point measurement channel
        instrument_write("channel.multiple.open(\"{0}\")".format(m_chan))

    # open the source channel
    instrument_write("channel.multiple.open(\"{0}\"".format(s_chan))


instrument_disconnect(my_daq)

t2 = time.time()  # Stop the timer...

# Notify the user of completion and the data streaming rate achieved.
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2 - t1))

input("Press Enter to continue...")
exit()

