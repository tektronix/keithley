--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Strings.tsp

The String library provides generic functions for string manipulation, such as finding and
extracting substrings. When indexing a string in TSP Language, the first character is at position
1 (not 0). Indices may be negative and are interpreted as indexing backwards, from the end of 
the string. Thus, the last character is at position -1, and so on.

Commands used in this script:
tostring()
	Converts the Lua value at the given index to a string. The Lua value must be a string or a number; 
	otherwise, the function returns NULL.

string.byte(s [,i]) 
	Returns the internal numerical code of the i-th character of string s, or nil if the index is out of 
	range.

string.char(i1, i1, ) 
	Receives 0 or more integers. Returns a string with length equal to the number of arguments, in which 
	each character has the internal numerical code equal to its corresponding argument.

string.format(fs, e1, e2, )
	Returns a formatted version of its variable number of arguments following the description given in 
	its first argument, which must be a string. The format string follows the same rules as the print 
	family of ANSI C functions. The only differences are that the options/modifiers *, l, L, n, p, and
	h are not supported. The options c, d, E, e, f, g, G, I, o, u, X, and x all expect a numeric argument, 
	where s expects a string argument. String values to be formatted with %s cannot contain embedded zeros.

string.len(s) 
	Returns the length of the strings.

string.lower(s)  
	Returns a copy of the string s with all uppercase letters changed to lowercase.

string.rep(s, n) 
	Returns a string that is the concatenation of n copies of the string s.

string.sub(s, i [,j]) 
	Returns the substring of s that starts at i and continues until j. i and j may be negative. If j is 
	absent, then it is assumed to be equal to 1, which is the same as the string length. In particular, 
	the call string.sub(s,1,j) returns a prefix s with length j, and string.sub(s, -i) returns a suffix s 
	with length i.

string.upper(s)  
	Returns a copy of the string s with all lowercase letters changed to uppercase.


Rev1: JLT 10.28.2005
Rev2: BCO 5.2.2019

The following example utilizes the string library commands discussed above. For additional string 
library details, refer to the Lua 5.0 reference manual available at 'http://www.lua.org'.

]]--
reset()

-- First, it's important to know that you force a value that's like string to be a string
print(type(359.2),359.2)
numString = tostring(359.2)
print(type(numString), numString)
print(" ")
delay(2)

-- Let's return the secondary display string of the 2602 and do some string manipulation using the 
-- string library.

displaystring = display.gettext(false,2)
print("The secondary display shows: ",displaystring)
print(" ")
delay(2)

-- Let's use the 'string.byte' function to return the internal numerical codes

for index = 1, 32 do
	print("The internal numeric code for index = "..index.." is ",string.byte(displaystring,index))
end
print(" ")
delay(2)

-- Now, let's use the 'string.char' function to see its results. What you should see is all of the ASCII
-- characters printed.  See the 2600B Reference Manual Appendix F for what the characters should be.

for index = 0, 255 do
	print("The ASCII character for index = "..index.." is ",string.char(index))
end
print(" ")
delay(2)

-- OK, let's take a look to see how the 'string.format' function works. It follows the conventions
-- of the C function, 'printf'

print("25.39 as an Unsigned integer: ",string.format("%u", 25.39))
print("25.39 as a left-padded Unsigned integer: ",string.format("%05u", 25.39))
print("-25.39 as an Unsigned integer: ",string.format("%u", -25.39))
print("-25.39 as a signed integer: ",string.format("%d", -25.39))
print("25.39 as a floating point: ",string.format("%f", 25.39))
print("25.39 as a floating point (to 3 digits): ",string.format("%.3f", 25.39))
print("25.39 in scientific notation (big E): ",string.format("%E", 25.39))
print("25.39 in scientific notation (little e): ",string.format("%e", 25.39))
print("25.39 in scientific notation (to 2 digits): ",string.format("%.2e", 25.39))

print(" ")
delay(2)

-- Remember the string display we retrieved. Let's determine the actual string length

print("The string length of the secondary display = ",string.len(displaystring))
print(" ")
delay(2)

-- Did you notice how the display string had upper and lower case letters. We can use the 'string.lower'
-- function to get the string in all lower case.

print("The display string in lower case = ",string.lower(displaystring))
print(" ")
delay(2)

-- Lua also has a similar string function to convert to upper case as well.

print("The display string in upper case = ",string.upper(displaystring))
print(" ")
delay(2)

-- The string library 'string.rep' allows you to concatenate strings 'n' times. Let's concatenate the 
-- display string 3 times.

print("The concatenated string is ",string.rep(displaystring,5))
print(" ")
delay(2)

-- Finally, lets use the 'string.sub' function to get various substrings of the secondary display string.

for index = 1, 32 do
	print("The substring starting at index "..index.." = ",string.sub(displaystring,index))
end	
