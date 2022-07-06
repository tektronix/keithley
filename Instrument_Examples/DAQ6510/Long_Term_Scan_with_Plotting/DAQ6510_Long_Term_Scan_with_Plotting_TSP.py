"""***********************************************************
*** Copyright Tektronix, Inc.                           ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************"""
import socket
import struct
import math
import time
import matplotlib
import matplotlib.pyplot as myplot

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


def write_data_to_file(file_and_path, write_string):
    ofile = open(output_data_path, "a")  # Open/create the target data
    ofile.write(write_string)
    ofile.close()                       # Close the data file.
    return

def generate_graph(readings_string, plotter):
    # Parse the input string. We will anticipate that both readings and relative timestamps
    # will be returned. We will only be using the relative time for the CH101 readings
    # to plot our data against via the x-axis.
    tmp_list = readings_string.split(',')
    print(tmp_list)
    relative_time = float(tmp_list[1])
    print(relative_time)
    ch101 = float(tmp_list[0])
    ch102 = float(tmp_list[2])
    ch103 = float(tmp_list[4])
    ch104 = float(tmp_list[6])
    ch105 = float(tmp_list[8])
    print(ch101)
    
    myplot.ion()
    fig, ax = plotter.subplots()
    ax.plot(relative_time, ch101, label = 'CH101')
    ax.plot(relative_time, ch102, label = 'CH102')
    ax.plot(relative_time, ch103, label = 'CH103')
    ax.plot(relative_time, ch104, label = 'CH104')
    ax.plot(relative_time, ch105, label = 'CH105')

    ax.set(xlabel='Time (s)', ylabel='Voltage (V)', title = 'Long Term Voltage Monitor')
    ax.legend()
    ax.grid(True)
    plotter.show()

    return plotter

def update_graph(readings_string, plotter):
    # Parse the input string. We will anticipate that both readings and relative timestamps
    # will be returned. We will only be using the relative time for the CH101 readings
    # to plot our data against via the x-axis.
    tmp_list = readings_string.split(',')
    relative_time = float(tmp_list[1])
    ch101 = float(tmp_list[0])
    ch102 = float(tmp_list[2])
    ch103 = float(tmp_list[4])
    ch104 = float(tmp_list[6])
    ch105 = float(tmp_list[8])

    #myplot.ion()
    fig, ax = plotter.subplots()
    ax.plot(relative_time, ch101)
    ax.plot(relative_time, ch102)
    ax.plot(relative_time, ch103)
    ax.plot(relative_time, ch104)
    ax.plot(relative_time, ch105)

    plotter.draw()
    plotter.pause(0.1)
    plotter.clf()
    # import matplotlib.pyplot as plt
    # import numpy as np
    #myplot.ion()
    #for i in range(50):
        #y = np.random.random([10,1])
        #myplot.plot(y)
        #myplot.draw()
        #myplot.pause(0.1)
        #myplot.clf()
    #exit()
    return plotter

"""*********************************************************************************

        Data logging often lends itself to reliability and stress testing models
        that can last for days, weeks, and even months. While not agressive in
        terms of collection, the individual running the test does require a high
        level of reliability to ensure consistent operation and persistent collection
        and preservation. With respect to the latter, this usually involves either
        saving to a controlling PC or, if the data logger is set up to run autonomously,
        to USB.
        
	This application example demonstrates how to use the DAQ6510 to log
	DC Voltage measurement scans over an extended period. The data are preserved
	both by streaming to the controlling PC and saving to USB. Additionally
	we enable the feaure which, in the event of a power failure, will restart the
	scanning and data logging operation. 

*********************************************************************************"""
ip_address = "192.168.1.62"     # Place your instrument's IP address here.
my_port = 5025

s = socket.socket()                 # Establish a TCP/IP socket object
# Open the socket connection
instrument_connect(s, ip_address, my_port, 20000, 0, 1)

t1 = time.time()                    # Start the timer...

channel_string = "101:105"
output_data_path = time.strftime("scandata_%Y-%m-%d_%H-%M-%S.csv")

instrument_write(s, "reset()")                                                                                      # Reset the DAQ6510  
instrument_write(s, "channel.setdmm(\"{0}\", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_VOLTAGE)".format(channel_string))  # Set up channel settings for Slot 1
                                                                                                                    # temperature measurements for
                                                                                                                    # the defined channels. 
# Configure the scan settings...
scan_count = 20160                                                                                                  # 60 minutes * 24 hours * no.of.days (2 wks = 14 days)
scan_interval = 10.0                                                                                                # 60 seconds = 1 minute
instrument_write(s, "scan.create(\"{0}\")".format(channel_string))                                                  # Set up the scan
channel_count = int(instrument_query(s, "print(scan.stepcount)", 16).rstrip())                                      # Have the data logger report the programmed number of channels
print(channel_count)
instrument_write(s, "defbuffer1.capacity = {0}".format(scan_count * channel_count))                                 # Set the scan count to 24 hrs * 60 min/hr = 1440
instrument_write(s, "scan.scancount = {0}".format(scan_count))                                                      # Set the scan count to 24 hrs * 60 min/hr = 1440
instrument_write(s, "scan.scaninterval = {0}".format(scan_interval))                                                # Set the time between scans to 60 s
write_to_usb_drive = True
if write_to_usb_drive == True:
    my_output_file = time.strftime("scandata_usb_%Y-%m-%d_%H-%M-%S.csv")
    instrument_write(s, "scan.export(\"/usb1/{0}\", scan.WRITE_AFTER_SCAN, buffer.SAVE_RELATIVE_TIME)".format(my_output_file)) # Ensure data gets written to a USB drive                                                                                                              # after each scan
instrument_write(s, "scan.restart = scan.ON")                   # Enable scan restart after power failure
instrument_write(s, "display.watchchannels = \"{0}\"".format("101:120"))                                            # Channel list mush be 'none', 'all', or less than 20 channels
instrument_write(s, "waitcomplete()")
instrument_write(s, "trigger.model.initiate()")

start_index = 1
end_index = channel_count
total_readings = 0
first_plot = 1

myplot.ion()
fig, ax = plotter.subplots()

while True:
    # Check to make certain readings are in the buffer to extract. 
    j = int(instrument_query(s, "print(defbuffer1.n)", 16).rstrip())
    if (j >= end_index):
        # get the readings...
        scan_readings = instrument_query(s, "printbuffer({0}, {1}, defbuffer1.readings, defbuffer1.relativetimestamps)".format(start_index, end_index), 2048)
        print(scan_readings)
        start_index += channel_count
        end_index += channel_count
        total_readings += channel_count
        
        # write to file
        write_data_to_file(output_data_path, scan_readings)

        # update graph
        if first_plot == 1:
            myplot = generate_graph(scan_readings, myplot)
            first_plot = 0
        else:
            myplot = update_graph(scan_readings, myplot)
        
        # display on plot
    else:
        time.sleep(1.0)                               # No point in polling for data if the scan interval has not yet expired
    
# Close the socket connection
instrument_disconnect(s)
t2 = time.time()

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
