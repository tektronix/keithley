"""***********************************************************
*** Copyright Tektronix, Inc.                           ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************"""
import socket
import struct
import math
import time
import sys
import matplotlib
import matplotlib.pyplot as myplot

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
	This example application demonstrates how to use two Model 2450 instruments to perform I-V
        characterization of field effect transistors (FETs). The Model 2450 is a good choice for semiconductor
        device testing because it can quickly and accurately source and measure both current and voltage.

        Determining the I-V parameters of FETs helps you ensure that they function properly in their intended
        applications, and that they meet specifications. There are many I-V tests that you can perform with
        the Model 2450, including gate leakage, breakdown voltage, threshold voltage, transfer
        characteristics, and drain current. The number of Model 2450 instruments required for testing
        depends on the number of FET terminals that must be biased and measured.

        This application shows you how to perform a drain family of curves (Vds-Id) on a three-terminal
        MOSFET. The MOSFET is the most commonly used FET because it is the basis for digital integrated
        circuits.
*********************************************************************************"""
ip_address_gate_smu = "192.168.1.25"     # Place your instrument's IP address here.
my_port = 5025
gate_smu = socket.socket(socket.AF_INET, socket.SOCK_STREAM)           # Establish a TCP/IP socket object
instrument_connect(gate_smu, ip_address_gate_smu, my_port, 20000, 0, 1)         # Open the socket connection

t1 = time.time()                                                        # Start the timer...

instrument_write(gate_smu, "*RST")                                      # Reset the SMU
instrument_write(gate_smu, ":SENSE:FUNC \"CURR\"")                      # Set the instrument to measure current.
instrument_write(gate_smu, ":SENSE:CURR:RANG:AUTO ON")                        # Set the current range to autorange.
#instrument_write(gate_smu, ":ROUT:TERM REAR")                           # Set to use rear-panel terminals.
instrument_write(gate_smu, ":SOUR:FUNC VOLT")                           # Set to source voltage.
instrument_write(gate_smu, ":SOUR:VOLT:RANG 20")                             # Set the source voltage to 20 V.
instrument_write(gate_smu, ":SOUR:VOLT:ILIMIT 0.01")                    # Set the current limit to 10 mA.
instrument_write(gate_smu, "SOUR:CONF:LIST:CRE \"stepVals\"")           # Create a source configuration list called
                                                                        # stepVals.
instrument_write(gate_smu, "DIG:LINE1:MODE TRIG, OUT")                  # Set digital line 1 to trigger out.
instrument_write(gate_smu, "DIG:LINE2:MODE TRIG, IN")                   # Set digital line 2 to trigger in.
instrument_write(gate_smu, "TRIG:DIG1:OUT:STIM NOT1")                   # Set the stimulus for digital line 1 to the
                                                                        # notify1 event.

instrument_write(gate_smu, "TRIG:DIG1:OUT:LOG POS")
instrument_write(gate_smu, "TRIG:DIG2:IN:CLE")                          # Clear digital line 2.
instrument_write(gate_smu, "TRIG:DIG2:IN:EDGE RIS")                     # Set to detect rising edge on line 2.
for i in range (2, 6):
    instrument_write(gate_smu, "SOUR:VOLT {0}".format(i))               # Set the voltage level to the iteration number.
    instrument_write(gate_smu, "SOUR:CONF:LIST:STORE \"stepVals\"")     # Store the source configuration to stepVals.

instrument_write(gate_smu, "TRIG:BLOC:CONF:RECALL 1, \"stepVals\"")     # Create trigger model block 1 to load stepVals at the first index.
instrument_write(gate_smu, "TRIG:BLOC:SOUR:STAT 2, ON")                 # Create block 2 to turn the output on.
instrument_write(gate_smu, "TRIG:BLOC:MEAS 3")                          # Create block 3 to make a measurement.
instrument_write(gate_smu, "TRIG:BLOC:NOT 4, 1")                        # Create block 4 to generate the notify1 event.
instrument_write(gate_smu, "TRIG:BLOC:WAIT 5, DIG2")                    # Create block 5 to wait on digital line 2.
instrument_write(gate_smu, "TRIG:BLOC:CONF:NEXT 6, \"stepVals\"")       # Create block 6 to load the next index of stepVals.
instrument_write(gate_smu, "TRIG:BLOC:BRAN:COUN 7, 4, 3")               # Create block 7 to branch to block 3, 3 times.
instrument_write(gate_smu, "TRIG:BLOC:SOUR:STAT 8, OFF")                # Create block 8 to turn the output off.

ip_address_drain_smu = "192.168.1.26"     # Place your instrument's IP address here.
my_port = 5025
drain_smu = socket.socket(socket.AF_INET, socket.SOCK_STREAM)           # Establish a TCP/IP socket object
instrument_connect(drain_smu, ip_address_drain_smu, my_port, 20000, 0, 1)   # Open the socket connection

instrument_write(drain_smu, "*RST")                                     # Reset the SMU
instrument_write(drain_smu, ":SENSE:FUNC \"CURR\"")                     # Set the instrument to measure current.
instrument_write(drain_smu, ":CURR:RANG:AUTO ON")                       # Set the current range to autorange.
#instrument_write(drain_smu, ":ROUT:TERM REAR")                          # Set to use rear-panel terminals.
instrument_write(drain_smu, ":SOUR:FUNC VOLT")                          # Set to source voltage.
instrument_write(drain_smu, ":SOUR:VOLT 20")                            # Set the source voltage to 20 V.
instrument_write(drain_smu, ":SOUR:VOLT:ILIMIT 1.0")                    # Set the current limit to 10 mA.
instrument_write(drain_smu, ":SOUR:CONF:LIST:CRE \"sweepVals\"")        # Create a source configuration list called
                                                                        # stepVals.
instrument_write(drain_smu, "DIG:LINE1:MODE TRIG, IN")                  # Set digital line 1 to trigger in.
instrument_write(drain_smu, "TRIG:DIG1:IN:CLE")                         # Clear digital line 1.
instrument_write(drain_smu, "TRIG:DIG1:IN:EDGE RIS")                    # Detect for a rising edge on line 1.                                                                    
instrument_write(drain_smu, "DIG:LINE2:MODE TRIG, OUT")                 # Set digital line 2 to trigger out.
instrument_write(drain_smu, "TRIG:LINE2:OUT:LOG POS")                 # 
instrument_write(drain_smu, "TRIG:DIG2:OUT:STIM NOT2")                  # Set the stimulus for digital line 2 to the notify2 event.

i = 0.0
while i <= 5:
    instrument_write(drain_smu, "SOUR:VOLT {0:0.4E}".format(i))              # Set the voltage level to the iteration number.
    instrument_write(drain_smu, "SOUR:CONF:LIST:STORE \"sweepVals\"")   # Store the source configuration to sweepVals.
    i += 0.1
    
instrument_write(drain_smu, "TRIG:BLOC:CONF:RECALL 1, \"sweepVals\"")    # Create trigger model block 1 to load sweepVals at the first index.
instrument_write(drain_smu, "TRIG:BLOC:SOUR:STAT 2, ON")                 # Create block 2 to turn the output on.
instrument_write(drain_smu, "TRIG:BLOC:WAIT 3, DIG1")                    # Create a block to wait on digital line 3.
instrument_write(drain_smu, "TRIG:BLOC:DEL:CONS 4, 0.01")                # Create a block to delay for 0.01 seconds.
instrument_write(drain_smu, "TRIG:BLOC:MEAS 5")                          # Create a block to take a measurement.
instrument_write(drain_smu, "TRIG:BLOC:CONF:NEXT 6, \"sweepVals\"")      # Create a block to load the next index of sweepVals.
instrument_write(drain_smu, "TRIG:BLOC:BRAN:COUN 7, 51, 4")              # Create a block to branch to block 4, 50 times.
instrument_write(drain_smu, "TRIG:BLOC:NOT 8, 2")                        # Create a block to generate the notify2 event.
instrument_write(drain_smu, "TRIG:BLOC:BRAN:COUN 9, 4, 3")               # Create a block to branch to block 3 three times.
instrument_write(drain_smu, "TRIG:BLOC:SOUR:STAT 10, OFF")               # Create a block to turn the output off.

instrument_write(drain_smu, "INIT")                                     # Trigger the sweeper (drain) SMU that will be waiting
                                                                        # for a measure start signal from the stepper (gate)
                                                                        # SMU.
instrument_write(gate_smu, "INIT")                                     # Trigger the steper (gate) SMU


# Calculate the number of readings that will be collected.
expected_readings_count = 51 * 4 # 51 readings per sweep, 4 steps
j = 1
# Loop until all measurements are collected...
while j < expected_readings_count:
    time.sleep(1.0)
    # Check to make certain readings are in the buffer to extract. 
    j = int(instrument_query(drain_smu, ":TRAC:ACT? \"defbuffer1\"", 16).rstrip())
    print("Running...")

# Get the reading + relative timestamp pairs out one at a time and print to the display. 
temp_list = instrument_query(drain_smu, ":TRAC:DATA? {0}, {1}, \"defbuffer1\", REL, READ".format(1, 51),
                             (51*2*16)).rstrip().split(',')
relative_times = []
v20 = []
for j in range(0, 102, 2):
    relative_times.append(float(temp_list[j]))
    v20.append(float(temp_list[j+1]))

#print(relative_times)
#print(v20)

temp_list.clear()
temp_list = instrument_query(drain_smu, ":TRAC:DATA? {0}, {1}, \"defbuffer1\", READ".format(52, 102),
                             (51*2*16)).rstrip().split(',')
v30 = []
for j in range(0, 51):
    v30.append(float(temp_list[j]))
    
#print(v30)

temp_list.clear()
temp_list = instrument_query(drain_smu, ":TRAC:DATA? {0}, {1}, \"defbuffer1\", READ".format(103, 153),
                             (51*2*16)).rstrip().split(',')
v40 = []
for j in range(0, 51):
    v40.append(float(temp_list[j]))
#print(v40)

temp_list.clear()
temp_list = instrument_query(drain_smu, ":TRAC:DATA? {0}, {1}, \"defbuffer1\", READ".format(154, 204),
                             (51*2*16)).rstrip().split(',')
v50 = []
for j in range(0, 51):
    v50.append(float(temp_list[j]))
#print(v50)

# Close the socket connection
instrument_disconnect(gate_smu)
instrument_disconnect(drain_smu)

# Finally plot the curves; using only the relative times with respect to the first sweep...
fig, ax = myplot.subplots()
ax.plot(relative_times, v20, label = 'step_2V')
ax.plot(relative_times, v30, label = 'step_3V')
ax.plot(relative_times, v40, label = 'step_4V')
ax.plot(relative_times, v50, label = 'step_5V')

ax.set(xlabel='time (s)', ylabel='current (A)', title = 'MOSFET I-V Curves')
ax.legend()
ax.grid(True)
myplot.show()


t2 = time.time()

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Total Time Elapsed: {0:.3f} s".format(t2-t1))

input("Press Enter to continue...")
exit()
