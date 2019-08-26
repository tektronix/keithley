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
	This application example demonstrates how to use the DAQ6510 to log
	thermocouple-based temperature measurement scans, using internal
	cold-junction compensation (CJC) correction, over a 24-hour period.

        This type of test is typically performed when a device under test (DUT)
        is placed in an environmental chamber and exposed to extreme conditions.
        The system captures data at different locations on the DUT. The data is
        then exported from the DAQ6510 to a computer where a thermal profile is
        generated. This thermal profile provides designers and consumers with a
        thorough understanding of the thermal operating characteristics of their
        device or product. 
*********************************************************************************"""
ip_address = "192.168.1.65"     # Place your instrument's IP address here.
my_port = 5025

functions_path = "functions_V4.lua"

s = socket.socket()                 # Establish a TCP/IP socket object
# Open the socket connection
instrument_connect(s, ip_address, my_port, 20000, 0, 1)

t1 = time.time()                    # Start the timer...

instrument_write(s, "*RST")                                     # Reset the DAQ6510
instrument_write(s, ":FUNCtion 'TEMPerature',(@101:110)")                       # Set up channel settings for Slot 1
                                                                                # temperature measurements for
                                                                                # channels 101 through 110.
instrument_write(s, ":SENSe:TEMPerature:TRANsducer TCouple,(@101:110)")
instrument_write(s, ":SENSe:TEMPerature:TCouple:TYPE K,(@101:110)")
instrument_write(s, ":SENSe:TEMPerature:TCouple:RJUNction:RSELect INTernal,(@101:110)")
instrument_write(s, ":SENSe:TEMPerature:ODETector ON,(@101:110)")
instrument_write(s, ":ROUTe:SCAN:CREAte (@101:110)")             # Set up Scan

instrument_write(s, ":ROUTe:SCAN:COUNt:SCAN 1440")              # Set the scan count to 24 hrs * 60 min/hr = 1440
instrument_write(s, ":ROUTe:SCAN:INTerval 60.0")                # Se the time between scans to 60 s
write_to_usb_drive = True
if write_to_usb_drive == True:
    my_output_file = time.strftime("scan24hr%Y%m%d.csv")
    instrument_write(s, ":ROUTe:SCAN:EXPORT \"/usb1/{0}\", SCAN, ALL".format(my_output_file)) # Ensure data gets written to a USB drive
                                                                                              # after each scan
instrument_write(s, ":ROUTe:SCAN:RESTart ON")                   # Enable scan restart after power failure
instrument_write(s, "*WAI")
instrument_write(s, ":INIT")

# Close the socket connection
instrument_disconnect(s)
t2 = time.time()

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
