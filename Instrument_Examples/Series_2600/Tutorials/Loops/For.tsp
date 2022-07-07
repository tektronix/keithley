--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

For.tsp

This tutorial example shows how to use the FOR..DO loop.

Please review the ForLoop.doc document for details on teh syntax and usage of the 
For..Do loop control.

For..Do loop control construct:

for var = exp1, exp2 [,exp3] do
	block
end

Where:
	var		A variable expression
	exp1	Start loop at the value of the first exp1
	exp2 	End loop until it passes the second exp2
	[exp3]	Optional third parameter. Increments loop by steps of the third exp3. 
	block	The block of code to be executed in the loop



Rev1: JLT 06.03.2005
Rev2: BCO 5.2.2019
]]--

reset()

-- **************** EXAMPLE 1 *******************************
-- The following example will sweep the output of SMUA in one volt increments from 1 to 10 volts.
print("For Loop 1:")
smua.source.func = smua.OUTPUT_DCVOLTS
smua.source.output = smua.OUTPUT_ON

for volts = 1, 10 do
	smua.source.levelv = volts
	print(volts)
	delay(0.5) -- Short delay so you can see the action on the front panel.
end	

smua.source.output = smua.OUTPUT_OFF
delay(2)
print(" ")

-- **************** EXAMPLE 2 *******************************
-- The following example will sweep the output of SMUA in 0.1 volt increments from 1 to 10 volts.
print("For Loop 2:")
smua.source.func = smua.OUTPUT_DCVOLTS
smua.source.output = smua.OUTPUT_ON

for volts = 1, 10, 0.5 do
	smua.source.levelv = volts
	print(volts)
	delay(0.01)	-- Short delay so you can see the action on the front panel.
end	

smua.source.output = smua.OUTPUT_OFF
delay(2)
print(" ")

-- **************** EXAMPLE 3 *******************************
-- The following example will sweep the output of SMUA in -0.1 volt increments from 10 to -10 volts.
print("For Loop 3:")

Start = 10
Stop = -10
Step = -2

smua.source.func = smua.OUTPUT_DCVOLTS
smua.source.output = smua.OUTPUT_ON

for volts = Start, Stop, Step do
	smua.source.levelv = volts
	print(volts)
	delay(0.01)	-- Short delay so you can see the action on the front panel.
end	

smua.source.output = smua.OUTPUT_OFF
delay(2)
print(" ")

-- **************** EXAMPLE 4 *******************************
--[[
The following example illustrates the use of a generic For..Do loop to traverse through a 
list of voltage values in a table. You can put as many values in the table and not have to
worry about knowing how many values are in the table.

In this example, the FOR loop evaluates the function, 'ipairs(voltageList)'. 'ipairs()' allows 
you to iterate over the elements of an array or table, following the convention that the array 
ends at its first nil element. 

After evaluating 'ipairs(voltageList)', the For loop is incremented using the variable 'index'
until a nil index is reached by reaching the end of the array or table. Each value of the array
or table is assigned to the variable 'volts' with an index value.
]]
print("For Loop 4:")

-- Create a voltage list.
voltageList = {1, 5, -5, -4, -9, 10, 8, 2, 0, -1, 1, -2, 0.5}

smua.source.func = smua.OUTPUT_DCVOLTS
smua.source.output = smua.OUTPUT_ON

for index, volts in ipairs(voltageList) do
	smua.source.levelv = volts
	print("The loop index = "..string.format('%u',index)..". Outputting a voltage of "..volts.." volts.")
	delay(0.1) -- Short delay so you can see the action on the front panel.
end	

smua.source.output = smua.OUTPUT_OFF
delay(2)
print(" ")

-- This For loop is just like the last one, but instead of using ipairs, we can just use the index

print("For Loop 4.5:")

-- Create a voltage list.
voltageList = {1, 5, -5, -4, -9, 10, 8, 2, 0, -1, 1, -2, 0.5}

smua.source.func = smua.OUTPUT_DCVOLTS
smua.source.output = smua.OUTPUT_ON

for index in voltageList do
	smua.source.levelv = voltageList[index]
	print("Outputting a voltage of "..voltageList[index].." volts.")
	delay(0.1) -- Short delay so you can see the action on the front panel.
end	

smua.source.output = smua.OUTPUT_OFF