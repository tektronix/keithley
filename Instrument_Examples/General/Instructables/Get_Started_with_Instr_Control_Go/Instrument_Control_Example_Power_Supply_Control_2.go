/***********************************************************
 *** Copyright Tektronix, Inc.                           ***
 *** See www.tek.com/sample-license for licensing terms. ***
 ***********************************************************/
package main
import (
    "net"			// added for sockets-based comms activities
    "os"			// added for fluid system feedback
	"strconv"		// added for string to other variable conversion
	"strings"		// added for string formatting and manipulation
    "io/ioutil"		// added for file read/write activities
	"fmt"			// added for string formatting and manipulation
	"time"			// added for applying delays
)

var echo_commands int = 0	// Used for debugging


/*********************************************************************************
	Function: instrument_connect(ip_address string, my_port int) (*net.TCPConn, error)
	
	Purpose: Open an instance of an instrument object for remote communication
			 over LAN/Ethernet.

	Parameters:
		ip_address (string) - The TCP/IP address string associated with the target
					 instrument. 
		my_port (int) - The instrument connection port. 

	Returns:
		*net.TCPConn - The TCP instrument connection object used for sending
					   and receiving data. 
		error - The error code associate with any failures internal to the
		        function. 

	Revisions:
		2019-07-04    JJB    Initial revision.
*********************************************************************************/
func instrument_connect(ip_address string, my_port int) (*net.TCPConn, error){
	// First build the string that will be consumed by the ResolveTCPAddr()
	// function to obtain the TCP address object.
	connection_string := ip_address + ":" + strconv.Itoa(my_port)
    tcpAddr, err := net.ResolveTCPAddr("tcp", connection_string)
	
	// Attempt to connect to the target instrument
	conn, err := net.DialTCP("tcp", nil, tcpAddr)
    if err != nil {
        println("Instrument connection failed:", err.Error())
        os.Exit(1)
    }
	
	// Return the connection instance and the error code (if applicable)
	return conn, err
}


/*********************************************************************************
	Function: instrument_disconnect(conn *net.TCPConn)
	
	Purpose: Break the LAN/Ethernet connection between the controlling computer
			 and the target instrument.

	Parameters:
		conn (*net.TCPConn) - The TCP instrument connection object used for sending
							  and receiving data.

	Returns:
		None

	Revisions:
		2019-07-04    JJB    Initial revision.
*********************************************************************************/
func instrument_disconnect(conn *net.TCPConn){
	conn.Close()
}


/*********************************************************************************
	Function: instrument_write(conn *net.TCPConn, my_command string)
	
	Purpose: Issue controlling commands to the target instrument.

	Parameters:
		conn (*net.TCPConn) - The TCP instrument connection object used for sending
							  and receiving data.
		my_command (string) - The command issued to the instrument to make it 
							  perform some action or service. 
	Returns:
		None

	Revisions:
		2019-07-04    JJB    Initial revision.
*********************************************************************************/
func instrument_write(conn *net.TCPConn, my_command string){
	// Write the command string to the target instrument. 
	var err error
	if echo_commands == 1{
		println(my_command)
	}
	var updated_command string = fmt.Sprintf("%s\n", my_command)
	_, err = conn.Write([]byte(updated_command))
    if err != nil {
        println("Write to instrument failed:", err.Error())
        os.Exit(1)
    }
}


/*********************************************************************************
	Function: instrument_read(conn *net.TCPConn, anticipated_receive_size int)(string)
	
	Purpose: Break the LAN/Ethernet connection between the controlling computer
			 and the target instrument.

	Parameters:
		conn (*net.TCPConn) - The TCP instrument connection object used for sending
							  and receiving data.

	Returns:
		reply_string (string) - The requested information returned from the 
								target instrument.

	Revisions:
		2019-07-04    JJB    Initial revision.
*********************************************************************************/
func instrument_read(conn *net.TCPConn, anticipated_receive_size int) (string){
	// Read the response back from the target instrument. 
	var err error
	reply := make([]byte, anticipated_receive_size) // Note that the TCP connection	
								// will support a return byte size
								// from 1 to 65495. We should 
								// consider passing in a byte array
								// size argument to support efficient
								// data extraction. 
    _, err = conn.Read(reply)	// Note that the return type is address
								// byte array. 
    if err != nil {
        println("Write to server failed:", err.Error())
        os.Exit(1)
    }
	
	// Convert the byte array to a string then remove spaces and 
	// null characters before returning to the caller. 
	reply_string := strings.TrimRight(string(reply), " \x00")
	return reply_string
}

