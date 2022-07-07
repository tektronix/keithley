--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

triggerin.tsp

This example will perform a sweep. The sweep will wait for an input trigger on line 1 before each step
of the sweep is executed. If no trigger is received after a specific amount of time, the sweep will
execute the step and then wait for the next trigger.


Commands used in this example:
digio.trigger[line].assert()
Where:
		line		Asserts a trigger on the specified line.
		
digio.trigger[line].clear()
Where:
		line		Clears a trigger event on a digital I/O line.
		
digio.trigger[line].mode = <mode>
Where:
		line		Line is a digital I/O trigger line: 1 to 14
		mode		Set tmode to one of the following values:
						1 or digio.TRIG_FALLING       
								Input: Detects falling edge triggers.
								Output: Asserts TTL-low trigger pulse.
						2 or digio.TRIG_RISING         
								Input: Detects rising edge triggers.
								Output: Asserts TTL-high trigger pulse.
						3 or digio.TRIG_EITHER         
								Input: Detects rising or falling edge triggers.
								Output: Asserts a TTL-low trigger pulse.
						5 or digio.TRIG_SYNCHRONOUS             
								Input: Detects falling edge-triggers, and then latch and drive them low.
								Output: Asserts a TTL-low trigger pulse.
								
digio.trigger[line].pulsewdith = <width>
Where:
		line		Line is a digital I/O trigger line: 1 to 14.
		width		The length of time in seconds that the trigger line will be asserted for 
					output triggers.

digio.trigger[line].release()
Where:
		line		Line is a digital I/O trigger line: 1 to 14.
	
		
digio.trigger[line].wait(timeout)
Where:
		line		Line is a digital I/O trigger line: 1 to 14.
		timeout		Set timeout in seconds 
	
Rev1: JLT 8.15.2005
Rev2: BCO 5.2.2019
]]--

-- Let's reset the 260x to a known default condition first
reset()

-- Let's set up the input and output trigger specifics.
digio.trigger[1].mode = digio.TRIG_FALLING			-- Configure line 1 to wait for a falling edge trigger
digio.trigger[2].mode = digio.TRIG_FALLING			-- Cofnigure line 2 to assert a falling edge trigger
digio.trigger[2].pulsewidth = 0.5					-- Half second pulse width for output trigger.
digio.trigger[1].clear()							-- Clear any triggers

-- Let's set up a loop to perform a very simple 10 point voltage sweep

smua.source.func = smua.OUTPUT_DCVOLTS				-- Set for DC Volts output
smua.source.output = smua.OUTPUT_ON					-- Turn the output on

for volts = 1, 10 do
	digio.trigger[2].assert()						-- Assert the trigger
	digio.trigger[1].wait(5)						-- Wait no more than 5 seconds for a trigger
	smua.source.levelv = volts						-- Output a voltage
	reading = smua.measure.i()						-- Take a measurement
	print("At output volts = ",volts,", the measured current is ",reading," amps")
	digio.trigger[1].clear()						-- Clear the trigger event
end	

smua.source.output = smua.OUTPUT_OFF				-- Turn the output off
