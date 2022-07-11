--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

While.tsp

This tutorial example shows how to use the While loop construct.

While..Do loop control construct:

while exp do 
	block 
end

Where:
	exp		The condition expression of the control structure. It may return any value. 
			Both false and nil are considered false. All values different from nil and false 
			are considered true (in particular, the number 0 and the empty string are also true).
			 
	block	The block of code to be executed in the loop
	
The 260x tests the While condition; if the condition is false, then the loop ends; otherwise, the
260x executes the body of the loop and repeats the process.



Rev1: JLT 7.19.2005
]]--

-- This example uses a While loop to sweep voltage. The condition to test for is if the voltage
-- to be output is greater than 10.

maxOutputVoltage = 10
voltsOut = -5
smua.source.func = smua.OUTPUT_DCVOLTS
smua.source.output = smua.OUTPUT_ON


while voltsOut <= maxOutputVoltage do
	print("Outputting a voltage value of ",voltsOut,"Volts.")
	smua.source.levelv = voltsOut
	voltsOut = voltsOut + 0.5
	delay(0.3)					-- Short delay so you can see the action on the front panel.
end	
print("End loop!")

smua.source.output = smua.OUTPUT_OFF
delay(2)

-- This example uses a While loop to sweep voltage. In this case, we use a table of values. A key feature
-- of using the While..Do loop is that no matter how big the table of values is, and you don't even have to
-- remember how many points are in the table, the while loop will stop when the table has been exhausted.
-- Any values -- beyond table list are considered a FALSE condition, thus terminating the loop. In this 
-- example, the loop will terminate after the final value of -9 has been sourced.

outputVoltsList = {1,2,3,4,5,6,7,8,9,0,-1,-2,-3,-4,-5,-6,-7,-8,-9}

smua.source.func = smua.OUTPUT_DCVOLTS
smua.source.output = smua.OUTPUT_ON

i = 1
while outputVoltsList[i] do
	print("Outputting a voltage value of ",outputVoltsList[i],"Volts.")
	smua.source.levelv = outputVoltsList[i]
	delay(0.3)					-- Short delay so you can see the action on the front panel.
	i = i + 1
end	
print("End loop!")
smua.source.output = smua.OUTPUT_OFF
