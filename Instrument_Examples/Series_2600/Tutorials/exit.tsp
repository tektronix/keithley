--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Exit.tsp

Commands Used:
exit()

Aborts script execution. This command will not wait for overlapped commands to complete
before terminating script execution. If overlapped commands are required to finish,
use the waitcomplete function prior to calling exit.



Rev1: JLT 9.17.2005
]]--

-- Set up SMUA for the test

smua.source.func = smua.OUTPUT_DCVOLTS			-- Set the source function to DC Volts
smua.source.output = smua.OUTPUT_ON				-- Turns on the output

-- Reset the Timer and start the loop
timer.reset()
for j = 1, 10 do							-- Create a For..Do loop to sweep from 1 to 10 volts
     smua.source.levelv = j					-- Set the output level to the integer value of j
     delay(j)								-- Delay the amount of time that j in the loop is equivalent to.
     current = smua.measure.i()				-- Measure the current.
     print("Delay time = ", j," seconds.")		-- Print the delay time
     -- print("Source Voltage = ",j," Volts. Measured Current = ",current," Amps.") -- Print the sourced voltage and measured current
	elapsedTime = timer.measure.t()			-- Get the elapsed time
     print("elapsedTime = ", string.format("%d",elapsedTime)," seconds.")          -- Print the elapsed time
	if elapsedTime > 25 then 
	     smua.source.output = smua.OUTPUT_OFF	-- Turns off the output
		exit()	    						-- If elapsed time > 25 then exit.										
     end
end												-- End of the For..Do loop
smua.source.output = smua.OUTPUT_OFF			-- Turns off the output

-- Measure the elapsed time since the timer was last reset.
elapsedTime = timer.measure.t()					
print("Execution time = ",elapsedTime," seconds.")
