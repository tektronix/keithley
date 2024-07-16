

--[[


This Example does same DMM Readings with scanning using scripting commands
instead of the built in scan on the 3706.  This method may be better suited for 
some applications.

DMM needs to be configured once then a specified number of readings
 are taken. 


Each setup will be doing DCV, 1 NPLC and 10 V range

Basic_Scan_1()
Using 3706 with switching card in slot 1
This setup shows using Exclusive Close Method to close a series of channels then taking
a dmm measurement.  Using this method, the programmer must ensure the proper Analog
Backplanes are closed in order to take a measurement

Basic_Scan_2()
Using a 3706 with switching card in slot	1
This setup shows using the dmm.close method to close a series of channels then taking
dmm measurement.  Using this method, the 3706 ensures proper measurement by opening and 
closing all channels needed to take a good measurement.

******************************************************************************
								NOTE:
The two different methods here achieve the same measurement.  However it is important
to note that using any of the close methods associated with channel do not ensure a proper
measurement path. It is left up to the programmer to ensure the proper measurement path.
Examples: If using channel.close, it is possible to have multiple channels
closed that at connected to Analog bus #1 that can affect the accuracy of the measurement.
Another example would if using an channel.exclusiveclose or channel.exclusiveslotclose 
it is possible that the proper backplanes are not closed resulting in possible improper measurements

dmm.measure ensures a good measurement path to the dmm by opening all channels
connected to the measurement analog bus and closing all backplane relays needed. It 
also writes the dmm configuration associated with the channel to the dmm.  This will 
error if channel is configured as no function

The trade off is that since the dmm.close needs to check for proper measurement path 
and write dmm function to the dmm, the method in setup #1 will be a little faster.


*******************************************************************************
To Run:
1) Load TSP file to 3706 Memory 
	- Select the .tsp file of interest
	- Press the run arrow in Test Script Builder Main Menu 
	
2) Run Program
	- At the TSP> prompt in the Instrument Control Panel, type Basic_Scan_1() or
		Basic_Scan_2()
	    
Required equipment:	
3706 System Switch and Multimeter
Multiplexer Switch Card


Rev: 1-EEB
	 1.1-Update Function Names-EEB
	 
	 
]]

function Basic_Scan_1()						-- Define Function
reset()										-- Reset
reading_buffer=dmm.makebuffer(1000)			-- Configure Buffer
reading_buffer.appendmode=1					-- Set buffer to append mode
dmm.func = dmm.DC_VOLTS						-- Set measurement function
dmm.nplc=1									-- Set NPLC
dmm.range=10								-- Set Range
channel.setbackplane("1001:1010","1911")	-- Set analog backplane 1 to close for each channel in the scan
-- load table with channels in scan
mem_pattern1 = {"1001", "1002", "1003", "1004", "1005", "1006", "1007", "1008", "1009", "1010"}
for i = 1, 10 do							-- For, next loop with index i
	channel.exclusiveclose(mem_pattern1[i])	-- Exclusive close each channel in mem_pattern1 table per index of i
	dmm.measure(reading_buffer)				-- do a single dmm measure and put into buffer
end											-- End loop
printbuffer(1,10,reading_buffer)			-- Print Buffer
end											-- End Function




function Basic_Scan_2()						-- Define Function
reset()										-- Reset
reading_buffer=dmm.makebuffer(1000)			-- Configure Buffer
reading_buffer.appendmode=1					-- Set buffer to append mode
dmm.func = dmm.DC_VOLTS						-- Set measurement function
dmm.nplc=1									-- Set NPLC
dmm.range=10								-- Set Range
dmm.configure.set("mydcvolts")				-- Save Configuration
dmm.setconfig("1001:1010","mydcvolts")		-- Assign configuration to channels
-- load table with channels in scan
mem_pattern1 = {"1001", "1002", "1003", "1004", "1005", "1006", "1007", "1008", "1009", "1010"}
for i = 1, 10 do							-- For, next loop with index i
	dmm.close(mem_pattern1[i])				-- Dmm.close each channel in mem_pattern1 table per index of i
	dmm.measure(reading_buffer)				-- do a single dmm measure and put into buffer
end											-- End loop
printbuffer(1,10,reading_buffer)			-- Print Buffer
end	

Basic_Scan_1()

