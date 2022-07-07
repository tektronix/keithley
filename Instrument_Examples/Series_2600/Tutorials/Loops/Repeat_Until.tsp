--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Repeat_Until.tsp

This tutorial example shows how to use the Repeat loop construct.

Repeat..Until loop control construct:

repeat 
	block 
until

Where:
	block	The block of code to be executed in the loop

	Until	The conditional check, looking for a true statement
		
When using the Repeat-Until statement, the loop repeats the body of block of code unit the condition 
the condition is True, then the loop ends; otherwise, the 260x executes the body of the loop and 
repeats the process. The test is done after the body, so the body is always executed at least once.



Rev1: JLT 07.19.2005
Rev2: BCO 5.2.2019
]]--
reset()
-- This example uses a Repeat loop to sweep voltage. The condition to test for is if the voltage
-- to be output is greater than 10.

maxOutputVoltage = 10
voltsOut = -5
smua.source.func = smua.OUTPUT_DCVOLTS
smua.source.output = smua.OUTPUT_ON

repeat
	print("Outputting a voltage value of ",voltsOut,"Volts.")
	smua.source.levelv = voltsOut
	voltsOut = voltsOut + 0.5
	delay(0.3)					-- Short delay so you can see the action on the front panel.
until voltsOut > maxOutputVoltage
print("Condition met!")

smua.source.output = smua.OUTPUT_OFF
delay(2)
reset()

-- This example uses a Repeat-Until loop to sweep voltage. In this case, we use a table of values. A key feature
-- of using the Repeat..Until loop is that no matter how big the table of values is, and you don't even have to
-- remember how many points are in the table. You use a simple counter in the loop to keep track. 

-- In order for the loop to terminate, the condition must be true. However, if we use the 'not' operator 
-- after the 'unitl' command, we force the condition to be false while sweeping through the table. Once all of the
-- values of the table have been sourced, anything beyond the values now will force the condition to be True,
-- stopping the loop.

outputVoltsList = {1,2,3,4,5,6,7,8,9,0,-1,-2,-3,-4,-5,-6,-7,-8,-9}

smua.source.func = smua.OUTPUT_DCVOLTS
smua.source.output = smua.OUTPUT_ON

i = 1
repeat
	print("Outputting a voltage value of ",outputVoltsList[i],"Volts.")
	smua.source.levelv = outputVoltsList[i]
	delay(0.3)					-- Short delay so you can see the action on the front panel.
	i = i + 1
until not outputVoltsList[i]

smua.source.output = smua.OUTPUT_OFF