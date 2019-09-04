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
	To measure the leakage current or insulation resistance of a device, you need to apply a fixed voltage
        to the device and measure the resulting current. Depending on the device under test, the measured
        current is typically very small, usually less than 10 nA.

        This application consists of two examples that demonstrate:
        • How to use the Model 2450 to perform leakage current measurements on a capacitor
        • How to use the Model 2450 to measure insulation resistance between the two conductors of a
          coaxial cable

        The only difference between these two application examples is that when you measure leakage
        current, the results are returned in units of amperes. When you measure insulation resistance, the
        results are returned in units of ohms.

        The leakage current application applies the voltage for a specified period because the device needs
        time to charge. In some cases, the resulting current is measured the entire time the device is biased.
        In other cases, only one reading is made at the end of the soak period.
*********************************************************************************"""
ip_address = "192.168.1.25"     # Place your instrument's IP address here.
my_port = 5025

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)           # Establish a TCP/IP socket object
instrument_connect(s, ip_address, my_port, 20000, 0, 1)         # Open the socket connection

t1 = time.time()                                                # Start the timer...

instrument_write(s, "reset()")                                          # Reset the SMU
instrument_write(s, "smu.source.func = smu.FUNC_DC_VOLTAGE")            # Set to source voltage.
instrument_write(s, "smu.source.level = 20")                            # Set the source voltage to 20 V.
instrument_write(s, "smu.source.ilimit.level = 10e-3")                  # Set the current limit to 10 mA.
instrument_write(s, "smu.measure.func = smu.FUNC_DC_CURRENT")           # Set the instrument to measure current.
instrument_write(s, "smu.measure.terminals = smu.TERMINALS_REAR")       # Set to use rear-panel terminals.
instrument_write(s, "smu.measure.autorange = smu.ON")                   # Set the current range to autorange.
instrument_write(s, "smu.measure.nplc = 1")                             # Set the number of power line cycles to 1.
instrument_write(s, "trigger.model.load(\"DurationLoop\", 60, 0.2)")    # Load the Duration Loop trigger model to run
                                                                        # for 60 s at 200 ms intervals.
instrument_write(s, "smu.source.output = smu.ON")                       # Turn on the output.
instrument_write(s, "trigger.model.initiate()")                         # Initiate readings
# instrument_write(s, "waitcomplete()")                                   # Allow time for all measurements to complete.

# Calculate the number of readings that will be collected.
expected_readings_count = int((run_duration / sample_interval) + 1)
j = 1
# Format a column header for the instrument feedback.
print("{0:10} | {1:<10} | {2:<10}".format("Rdg.Num.", "Time (s)", "Current (A)"))
while j <= expected_readings_count:
    time.sleep(sample_interval)
    # Check to make certain readings are in the buffer to extract. 
    end_index = int(instrument_query(s, "print(defbuffer1.n)").rstrip())
    if end_index >= j:
        # Get the reading + relative timestamp pairs out one at a time and print to the display. 
        temp_list = instrument_query(s, "printbuffer({0}, {1}, defbuffer1.relativetimestamps, defbuffer1.readings)".
                                     format(j, j),(16*2)).rstrip().split(',')
        print("{0:10} | {1:0.4f} | {2:0.4E}".format(counter, float(temp_list[0]), float(temp_list[1])))
        j += 1

instrument_write(s, "smu.source.level = 0")                             # Discharge the capacitor to 0 V.
instrument_write(s, "smu.source.output = smu.OFF")                      # Turn off the output.
    
# Close the socket connection
instrument_disconnect(s)
t2 = time.time()

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
