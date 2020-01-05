# DAQ6510 Three Ways to Manage Scanning

These examples demonstrates different means on how to conduct scanning using the DAQ6510. 
	
	1. DAQ6510_Traditional_Scan_Using_Model_7701 - This example application demonstrates 
	   the tradition means of scanning channels to capture multiple data points over long 
	   periods of time. This setup employs the Model 7701 multiplexer but can easily be 
	   modified to support the variety of other multiplexer card options available. 
	2. DAQ6510_Pseudo_Scan_Using_Model_7701 - This example application demonstrates a 
	   more methodical means of scanning channels to capture multiple data points we 
	   refer to as pseudo scanning.	Instead of a single trigger to execute the sequential 
	   scanning and looping control, the operator iterate over each individual channel 
	   capturing and exracting one reading at a time.
	3. DAQ6510_Scan_with_User_Controlled_Interval - This example application demonstrates 
	   the use of traditional style scanning but using a single scan at a time. This 
	   method was preferred for the potential for flexibility of the interval between scans.
	
You will find examples all using the SPCI command set implementations. 
* Each is written in Python 3
* Each uses sockets-based communications to control the DAQ6510
