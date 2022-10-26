--[[ GLOBAL VARS DEFINED HERE ]]--
gInstPort = 5025
gPsuInstId = nil
gShuntVal = 0.1

--[[ SYSTEM FUNCTIONS DEFINED HERE ]]--
function DAQ_ChanConfig(voltChans, currChans, tempChan)
	--[[ 
		Configure the channel measurement settings to optimize for speed
			a. Setting a fixed range
			b. Disabling auto zero
			c. Disabling auto delay
			d. Turn line sync off
			e. Disable filtering and limits
			f. Decreasing the power line cycles (PLC) to the minimum
	]]--
	
	reset()
	
	-- Configure channels measuring output voltage
	channel.setdmm(voltChans, dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_VOLTAGE)
	channel.setdmm(voltChans, dmm.ATTR_MEAS_AUTO_DELAY, dmm.DELAY_OFF)
	channel.setdmm(voltChans, dmm.ATTR_MEAS_RANGE, 10)
	channel.setdmm(voltChans, dmm.ATTR_MEAS_RANGE_AUTO, dmm.OFF)
	channel.setdmm(voltChans, dmm.ATTR_MEAS_AUTO_ZERO, dmm.OFF)
	channel.setdmm(voltChans, dmm.ATTR_MEAS_DIGITS, dmm.DIGITS_4_5)
	channel.setdmm(voltChans, dmm.ATTR_MEAS_NPLC, 0.0005)
	channel.setdmm(voltChans, dmm.ATTR_MEAS_LINE_SYNC, dmm.OFF)
	channel.setdmm(voltChans, dmm.ATTR_MEAS_LIMIT_ENABLE_1, dmm.OFF)
	channel.setdmm(voltChans, dmm.ATTR_MEAS_LIMIT_ENABLE_2, dmm.OFF)
	
	-- Configure channels measuring current by way of the shunt
	channel.setdmm(currChans, dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_VOLTAGE)
	channel.setdmm(currChans, dmm.ATTR_MEAS_AUTO_DELAY, dmm.DELAY_OFF)
	channel.setdmm(currChans, dmm.ATTR_MEAS_RANGE, .1)
	channel.setdmm(currChans, dmm.ATTR_MEAS_RANGE_AUTO, dmm.OFF)
	channel.setdmm(currChans, dmm.ATTR_MEAS_AUTO_ZERO, dmm.OFF)
	channel.setdmm(currChans, dmm.ATTR_MEAS_DIGITS, dmm.DIGITS_4_5)
	channel.setdmm(currChans, dmm.ATTR_MEAS_NPLC, 0.0005)
	channel.setdmm(currChans, dmm.ATTR_MEAS_LINE_SYNC, dmm.OFF)
	channel.setdmm(currChans, dmm.ATTR_MEAS_LIMIT_ENABLE_1, dmm.OFF)
	channel.setdmm(currChans, dmm.ATTR_MEAS_LIMIT_ENABLE_2, dmm.OFF)
	
	-- Configure channel measuring temperature
	channel.setdmm(tempChan, dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE)
	channel.setdmm(tempChan, dmm.ATTR_MEAS_OPEN_DETECTOR, dmm.OFF)
	channel.setdmm(tempChan, dmm.ATTR_MEAS_AUTO_DELAY, dmm.DELAY_OFF)
	channel.setdmm(tempChan, dmm.ATTR_MEAS_AUTO_ZERO, dmm.OFF)
	channel.setdmm(tempChan, dmm.ATTR_MEAS_NPLC, 0.0005)
end

function DAQ_ScanConfig(scanchan, myScanCnt)
	--[[
		Establish the scan and buffer settings
	]]--
	scan.scancount = myScanCnt
	scan.scaninterval = 0.0
	scan.create(scanchan)    
	
	defbuffer1.clear()
	format.data = format.ASCII
	
	-- Note that scan.stepcount should only be used after
	-- scan channels have been defined per scan.create()
	-- or scan.add(), otherwise this system attribute will
	-- be set to zero. 
	defbuffer1.capacity = scan.scancount * scan.stepcount
end

function DAQ_Trig()
	--[[
		Trigger the start of the scan
	]]--
	trigger.model.initiate()
end

