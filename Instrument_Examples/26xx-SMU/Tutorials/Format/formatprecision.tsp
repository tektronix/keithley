--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

formatprecision.tsp

The format.asciiprecision command sets the precision for the ASCII data format.

format.asciiprecision = <precision value>
Where:
		precision value 		A value from 1 to 16. Default is 6.
		.


Rev1: JLT 9.09.2005
]]--

-- This example shows how you can change the ASCII precision and see how the results are returned with the
-- set value of the precision

smua.source.func = smua.OUTPUT_DCVOLTS			-- Set the source function to DC Volts
smua.source.output = smua.OUTPUT_ON				-- Turns on the output

for digits = 3, 10 do							-- Use the loop values to set the ASCII precision
	print("ASCII Precision set to ",digits,"digits.")
	format.asciiprecision = digits
	for j = 1, 5 do								-- Create a For..Do loop to sweep from 1 to 15 volts
    	smua.source.levelv = j					-- Set the output level to the integer value of j
     	current = smua.measure.i( )				-- Measure the current.
     	print("Source Voltage = ",j," Volts. Measured Current = ",current," Amps.")
     											-- Print the sourced voltage and measured current
    end
    print("")
end												-- End of the For..Do loop
smua.source.output = smua.OUTPUT_OFF			-- Turns off the output
