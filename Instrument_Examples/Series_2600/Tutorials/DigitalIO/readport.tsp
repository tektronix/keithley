--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

readport.tsp

Programs the 260x to read the digital I/O port. The program then breaks down the port value into
its binary equivalent.

Commands used in this example:
data = digio.readport()
	Where:
			data 	 	Returns the result of the Digital I/O port that is read.

	The binary equivalent of the returned value indicates the input pattern on the I/O port. The least 
	significant bit of the binary number corresponds to line 1 and bit 14 corresponds to line 14. 
	For example, a returned value of 170 has a binary equivalent of 00000010101010. Lines 2, 4, 6 and 8 
	are high (1), and the other 10 lines are low (0).

		 	 		
Rev1: JLT 8.15.2005
]]--

-- Let's reset the 260x to a known default condition first
reset()

binaryValue = ""					-- Declare a string to hold the binary values


data = digio.readport()				-- Read the port
print("The Digital I/O port reads as ",data)

-- Let's convert the port value to a binary representation

for line = 1, 14 do
	TempValue = math.mod(data,2)
	binaryValue = (TempValue)..binaryValue
	data = math.floor(data /2)
end	

print ("Bit 14 ---> Bit 1: ",string.format("%s",binaryValue))

bitline = 14
for line = 1, 14 do
	print ("Bit ",string.format("%s",bitline)," = ",string.sub(binaryValue,line,line))
	bitline = bitline -1
end	
