--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Random Noise Generator.tsp

This is an illustration how you can use the Math Library features to generate a random noise generator and 
output them with the 2602.

Commands used:
math.random([x],[y])
	When called without an argument, returns a pseudo-random real number in the range [0, 1).
	When called with number x, returns a pseudo-random integer in the range [1,n].
	When called with two arguments, x and y, returns a pseudorandom integer in the range [x, y].


Rev1: JLT 9.09.2005
Rev2: BCO 5.2.2019
]]--

-- Create a 500-point, random noise waveform. The random math library function will determine the amplitude.

numPoints = 500
minVolts = -1
maxVolts = 1


smua.source.func = smua.OUTPUT_DCVOLTS			-- Set the source function to DC Volts
smua.source.output = smua.OUTPUT_ON				-- Turns on the output

for pt= 1, numPoints do							-- Create a For..Do loop to generate random numbers
	rand = math.random()						-- Returns a pseudorandom floating point number fro 0 to 1
	outputVolts = (maxVolts - minVolts)*rand + minVolts; -- Scale our random number to be in the range [minVolts, maxVolts]
   	smua.source.levelv = outputVolts			-- Set the output level 
   	current = smua.measure.i()					-- Measure the current.
   	print("Volts = ",outputVolts,", Current = ",current)	 
end

smua.source.output = smua.OUTPUT_OFF			-- Turns off the output
