--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

makegetter.tsp

This tutorial program creates a function to set the value of an attribute. This function creates a function 
that when called returns the value of the attribute. This function is useful for aliasing attributes to improve 
execution speed. Calling the getter function will execute faster than accessing the attribute directly.

Creating a getter function is only useful if it is going to be called several times. Otherwise the 
overhead of creating the getter function outweighs the overhead of accessing the attribute directly.

The makegetter command is an ideal command for creating an alias of a 260x command for easier identification.


Commands used in this example:

setter = makesetter(table, attributename)
Where:
			table     		Read-only table were the attribute is located.
	`		attributename   The string name of the attribute.
			setter   		Function that sets the value of the given attribute.

getter = makegetter(table, attributename)
Where:
			table     		Read-only table were the attribute is located.
	`		attributename   The string name of the attribute.
			getter   		Function that returns the value of the given attribute.

Rev1: JLT 7.19.2005
Rev2: BCO 5.2.2019
]]--

-- Let's create a very basic Linear Sweep by using the makesetter command. In order to perform the sweep,
-- we we will use a function called 'setoutput' that will set the value of the given atrirbute. Since we will
-- sweep voltage, the 260x command used to source a voltage is: smuX.source.levelY where 'X' is either an 'a'
-- or 'b' for smua or smub and 'Y' is either 'i' or 'v' for current or voltage respectively. The attribute that
-- we will set is the 'levelv' attribute in the command.

-- At the end of the sweep, we will execute a getter function to return the last value attribute that was set.

reset()												-- Reset the 260x
display.screen = 2									-- Set to display screen 2
display.smua.measure.func = display.MEASURE_DCAMPS	-- Display current measurements

-- Declare 'makesetter' and 'makegetter' functions
setoutput = makesetter(smua.source, "levelv")		-- Use makesetter to alias the sourcing command to be called 'setoutput' as the function
													
getOutputValue = makegetter(smua.source, "levelv")	-- Use makegetter to return the value of the specific attribute 													

smua.source.output = smua.OUTPUT_ON					-- Turn the output on
timer.reset()
for v = 1, 10, 0.001 do								-- Sweep voltage from 1 to 10 volts
   	setoutput(v)									-- Set the new output level	
	v2 = getOutputValue()							-- Get the value we just set
   	--reading = smua.measure.i()						-- Make a measurement
   	--print(reading)									-- Print the reading							
end
elapsedTime = timer.measure.t()
print("Time elapsed with getter: "..elapsedTime)
reset()

-- Now let's try the same thing without the getter

smua.source.output = smua.OUTPUT_ON					-- Turn the output on
timer.reset()
for v = 1, 10, 0.001 do								-- Sweep voltage from 1 to 10 volts
   	setoutput(v)									-- Set the new output level	
	v2 = smua.source.levelv							-- Get the value we just set
   	--reading = smua.measure.i()						-- Make a measurement
   	--print(reading)									-- Print the reading							
end
elapsedTime = timer.measure.t()
print("Time elapsed without getter: "..elapsedTime)

smua.source.output = smua.OUTPUT_OFF