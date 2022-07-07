--[[ 
	Start TSP-Net Function Wrappers 
]]
-- Initialize connection between DAQ and controlled instrument
function tspnet_connect(remote_ip, remote_port, tspNetInstId)
	tspNetInstId = tspnet.connect(remote_ip, remote_port, "*RST")
	if tspNetInstId == nil then return nil end
	tspnet_ipaddress = remote_ip
	tspnet.termination(tspNetInstId, tspnet.TERM_LF)
	tspnet_write(tspNetInstId, "*RST")
	return tspNetInstId
end

-- Send command to controlled remote instrument
function tspnet_write(tspNetInstId, command)
	tspnet.execute(tspNetInstId, command)
end

-- Query data from the controlled instrument and return as a string
function tspnet_query(tspNetInstId, command, timeout)
	timeout = timeout or 5.0 --Use default timeout of 5 secs if not specified
	tspnet.execute(tspNetInstId, command)
	timer.cleartime()
	while tspnet.readavailable(tspNetInstId) == 0 and timer.gettime() < timeout do
		delay(0.1)
	end
	return tspnet.read(tspNetInstId)
end

-- Terminate the connection between the master and subordinate instrument
function tspnet_disconnect(tspNetInstId)
	if tspNetInstId ~= nil then
		tspnet.disconnect(tspNetInstId)
		tspNetInstId = nil
	end
end
--[[ 
	End TSP-Net Function Wrappers 
]]

--[[
	Start SMU Setup and Control Functions
]]
function smu_voltage_source_setup(i_level)
	smu.source.func = smu.FUNC_DC_VOLTAGE
	smu.source.autorange = smu.ON
	smu.source.level = i_level
	
	-- Set up the measure function.
	smu.measure.func = smu.FUNC_DC_CURRENT
	smu.measure.autorange = smu.ON
	smu.measure.terminals = smu.TERMINALS_FRONT
	waitcomplete()
end

function smu_set_output_state(my_state)
	if my_state == 1 then
		smu.source.output = smu.ON
	else
		smu.source.output = smu.OFF
	end
end 
--[[
	End SMU Setup and Control Functions
]]

--[[
	Start MSO5 Setup and Control Functions
]]
function mso5_getidstring(inst_id)
	--local myID = tspnet.idn(inst_id)
	local myID = tspnet_query(inst_id, "*IDN?", 5)
	delay(0.1)
	return myID
end

function mso5_setup_for_threshold_level_trigger(inst_id, channel, level)
	tspnet_write(inst_id, "*RST")
	delay(1.0)
	-- Configure the vertical settings...
	tspnet_write(inst_id, ":DISPLAY:WAVEVIEW1:CH" .. channel .. ":STATE 1")
	tspnet_write(inst_id, ":CH" .. channel .. ":SCAle " .. 0.5)
	tspnet_write(inst_id, ":CH" .. channel .. ":OFFSet " .. 3.0)
	
	-- Configure the horizontal settings...
	tspnet_write(inst_id, ":HORizontal:SCAle 40e-6")
	tspnet_write(inst_id, ":HORizontal:POSition 10")
	
	-- Configure the trigger settings...
	tspnet_write(inst_id, ":TRIGger:A:TYPe EDGE")
	tspnet_write(inst_id, ":TRIGger:A:EDGE:SOUrce CH" .. channel)
	tspnet_write(inst_id, ":TRIGger:A:LEVel:CH" .. channel .." " .. level)
	tspnet_write(inst_id, ":TRIGger:A:EDGE:SLOpe RISE")
	tspnet_write(inst_id, ":TRIGger:A:MODe NORMal")
end 
--[[
	End MSO5 Setup and Control Functions
]]


--[[ #######################################################################
		MAIN CODE IS DEFINED HERE
]]-- #######################################################################
local instAddrMSO5 = "192.168.1.5" 	-- Remote instrument IP address
local instPortMSO5 = 4000 			-- Default ethernet port for 2260B
local mso5InstId = nil 				

-- Intitialize overall tsp-net configuration...
reset()
tspnet.reset()
tspnet.timeout = 5.0 

-- Connect to remote LAN instuments...
mso5InstId = tspnet_connect(instAddrMSO5, instPortMSO5, mso5InstId)
print(mso5_getidstring(mso5InstId))
mso5_setup_for_threshold_level_trigger(mso5InstId, 1, 2.5)

-- Configure the SMU
smu_voltage_source_setup(5.0)
delay(1.0)
smu_set_output_state(1)
local reading = smu.measure.read()
delay(1.0)
smu_set_output_state(0)

-- Disconnnect from remote LAN instruments...
tspnet_disconnect(mso5InstId)