--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

readbit.tsp

Programs the 260x to read one digital I/O line. This example will read all 14 digital I/O lines.

Commands used in this example:
data = digio.readbit(line)
	Where:
		data 	 	Returns the result of the Digital I/O line that is read.
		line		Specifies which digital I/O line to read

A returned value of 0 indicates that the line is low. A returned value of 1 indicates that the 
line is high.
		 	 		
Rev1: JLT 8.15.2005
Rev2: BCO 5.2.2019
]]--

-- Let's reset the 26xx to a known default condition first
reset()

-- Let's set up a loop to read all 14 lines

for line = 1, 14 do
	data = digio.readbit(line)
	print("Line ",string.format('%u',line),"=",string.format('%u', data))
end