function DAQ_ParseReadingBuffer(bufSize)
	--[[
		This utility function is used to break apart the default
		buffer where the collection of all readings is stored
		and separate them out into individual accessible buffers
		for each test point of interest. 
		
		Note that for the buffers which hold current values, we
		not only extract, but also calculate based upon a known
		shunt resistance value (defined as a global above). 
	]]--
	
	-- Create a series of writable buffers to hold data from each point
	voltBuff1 = buffer.make(bufSize, buffer.STYLE_WRITABLE)
	voltBuff2 = buffer.make(bufSize, buffer.STYLE_WRITABLE)
	voltBuff3 = buffer.make(bufSize, buffer.STYLE_WRITABLE)
	currBuff1 = buffer.make(bufSize, buffer.STYLE_WRITABLE)
	currBuff2 = buffer.make(bufSize, buffer.STYLE_WRITABLE)
	currBuff3 = buffer.make(bufSize, buffer.STYLE_WRITABLE)
	tempBuff = buffer.make(bufSize, buffer.STYLE_WRITABLE)

	-- Establish the fill mode
	voltBuff1.fillmode = buffer.FILL_CONTINUOUS
	voltBuff2.fillmode = buffer.FILL_CONTINUOUS
	voltBuff3.fillmode = buffer.FILL_CONTINUOUS
	currBuff1.fillmode = buffer.FILL_CONTINUOUS
	currBuff2.fillmode = buffer.FILL_CONTINUOUS
	currBuff3.fillmode = buffer.FILL_CONTINUOUS
	tempBuff.fillmode = buffer.FILL_CONTINUOUS

	-- Define the buffer format
	buffer.write.format(voltBuff1, buffer.UNIT_VOLT, buffer.DIGITS_4_5)
	buffer.write.format(voltBuff2, buffer.UNIT_VOLT, buffer.DIGITS_4_5)
	buffer.write.format(voltBuff3, buffer.UNIT_VOLT, buffer.DIGITS_4_5)
	buffer.write.format(currBuff1, buffer.UNIT_AMP, buffer.DIGITS_4_5)
	buffer.write.format(currBuff2, buffer.UNIT_AMP, buffer.DIGITS_4_5)
	buffer.write.format(currBuff3, buffer.UNIT_AMP, buffer.DIGITS_4_5)
	buffer.write.format(tempBuff, buffer.UNIT_CELSIUS, buffer.DIGITS_4_5)

	-- Iterate through the main system buffer to extract specific
	-- readings per buffer. 
	for i = 1, defbuffer1.n, 7 do
		-- Extract voltage values
		holder1 = defbuffer1.readings[i]
		buffer.write.reading(voltBuff1, holder1)
		
		holder2 = defbuffer1.readings[i+1]
		buffer.write.reading(voltBuff2, holder2)
		
		holder3 = defbuffer1.readings[i+2]
		buffer.write.reading(voltBuff3, holder3)
		
		-- Extract current values per I = V/R
		holder4 = defbuffer1.readings[i+3]
		holder4 = holder4 / gShuntVal		-- calculate I
		buffer.write.reading(currBuff1, holder4)
		
		holder5 = defbuffer1.readings[i+4]
		holder5 = holder5 / gShuntVal		-- calculate I
		buffer.write.reading(currBuff2, holder5)
		
		holder6 = defbuffer1.readings[i+5]
		holder6 = holder6 / gShuntVal		-- calculate I
		buffer.write.reading(currBuff3, holder6)
		
		-- Extract temperature values
		holder7 = defbuffer1.readings[i+6]
		buffer.write.reading(tempBuff, holder7)
	end
end

function PSU_Configure(ipAddress, vLevel, iLevel, outState)
	gPsuInstId = PowerSupply_Connect(ipAddress, gInstPort)
	PowerSupply_SetVoltage(gPsuInstId, vLevel)
	PowerSupply_SetCurrent(gPsuInstId, iLevel)
	PowerSupply_OutputState(gPsuInstId, outState)
	PowerSupply_SetDisplayText(gPsuInstId, "Start Test")
end

function PSU_Disable()
	PowerSupply_OutputState(gPsuInstId, 0)
	PowerSupply_SetDisplayText(gPsuInstId, "End Test")
	PowerSupply_Disconnect(gPsuInstId)
end

function PSU_Off()
	PowerSupply_OutputState(gPsuInstId, 0)
end

function PowerSupply_Connect(instAddr, remote_port)
	psuId = tspnet_init(instAddr, remote_port)
	return psuId
end 

function PowerSupply_Disconnect(instId)
	tspnet_destroy(instId)
end

function PowerSupply_SetVoltage(instId, vLevel)
	sndBuffer = string.format("SOURce:VOLTage %f", vLevel)
	tspnet_send(instId, sndBuffer)
end 

function PowerSupply_SetCurrent(instId, iLevel)
	sndBuffer = string.format("SOURce:CURRent %f", iLevel)
	tspnet_send(instId, sndBuffer)
end 

function PowerSupply_OutputState(instId, myState)
	if myState == 0 then
		tspnet_send(instId, "OUTP OFF")
	else
		tspnet_send(instId, "OUTP ON")
	end
end

function PowerSupply_GetOutputState(instId)
	return tspnet_query(instId, "OUTP?")
end

function PowerSupply_SetDisplayText(instId, myText)
	sndBuffer = string.format("DISP:USER:TEXT \"%s\"", myText)
	tspnet_send(instId, sndBuffer)
end

-- Initialize connection between DAQ and controlled instrument
function tspnet_init(remote_ip, remote_port)
	tspnet.timeout = 5.0
	tspnet.reset()
	tspnet_instID = tspnet.connect(remote_ip, remote_port, "*RST\n")
	if tspnet_instID == nil then return nil	end
	tspnet_ipaddress = remote_ip
	tspnet.termination(tspnet_instID, tspnet.TERM_LF)
	
	tspnet_send(tspnet_instID, "*RST")
	return tspnet_instID
end

-- Send command to controlled remote instrument
function tspnet_send(tspnet_instID, command)
	tspnet.execute(tspnet_instID, command)
end

-- Query data from the controlled instrument
function tspnet_query(tspnet_instID, command, timeout)
	timeout = timeout or 5.0	--Use default timeout of 5 secs if not specified
	tspnet.execute(tspnet_instID, command)
	timer.cleartime()
	
	while tspnet.readavailable(tspnet_instID) == 0 and timer.gettime() < timeout do
		delay(0.1)
	end
	return tspnet.read(tspnet_instID)
end

-- Terminate the connection between the master and subordinate instrument
function tspnet_destroy(tspnet_instID)
	if tspnet_instID ~= nil then
		tspnet.disconnect(tspnet_instID)
		tspnet_instID = nil
	end
end

print("Done...")