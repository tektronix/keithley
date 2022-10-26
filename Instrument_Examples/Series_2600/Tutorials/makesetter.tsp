--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

makesetter.tsp

This tutorial program creates a function to set the value of an attribute. This function creates a function 
that when called sets the value of the attribute. This function is useful for aliasing attributes to improve 
execution speed. Calling the setter function will execute faster than accessing the attribute directly.

Creating a setter function is only useful if it is going to be called several times. Otherwise the 
overhead of creating the setter function outweighs the overhead of accessing the attribute directly.

The makesetter command is an ideal command for creating an alias of a 260x command for easier identification.


Commands used in this example:

setter = makesetter(table, attributename)
Where:
			table     		Read-only table were the attribute is located.
	`		attributename   The string name of the attribute.
			setter   		Function that sets the value of the given attribute.

Rev1: JLT 7.19.2005
Rev2: BCO 5.2.2019
]]--

-- Let's create a very basic Linear Sweep by using the makesetter command. In order to perform the sweep,
-- we we will use a function called 'setoutput' that will set the value of the given atrirbute. Since we will
-- sweep voltage, the 260x command used to source a voltage is: smuX.source.levelY where 'X' is either an 'a'
-- or 'b' for smua or smub and 'Y' is either 'i' or 'v' for current or voltage respectively. The attribute that
-- we will set is the 'levelv' attribute in the command.

-- To really show off setters, we won't perform any measurements, instead, we'll just set the voltage output
-- (Measuring can add an unknown amount of time thanks to settling requirements)

reset()												-- Reset the 260x
display.screen = 2									-- Set to display screen 2
display.smua.measure.func = display.MEASURE_DCAMPS	-- Display current measurements
setoutput = makesetter(smua.source, "levelv")		-- Use makesetter to alias the sourcing command to be called 'setoutput' as the function

smua.source.output = smua.OUTPUT_ON					-- Turn the output on
timer.reset()
for v = 1, 10, 0.001 do									-- Sweep voltage from 1 to 10 volts
   	setoutput(v)									-- Set the new output level	
   	--reading = smua.measure.i()						-- Make a measurement
   	--print("Current = "..reading)					-- Print the reading							
end
elapsedTime = timer.measure.t()
print("Time elapsed with setter: "..elapsedTime)

-- Now let's try the same thing without the setter
reset()
smua.source.output = smua.OUTPUT_ON
timer.reset()
for v = 1, 10, 0.001 do								-- Sweep voltage from 1 to 10 volts
   	smua.source.levelv = v							-- Set the new output level	
   	--reading = smua.measure.i()						-- Make a measurement
   	--print("Current = "..reading)					-- Print the reading							
end
elapsedTime = timer.measure.t()
print("Time elapsed without setter: "..elapsedTime)

smua.source.output = smua.OUTPUT_OFF
