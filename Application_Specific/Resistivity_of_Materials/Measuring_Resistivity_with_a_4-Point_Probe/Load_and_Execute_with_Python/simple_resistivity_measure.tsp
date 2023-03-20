--[[
	
Script: Measuring Resistivity of a Material
Written by: Keithley Applications Engineering (Mary Anne Tupta)
`
***********************************************************
*** Copyright 2023 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************
]]

function resistivity_4point(testcurrent)
	--Reset the instrument
	reset()
	
	--Set to source current
	smu.source.func = smu.FUNC_DC_CURRENT
	
	--Negative value of user test current
	smu.source.level = -1*testcurrent
	
	--Measure voltage
	smu.measure.func = smu.FUNC_DC_VOLTAGE
	
	--Set to 4 wire measure mode
	smu.measure.sense = smu.SENSE_4WIRE
	
	--Set the measurement unit to Ohms
	smu.measure.unit = smu.UNIT_OHM
	
	--Turn on the output
	smu.source.output = smu.ON
	
	--Take a resistance measurement
	res1 = smu.measure.read()
	smu.source.level = testcurrent
	res2 = smu.measure.read()
	
	--Calculate the resistivity from the reading
	local res = resistivity(res1, res2)
	
	--Set the display to the user swipe screen and display resistivity
	display.changescreen(display.SCREEN_USER_SWIPE)
	display.settext(display.TEXT1, string.format("Resistivity"))
	display.settext(display.TEXT2, string.format(" = %.4f Ohms/Square", res))
	
	--Turn the output off
	smu.source.output = smu.OFF
	return res
end

--Function to calculate resistivity
function resistivity(R1, R2)
	return 4.5324*((math.abs(R1)+math.abs(R2))/2)
end

print("Script file loaded!")
