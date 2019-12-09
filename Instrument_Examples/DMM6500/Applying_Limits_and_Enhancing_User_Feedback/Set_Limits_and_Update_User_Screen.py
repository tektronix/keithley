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
        instrument_write(my_socket, "reset()")
    if do_clear == 1:
        instrument_write(my_socket, "clear()")
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
    time.sleep(0.1)
    return instrument_read(my_socket, receive_size)


"""*********************************************************************************

	This example application demonstrates the use of applying limits checking
	on the touchscreen series of DMMs from Tektonix/Keithley, and is appliable
	to the following models:
	    a. DMM6500
	    b. DMM7510
	    c. DMM7512
	    d. DAQ6510

*********************************************************************************"""
daq_ip_address = "192.168.1.165"  # Define your instrument's IP address here.
daq_port = 5025  # Define your instrument's port number here.

do_instr_reset = 1
do_instr_clear = 0
do_instr_id_query = 1

t1 = time.time()

# Open the socket connections...
s_daq = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  # Establish a TCP/IP socket object
instrument_connect(s_daq, daq_ip_address, daq_port, 20000, do_instr_reset, do_instr_clear, do_instr_id_query)

instrument_write(s_daq, "reset()")
# set the instrument to measure voltage
instrument_write(s_daq, "dmm.measure.func = dmm.FUNC_DC_VOLTAGE")
# set the range to 10 V
instrument_write(s_daq, "dmm.measure.range = 10")
# set the nplc to 0.1
instrument_write(s_daq, "dmm.measure.nplc = 1.0")
# disable auto clearing for limit 1
instrument_write(s_daq, "dmm.measure.limit[1].autoclear = dmm.OFF")
# set the beeper to sound if the reading exceeds the limits for limit 1
instrument_write(s_daq, "dmm.measure.limit[1].audible = dmm.AUDIBLE_FAIL")
# enable limit 1 checking for voltage measurements
instrument_write(s_daq, "dmm.measure.limit[1].enable = dmm.ON")
instrument_write(s_daq, "dmm.measure.limit[1].high.value = 5.05")
instrument_write(s_daq, "dmm.measure.limit[1].low.value = 4.95")

# clear limit 1 conditions
instrument_write(s_daq, "dmm.measure.limit[1].clear()")

# take a measurement
reading = float(instrument_query(s_daq, "print(dmm.measure.read())", 32).strip('\n'))
print("Measured: {0} V".format(reading))

# Change over to the USER swipe screen and clear any existing text
instrument_write(s_daq, "display.clear()")
instrument_write(s_daq, "display.changescreen(display.SCREEN_USER_SWIPE)")

limit_state = instrument_query(s_daq, "print(dmm.measure.limit[1].fail)", 32)
if "FAIL_HIGH" in limit_state:
    instrument_write(s_daq, "display.settext(display.TEXT1, \"FAIL\")")
    instrument_write(s_daq, "display.settext(display.TEXT2, \"Address failure conditions!!!\")")
else:
    instrument_write(s_daq, "display.settext(display.TEXT1, \"\")")
    instrument_write(s_daq, "display.settext(display.TEXT2, \"\")")


instrument_disconnect(s_daq)
t2 = time.time()

# Notify the user of completion and the data streaming rate achieved.
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2 - t1))

input("Press Enter to continue...")
exit()

