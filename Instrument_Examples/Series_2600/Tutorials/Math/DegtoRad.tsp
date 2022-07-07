--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

DegtoRad.tsp

This is an illustration how you can use the Math Library features to convert Degrees to Radian or
could be used to go from Radians to Degrees.

Commands used:
math.rad(x)
	Returns the value of x in radians, where x is in degrees.

math.deg(x)
	Returns the value of x in degrees, where x is in radians.


Rev1: JLT 9.09.2005
]]--

-- We'll run a sweep from 0 to 360 degrees to convert to radians. Once we have the radian value, we'll
-- convert back to degrees.

for degree = 0, 360, 10 do
	radians = math.rad(degree)
	degrees = math.deg(radians)
	print("Initial angle ="..degree,", converted to radians ="..radians,", back to degrees ="..degrees)
end	
