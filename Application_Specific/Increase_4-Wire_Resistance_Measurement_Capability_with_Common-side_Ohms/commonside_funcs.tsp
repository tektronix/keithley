function do_beep(duration, frequency)
    beeper.beep(duration, frequency)
end

function csohmsSetup(myRange, myNplc, filterCnt, channelStr)
	reset()
	channel.open('allslots')
	errorqueue.clear()
	eventlog.clear()
	dataqueue.clear()

	-- Configure the scan channel for the slot 1 card
	-- Enable common-side ohms
	dmm.func = dmm.COMMON_SIDE_OHMS
	dmm.autorange = dmm.OFF
	dmm.range = myRange
	dmm.nplc = myNplc
	-- Enable offset compensation (though on by
	--  default when using common-side ohms
	dmm.offsetcompensation = dmm.ON
	-- Ensure autodelay and autozero are active
	dmm.autodelay = dmm.ON
	dmm.autozero = dmm.ON
	-- Enable averaging and adjust settings
	dmm.filter.type = dmm.FILTER_REPEAT_AVG
	dmm.filter.count = filterCnt
	dmm.filter.window = 0.0
	dmm.filter.enable = dmm.ON
	-- Define the settings above as a configuration
	dmm.configure.set('commonside4w')
	-- ...and apply the configuration to the channels
	-- of interest. 
	dmm.setconfig(channelStr, 'commonside4w')
	waitcomplete()
end

function setupBuffer(bufferSize)
	-- Define a custom buffer, size it, and set the append mode
	mybuffer = dmm.makebuffer(bufferSize)
	mybuffer.clear()
	mybuffer.appendmode = 1
end

function scanSetup(scanCount, channelStr)
	-- Configure the scan attributes
	scan.mode = scan.MODE_FIXED_ABR
	scan.measurecount = 1
	scan.scancount = scanCount
	scan.create(channelStr)
end

function initScan()
	scan.background(mybuffer)
end 

function computeStats()
	ch1001Avg = 0
	ch1001Max = 0
	ch1001Min = 0
	ch1001Pk2Pk = 0
		
	ch1002Avg = 0
	ch1002Max = 0
	ch1002Min = 0
	ch1002Pk2Pk = 0
	
	ch1003Avg = 0
	ch1003Max = 0
	ch1003Min = 0
	ch1003Pk2Pk = 0
	
	ch1004Avg = 0
	ch1004Max = 0
	ch1004Min = 0
	ch1004Pk2Pk = 0
	
	ch1005Avg = 0
	ch1005Max = 0
	ch1005Min = 0
	ch1005Pk2Pk = 0

	for i = 1, 50, 5 do
		ch1001Avg = ch1001Avg + mybuffer[i]
		ch1002Avg = ch1002Avg + mybuffer[i+1]
		ch1003Avg = ch1003Avg + mybuffer[i+2]
		ch1004Avg = ch1004Avg + mybuffer[i+3]
		ch1005Avg = ch1005Avg + mybuffer[i+4]
		
		if i == 1 then
			ch1001Min = ch1001Avg
			ch1001Max = ch1001Avg
			
			ch1002Min = ch1002Avg
			ch1002Max = ch1002Avg
			
			ch1003Min = ch1003Avg
			ch1003Max = ch1003Avg
			
			ch1004Min = ch1004Avg
			ch1004Max = ch1004Avg
			
			ch1005Min = ch1005Avg
			ch1005Max = ch1005Avg
		else
			
			if (mybuffer[i] < ch1001Min) then ch1001Min = mybuffer[i] end 
			if (mybuffer[i] > ch1001Max) then ch1001Max = mybuffer[i] end 
			
			
			if mybuffer[i+1] < ch1002Min then ch1002Min = mybuffer[i+1] end 
			if mybuffer[i+1] > ch1002Max then ch1002Max = mybuffer[i+1] end 
			
			
			if mybuffer[i+2] < ch1003Min then ch1003Min = mybuffer[i+2] end 
			if mybuffer[i+2] > ch1003Max then ch1003Max = mybuffer[i+2] end 
			
			
			if mybuffer[i+3] < ch1004Min then ch1004Min = mybuffer[i+3] end 
			if mybuffer[i+3] > ch1004Max then ch1004Max = mybuffer[i+3] end 
			
			
			if mybuffer[i+4] < ch1005Min then ch1005Min = mybuffer[i+4] end 
			if mybuffer[i+4] > ch1005Max then ch1005Max = mybuffer[i+4] end 
		end
	end
	
	ch1001Avg = ch1001Avg/10
	ch1002Avg = ch1002Avg/10
	ch1003Avg = ch1003Avg/10
	ch1004Avg = ch1004Avg/10
	ch1005Avg = ch1005Avg/10
	
	ch1001Pk2Pk = ch1001Max - ch1001Min
	ch1002Pk2Pk = ch1002Max - ch1002Min
	ch1003Pk2Pk = ch1003Max - ch1003Min
	ch1004Pk2Pk = ch1004Max - ch1004Min
	ch1005Pk2Pk = ch1005Max - ch1005Min
	
	--print(tostring(ch1001Avg) .. " " .. tostring(ch1001Pk2Pk) .. " " .. tostring(ch1001Max) .. " " .. tostring(ch1001Min))
end

function getChanStats(chan)
	if chan == 1001 then
		print(tostring(ch1001Avg) .. " " .. tostring(ch1001Pk2Pk) .. " " .. tostring(ch1001Max) .. " " .. tostring(ch1001Min))
	elseif chan == 1002 then
		print(tostring(ch1002Avg) .. " " .. tostring(ch1002Pk2Pk) .. " " .. tostring(ch1002Max) .. " " .. tostring(ch1002Min))
	elseif chan == 1003 then
		print(tostring(ch1003Avg) .. " " .. tostring(ch1003Pk2Pk) .. " " .. tostring(ch1003Max) .. " " .. tostring(ch1003Min))
	elseif chan == 1004 then 
		print(tostring(ch1004Avg) .. " " .. tostring(ch1004Pk2Pk) .. " " .. tostring(ch1004Max) .. " " .. tostring(ch1004Min))
	elseif chan == 1005 then 
		print(tostring(ch1005Avg) .. " " .. tostring(ch1005Pk2Pk) .. " " .. tostring(ch1005Max) .. " " .. tostring(ch1005Min))
	end
end
print("functions loaded")