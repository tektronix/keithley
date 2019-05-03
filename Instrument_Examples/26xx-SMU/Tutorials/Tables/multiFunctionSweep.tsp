--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

MultiFunctionSweep.tsp

This tutorial example shows how to use a table to sweep currents and voltages. 

Test Script Language makes extensive use of the data type table, which is essentially a very flexible
array like data type. For examples, let's define a table called voltages with values for the table.

voltages = {1, 2, 3, 4)

This is a table with four elements, which are numbers. Tables can also contain strings, attributes, or even functions



Rev1: JLT 09.21.2005


The following example creates what Keithley refers to as a Source-Memory list. This list type is used
frequently with the Keithley 2400 SourceMeter but it implemented using a script with the 260x.
A table is defined with various attributes. In the table, we will define what function will be used as
the sourcing function, what that source level will be, and what the measurement function will be. So
instead of just numbers, we can insert attributes into the table and manipulate the table to the required
measurements.

In the for..loop, we check what the sourcing function is and output the value, then make the measurement.
We define an alias 'step' to hold the parameters of the defined table. Essentially, we are associating
a variable to the parameters, much like in Visual Basic and C.

Should your application require more or fewer test points, you simple modify the table. There is no need
to update the for loop. A Lua function, 'table.getn()' is used to determine the number of points in the
table which controls the loop.
--]]

reset()													-- Reset 260x
sourceMem = { { func = 'v', level = 10, meas = 'i' },	-- Define points for the equivalent Source-Memory  
	    { func = 'i', level = 0.1, meas = 'v' },		-- Sweep in the 2400. Parameters define the source 
	    { func = 'i', level = 0.1, meas = 'i' },		-- function, the output value, and the measurement  
	    { func = 'v', level = 1, meas = 'i' }, 			-- function.
	    { func = 'i', level = 0.001, meas = 'v' } }

readings = { }											-- Define table readings to hold measurements.

for j = 1, table.getn(sourceMem) do						-- Set for..do loop from 1 to 5
    step = sourceMem[j]									-- Alias step to hold the parameters of sourceMem[j]
	if (step.func == 'v') then							-- If  the parameter func = v, then
		smua.source.func = smua.OUTPUT_DCVOLTS			--	 Set output function to DC Volts.	
		smua.source.levelv = step.level					--   Set output level to the value of parameter level
		smua.source.output = smua.OUTPUT_ON				--   Turn Source Output On
		if (step.meas == 'i') then						--   If the parameter meas = i then
			readings[j] = smua.measure.i()				--      Measure Current. Store in readings table.
		else											--   Else
			readings[j] = smua.measure.v()				--      Measure Voltage. Store in readings table.
		end												--   End if
		smua.source.output = smua.OUTPUT_OFF			--   Turn Source Output Off
	else												-- Else step.func = 'i'
		smua.source.func = smua.OUTPUT_DCAMPS			--   Set output function to DC Amps.
		smua.source.leveli = step.level					--   Set output level to the value of parameter level
		smua.source.output = smua.OUTPUT_ON				--   Turn Source Output On
		if (step.meas == 'v') then						--   If the parameter meas = v then
			readings[j] = smua.measure.v()				--      Measure Voltage. Store in readings table.
		else											--   Else
			readings[j] = smua.measure.i()				--      Measure Current. Store in readings table. 
		end												--   End if
		smua.source.output = smua.OUTPUT_OFF			--   Turn Source Output Off
	end													-- End If
end														-- End of For..Do loop		



-- ==============================================================================================
-- This line, not in the example, prints the result of the measurement so you can verify the test.
printnumber(readings[1],readings[2],readings[3],readings[4],readings[5])
