--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

triggerout.tsp

This example exercises the digital output to output triggers through the digital I/O port. Variable
parameters include pulsewdith.


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
]]--

-- Let's reset the 260x to a known default condition first
reset()

-- Let's set up a loop to output a trigger for a specific pulse width on line 2

for trigCount = 1, 10000 do
	
	digio.trigger[2].pulsewidth =0.005				--Set line 1 pulse width
	digio.trigger[2].mode = digio.TRIG_FALLING
													--Set line 2 mode to falling edge.
	digio.trigger[2].assert() 						--Assert trigger on line 1.
end
