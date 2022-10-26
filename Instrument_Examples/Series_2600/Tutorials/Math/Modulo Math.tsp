--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Modulo Math.tsp

This is an illustration how you can use the Math Library feature 'math.mod() to do modulo mathematics.
This code illustrates how you can convert an integer number to its 14-bit representation for numbers
between 0 to 16383. This can be useful when you are working with the 260x digital I/O port.

Commands used:
math.mod(x,y)
	Returns an approximation to the mathematical value f such that f has the same sign as x, 
	the absolute value of f is less than the absolute value of y, and there exists an integer k 
	such that k*y+f = x.

math.floor(x)
	Returns the largest floating-point number not greater than x whose value is an exact mathematical 
	integer.


Rev1: JLT 9.09.2005
Rev2: BCO 5.2.2019
]]--

-- Some basic examples first

print("Modulo(5, 2) = "..math.mod(5, 2))
print("Modulo(12, 5) = "..math.mod(12, 5))
print("Floor(6.82563) = "..math.floor(6.82563))

binaryValue = ""								-- Declare a string to hold the binary values

data = 34568
print("The integer value = ",data)

-- Let's convert the data value to a binary representation

for line = 1, 14 do
	TempValue = math.mod(data,2)				-- Use the math.mod library function, this code basically checks if data is even
	binaryValue = (TempValue)..binaryValue		-- Concatenate the string
	data = math.floor(data /2)					-- Use the math.floor library function. Returns the 
												-- integer value below a given value
	print("data = "..data)
end	

print ("Bit 14 ---> Bit 1: ",string.format("%s",binaryValue))

bitline = 14
for line = 1, 14 do
	print ("Bit ",string.format("%s",bitline)," = ",string.sub(binaryValue,line,line))
	bitline = bitline -1
end	