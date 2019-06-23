-- Burden Voltage Check
-- Check voltage drop on selected current range of max current in default buffer.
LeadsResistance = 0.04 --ohm

function RangeResistance(Range)

 if Range == 3 or Range==1 then
 	return 0.270
 elseif Range == 0.1  then
 	return 1.235
 elseif Range == 0.01  then
 	return 12.53
 elseif Range == 0.001  then
 	return 130.86
 elseif Range == 0.0001  then
 	return 1039.6
 elseif Range == 0.00001  then
 	return 10130
 elseif Range ==10  then
 	return 0.0137
 else return 10130
 end
end


if defbuffer1.n > 0 then
	statsVar = buffer.getstats(defbuffer1)
	Range = dmm.measure.range	
	DMMResistance = RangeResistance(Range)
	TotalResistance = DMMResistance + LeadsResistance
	BurdenMaxRange = Range * TotalResistance
	if statsVar.max.reading == 9.9e+37 then -- in case of overflow in buffer 
		BurdenLastMeas = defbuffer1[defbuffer1.endindex] * TotalResistance
		display.settext(display.TEXT1, math.floor(BurdenLastMeas * 1000).." mV (Last Meas.)")
	else
		BurdenMaxMeas=statsVar.max.reading * TotalResistance	
		display.settext(display.TEXT1, math.floor(BurdenMaxMeas * 1000).." mV (Max.)")
	end
	display.settext(display.TEXT2, math.floor(BurdenMaxRange * 1000).." mV Full Range")
	display.changescreen(display.SCREEN_USER_SWIPE)
end
