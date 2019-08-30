"""***********************************************************
*** Copyright Tektronix, Inc.                           ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************"""
import socket
import struct
import math
import time
import sys

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
	Function: instrument_query_binary(my_socket, my_command, expected_number_of_readings)
	
	Purpose: This function issues control commands to the target instrument with
                 the expectation that data will be returned. For this function
                 instance, the returned data is specifically) expected to be in
                 binary format. Note that this function does not handle directing
                 the target instrument to return its data in binary format - it is
                 the user's responsibility to understand/issue the commands that
                 manage the binary formats.

                 Binary formatting can promote either single or double floating point
                 format of IEEE Std 754. This function assumes the following defaults:
                     * Normal byte order (non-swapped)
                     * Single precision format
                     * Little endian byte order

	Parameters:
		my_socket - The TCP instrument connection object used for sending
			    and receiving data.
		my_command (string) - The command issued to the instrument to make it 
				      perform some action or service.
		expected_number_of_readings (int) - This is number of readings that
                                                    is being requested to be returned
                                                    from the instrument to the caller. 
	Returns:
		reply_string (string) - The requested information returned from the 
					target instrument. Obtained by way of a caller
					to instrument_read().

	Revisions:
		2019-08-29    JJB    Initial revision.
*********************************************************************************"""
def instrument_query_binary(my_socket, my_command, expected_number_of_readings):
    receive_size = expected_number_of_readings * sys.getsizeof(float())

    instrument_write(my_socket, my_command)
    response = my_socket.recv(receive_size)
    fmtStr = '%df' % expected_number_of_readings
    altResp = struct.unpack(fmtStr, response[2:-1]) # Note the index offset applied
                                                    # to the response data. This is
                                                    # applicable to a majority of
                                                    # Keithley measurment tools. If
                                                    # you choose to repurpose this
                                                    # code for use with equipment from
                                                    # another vendor
    return altResp


"""*********************************************************************************
	Many products need to be environmentally-stressed during performance testing. This is accomplished
        by placing the device in a chamber where the temperature can be set and controlled and soaking the
        DUT at the required set-point conditions. Temperature changes are not instantaneous so there is
        some wait time between scans. The DAQ6510 can monitor the environment until the target
        temperature has been reached at which point the instrument automatically begins the scan.
        
        This application example demonstrates how to use a DAQ6510 to initiate a scan based on the
        temperature of the environment around the device under test (DUT). This example will model a
        situation where resistance DUTs are measured after the temperature exceeds 30 °C.
*********************************************************************************"""
ip_address = "192.168.1.65"     # Place your instrument's IP address here.
my_port = 5025

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)                 # Establish a TCP/IP socket object
# Open the socket connection
instrument_connect(s, ip_address, my_port, 20000, 0, 1)

t1 = time.time()                    # Start the timer...

scan_count = 10
scan_interval = 10.0
monitor_channel = "110"                                                 # Make it flexible since this data logger allows it

instrument_write(s, "*RST")                                             # Reset the DAQ6510
instrument_write(s, "FUNC \"TEMP\", (@{0})".format(monitor_channel))    # Monitor temperature on this channel
instrument_write(s, "TEMP:TRAN TC, (@{0})".format(monitor_channel))     # Set transducer type to thermocouple
instrument_write(s, "TEMP:TC:TYPE K, (@{0})".format(monitor_channel))   # Set thermocouple type to K
instrument_write(s, "TEMP:UNIT CELS, (@{0})".format(monitor_channel))   # Set unit to Celsius
instrument_write(s, "TEMP:TC:RJUN:RSEL INT, (@{0})".format(monitor_channel))    # Set internal reference
instrument_write(s, "ROUT:SCAN:MON:CHAN (@{0})".format(monitor_channel))        # Establish the monitor channel
instrument_write(s, "ROUT:SCAN:MON:LIM:UPP 30")                         # Set upper limit to 30 Celsius degree
instrument_write(s, "ROUT:SCAN:MON:LIM:UPP 25")                         # Set lower limit to 25 Celsius degree
instrument_write(s, "ROUT:SCAN:MON:MODE UPP")                           # Set monitor mode to upper                             
instrument_write(s, "FUNC \"RES\", (@102:105)")                         # Scan resistance on channel 102 through 105
instrument_write(s, "RES:RANG:AUTO ON, (@102:105)")                     # Set auto range
instrument_write(s, "ROUT:CHAN:DEL 1.0, (@{0},102:105)".format(monitor_channel))# Apply a per-channel delay within the scan
instrument_write(s, "ROUTe:SCAN:CRE (@{0},102:105)".format(monitor_channel))    # Setup the scan list
instrument_write(s, "ROUT:SCAN:INT {0}".format(scan_interval))          # Set trigger interval between scans to 0 s
channel_count = int(instrument_query(s, "ROUT:SCAN:COUN:STEP?", 16).rstrip()) # Get the number of channels configured in the scan
instrument_write(s, "ROUT:SCAN:COUN:SCAN {0}".format(scan_count))       # Set the number of times the scan will be executed
sample_count = scan_count*channel_count
instrument_write(s, "TRAC:CLE")                                         # Clear the reading buffer
instrument_write(s, "TRACe:POINts {0}, \"defbuffer1\"".format(sample_count))    # Set the number of points in the reading buffer

instrument_write(s, "*WAI")                                             # Allow time for all settings to take effect
instrument_write(s, "INIT")                                             # Initiate the scan

# Establish a loop which will iteratively extract the readings from the reading buffer
start_index = 1
end_index = channel_count
estimated_receive_size = 16 * channel_count         # Estimate the ASCII character receveive byte size as
                                                    # 14 characters per reading + 1 comma/rdg + 1 terminator
                                                    # times the number of readings you want to extract per query.
accumulated_readings = 0
while accumulated_readings < sample_count:
    readings_count = int(instrument_query(s, "TRACe:ACTual? \"defbuffer1\"", 16).rstrip())
    time.sleep(0.5)                                 # Add a short delay to minimize communications traffic
    if readings_count >= end_index:
        monitor_buffer_index = int(instrument_query(s, "TRACe:ACTual? \"defbuffer2\"", 16).rstrip())
        print(monitor_buffer_index)
        response = instrument_query(s, "TRACe:DATA? {0}, {1}, \"defbuffer2\", READ".format(monitor_buffer_index, monitor_buffer_index), 16)
        print(response)
        response = instrument_query(s, "TRACe:DATA? {0}, {1}, \"defbuffer1\", READ".format(start_index, end_index),
                                    estimated_receive_size)
        print(response)
        start_index += channel_count
        end_index += channel_count
        accumulated_readings += channel_count

instrument_write(s, "DISP:SCR SWIPE_SCAN")                              # Switch to the HOME UI after scanning and processing
                                                                        # is complete.
                                                                        
# Close the socket connection
instrument_disconnect(s)
t2 = time.time()

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
