--[[
	Save defbuffer1 + basic statistics to USB flash drive. 
]]

if file.usbdriveexists() == 0 then   -- Check if USB drive is inserted
	display.prompt(display.BUTTONS_OK, "Please insert a USB flash drive into the front-panel USB port.")	   
	result = display.waitevent()  -- result isn't used, always button 'ok'
	loopcount = 0
	while (file.usbdriveexists() == 0 and loopcount<8) do-- Wait up to 4 sec for the USB to be mounted after 'ok'
		loopcount = loopcount + 1
		delay(0.5)
	end
end

if defbuffer1.n > 0 and file.usbdriveexists() != 0 then
	statsVar = buffer.getstats(defbuffer1)
	description = display.input.string("Description (file name)",display.SFORMAT_ANY)
	fileVar = file.open("/usb1/"..description ..".csv", file.MODE_WRITE)
	strunit = defbuffer1.units[1]
	sep=","  -- separator ',' used in the csv file.
	--sep="	" -- tab may be preferred.
	-- TODO: Save the buffer with the first position being the oldest measurement, not position 1, using defbuffer1.startindex
	file.write(fileVar, "Relative Time"..sep.."Reading ("..strunit..")"..sep..sep..description .."\n")
	if defbuffer1.n >= 4 then -- If not more than 4 readings, don't print statistics
		starti = 5
		file.write(fileVar, defbuffer1.relativetimestamps[1]..sep..defbuffer1.readings[1]..sep..sep.."Mean:"..sep..statsVar.mean.."\n")
		file.write(fileVar, defbuffer1.relativetimestamps[2]..sep..defbuffer1.readings[2]..sep..sep.."StdDev:"..sep..statsVar.stddev.."\n")
		file.write(fileVar, defbuffer1.relativetimestamps[3]..sep..defbuffer1.readings[3]..sep..sep.."Min:"..sep..statsVar.min.reading.."\n")
		file.write(fileVar, defbuffer1.relativetimestamps[4]..sep..defbuffer1.readings[4]..sep..sep.."Max:"..sep..statsVar.max.reading.."\n")
	else
		starti = 1
	end
	for i = starti, defbuffer1.n do
    	file.write(fileVar, defbuffer1.relativetimestamps[i]..sep..defbuffer1.readings[i].. "\n")     
	end
	file.close(fileVar)
	beeper.beep(0.1, 1000) -- ready beep	
else
	beeper.beep(0.5, 100) -- fail beep	
end 
