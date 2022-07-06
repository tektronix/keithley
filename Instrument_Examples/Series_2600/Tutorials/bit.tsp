--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Bit.tsp

This tutorial illustrates the use of the Bit commands.


value = bit.bitand(value1, value2)  
Where:
		value1 		First number for the AND operation.
		value2 		Second number for the AND operation.
		value 		Returned result of the AND operation.
   
value = bit.bitor(value1, value2)
Where:
		value1 		First number for the OR operation.
		value2 		Second number for the OR operation.
		value 		Returned result of the OR operation.

value = bit.bitxor(value1, value2)
Where:
		value1 		First number for the XOR operation.
		value2 		Second number for the XOR operation.
		value 		Returned result of the XOR operation.

value = bit.clear(value1, index)
Where:
		value1 		Given number.
		index 		Index position of the bit to be cleared (1 to 32).
		value 		Returns the result of the manipulation.
 
value = bit.get(value1, index) 
Where:
		value1 		Given number.
		index 		Index position of the bit to be retrieved (1 to 32).
		value 		Returned weighted value of the bit.
 
value = bit.getfield(value1, index, width)
Where:
		value1 		Given number.
		index 		Index position of the first bit; 1 to (33  width).
		width 		Field width  number of bits to be included in the field; 1 to 24.
		value 		Returned value of the bit field.
  
value = bit.set(value1, index)  
Where:
		value1 		Given number.
		index 		Index position of the bit to be set (1 to 32).
		value 		Returned value of the new number.

value = bit.setfield(value1, index, width, fieldvalue)  
Where:
		value1 		Given number.
		index 		Index position of the least significant bit of the field; 1 to (33  width).
		width 		Field width  number of bits in the field; 1 to 24.
		fieldvalue 	Value to write to the field.
		value 		Returned value of the new number.

value = bit.test(value1, index)  
Where:
		value1 		Given number.
		index 		Index position of the bit to be tested (1 to 32).
		value 		Returned decimal value of the bit.

value = bit.toggle(value1, index)
Where:
		value1 		Given number.
		index 		Index position of the bit to be toggled (1 to 32).
		value 		Returned value of the new number.	



Rev1: JLT 06.01.2005
]]--

reset()

-- For this example, we will set 'value1' to 21 and 'value2' to 25
-- Note that '\n' is used to print a new line.

value1 = 21
value2 = 25

-- Perform the bit AND function
print("Bitwise logical AND operation")
value = bit.bitand(value1,value2)
print(value1," AND ",value2," = ",value,"\n")


-- Perform the bit OR function
print("Bitwise logical OR operation")
value = bit.bitor(value1,value2)
print(value1," OR ",value2," = ",value,"\n")

-- Perform the bit XOR function
print("Bitwise logical XOR operation")
value = bit.bitor(value1,value2)
print(value1," XOR ",value2," = ",value,"\n")


-- Peform a bit clear on value2 with an index of 4
print("Bit CLEAR operation")
value = bit.clear(value2, 4)
print(value2," after clearing bit index 4 = ",value,"\n")


-- Get the bit information for value1. This example only looks at the first 16 bits.
print("Bit GET operation")
for index = 1,16 do
	value = bit.get(value1,index)
	print("At Bit Index = ",index,", the bit value = ",value)
end	
print()  -- Print a space between sections

-- This part of the example returns a field of bits starting at a given index position,
-- and prints the value. This example only will look at field of 8 bits.
print("Bit GETFIELD operation")
for index = 1, 8 do 
	value = bit.getfield(value2, index, 8)
	print("With an width of 8 and Index = ",index,", the new value = ",value)
end
print()  -- Print a space between sections


-- This part will set a bit in value1 at index 6 to change the value of value1. This new value1 will
-- be used in the remaining sections.
print("Bit SET operation")
value = bit.set(value1, 6)
print(value1,"after setting bit index 6 = ",value,"\n")
value1 = value					-- Updates value1 to the new value for the next sections.


-- This part will overwrite a bit field at a given index position set by the loop. The value that 
-- will be overwritten will be that of 'value1'. Width will be 4. Watch how 'value1' is changed.
-- The field value to be used is 5 (Binary 0101)
print("Bit SETFIELD operation")
for index = 1, 8 do
	value = bit.setfield(value1, index, 4, 5)
	print("After overwriting 'value1', starting at Index = ",index," with a binary value of 0101, the new value = ",value)
end
print()		-- Print a space between sections

	
-- This next section performs returns the Boolean value (true or false) of a bit at a given index position.
-- We will use the last value computed in the previous section for 'value1'.
print("Bit TEST operation")
value1 = value
for index= 1, 11 do
	value = bit.test(value1,index)
	print("The boolean value at Index = ",index,"is ",value)
end
print()		-- Print a space between sections
	
	
-- This final section toggles a bit. We will use 'value2' and toggel the bit at index = 2
print("Bit TOGGLE operation")
value = bit.toggle(value2, 2)
print("After toggling the bit at index 2, the new value of 'value2' = ",value)



