--[[ 
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

PrintBuffer.tsp 

This tutorial enables a voltage source and current measurement on channels SMUA and 
SMUB of a Keithley Model 2602 System SourceMeter. Readings are stored in Nonvolatile r
eading buffers (nvbuffer1, nvbuffer2) and then printed to the output queue using the 
printbuffer() command.

printbuffer(start_index, end_index, st_1 [, st_n])

Where:   
start_index     Starting index of values to print.
end_index       Ending index of values to print.
st_1 , st_n     Sub-tables from which to print values.


Rev1: 5.24.2005 JAC
-- ]]  

src_volt = 1 										--Source Variable
num_readings = 50 									--Number of Readings

smua.measure.count = num_readings 					--Initialize buffer 
smub.measure.count = num_readings 					--Initialize buffer

smua.source.levelv = 0 								--Zero Source
smub.source.levelv = 0 								--Zero Source

smua.source.output = smua.OUTPUT_ON 				--Enable Output
smub.source.output = smub.OUTPUT_ON 				--Enable Output

smua.source.levelv = src_volt 						--Source  
smua.source.levelv = src_volt 						--Source

smua.measure.overlappedi(smua.nvbuffer1) 			--Simultaneous measurement of smua
smub.measure.overlappedi(smub.nvbuffer1) 			--and smub using Overlapped command
waitcomplete() 										--wait until measurements are complete before moving on 

print("SmuA Measurements: ") 
printbuffer(1,num_readings,smua.nvbuffer1)			--Print measurements using printbuffer()
print("")
print("SmuB Measurements: ")
printbuffer(1,num_readings,smub.nvbuffer1)			--Print measurements using printbuffer()

smua.source.output = smua.OUTPUT_OFF 				--Disable Output
smub.source.output = smub.OUTPUT_OFF 				--Disable Output

