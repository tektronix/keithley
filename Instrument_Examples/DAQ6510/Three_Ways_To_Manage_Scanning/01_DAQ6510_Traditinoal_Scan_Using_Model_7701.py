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

	This example application demonstrates the tradition means of scanning
	channels to capture multiple data points.
            A. All channels of interest are configured for their measurement
               function with desired attributes.
            B. We size the internal data buffer to accomodate all the scan data.
               In this case, 31 channels of two Model 7701 multiplexer cards
               are monitored every 30s. (The scaning of all channels takes
               approximately 20s with the measurement configuration shown and
               an additional 10s is added.) We want to scan for 5 days, and loop
               this 21600 times; total number of points is 1,339,200. 
            C. The scanning is armed and initiated.
            D. The data buffered is monitored during the scanning process and,
               when each new scan of all channels occurs, the new data are extracted.
            E. New data are added to a *.csv file. 

*********************************************************************************"""
my_ip_address = "192.168.1.65"  # Define your instrument's IP address here.
my_port = 5025  # Define your instrument's port number here.

do_instr_reset = 1
do_instr_clear = 1
do_instr_id_query = 1

t1 = time.time()

# Open the socket connections...
my_daq = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  # Establish a TCP/IP socket object
my_daq.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
instrument_connect(my_daq, my_ip_address, my_port, 20000, do_instr_reset, do_instr_clear, do_instr_id_query)

# Configure the 4W RTD channels.
instrument_write(my_daq, "TRAC:CLE")
instrument_write(my_daq, "TRAC:POIN 1339200, \"defbuffer1\"")

instrument_write(my_daq, "FUNC \"VOLT:DC\", (@102:116,118:132,202:216,218:232)")        # temperature
instrument_write(my_daq, "VOLT:DC:RANG:AUTO ON, (@102:116,118:132,202:216,218:232)")    # auto range on
instrument_write(my_daq, "VOLT:DC:DEL:AUTO ON, (@102:116,118:132,202:216,218:232)")     # auto delay on
instrument_write(my_daq, "VOLT:DC:NPLC 5, (@102:116,118:132,202:216,218:232)")          # NPLC of 5
instrument_write(my_daq, "DISP:VOLT:DC:DIG 6")                                          # display digits 6.5
instrument_write(my_daq, "VOLT:DC:AZER ON, (@102:116,118:132,202:216,218:232)")         # auto zero on
instrument_write(my_daq, "VOLT:DC:INP MOHM10, (@102:116,118:132,202:216,218:232)")      # auto zero on
instrument_write(my_daq, "COUN 1, (@102:116,118:132,202:216,218:232)")                  # measure count of 1
instrument_write(my_daq, "VOLT:DC:LINE:SYNC ON, (@102:116,118:132,202:216,218:232)")    # line synchronization enabled
instrument_write(my_daq, "VOLT:DC:UNIT VOLT, (@102:116,118:132,202:216,218:232)")       # units of volts
instrument_write(my_daq, "VOLT:DC:REL 0, (@102:116,118:132,202:216,218:232)")           # relative offset of 0
instrument_write(my_daq, "VOLT:DC:AVER OFF, (@102:116,118:132,202:216,218:232)")        # averaging off
instrument_write(my_daq, "CALC1:VOLT:DC:MATH:STAT OFF, (@102:116,118:132,202:216,218:232)")   # math off
instrument_write(my_daq, "CALC2:VOLT:DC:LIM1:STAT OFF, (@102:116,118:132,202:216,218:232)")   # limit 1 off
instrument_write(my_daq, "CALC2:VOLT:DC:LIM2:STAT OFF, (@102:116,118:132,202:216,218:232)")   # limit 2 off
instrument_write(my_daq, "ROUT:DEL 0, (@102:116,118:132,202:216,218:232)")              # channel delay 0


instrument_write(my_daq, "FUNC \"TEMP\", (@101,201)")       # temperature
instrument_write(my_daq, "TEMP:TRAN FRTD, (@101,201)")      # 4W RDT transducer
instrument_write(my_daq, "TEMP:RTD:FOUR PT100, (@101,201)") # device of PT100
instrument_write(my_daq, "TEMP:ODET ON, (@101,201)")        # open lead detection on
instrument_write(my_daq, "TEMP:OCOM ON, (@101,201)")        # offset compensation on
instrument_write(my_daq, "TEMP:UNIT CELS, (@101,201)")       # units of celcius
instrument_write(my_daq, "TEMP:DEL:AUTO ON, (@101,201)")    # auto delay on
instrument_write(my_daq, "TEMP:NPLC 5, (@101,201)")         # NPLC of 5
instrument_write(my_daq, "DISP:TEMP:DIG 3")                 # display digits 3.5
instrument_write(my_daq, "TEMP:AZER ON, (@101,201)")        # auto zero on
instrument_write(my_daq, "COUN 1, (@101,201)")              # measure count of 1
instrument_write(my_daq, "TEMP:LINE:SYNC ON, (@101,201)")   # line synchronization enabled
instrument_write(my_daq, "TEMP:REL 0, (@101,201)")          # relative offset of 0
instrument_write(my_daq, "TEMP:AVER OFF, (@101,201)")       # averaging off
instrument_write(my_daq, "CALC1:TEMP:MATH:STAT OFF, (@101,201)")   # math off
instrument_write(my_daq, "CALC2:TEMP:LIM1:STAT OFF, (@101,201)")   # limit 1 off
instrument_write(my_daq, "CALC2:TEMP:LIM2:STAT OFF, (@101,201)")   # limit 2 off
instrument_write(my_daq, "ROUT:DEL 0, (@101,201)")          # channel delay 0

instrument_write(my_daq, "ROUTe:CSO (@ALLSLOTS), OFF")      # disable commonside ohms
instrument_write(my_daq, "*WAI")
instrument_write(my_daq, "ROUT:SCAN:COUN:SCAN 21600")           # this is the count based on the typical
                                                            #    scan duration for this setup for the
                                                            #    thirty channels in the scan
instrument_write(my_daq, "ROUT:SCAN:INT 30.0")              # 30s scan interval
instrument_write(my_daq, "ROUT:SCAN:CRE (@101:116,118:132,201:216,218:232)")
instrument_write(my_daq, "*WAI")
instrument_write(my_daq, "INIT")
instrument_disconnect(my_daq)       # disconnect after instrument configuration

time.sleep(0.5)

# Execute pseudo-scan sequence....
channel_list = (["101", "102", "103", "104", "105", "106", "107", "108", "109", "110", "111",
                 "112", "113", "114", "115", "116", "118", "119", "120", "121", "122", "123",
                 "124", "125", "126", "127", "128", "129", "130", "131", "132",
                 "201", "202", "203", "204", "205", "206", "207", "208", "209", "210", "211",
                 "212", "213", "214", "215", "216", "218", "219", "220", "221", "222", "223",
                 "224", "225", "226", "227", "228", "229", "230", "231", "232"])

# Establish the scan looping for 120 hours....
do_instr_reset = 0
do_instr_clear = 0
do_instr_id_query = 0

output_data_path = time.strftime("./Data_Archive/data_%Y-%m-%d_%H-%M-%S.csv")   # This is the output file that is created which
                                                                                # will hold your readings provided in ASCII
                                                                                # format in a text file.
write_data(output_data_path, "DAQ6510 Scan Data")
write_data(output_data_path, ("101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,118,119,120,121,"
                              "122,123,124,125,126,127,128,129,130,131,132,201,202,203,204,205,206,207,208,209,"
                              "210,211,212,213,214,215,216,218,219,220,221,222,223,224,225,226,227,228,229,230,"
                              "231,232"))

j = 0
actual_readings = 0
chunk_size = 31
start_index = 1
end_index = chunk_size
target_total = chunk_size * 21600 * 2
while end_index <= target_total:
    my_daq = socket.socket(socket.AF_INET, socket.SOCK_STREAM)  # Establish a TCP/IP socket object
    my_daq.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
    instrument_connect(my_daq, my_ip_address, my_port, 20000, do_instr_reset, do_instr_clear, do_instr_id_query)

    write_string = ""

    actual_readings = int(instrument_query(my_daq, "TRAC:ACT? \"defbuffer1\"", 32).strip())
    while actual_readings < end_index:
        actual_readings = int(instrument_query(my_daq, "TRAC:ACT? \"defbuffer1\"", 32).strip())

    write_string = instrument_query(my_daq, "TRAC:DATA? {0}, {1}, \"defbuffer1\"".format(start_index, end_index), 1024)
    start_index += chunk_size
    end_index += chunk_size

    instrument_disconnect(my_daq)
    # print(write_string)
    write_data(output_data_path, write_string)


t2 = time.time()  # Stop the timer...

# Notify the user of completion and the data streaming rate achieved.
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2 - t1))

input("Press Enter to continue...")
exit()

