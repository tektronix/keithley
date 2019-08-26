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
	This example application demonstrates how to use the DAQ6510 to perform
	complex multi-channel, mixed function scanning in a production-test
	environment. The DAQ6510 can perform more than one function in a multichannel
	scan, providing a range of dataacquisition options in a single test.

	In this production environment the DAQ6510 is:
        - Integrated into a test stand.
        - Wired to a fixture that is connected to an active device under test (DUT).
        - Quickly capturing DC volts and current, temperature, and AC volts and current.
        
        Prior to the start of the scan, you can step through each of the configured
        channels on the DAQ6510, which allows you to troubleshoot the test
        configuration. This allows you to view the readings of individually closed
        channels to ensure that connections to the DUT are secure. 
*********************************************************************************"""
ip_address = "192.168.1.65"     # Place your instrument's IP address here.
my_port = 5025

s = socket.socket()                 # Establish a TCP/IP socket object
# Open the socket connection
instrument_connect(s, ip_address, my_port, 20000, 0, 1)

t1 = time.time()                    # Start the timer...

instrument_write(s, "reset()")                                     # Reset the DAQ6510
# Establish channel settings for the scan card configuration...
instrument_write(s, "channel.setdmm(\"101\", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_AC_VOLTAGE)")     # Set channel 101 for ACV
instrument_write(s, "channel.setdmm(\"101\", dmm.ATTR_MEAS_DETECTBW, dmm.DETECTBW_30HZ)")       # Set channel 101, low-end bandwidth to 30Hz
instrument_write(s, "channel.setdmm(\"102:110\", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_VOLTAGE)") # Set channels 102-110 for DCV

# Set channels 111-114 for Temperature measurement using Type K
# thermocouples with a simulated reference junction set to 23°C
instrument_write(s, "channel.setdmm(\"111:114\", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE)")
instrument_write(s, "channel.setdmm(\"111:114\", dmm.ATTR_MEAS_TRANSDUCER, dmm.TRANS_THERMOCOUPLE)")
instrument_write(s, "channel.setdmm(\"111:114\", dmm.ATTR_MEAS_THERMOCOUPLE, dmm.THERMOCOUPLE_K)")
instrument_write(s, "channel.setdmm(\"111:114\", dmm.ATTR_MEAS_REF_JUNCTION, dmm.REFJUNCT_SIMULATED)")
instrument_write(s, "channel.setdmm(\"111:114\", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE, dmm.ATTR_MEAS_SIM_REF_TEMP, 23)")

instrument_write(s, "channel.setdmm(\"121\", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_AC_CURRENT)") # Set channel 121 to measure ACI
instrument_write(s, "channel.setdmm(\"122\", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_CURRENT)") # Set channel 122 to measure DCI

instrument_write(s, "channel.setlabel(\"101\", \"ACSource\")")      # Apply a label to channel 101
instrument_write(s, "channel.setlabel(\"111\", \"Reg12VTemp\")")    # Apply a label to channel 111
instrument_write(s, "channel.setlabel(\"112\", \"Reg5VTemp\")")     # Apply a label to channel 112
instrument_write(s, "channel.setlabel(\"113\", \"LoadTemp1\")")     # Apply a label to channel 113
instrument_write(s, "channel.setlabel(\"114\", \"LoadTemp2\")")     # Apply a label to channel 114

instrument_write(s, "scan.create(\"101:114,121,122\")")         # Generate the scan...
instrument_write(s, "display.watchchannels = \"101:114,121,122\"")         # Define which channels are shown on the display readback and progress bar

scan_count = 10
channel_count = 16
instrument_write(s, "scan.scancount = {0}".format(scan_count))  # Set the number scans
instrument_write(s, "defbuffer1.clear()")                       # Clear and size the buffer
instrument_write(s, "defbuffer1.capacity = {0}".format(scan_count*channel_count))
instrument_write(s, "trigger.model.initiate()")                 # Initiate the scan
instrument_write(s, "waitcomplete()")                           # Wait for scan completion
time.sleep(45.0)

# Extract the data...
print(instrument_query(s, "printbuffer(1, defbuffer1.n, defbuffer1, defbuffer1.readings, defbuffer1.channels)", 2048))

# Close the socket connection
instrument_disconnect(s)
t2 = time.time()

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
