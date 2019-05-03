--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

PrintNumber.tsp

This tutorial illustrates how the printnumber() command works.

printnumber(v1, [, vn]

Where:   
v1...vn   	Numbers to print


Rev1: JLT 5.23.2005
]]--


for Loop1 = 1, 3 do
	for Loop2 = 1, 3 do
		for Loop3 = 1, 3 do
			printnumber(Loop1,Loop2,Loop3)
		end										-- End for Loop3
	end											-- End for Loop2		
end												-- End for Loop1

delay(1)
print("")
print("Now the 260x will take measurements and print the data using printnumber().")
print("")

-- Execute a simple sweep. Use printnumber() to display values.
ON = 1
OFF = 0
smua.reset()
smua.source.output = ON

timer.reset()
print("volts","","current","time")
for volts = 1, 10 do
	smua.source.levelv = volts
	reading = smua.measure.i()
	printnumber(volts,reading,timer.measure.t())
end

smua.source.output = OFF

print("Test Complete")
