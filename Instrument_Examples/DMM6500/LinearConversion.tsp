-- calculate the two constant m and b of the linear conversion, apply them as Math operation and set unit
-- Y = m.X+b

-- get the user input 
displayunit = display.input.string("The unit of Y: ('Pa' or ...)", display.SFORMAT_ANY)
displayunit = string.sub(displayunit, 1, 2)
X1 = display.input.number("Enter measured value X1:", display.NFORMAT_PREFIX, 0.004)
Y1 = display.input.number("Enter Y1 "..displayunit.." related to X1 "..X1..":" , display.NFORMAT_PREFIX, 0)
repeat
	X2 = display.input.number("Enter measured value X2:", display.NFORMAT_PREFIX, 0.020)
	if X1 == X2 then
		warningprompt = display.prompt(display.BUTTONS_NONE, "X2 must be different from X1, try again.")
		delay(2)
		display.delete(warningprompt)
	end 
until X1 != X2
Y2 = display.input.number("Enter Y2 "..displayunit.." related to X2 "..X2..":" , display.NFORMAT_PREFIX, 100)

-- prcoess input and set m, b and unit
m = (Y2-Y1) / (X2-X1)
dmm.measure.math.format = dmm.MATH_MXB
dmm.measure.math.mxb.mfactor = m
dmm.measure.math.mxb.bfactor = Y1 - (m * X1)
dmm.measure.math.enable = dmm.ON
buffer.unit(buffer.UNIT_CUSTOM1, displayunit)
defbuffer1.clear()  --try not to mix units in one buffer

--dmm.digitize.math.format = dmm.MATH_MXB
--dmm.digitize.math.enable = dmm.ON
