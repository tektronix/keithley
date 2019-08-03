-- calculate the two constant m and b of the linear conversion, apply them as Math operation and set unit
-- Y = m.X+b

function GetX1Y1X2Y2_custom()
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
	return X1,Y1,X2,Y2,displayunit
end

function GetX1Y1X2Y2_VtoA()
	displayunit = "AM"   -- M: calculated value, avoid confusion with a real "A" measurement
	X1 = 0
	Y1 = 0
	repeat
		X2 = display.input.number("Resistor value (Ohm):", display.NFORMAT_PREFIX, 1)
		if X2 <= 0 then
			warningprompt = display.prompt(display.BUTTONS_NONE, "The resistor must be > 0 Ohm, try again.")
			delay(2)
			display.delete(warningprompt)
		end 
	until X2 > 0
	Y2 = 1
	return X1,Y1,X2,Y2,displayunit
end

function GetX1Y1X2Y2_0to100percent()
	displayunit = "%"
	X1 = 0
	Y1 = 0
	repeat
		X2 = display.input.number("Value representing 100%:", display.NFORMAT_PREFIX)
		if X2 == 0 then
			warningprompt = display.prompt(display.BUTTONS_NONE, "The value must be different from 0, try again.")
			delay(2)
			display.delete(warningprompt)
		end 
	until X2 != 0
	Y2 = 100
	return X1,Y1,X2,Y2,displayunit
end

function SetLinearConversion(X1,Y1,X2,Y2,displayunit)
-- prcoess input and set m, b and unit
	m = (Y2-Y1) / (X2-X1)
	dmm.measure.math.format = dmm.MATH_MXB
	dmm.measure.math.mxb.mfactor = m
	dmm.measure.math.mxb.bfactor = Y1 - (m * X1)
	dmm.measure.math.enable = dmm.ON
	buffer.unit(buffer.UNIT_CUSTOM1, displayunit)
	defbuffer1.clear()  --try not to mix units in one buffer
	--dmm.digitize.math.format = dmm.MATH_MXB   --maybe added later
	--dmm.digitize.math.mxb.mfactor = m
	--dmm.digitize.math.mxb.bfactor = Y1 - (m * X1)
	--dmm.digitize.math.enable = dmm.ON
end

-- get the user input 
optionID = display.input.option("Linear Conversions:","Custom", "Volt -> Amp, R?", "0-X -> 0-100%","1 -> 1, 7 digit" )

-- process based on type of conversion
if optionID == display.BUTTON_OPTION1 then
	X1,Y1,X2,Y2,displayunit = GetX1Y1X2Y2_custom()
	SetLinearConversion(X1,Y1,X2,Y2,displayunit)
elseif optionID == display.BUTTON_OPTION2 then
	X1,Y1,X2,Y2,displayunit = GetX1Y1X2Y2_VtoA()
	SetLinearConversion(X1,Y1,X2,Y2,displayunit)
elseif optionID == display.BUTTON_OPTION3 then
	X1,Y1,X2,Y2,displayunit = GetX1Y1X2Y2_0to100percent()
	SetLinearConversion(X1,Y1,X2,Y2,displayunit)
elseif optionID == display.BUTTON_OPTION4 then
	displayunit=tostring(dmm.measure.unit)
	displayunit = string.sub(displayunit, 10, 10)
	SetLinearConversion(0,0,10,10,displayunit)
elseif optionID == display.BUTTON_CANCEL or optionID == nil then
	buffer.unit(buffer.UNIT_CUSTOM1, "X")
	warningprompt = display.prompt(display.BUTTONS_NONE, "OK, linear is not your thing now ;)")
	delay(3)
	display.delete(warningprompt)
end
