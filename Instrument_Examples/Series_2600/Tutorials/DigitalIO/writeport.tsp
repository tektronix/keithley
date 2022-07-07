--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

writeport.tsp

Programs the 260x to write a port value to the Digital I/O. This example will increment the port value
from 0 to 16383, which will turn on all of the bits.


Commands used in this example:
digio.writeport(data)
Where:
		data		Value to write to the port; 0 to 16383.

Rev1: JLT 8.15.2005
]]--

-- Let's reset the 260x to a known default condition first
reset()

-- Let's set up a loop to write values to the port from 0 to 16383

for portVal = 0, 16383 do
	print("Writing to the port a value of ",string.format("%s",portVal))
	digio.writeport(portVal)
--	delay(.1)
end
