
--[[


This Example does same DMM Readings with scanning
DMM needs to be configured once then a specified number of readings
 are taken. 



Each setup will be doing DCV, 1 NPLC and 10 V range

DMM_Simple_Scan()
Using 3706 with switching card in slot 1

To Run:
1) Load TSP file to 3706 Memory 
	- Select the .tsp file of interest
	- Press the run arrow in Test Script Builder Main Menu 
	
2) Run Program
	- At the TSP> prompt in the Instrument Control Panel, type DMM_Simple_Scan()
	    
Required equipment:	
3706 System Switch and Multimeter
Multiplexer Switch Card


Rev: 1-EEB
	 1.1-Updated Function Names-EEB
	 
]]


function DMM_Simple_Scan()
-- Sets up 10 channel scan by saving configurations to channels
reset()										-- Reset
reading_buffer=dmm.makebuffer(1000)			-- Configure Buffer
dmm.func = dmm.DC_VOLTS						-- Set measurement function
dmm.nplc=1									-- Set NPLC
dmm.range=10								-- Set Range
dmm.configure.set("mydcvolts")				-- Save Configuration
dmm.setconfig("1001:1010","mydcvolts")		-- Assign configuration to channels
scan.create("1001:1010")					-- create scan 
scan.scancount=1							-- Set Scan Count
scan.execute(reading_buffer)				-- Execute Scan and save to buffer
printbuffer(1,10,reading_buffer)			-- print buffer

end

DMM_Simple_Scan()