/*********************************************************************************
	Function: instrument_query(conn *net.TCPConn, my_command string, 
	                           anticipated_receive_size int) (string)
	
	Purpose: Break the LAN/Ethernet connection between the controlling computer
			 and the target instrument.

	Parameters:
		conn (*net.TCPConn) - The TCP instrument connection object used for sending
							  and receiving data.
		my_command (string) - The command issued to the instrument to make it 
							  perform some action or service. 
	Returns:
		reply_string (string) - The requested information returned from the 
								target instrument. Obtained by way of a caller
								to instrument_read().

	Revisions:
		2019-07-04    JJB    Initial revision.
*********************************************************************************/
func instrument_query(conn *net.TCPConn, my_command string, anticipated_receive_size int) (string) {
	// A query is the same as a question: send an "ask" and receive
	// a reply. 
	instrument_write(conn, my_command + "\n")
	return instrument_read(conn, anticipated_receive_size)
}


/*********************************************************************************
	Function: load_script_file_onto_keithley_instrument(my_script_file string,
                                                        conn *net.TCPConn)
	
	Purpose: Copy the contents of a specific script file off of the computer 
	         and upload onto the target instrument. 

	Parameters:
		my_script_file (string) - The script file/path (ASCII text format) that 
								  will be read from the computer and sent to the
								  instrument. 
		conn (*net.TCPConn) - The TCP instrument connection object used for 
							  sending and receiving data. 
	Returns:
		None

	Revisions:
		2019-07-04    JJB    Initial revision.
*********************************************************************************/
func load_script_file_onto_keithley_instrument(my_script_file string, conn *net.TCPConn){
	var my_response_receive_size = 128
	
	// Read the entire script file into the computer's memory...
	dat, err := ioutil.ReadFile(my_script_file)
	check(err)
	
	instrument_write(conn, "if loadfuncs ~= nil then script.delete('loadfuncs') end")
	instrument_write(conn, "loadscript loadfuncs\n" + string(dat) + "\nendscript")
	println("Reply from instrument = ", string(instrument_query(conn, "loadfuncs()", my_response_receive_size)))
}

func check(e error) {
    if e != nil {
        panic(e)
    }
}

/*********************************************************************************
	This example configures the power supply to source constant current and loops
	to increase from 0 to 3A, returning the voltage, current and power measured
	at each step. Note that the SCPI command set used here is compatible with the 
	Keithley Series 2260B power supplies, but may be applicable to other 
	makes/models.
*********************************************************************************/
func main() {
	var my_ip_address string = "134.63.78.220"
	var my_port int = 2268
	var my_id_receive_size = 128
	var command_string string = ""
	var source_value float32 = 0.0
	
	// Connect to the target instrument....
	conn, _ := instrument_connect(my_ip_address, my_port)
	
	// Ask the instrument to identify itself....
    println("Reply from instrument = ", string(instrument_query(conn, "*IDN?", my_id_receive_size)))
	
	instrument_write(conn, "OUTPut:MODE 1")	// set for constant current
	command_string = fmt.Sprintf("CURR %f", source_value)
	instrument_write(conn, command_string)	// set current level to start at 1A
	instrument_write(conn, "CURR:PROT MAX")	// set the current protection to its max
	instrument_write(conn, "VOLT 36.0")		// set voltage limit to start at 20V
	instrument_write(conn, "VOLT:PROT 40.0")// set voltage protection to 10% above the limit
	instrument_write(conn, "DISP:MENU 2")	// set the display to show measured
											// power and current
	instrument_write(conn, "OUTP ON")		// turn the output on
	
	// Step the voltage up 1V at a time; delay; then measure voltage,  
	// current, and power.  
	for i := 0; i <= 10;  i++ {
		command_string = fmt.Sprintf("CURR %f", float32(i) * 0.3)
		instrument_write(conn, command_string)
		time.Sleep(1 * time.Second)
		
		println("Voltage = ", string(instrument_query(conn, 
				"MEAS:VOLT?", my_id_receive_size)))
		println("Current = ", string(instrument_query(conn, 
				"MEAS:CURR?", my_id_receive_size)))
		println("Power = ", string(instrument_query(conn, 
				"MEAS:POW?", my_id_receive_size)))
	}
	
	instrument_write(conn, "OUTP OFF")		// turn the output off
	
	// Close the connection to the instrument
    instrument_disconnect(conn)
}