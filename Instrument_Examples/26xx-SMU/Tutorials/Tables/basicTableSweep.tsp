--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

BasicTableSweep.tsp

This tutorial example shows how to use a simple table to sweep a voltage. 

Test Script Language makes extensive use of the data type table, which is essentially a very flexible
array like data type. For examples, let's define a table called voltages with values for the table.

voltages = {1, 2, 3, 4)

This is a table with four elements, which are numbers. Tables can also contain strings or attributes



Rev1: JLT 09.21.2005


The following example uses For..Do loop to traverse through a list of voltage values in a table. 
You can put as many values in the table and not have to worry about knowing how many values are in 
the table.

]]--

-- Create a voltage list.
VoltageList = {1, 5, -5, -4, -9, 10, 8, 2, 0, -1, 1, -2, 0.5}
smua.reset()
smua.source.func = smua.OUTPUT_DCVOLTS
smua.source.output = smua.OUTPUT_ON
 
for element= 1, 13 do
	smua.source.levelv = VoltageList[element]
	delay(0.5)					-- Short delay so you can see the action on the front panel.
	reading = smua.measure.i()
	print("The loop index = "..element..". Outputting a voltage of "..VoltageList[element].." volts. Reading = ",reading,"amps")	
end	

smua.source.output = smua.OUTPUT_OFF
