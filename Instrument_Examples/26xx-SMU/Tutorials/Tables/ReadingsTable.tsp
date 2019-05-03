--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
*********************************************************** 

ReadingsTable.tsp

This tutorial example shows how to use a simple table to sweep a voltage and store the readings in
another table. 

Test Script Language makes extensive use of the data type table, which is essentially a very flexible
array like data type. For examples, let's define a table called voltages with values for the table.

voltages = {1, 2, 3, 4)

This is a table with four elements, which are numbers. Tables can also contain strings or attributes



Rev1: JLT 09.21.2005


The following example uses For..Do loop to traverse through a list of voltage values in a table. 
You can put as many values in the table and not have to worry about knowing how many values are in 
the table.

The readings are then stored in a table call CurrentReadings. By using another table in the sweep to store
the readings, we can speed up the measurement process and print the readings after the test. If you place
a resistor across SMU channel A High and Low, we can then use tables to calculate the resistance and 
print the values.

]]--

-- Create a voltage list.
VoltageList = {1, 5, -5, -4, -9, 10, 8, 2, 0, -1, 1, -2, 0.5}

-- Create an empty table to store the current measurements.
CurrentReadings = {}

smua.reset()
smua.source.func = smua.OUTPUT_DCVOLTS
smua.source.output = smua.OUTPUT_ON
 
for element= 1, 13 do
	smua.source.levelv = VoltageList[element]
	CurrentReadings[element] = smua.measure.i()
end	

smua.source.output = smua.OUTPUT_OFF

-- Calculate the resistance and print the results. Create a table to hold the resistance values.
resistances = {}

for index = 1, 13 do
	resistances[index] = VoltageList[index] / CurrentReadings[index]
	print("V=",VoltageList[index],",  I=",CurrentReadings[index],", Resistance=",resistances[index])
end

