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
        print(cmd)
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
	Function: load_script_file_onto_keithley_instrument(my_script_file, my_socket)
	
	Purpose: Copy the contents of a specific script file off of the computer 
	         and upload onto the target instrument. 

	Parameters:
		my_script_file (string) - The script file/path (ASCII text format) that 
					  will be read from the computer and sent to the
					  instrument. 
		my_socket - The TCP instrument connection object used for 
				      sending and receiving data. 
	Returns:
		None

	Revisions:
		2019-07-30    JJB    Initial revision.
*********************************************************************************"""
def load_script_file(my_script_file, my_socket):
    # This function opens the functions.lua file in the same directory as
    # the Python script and trasfers its contents to the DMM7510's internal
    # memory. All the functions defined in the file are callable by the
    # controlling program. 
    func_file = open(my_script_file, "r")
    contents = func_file.read()
    func_file.close()

    send_buffer = "if loadfuncs ~= nil then script.delete('loadfuncs') end"
    instrument_write(my_socket, send_buffer)
    send_buffer = "loadscript loadfuncs\n{0}\nendscript".format(contents)
    instrument_write(my_socket, send_buffer)
    send_buffer = "loadfuncs()"
    print(instrument_query(my_socket, send_buffer, 100))
    return    


"""*********************************************************************************
	This example copies the contents of a script file on the host computer and
	sends to the LAN-connected instrument. 
*********************************************************************************"""
ip_address = "192.168.1.2"     # Place your instrument's IP address here.
my_port = 5025
output_data_path = time.strftime("data_%Y-%m-%d_%H-%M-%S.csv")   # This is the output file that is created which
                                                                 # will hold your readings provided in ASCII
                                                                 # format in a text file. """
functions_path = "functions_V4.lua" # This file holds the set of TSP (Lua-
                                    # based) functions that are called by
                                    # the Python script to help minimize the
                                    # amount of bytes needed to setup up and
                                    # more importantly, extract readings from
                                    # the instrument. The file is opened and """

s = socket.socket()                 # Establish a TCP/IP socket object
# Open the socket connection
instrument_connect(s, ip_address, my_port, 20000, 1, 1)

load_script_file(functions_path, s)

t1 = time.time()                    # Start the timer...
instrument_write(s, "do_beep(0.5, 4000)")

# Close the socket connection
instrument_disconnect(s)
t2 = time.time()

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
