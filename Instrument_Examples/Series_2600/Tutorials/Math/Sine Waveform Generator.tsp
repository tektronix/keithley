--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Sine Waveform Generator.tsp

This is an illustration how you can use the Math Library features to generate a sine waveform and 
output them with the 2602.

Commands used:
math.sin(x)
	Returns the trigonometric sine function of x.

math.pi
	Variable containing the value of ? (3.141592654).

We use the fomula: s(n) = Amplitude * sin( 2 * PI * f * n/F )


Rev1: JLT 9.09.2005
]]--

-- Create a 100-point, 5Vpp Sine waveform. Any of the paramters can be modified for any frequency or
-- number of points.

numPoints = 100
amplitude = 5
frequency = 1

sinewave={}
for pt= 0, numPoints do
	sinewave[pt]=amplitude*math.sin(2*math.pi*frequency*(pt/numPoints))
end

-- Create loop to output Sinewave output with 260x. Set for DC Volts output and turn output on

smua.source.func = smua.OUTPUT_DCVOLTS			-- Set the source function to DC Volts
smua.source.output = smua.OUTPUT_ON				-- Turns on the output

for pt= 0, numPoints do							-- Create a For..Do loop to sweep the Sinewave
   	smua.source.levelv = sinewave[pt]			-- Set the output level 
   	current = smua.measure.i()					-- Measure the current.
   	print("Volts = ",sinewave[pt],", Current = ",current)	 
end

smua.source.output = smua.OUTPUT_OFF			-- Turns off the output
