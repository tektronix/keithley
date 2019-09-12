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
	This application example demonstrates how to use a Model 2450, 2460, or 2461 to measure a low-resistance
        device.

        You may need to make low-resistance measurements (<10 Ω) in a number of applications. Typical
        applications include continuity testing of cables and connectors, substrate vias, and resistors.
        Typically, you make these resistance measurements by forcing a current and measuring the resulting
        voltage drop. The Model 2450 automatically calculates the resistance. The measured voltage is
        usually in the mV range or less. Built-in features of the Model 2450 optimize low-resistance
        measurements, such as remote sensing and offset compensation.
*********************************************************************************"""
ip_address = "192.168.1.25"     # Place your instrument's IP address here.
my_port = 5025

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)                 # Establish a TCP/IP socket object
# Open the socket connection
instrument_connect(s, ip_address, my_port, 20000, 0, 1)

t1 = time.time()                    # Start the timer...

instrument_write(s, "*RST")                                             # Reset the SMU
instrument_write(s, "TRIG:LOAD \"SimpleLoop\", 100")                    # Configure Simple Loop trigger model template to make 100 readings.
instrument_write(s, "SENS:FUNC \"RES\"")                                # Set to measure resistance.
instrument_write(s, "SENS:RES:RANG:AUTO ON")                            # Turn on auto range.
instrument_write(s, "SENS:RES:OCOM ON")                                 # Enable offset compensation.
instrument_write(s, "SENS:RES:RSEN ON")                                 # Set to use 4-wire sense mode.
instrument_write(s, "DISP:SCR SWIPE_GRAPh")                             # Show the GRAPH swipe screen.
instrument_write(s, "OUTP ON")                                          # Turn on the output.
instrument_write(s, "INIT")                                             # Initiate readings
instrument_write(s, "*WAI")                                             # Allow time for all measurements to complete.
readings_1 = instrument_query(s, "TRAC:DATA? 1, 50, \"defbuffer1\", READ, REL", (16*100)).rstrip()
readings_2 = instrument_query(s, "TRAC:DATA? 51, 100, \"defbuffer1\", READ, REL", (16*100)).rstrip()
instrument_write(s, "OUTP OFF")                                          # Turn off the output.

#print(readings_1)
#print(readings_2)
rdgs_list_1 = readings_1.split(',')
rdgs_list_2 = readings_2.split(',')

counter = 1
index = 0
print("{0:10} | {1:<10} | {2:<10}".format("Rdg.Num.", "Resistance", "Time"))
while counter <= 50:
    print("{0:10} | {1:0.4E} | {2:0.4f}".format(counter, float(rdgs_list_1[index]), float(rdgs_list_1[index+1])))
    counter += 1
    index += 2

index = 0      
while counter <= 100:
    print("{0:10} | {1:0.4E} | {2:0.4f}".format(counter, float(rdgs_list_2[index]), float(rdgs_list_2[index+1])))
    counter += 1
    index += 2
    
# Close the socket connection
instrument_disconnect(s)
t2 = time.time()

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
