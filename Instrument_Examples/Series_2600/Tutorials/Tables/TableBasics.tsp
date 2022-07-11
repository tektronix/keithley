--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
*********************************************************** 

TableBasics.tsp

This tutorial example shows how to use a simple table to sweep a voltage and store the readings in
another table. 

Test Script Language makes extensive use of the data type table, which is essentially a very flexible
array like data type. For examples, let's define a table called voltages with values for the table.

voltages = {1, 2, 3, 4)

This is a table with four elements, which are numbers. Tables can also contain strings or attributes


Rev1: BCO 5.2.2019


The following example shows some of the basic properties of tables.

]]--

-- First, create a table using { }

testTable = {1, 2, 3, 4, 5}

-- How manu items are in the table?

print("Table length =  "..table.getn(testTable))

-- What's in the table?

print("print(testTable) = ",testTable) -- Notice that this returns a memory address, but we can't do anything with that!
print("for item in testTable print(item) = ")
for item in testTable do
    print(item)
end

-- Let's make a new table

demoTable = {}
print("Length of new table = "..table.getn(demoTable))

-- But we need it to have a length of 10!

demoTable = {n=10}
print("Length of adjusted table = "..table.getn(demoTable))

-- Oops! I meant 15

table.setn(demoTable, 15)
print("Length of even more adjusted table = "..table.getn(demoTable))

-- Right now, this new table is filled with nil, so let's fill it with random numbers

for index = 1, table.getn(demoTable) do 
    demoTable[index] = math.random(1, 100)
    print("demoTable["..index.."] = "..demoTable[index])
end

-- Finally, we'll sort the table

table.sort(demoTable)
for index = 1, table.getn(demoTable) do 
    print("sorted demoTable["..index.."] = "..demoTable[index])
end


