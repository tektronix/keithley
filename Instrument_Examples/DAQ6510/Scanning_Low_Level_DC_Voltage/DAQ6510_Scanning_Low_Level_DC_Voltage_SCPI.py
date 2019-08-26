"""***********************************************************
*** Copyright Tektronix, Inc.                           ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************"""
import socket
import struct
import math
import time

echo_cmd = 1


"""*********************************************************************************
	Function: instrument_connect(my_socket, ip_address string, my_port int) 
	
	Purpose: Open an instance of an instrument object for remote communication
		 over LAN/Ethernet.

	Parameters:
                my_socket - Instance of a socket object.
                
		ip_address (string) - The TCP/IP address string associated with the
                                      target instrument. 
		my_port (int) - The instrument connection port. 

	Returns:
		my_socket - Updated instance of a socket object that includes
                            attributes of a valid connection. 

	Revisions:
		2019-07-30    JJB    Initial revision.
*********************************************************************************"""
def instrument_connect(my_socket, my_address, my_port, timeout, do_reset, do_id_query):
    my_socket.connect((my_address, my_port)) # input to connect must be a tuple
    my_socket.settimeout(timeout)
    if do_reset == 1:
        instrument_write(my_socket, "*RST")
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
	
	Purpose: Issue controlling commands to the target instrument.

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
	
	Purpose: Break the LAN/Ethernet connection between the controlling computer
			 and the target instrument.

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
	
	Purpose: Break the LAN/Ethernet connection between the controlling computer
		 and the target instrument.

	Parameters:
		my_socket - The TCP instrument connection object used for sending
			    and receiving data.
		my_command (string) - The command issued to the instrument to make it 
				      perform some action or service. 
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
	This application example demonstrates how to use the DAQ6510 to accurately
	measure DC voltage in a variety of ranges. To ensure accurate data, the
	NPLC (Number of Power Line Cycles) and autozero options are used for
	this test.

        The NPLC setting can be used to help reduce the induced noise originating
        from nearby AC power-conditioning circuits. A desktop power supply or
        power-transmission lines would generate this type of noise. Increasing NPLC
        cancels out this noise by integrating all sampled data collected in
        multiples of AC signal periods (n * 1/(transmission line frequency) seconds).
        The more AC line cycles used in the measurement, the more accurate the
        reading. The time required to conduct the scan also increases.
        
        The autozero function removes offset voltages that result from thermal
        EMFs. Thermal EMFs occur when there is a temperature difference at junctions
        consisting of different materials. For example, leads, instrument inputs,
        or card terminals. These EMFs adversely affect DCV measurement accuracy by
        offsetting the measured voltage.

        This example shows how to measure voltage in different ranges. To optimize
        scanning speed, you should set a fixed range. If speed is not an issue,
        the measurement range can be set to auto.
*********************************************************************************"""
ip_address = "192.168.1.65"     # Place your instrument's IP address here.
my_port = 5025

s = socket.socket()                 # Establish a TCP/IP socket object
# Open the socket connection
instrument_connect(s, ip_address, my_port, 20000, 0, 1)

t1 = time.time()                    # Start the timer...

instrument_write(s, "*RST")                                     # Reset the DAQ6510
channel_count = 6
scan_count = 10
buffer_size = channel_count * scan_count

instrument_write(s, ":TRAC:POIN {0}, \"defbuffer1\"".format(buffer_size))   # Set the buffer size (not necessary when using the default buffer, but added to show command use case)
instrument_write(s, ":ROUT:SCAN:BUFF \"defbuffer1\"")                       # Assign all scanned data to "defbuffer1"
nplc = 5
instrument_write(s, "FUNC 'VOLT:DC', (@101:106)")                           # Set channels functions to DCV

instrument_write(s, "VOLT:DC:RANG:AUTO ON, (@101:106)")                     # Set the channels ranges to auto range
instrument_write(s, "VOLT:DC:NPLC {0}, (@101:106)".format(nplc))            # Set NPLC to 5

instrument_write(s, "VOLT:DC:AZER ON, (@101:106)")                          # Set autozero function to ON
instrument_write(s, ":ROUTe:SCAN:CREAte (@101:106)")                            # Setup the scan list
instrument_write(s, "ROUT:SCAN:COUN:SCAN {0}".format(scan_count))           # Set autozero function to ON
instrument_write(s, "INIT")                                                 # Set autozero function to ON

j = 1
start_index = 1
end_index = channel_count
accumulated_readings = 0
while accumulated_readings < buffer_size:
    time.sleep(0.5)
    readings_count = int(instrument_query(s, "TRACe:ACTual?", 16).rstrip())
    if readings_count >= end_index:
        print(instrument_query(s, "TRACe:DATA? {0}, {1}, \"defbuffer1\", READ".format(start_index, end_index), 128))
        start_index += channel_count
        end_index += channel_count
        accumulated_readings += channel_count

# Close the socket connection
instrument_disconnect(s)
t2 = time.time()

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
