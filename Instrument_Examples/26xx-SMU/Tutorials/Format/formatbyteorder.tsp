--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

formatbyteorder.tsp

The format.byteorder command specifies the binary byte order for data printed using the 
printnumber and printbuffer functions.

Commands used:
format.data = format.[NORMAL, BIGENDIAN, NETWORK, SWAPPED, LITTLEENDIAN]

0 or format.NORMAL Most significant byte first.
0 or format.BIGENDIAN Most significant byte first.
0 or format.NETWORK Most significant byte first.
1 or format.SWAPPED Least significant byte first.
1 or format.LITTLEENDIAN Least significant byte first.
		.


Rev1: JLT 9.09.2005
Rev2: BCO 5.2.2019
]]--

-- This example shows the variation in the output when setting the different format binary byte orders. Note that
-- the 'printnumber' functions must be used so that you can see the binary result differences. However,
-- using the 'tonumber(x,[base])' function converts the floating point binary number 'x' to a 
-- representative number. If x is already a number, or a convertible string, then the number is 
-- returned; otherwise, it returns nil. You should be able to see the difference in the two byte orders
-- from the results printed.

reset()
format.data = format.REAL					-- Double-precision IEEE Std 754 binary format

smua.source.func = smua.OUTPUT_DCVOLTS			-- Set the source function to DC Volts
smua.source.output = smua.OUTPUT_ON				-- Turns on the output

-- This loop will run through the two main orders, NORMAL and SWAPPED.

for j = 0, 1 do								-- 0 = Normal, 1 = Swapped
	format.byteorder = j
	print("Byte Order = ",j," (0=Normal, 1=Swapped)")
	for volts = 1, 5 do						-- Create a For..Do loop to sweep from 1 to 5 volts
   		smua.source.levelv = volts			-- Set the output level to the integer value of j
   		voltage = smua.measure.v( )			-- Measure the sourced voltage.
   		printnumber(voltage)
   		print(tonumber(voltage,10))			-- Print the measured voltage
   	end
   	print("")
end	

