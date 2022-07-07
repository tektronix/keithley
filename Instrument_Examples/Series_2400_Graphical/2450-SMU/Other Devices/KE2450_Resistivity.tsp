--Script for Measuring Resistivity of a Material Using a 4-Point Probe

--Function to calculate resistivity
function resistivity(R1, R2)
	return 4.5324*((math.abs(R1)+math.abs(R2))/2)
end

--Reset the instrument
reset()

--Set to source current
smu.source.func = smu.FUNC_DC_CURRENT

--User input test current
testcurrent = display.input.number("Enter a Test Current", display.NFORMAT_PREFIX, 0, 0, 1)

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
display.settext(display.TEXT2, string.format(" = %.3e Ohms/Square", res))

--Turn the output off
smu.source.output = smu.OFF