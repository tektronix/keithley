--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

setup_recall.tsp

This tutorial example will use the setup.recall() function to recall a setup from one of the five
locations in the 260x. 

Commands Used:
setup.recall(n)
W     here:
	<n>			For an n setting of 0, the unit recalls the factory default (reset) setup. 
				For an n setting of 1 to 5, the unit recalls a user saved setup. 
 			


Rev1: JLT 9.20.2005
]]--

-- This example will recall settings from the 260x. If you get an error while this example runs,
-- you may have to go back to the 'setup_save.tsp' example to 

setup.recall(2)									-- Recall setup from location 2
delay(5)										-- Wait 5 seconds before starting
smua.source.func = smua.OUTPUT_DCVOLTS			-- Set the source function to DC Volts
smua.source.output = smua.OUTPUT_ON				-- Turns on the output
for j = 1, 5, 0.1 do									-- Create a For..Do loop to sweep from 1 to 5 volts
     smua.source.levelv = j						-- Set the output level to the integer value of �j�
     current = smua.measure.i( )				-- Measure the current.
     print( current )							-- Return the measurement to the PC
end												-- End of the For..Do loop
smua.source.output = smua.OUTPUT_OFF			-- Turns off the output
