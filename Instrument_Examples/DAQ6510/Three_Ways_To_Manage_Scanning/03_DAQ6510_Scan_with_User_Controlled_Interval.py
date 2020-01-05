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
    altResp = struct.unpack(fmtStr, response[2:-1])  # Note the index offset applied
    # to the response data. This is
    # applicable to a majority of
    # Keithley measurment tools. If
    # you choose to re-purpose this
    # code for use with equipment from
    # another vendor
    return altResp


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

	This example application demonstrates the use of traditional style scanning
	but using a single scan at a time. This method was preferred for the potential
	for flexibility of the interval between scans.

            A. All channels of interest are configured for their measurement
               function with desired attributes.
            B. Labels per channel are added. This makes the channel definitions
               more verbose and visually consumable via the instrument front
               panel and in the buffered data if we were to choose to also request
               the channel labels when data are extracted. 
            C. We size the internal data buffer to its minimum since, in this example,
               we only monitor four channels and we want the data off the instrument
               and stored on the controlling instrument (whether it is a PC, a
               Raspberry Pi, a PLC, or other).
            D. We have seeded this example with the commands to save the measurement
               and scan configuration and the means to recall it. 
            E. The scan is armed and initiated with each call to INIT. We also
               monitor the volume of data in the buffer such that when all readings
               are present then all can be extracted at once. 
            F. The data are extracted in binary format to help reduce the volume of
               bytes transmitted over the communications interface. This increases
               performance efficiency that is most beneficial when we need to move
               large volumes of data from the instrument to the controller.
            G. New data are added to a *.csv file. 


*********************************************************************************"""
my_ip_address = "192.168.1.165"  # Define your instrument's IP address here.
my_port = 5025  # Define your instrument's port number here.

do_instr_reset = 1
do_instr_clear = 1
do_instr_id_query = 1
output_data_path = time.strftime("./Data_Archive/data_%Y-%m-%d_%H-%M-%S.csv")   # This is the output file that is created which
                                                                                # will hold your readings provided in ASCII
                                                                                # format in a text file.
t1 = time.time()

# Open the socket connections...
my_daq = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  # Establish a TCP/IP socket object
my_daq.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
instrument_connect(my_daq, my_ip_address, my_port, 20000, do_instr_reset, do_instr_clear, do_instr_id_query)

# Configure the DCV channels.
instrument_write(my_daq, "FUNC \"VOLT:DC\", (@101,103,105,107)")        # dc volts
instrument_write(my_daq, "VOLT:DC:RANG:AUTO OFF, (@101,103,105,107)")   # auto range on
instrument_write(my_daq, "VOLT:DC:RANG 10, (@101,103,105,107)")
instrument_write(my_daq, "VOLT:DC:NPLC 0.0005, (@101,103,105,107)")     # NPLC of 5
instrument_write(my_daq, "VOLT:DC:AZER OFF, (@101,103,105,107)")        # auto zero on

instrument_write(my_daq, "ROUT:CHAN:LAB \"Cell1\", (@101)")         # label channel
instrument_write(my_daq, "ROUT:CHAN:LAB \"Cell2\", (@103)")         # label channel
instrument_write(my_daq, "ROUT:CHAN:LAB \"Cell3\", (@105)")         # label channel
instrument_write(my_daq, "ROUT:CHAN:LAB \"Cell4\", (@107)")         # label channel
instrument_write(my_daq, "DISP:WATC:CHAN (@101,103,105,107)")
instrument_write(my_daq, "FORM:DATA SRE")                           # request that the buffer data be returned in
                                                                    #   IEEE Std. 754 single-precision format; another
                                                                    #   option is REAL; see page 407 of the Reference
                                                                    #   Manual for more details
instrument_write(my_daq, ":FORM:BORD SWAP")                         # sets the byte order for the binary transfer format;
                                                                    #   default of SWAP (for little endian), the other
                                                                    #   option is NORMal (or big endian); see page 406
                                                                    #   of the Reference Manual for more details
instrument_write(my_daq, "ROUT:SCAN:COUN:SCAN 1")                   # set the number of times the scan will be executed
instrument_write(my_daq, "ROUTe:SCAN:CRE (@101,103,105,107)")       # setup the scan list
instrument_write(my_daq, "TRAC:CLE")                                # clear the active buffer
instrument_write(my_daq, "TRAC:POIN 10, \"defbuffer1\"")            # set the buffer size; note the minimum is 10

instrument_write(my_daq, "*WAI")                                      # wait for settings to take hold
# instrument_write(my_daq, "*SAV 0")                                  # commit the setup to memory
# instrument_write(my_daq, "*RCL 0")

scan_interval = 30.0
for j in range(0, 40320):
    t3 = time.time()
    instrument_write(my_daq, "INIT")                                # trigger the scan....
    accumulated_readings = 0
    while accumulated_readings < 4:                                 # loop to ensure readings are present in the buffer
        accumulated_readings = int(instrument_query(my_daq, "TRAC:ACT?", 16).rstrip())

    # IMPORTANT NOTE: Binary transfers start with '#0' and end with a new line. When performing binary-to-floating
    # point conversions make certain these characters are stripped or excluded from the binary-transferred readings.
    response = instrument_query_binary(my_daq, "TRACe:DATA? 1, 4, \"defbuffer1\", READ", 4)     # extract readings
    print(response)
    # parse the tuple into a string then write to file...
    write_string = ""
    for rdg in response:
        write_string += (str(rdg) + ",")
    write_data(output_data_path, write_string)
    t4 = time.time()
    time.sleep(scan_interval - (t4-t3))

instrument_disconnect(my_daq)       # disconnect after instrument configuration

t2 = time.time()  # Stop the timer...

# Notify the user of completion and the data streaming rate achieved.
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2 - t1))

input("Press Enter to continue...")
exit()

