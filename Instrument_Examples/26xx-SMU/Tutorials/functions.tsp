--[[ 
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Functions.tsp 

This tutorial will demonstrate how functions work in TSP

Rev1: BCO 5.2.2019
-- ]]  

-- First, we'll define a basic function that multiplies it's argument by 2

function x2(num)
    return num * 2
end

print("For input "..tostring(5)..", x2 returns "..x2(5).."\n")

-- Almost anything can be passed to function, including other functions

function applyToTable(tab, f)           -- This function applies function, f, to each item in a table, tab, and returns the result
    newtab = {n=table.getn(tab)}
    for index = 1, table.getn(tab) do
        tab[index] = x2(tab[index])
    end
    return tab
end

testTable = {1, 2, 3, 4, 5}             -- Make a new table
testTable = applyToTable(testTable, x2)
for index = 1, table.getn(testTable) do
    print(testTable[index])             -- Print the table after x2 has been applied to every item in it
end
print(" ")

-- You can also create functions that take a variable number of arguments, commonly called varargs.
-- Use use the constructor, '...' as the last input varaible to your function.
-- All extra arguments are then placed in a table called arg, let's look at an example

function sum(a, b, ...)             -- This function returns the sum of every number argument passed to it, it reques at least 2 arguments
    result = a+b
    for i = 1, arg.n do          -- Loop over every extra parameter passed, arg.n = the number of extra arguments
        result = result + arg[i]
    end
    return result
end

result = sum(10, 20, 30, 40, 50, 60, 70, 80)
print("sum(10, 20, 30, 40, 50, 60, 70, 80) = "..bigNumber)
print(" ")

-- A couple other examples with functions
-- Let's define a few new functions

function f(a, b) 
    return "For f, a = ",a," and b = ", b
end
function g(a, b, ...) 
    return "For g, a = ", a," and b = ", b,". There are ", arg.n," other arguments"
end
function r() return 1,2,3 end   --This function doesn't take any arguments, that's fine too

-- Let's play with these functions by calling passing them different arguments
print("Example 1: ", f(3))
print("Example 2: ", f(3, 4))
print("Example 3: ", f(3, 'four', 5))
print("Example 4: ", f(r(), 10))
print("Example 5: ", f(r()))
print("Example 6: ", g(3))
print("Example 7: ", g(3, 4))
print("Example 8: ", g(3, 4, '10', {11, 12, 13}))
print("Example 9: ", g(5, r()))