--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

formatdata.tsp

The format.data command specifies the type of data format to use. Valid formats are: ASCII, SREAL,
REAL, REAL32, REAL64.

Commands Used:
format.data = format.[ASCII, SREAL, REAL, REAL32, REAL64]

1 or format.ASCII 	ASCII format.
2 or format.SREAL 	Single precision IEEE-754 binary format.
2 or format.REAL32 	Single precision IEEE-754 binary format.
3 or format.REAL 	Double precision IEEE-754 binary format.
3 or format.REAL64 	Double precision IEEE-754 binary format.
		.

Rev1: JLT 9.09.2005
]]--

-- This example shows the variation in the output when setting the different format data types. Note that
-- the 'printnumber' functions must be used so that you can see the binary result differences. However,
-- using the 'tonumber(x,[base])' function converts the floating point binary number 'x' to a 
-- representative number. If x is already a number, or a convertible string, then the number is 
-- returned; otherwise, it returns nil.

format.asciiprecision = 6
format.byteorder = format.NORMAL				-- Normal Byte order

smua.source.func = smua.OUTPUT_DCVOLTS			-- Set the source function to DC Volts
smua.source.output = smua.OUTPUT_ON				-- Turns on the output

-- ASCII Data output
format.data = format.ASCII
print("ASCII Data output")
for volts = 1, 5 do							-- Create a For..Do loop to sweep from 1 to 5 volts
   	smua.source.levelv = volts				-- Set the output level to the integer value of j
--   	delay(.25)
   	current = smua.measure.i( )				-- Measure the current.
   	print(current)							-- Print the measured current
end

print("")
print("")
delay(2)

-- SREAL Data output
format.data = format.SREAL
print("SREAL Data output")
for volts = 1, 5 do							-- Create a For..Do loop to sweep from 1 to 5 volts
   	smua.source.levelv = volts				-- Set the output level to the integer value of j
--   	delay(1)
   	current = smua.measure.i( )				-- Measure the current.
   	printnumber(current)
   	print(tonumber(current,10))				-- Print the measured current
end	

print("")
print("")
delay(2)

-- REAL Data output
format.data = format.REAL
print("REAL Data output")
for volts = 1, 5 do							-- Create a For..Do loop to sweep from 1 to 5 volts
   	smua.source.levelv = volts				-- Set the output level to the integer value of j
--   	delay(1)
   	current = smua.measure.i( )				-- Measure the current.
   	printnumber(current)
   	print(tonumber(current,10))				-- Print the measured current
end

print("")
print("")
delay(2)

-- REAL32 Data output
format.data = format.REAL32
print("REAL32 Data output")
for volts = 1, 5 do							-- Create a For..Do loop to sweep from 1 to 5 volts
   	smua.source.levelv = volts				-- Set the output level to the integer value of j
--   	delay(1)
   	current = smua.measure.i( )				-- Measure the current.
	printnumber(current)
   	print(tonumber(current,10))				-- Print the measured current
end

print("")
print("")
delay(2)

-- REAL64 Data output
format.data = format.REAL64
print("REAL64 Data output")
for volts = 1, 5 do							-- Create a For..Do loop to sweep from 1 to 5 volts
   	smua.source.levelv = volts				-- Set the output level to the integer value of j
--   	delay(1)
   	current = smua.measure.i( )				-- Measure the current.
	printnumber(current)
   	print(tonumber(current,10))				-- Print the measured current
end

smua.source.output = smua.OUTPUT_OFF			-- Turns off the output
