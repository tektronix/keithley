--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

writeprotect.tsp

This program illustrates the writeprotect feature for the digital I/O port. We will set the mask to the
binary equivalent of '00000010000010', or a mask value of 130. Thus we are protecting lines 2 and 8
from being written to. We will then write out port values from 0 to 16383.

The 'writeprotect' can also be used to read back the mask value.


Commands used in this example:
digio.writeprotect = mask
Where:
		mask		Mask value to protect bit lines from being written to.

digio.writeport(data)
Where:
		data		Value to write to the port; 0 to 16383.
		

Rev1: JLT 8.15.2005
]]--

-- Let's reset the 260x to a known default condition first and reset all digital I/O lines to 0 (off)
reset()

-- Unprotect all the lines just to make sure they are!
digio.writeprotect = 0

-- Reset all digital I/O lines to 0
digio.writeport(0)

-- We will send the 'writeprotect' command for a mask value of 130
digio.writeprotect = 130
-- Let's set up a loop to write values to the port from 0 to 16383

for portVal = 0, 16383 do
	print("Writing to the port a value of ",string.format("%s",portVal))
	digio.writeport(portVal)
--	delay(.1)
end
