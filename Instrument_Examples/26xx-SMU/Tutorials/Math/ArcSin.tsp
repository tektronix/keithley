--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

ArcSin.tsp

Do you remember your trigonometry? The 260x and TSB offers math functions for ArcSin, ArcCos, ArcTan.

We'll use the essence of the DegtoRad.tsp example to do some trigonometry so you can see how these math
functions work. The angle needs to be converted to radians so the trig math returns the correct values.

Commands used:
math.asin(x)
 Returns the principal value of the trigonometric arc sine function of x.

math.rad(x)
 Returns the value of x in radians, where x is in degrees.
 
math.pi
 Variable containing the value of p (3.141592654).
  

Rev1: JLT 9.10.2005
]]--

-- We'll run a sweep from 0 to 360 degrees in 5 degree increments, converted to radians so we can get the
-- Sin value. The program will then compute the ArcSin value. To convert back to degrees, we will take the
-- result of math.asin() and multiply this value with 180/PI. The 'math.pi' function will be used.

-- Note that computing the ArcSin value returns angles that are within the span of:
-- -PI/2 <= y <= Pi/2. 
-- Check the values to see that the range for angles should be between -90 and 90 degrees.

for degree = 0, 360, 5 do
	radians = math.rad(degree)
	print("Angle ="..degree..", Sin("..degree..") =",math.sin(radians),", and ArcSin(",math.sin(radians),") = "..math.asin(math.sin(radians))*180/math.pi)	
end	
