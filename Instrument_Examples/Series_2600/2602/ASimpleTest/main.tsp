ON = 1
OFF = 0

beeper.beep(1,500)
smub.reset()
smub.source.output = ON
--TODO turn autozero off later

for i = 0, 1, 0.01 do
	smub.source.levelv = i
	local reading = smub.measure.i()
	print( "Current reading = " .. reading)
end

--if reading < 10 then print("pass")end
display.clear()
display.setcursor (1,1)
display.settext ("hello")
smub.source.output = OFF