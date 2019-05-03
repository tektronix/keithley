--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Delay.tsp

Programs the 260x to sweep from 1 to 10 volts, and make a measurement after a delay period.
Each time the delay executes, the delay increase in time using the values from the 'FOR' loop.
Measurements will be displayed along with the delay time.



Rev1: JLT 5.23.2005
Rev2: BCO 5.2.2019
]]--

-- Set up SMUA for the test
reset()
smua.source.func = smua.OUTPUT_DCVOLTS			-- Set the source function to DC Volts
smua.source.autorangev = smua.AUTORANGE_ON        -- Autorange voltage
smua.measure.autorangei = smua.AUTORANGE_ON       -- Autorange current
smua.source.output = smua.OUTPUT_ON			-- Turns on the output
for j = 1, 10 do							-- Create a For..Do loop to sweep from 1 to 10 volts
     smua.source.levelv = j					-- Set the output level to the integer value of j
     delay(j)								-- Delay the amount of time that j in the loop is equivalent to.
     current = smua.measure.i( )				-- Measure the current.
     print("Delay time = "..j.." seconds.")		-- Print the delay time
     print("Source Voltage = "..j.." Volts. Measured Current = "..current.." Amps.") -- Print the sourced voltage and measured current
end										-- End of the For..Do loop
smua.source.output = smua.OUTPUT_OFF			-- Turns off the output
