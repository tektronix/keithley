function do_beep(duration, frequency, count)
	for i = 1, count do
		beeper.beep(duration, frequency)
		delay(0.1)
	end
end
print("Loaded!!!")