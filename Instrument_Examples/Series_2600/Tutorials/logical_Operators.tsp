--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

LogicalOperators.tsp

The logical operators are 'and', 'or', and 'not'. Like control structures, all logical operators 
consider false and nil as false and anything else as true. 

The operator 'and' returns its first argument if it is false, otherwise it returns its second argument. 

The operator 'or' returns its first argument if it is not false; otherwise it returns its second 
argument.

The operator 'not' always returns true or false:


Rev1: JLT 10.29.2005

The following example utilizes the string library commands discussed above. For additional string 
library details, refer to the Lua programming website at 'http://www.lua.org'.

]]--

-- Let's run a couple of logical operations to see the results.
print('4 and 5 = ', 4 and 5)

print('nil and 13 = ', nil and 13)

print('false and 13 = ', false and 13)

print('4 or 5 = ', 4 or 5)

print('5 or 4 = ', 5 or 4)

print('false or \'str\' = ', false or 'str')

print('not nil = ', not nil)

print('not false = ', not false)

print('not 0 = ', not 0)

print('not not nil = ', not not nil)
