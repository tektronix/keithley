--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

BasicMath.tsp

This is an illustration how you can use the Math Library features to determine a variety of math
parameters including Absolute Value, Ceiling, Floor, Square Root, and Power

Commands used:
math.abs(x)
 Returns the absolute value of the argument x.

math.ceil(x)
 Returns the smallest floating-point number not less than x whose value is an exact mathematical integer.

math.floor(x)
 Returns the largest floating-point number not greater than x whose value is an exact mathematical integer.
 
math.pow(x, y)
 Returns x^y.
 
math.sqrt(x)
 Returns the non-negative square root of x.
 

Rev1: JLT 9.09.2005
]]--

-- We're going to create a table with 6 various values to demonstrate the 5 different math functions.

exampleTable = {-2.45, math.pi, 144, -12, 5.234, 1.945}

-- Lets do the math on the table values to see the results of the 5 functions. For the power function,
-- we will use the loop as the power value 'y'.

for loop = 1, table.getn(exampleTable) do 
	print("For the value ",exampleTable[loop],":")
	print("Absolute Value = ",math.abs(exampleTable[loop]))
	print("Ceiling Value  = ",math.ceil(exampleTable[loop]))
	print("Floor Value    = ",math.floor(exampleTable[loop]))
	print("Natural Log    = ",math.log(exampleTable[loop]))
	if exampleTable[loop] < 0 then
		print("Can't take square root on a negative number!")
	else	
		print("Square Root    = ",math.sqrt(exampleTable[loop]))
	end	
	print("Squared        = ",math.pow(exampleTable[loop],exampleTable[loop]))
	print(" ")
	delay(2)
end	
