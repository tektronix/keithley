--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

DisplayMeasureandDigits.tsp

Sets and displays to the Instrument Console of TSB what the current function is of the SMU along with the 
resolution.


Commands used in this example:

display.smuX.measure.function = <displaymeasure>
Where:
		displaymeasure = 	0 or 'display.MEASURE_DCAMPS' ;  Selects current measure function.
							1 or 'display.MEASURE_DCVOLTS' ; Selects volts measure function.
							2 or 'display.MEASURE_OHMS' ; Selects ohms measure function.
							3 or 'display.MEASURE_WATTS' ; Selects power measure function.
							
display.smuX.digits = <displaydigits>
Where:
		displaydigits		4 or 'display.DIGITS_4_5' ; Selects 4-1/2d resolution.
							5 or 'display.DIGITS_5_5' ; Selects 5-1/2d resolution.
							6 or 'display.DIGITS_6_5' ; Selects 6-1/2d resolution.
				
		
Rev1: JLT 7.16.2005
Rev2: BCO 5.2.2019
]]--

-- Let's reset the 260x to a known default condition first
reset()
display.screen = 0

-- Lets set the 260x to the different measurement displays and resolutions. A delay is included so you
-- can see the changes on the front panel of the 260x. We'll also retrieve the function and resolution
-- back from the 260x.

-- Set the display for DC volts and 4.5 digits
display.smua.measure.func = display.MEASURE_DCVOLTS
display.smua.digits = 5
resolution = display.smua.digits
measureFunction = display.smua.measure.func
print("Current display function is ",measureFunction,"and the resolution is ",resolution)
delay(3)

-- Set the display for DC Amps and 6.5 digits
display.smua.measure.func = display.MEASURE_DCAMPS
display.smua.digits = 4
resolution = display.smua.digits
measureFunction = display.smua.measure.func
print("Current display function is ",measureFunction,"and the resolution is ",resolution)
delay(3)

-- Set the display for Ohms and 5.5 digits
display.smua.measure.func = display.MEASURE_OHMS
display.smua.digits = 6
resolution = display.smua.digits
measureFunction = display.smua.measure.func
print("Current display function is ",measureFunction,"and the resolution is ",resolution)
delay(3)

-- Set the display for Watts and 4.5 digits
display.smua.measure.func = 3 -- display.MEASURE_WATTS
display.smua.digits = 3
resolution = display.smua.digits
measureFunction = display.smua.measure.func
print("Current display function is ",measureFunction,"and the resolution is ",resolution)