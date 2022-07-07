--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

MinMax.tsp

This is an illustration how you can use the Math Library features to determine the Minimum and
Maximum values of a set of numbers. We willuse the random noise generator code developed in the
'Random Noise Generator.tsp' file to get the min and max of the current measurements. 
output them with the 2602.

Commands used:
math.min(x)
	Returns the minimum value of its argument(s).

math.max(x)
	Returns the maximum value of its numeric argument(

math.random([x],[y])
	When called without an argument, returns a pseudo-random real number in the range [0, 1).
	When called with number x, returns a pseudo-random integer in the range [1,n].
	When called with two arguments, x and y, returns a pseudorandom integer in the range [x, y].


Rev1: JLT 9.09.2005
]]--

-- Create a 500-point, random noise waveform. The random math library function will determine the
-- amplitude.

current={}
numPoints = 500
minVolts = -10
maxVolts = 10
maxValue=-0.00000000001							-- Set a ridiculously small initial value
minValue=10000000000							-- Set a ridiculously large initial value

smua.source.func = smua.OUTPUT_DCVOLTS			-- Set the source function to DC Volts
smua.source.output = smua.OUTPUT_ON				-- Turns on the output

for pt= 1, numPoints do							-- Create a For..Do loop to sweep the Sinewave
	outputVolts = math.random(minVolts,maxVolts)
   	smua.source.levelv = outputVolts			-- Set the output level 
   	current[pt] = smua.measure.i( )					-- Measure the current.
   	--print("Volts = ",outputVolts,", Current = ",current[pt])	 
end

smua.source.output = smua.OUTPUT_OFF			-- Turns off the output

-- Determine the minimum and maximum measured current values
for pt = 1, numPoints-1 do
	maxValue = math.max(maxValue,current[pt])
	minValue = math.min(minValue,current[pt])
end

print("Maximum measured current = ",maxValue)
print("Minimum measured current = ",minValue)
print("")

-- Alternately
maxValue = math.max(unpack(current))
minValue = math.min(unpack(current))

print("Maximum measured current (unpacked)= ",maxValue)
print("Minimum measured current (unpacked)= ",minValue)