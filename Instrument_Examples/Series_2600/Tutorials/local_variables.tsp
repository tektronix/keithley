--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

local_variables.tsp

Local variables greatly improve the speed of TSP scripts, ~10us per "." removed in many cases.  They also
keep the instrument's memory clean.  TSP has automatic memory management, but keeping global variables
around can make mistakes harder to find.

This tutorial will help demonstrate the importance of using local variables

Rev1: BCO 5.2.2019
]]--

-- Let's make a new, fake attribute, this could stand in for any of functions or attributes in the SMU command set
globalTable = {}
globalTable.secondtable = {}
globalTable.secondtable.value = 1 

timer.reset()
for i = 1, 100000 do         -- Now we'll iterate with this value
    globalTable.secondtable.value = globalTable.secondtable.value + 1
end
elapsedTime = timer.measure.t()
print("Elapsed time with global variable = "..elapsedTime)

-- Now we'll do the same thing with a local variable
local var = 1

timer.reset()
for i = 1, 100000 do         -- Now we'll iterate with this value
    var = var + 1
end
elapsedTime = timer.measure.t()
print("Elapsed time with local variable = "..elapsedTime)
print(" ")

-- The difference you saw here was likely small, but in larger scripts with many variables, the timing difference can add up!

-- However! When using local variable, you have to be careful that the variable you're seeing right now is the one you think!

x = 12 -- global variable
print("global x = "..x) --> 12
do -- new block
    x = x - 2 -- This is adjusting the gloabl x to 10
    local x = x -- new, local, 'x', with value 10. We can no longer see the global 'x'
    print("local x = "..x) --> 10
    x = x+1
    do -- another block
        local x = x+1 -- another 'x'
        print("inner local x = "..x) --> 12
    end
end
print("again, global x = "..x) --> 10 (the global one)