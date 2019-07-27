--[[
	Save defbuffer1 + basic statistics to USB flash drive. 
]]

function indexofmeasurement(buffer ,seqnumber)
	if seqnumber <= buffer.n and seqnumber > 0 then -- check out of range
		if buffer.startindex == 1 then   -- check if index number and sequence number is the same
			return seqnumber
		else
			indexnumber=buffer.startindex + seqnumber - 1  --index number if there is no buffer limit
			if indexnumber > buffer.capacity then 
				indexnumber = indexnumber - buffer.capacity
			end
			return indexnumber			
		end	
	else 
		return buffer.startindex  --return index of first measurement if out of range
	end
end

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
	file.write(fileVar, "Relative Time"..sep.."Reading ("..strunit..")"..sep..sep..description .."\n")
	if defbuffer1.n >= 4 then -- If not more than 4 readings, don't print statistics
		index1=defbuffer1.startindex		
		index2=indexofmeasurement(defbuffer1,2)
		index3=indexofmeasurement(defbuffer1,3)
		index4=indexofmeasurement(defbuffer1,4)
		file.write(fileVar, defbuffer1.relativetimestamps[index1]..sep..defbuffer1.readings[index1]..sep..sep.."Mean:"..sep..statsVar.mean.."\n")
		file.write(fileVar, defbuffer1.relativetimestamps[index2]..sep..defbuffer1.readings[index2]..sep..sep.."StdDev:"..sep..statsVar.stddev.."\n")
		file.write(fileVar, defbuffer1.relativetimestamps[index3]..sep..defbuffer1.readings[index3]..sep..sep.."Min:"..sep..statsVar.min.reading.."\n")
		file.write(fileVar, defbuffer1.relativetimestamps[index4]..sep..defbuffer1.readings[index4]..sep..sep.."Max:"..sep..statsVar.max.reading.."\n")
		startindex = indexofmeasurement(defbuffer1,5)
	else
		startindex = defbuffer1.startindex -- start the loop below at the oldest measurement
	end	
	
	-- using the indexofmeasurement function for each buffer index would create too much ovehead hence more code
	if defbuffer1.startindex != 1 then  -- check if index number and sequence number is different
		if startindex < defbuffer1.startindex then -- the new startindex past end of buffer already due to the added lines above
			for i = startindex, defbuffer1.endindex do
    			file.write(fileVar, defbuffer1.relativetimestamps[i]..sep..defbuffer1.readings[i].. "\n")     
			end
		else -- write buffer part before startindex and part after startindex separately
			-- Part 1 startindex to end of the buffer
			for i = startindex, defbuffer1.capacity do
    			file.write(fileVar, defbuffer1.relativetimestamps[i]..sep..defbuffer1.readings[i].. "\n")     
			end
			-- Part 2 begin buffer to endindex
			for i = 1, defbuffer1.endindex do
    			file.write(fileVar, defbuffer1.relativetimestamps[i]..sep..defbuffer1.readings[i].. "\n")     
			end
		end
	else -- sequence 1 == index 1 
		for i = startindex, defbuffer1.n do
    		file.write(fileVar, defbuffer1.relativetimestamps[i]..sep..defbuffer1.readings[i].. "\n")
    	end
    end

	file.close(fileVar)
	beeper.beep(0.1, 1000) -- ready beep	
else
	beeper.beep(0.5, 100) -- fail beep	
end 
