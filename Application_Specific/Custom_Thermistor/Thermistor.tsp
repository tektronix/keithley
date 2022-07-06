dmm.measure.func = dmm.FUNC_RESISTANCE

display.clear()
display.changescreen(display.SCREEN_USER_SWIPE)

-- 10K thermistor (44006)
defaultA = 1.0295e-3
defaultB = 2.391e-4
defaultC = 1.568e-7

a = display.input.number("Coefficient A", display.NFORMAT_EXPONENT, defaultA)
b = display.input.number("Coefficient B", display.NFORMAT_EXPONENT, defaultB)
c = display.input.number("Coefficient C", display.NFORMAT_EXPONENT, defaultC)

button = display.input.option("Unit", "\19C", "\19F", "\19K")

while (true)
do
    logR = math.log(dmm.measure.read())
	
    kelvin = 1. / (a + b * logR + c * (math.pow(logR, 3.)))
    celsius = kelvin - 273.15
    fahrenheit = (celsius * 9. / 5.) + 32.

    if (button == display.BUTTON_OPTION1) or (button == nil) then
        text = string.format("%.3f \19C", celsius)
    elseif button == display.BUTTON_OPTION2 then 
        text = string.format("%.3f \19F", fahrenheit)
    else
        text = string.format("%.3f \19K", kelvin) 
    end
	
	display.settext(display.TEXT1, text)
end
