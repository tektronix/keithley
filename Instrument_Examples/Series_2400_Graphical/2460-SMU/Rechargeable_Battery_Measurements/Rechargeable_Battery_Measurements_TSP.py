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
        instrument_write(my_socket, "reset()")
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
    time.sleep(0.1)
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


def write_data_to_file(file_and_path, write_string):
    ofile = open(output_data_path, "a")  # Open/create the target data
    ofile.write(write_string)
    ofile.close()                       # Close the data file.
    return

"""*********************************************************************************
	This example application demonstrates how to use a single 2460 to perform automated 
        battery discharge and charge cycle testing.
*********************************************************************************"""
ip_address = "192.168.1.26"     # Place your instrument's IP address here.
my_port = 5025
output_data_path = time.strftime("NMH_AA_%Y-%m-%d_%H-%M-%S.csv")

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)                 # Establish a TCP/IP socket object
# Open the socket connection
instrument_connect(s, ip_address, my_port, 20000, 0, 1)

t1 = time.time()                    # Start the timer...

instrument_write(s, "reset()")                                              # Reset the SMU
instrument_write(s, "defbuffer1.clear()")                                   # Clear the buffer
instrument_write(s, "smu.source.offmode = smu.OFFMODE_HIGHZ")               # Turn on high-impedance output mode.
instrument_write(s, "smu.measure.sense = smu.SENSE_4WIRE")                  # Set to 4-wire sense mode.
instrument_write(s, "smu.source.func = smu.FUNC_DC_VOLTAGE")                # Set to source voltage.
instrument_write(s, "smu.source.level = 0.9")                               # Set source level to 0.9 V.
#instrument_write(s, "smu.terminals = smu.TERMINALS_REAR")                  # Select the rear-panel connections.
instrument_write(s, "smu.source.readback = smu.ON")                         # Turn on source readback.
instrument_write(s, "smu.source.range = 0.9")                               # Set source range to 2 V.
instrument_write(s, "smu.source.ilimit.level = 2.5")                        # Set the source limit to 2.5 A.
instrument_write(s, "smu.measure.func = smu.FUNC_DC_CURRENT")               # Set to measure current.
instrument_write(s, "smu.measure.range = 4.0")                              # Set current range to 4 A.
instrument_write(s, "smu.source.output = smu.ON")                           # Turn on the output.
instrument_write(s, "waitcomplete()")
instrument_write(s, "display.changescreen(display.SCREEN_USER_SWIPE)")      # Change to the user swipe screen

iteration = 1
voltage_limit = 0.9001
current = []
voltage = []
seconds = []
hours = []

while True:
    instrument_write(s, "smu.measure.read(defbuffer1)")
    current.append(float(instrument_query(s, "printnumber(defbuffer1.readings[{0}])".format(iteration), (64)).rstrip()))
    print(current[iteration-1])
    voltage.append(float(instrument_query(s, "printnumber(defbuffer1.sourcevalues[{0}])".format(iteration, iteration), 64).rstrip()))
    print(voltage[iteration-1])
    seconds.append(float(instrument_query(s, "printnumber(defbuffer1.relativetimestamps[{0}])".format(iteration, iteration), 64).rstrip()))
    print(seconds[iteration-1])
    hours.append(seconds[iteration-1]/3600)
    log_string = "Voltage = {0}; Current = {1}; Hours = {2:0.3f}\n".format(voltage[iteration-1], current[iteration-1], hours[iteration-1])
    print(log_string)
    write_data_to_file(output_data_path, log_string)

    instrument_write(s, "display.settext(display.TEXT1, string.format(\"Voltage = %.4fV\", {0}))".format(voltage[iteration-1]))
    instrument_write(s, "display.settext(display.TEXT2, string.format(\"Current = %.2fA, Time = %.2fHrs\", {0}, {1}))".format(current[iteration-1], hours[iteration-1]))
    if voltage[iteration-1] <= voltage_limit:
        break
    time.sleep(10)
    iteration += 1

instrument_write(s, "smu.source.output = smu.OFF")                                          # Turn off the output.
    
# Close the socket connection
instrument_disconnect(s)
t2 = time.time()

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
