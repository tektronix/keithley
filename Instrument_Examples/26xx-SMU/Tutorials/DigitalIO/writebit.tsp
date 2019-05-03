--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

writebit.tsp

Programs the 260x to write one digital I/O line. This example will write to all 14 digital I/O lines.
Each bit will be toggled on and off.


Commands used in this example:
digio.writebit(bit, data)
Where:
		bit 	 	Digital I/O line number (1 to 14)
		data		value to write to the bit; 0 (low) or 1 ( high)

Rev1: JLT 8.15.2005
]]--

-- Let's reset the 260x to a known default condition first
reset()

-- Let's set up a loop to toggle all 14 lines

for bit = 1, 14 do
	print("Writing a 1 to bit ", string.format('%u',bit))
	digio.writebit(bit, 1)
	delay(0.5)
	print("Writing a 0 to bit ", string.format('%u',bit))
	delay(0.5)
	digio.writebit(bit, 0)
end
