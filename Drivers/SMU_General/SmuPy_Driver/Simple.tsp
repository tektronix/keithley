-- *****************************************************************************
function do_beep(duration, frequency, count)
	for i = 1, count, 1 do
		beeper.beep(duration, frequency)
		delay(0.1)
	end
end

print("Functions Loaded")
