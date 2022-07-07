--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Trigonometry.tsp

Do you remember your trigonometry? The 260x and TSB offers math functions for Sin, Cos, Tan.

We'll use the essence of the DegtoRad.tsp example to do some trigonometry so you can see how these math
functions work. The angle needs to be converted to radians so the trig math returns the correct values.
You might use this to create a sine wave or a cosine wave that is 90 degrees out of phase with the sine
wave. This could be very useful when using the 2602 to output the two different functions. We'll actually
do this here.

Commands used:
math.cos(x)
 Returns the trigonometric cosine function of x.
 
math.sin(x)
 Returns the trigonometric sine function of x.
 
math.tan(x)
 Returns the trigonometric tangent function of x.
 
math.rad(x)
 Returns the value of x in radians, where x is in degrees.
 
 

Rev1: JLT 9.10.2005
]]--

smua.source.func = smua.OUTPUT_DCVOLTS			-- Set the source function to DC Volts
smua.source.output = smua.OUTPUT_ON				-- Turns on the output
smub.source.func = smua.OUTPUT_DCVOLTS			-- Set the source function to DC Volts
smub.source.output = smua.OUTPUT_ON				-- Turns on the output

-- We'll run a sweep from 0 to 360 degrees, converted to radians. We can then compute the Sin, Cos, and
-- Tan values, which will be printed in the Instrument Console.

-- We'll also run the output slow so you can watch the source action. Watch to see how the two outputs
-- are 90 degrees out of phase.

for degree = 0, 360 do
	radians = math.rad(degree)
	print("Angle =",degree,", Sin(",degree,") =",math.sin(radians),", Cos(",degree,") =",math.cos(radians),", Tan(",degree,") =",math.sin(radians))	
	smua.source.levelv = math.sin(radians)
	smub.source.levelv = math.cos(radians)
	delay(0.1)
end	

smua.source.output = smua.OUTPUT_OFF			-- Turns off the output
smub.source.output = smub.OUTPUT_OFF			-- Turns off the output
