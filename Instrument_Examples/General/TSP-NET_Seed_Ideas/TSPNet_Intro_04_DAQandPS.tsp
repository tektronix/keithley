--[[ 
	Start TSP-Net Function Wrappers 
]]--
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
]]--

--[[ 
	Start Keithley 2260B Function Wrappers 
]]--
function ke2260_getidstring(tspNetInstId)
	myID = tspnet_query(tspNetInstId, "*IDN?", 5)
	delay(0.1)
	return myID
end

-- Configure the output mode
function ps2260_set_supply_function(inst_id, my_mode)
	local command = ""
	if my_mode == 0 then
		command = "OUTPut:MODE 0"	-- voltage source
	elseif my_mode == 1 then
		command = "OUTPut:MODE 1" 	-- current source
	end
	tspnet_write(inst_id, command .."\n")
	delay(0.1)
end 

function ps2260_set_power_supply_output_levels(inst_id, v_level, i_limit)
	ps2260_set_voltage(inst_id, v_level)
	ps2260_set_current(inst_id, i_limit)
end

function ps2260_power_supply_setup(inst_id, voltage_level, current_level)
	ps2260_set_supply_function(inst_id, 0)
	ps2260_set_power_supply_output_levels(inst_id, voltage_level, current_level)
end 

-- Set 2260 Voltage
function ps2260_set_voltage(tspNetInstId, volt)
	tspnet_write(tspNetInstId, "VOLT " .. tostring(volt) .."\n")
	delay(0.1)
end

-- Set 2260 Current Limit
function ps2260_set_current(tspNetInstId, curr)
	tspnet_write(tspNetInstId, "CURR " .. tostring(curr) .."\n")
	delay(0.1)
end

-- Set 2260 Output State ON
function ps2260_set_output_state(tspNetInstId, my_state)
	if my_state == 0 then
		tspnet_write(tspNetInstId, "OUTP OFF\n")
	else
		tspnet_write(tspNetInstId, "OUTP ON\n")
	end
	delay(0.1)
end

function ps2260_measure_voltage(inst_id)
	--local myID = tspnet.idn(inst_id)
	--tspnet_write(inst_id, "FORM:ELEM \"READ\"")
	local my_volts = tspnet_query(inst_id, ":MEAS:VOLT?", 5)
	delay(0.1)
	return my_volts
end
--[[ 
	End Keithley 2260B Function Wrappers 
]]--

--[[
	Start DMM Setup and Control Functions
]]
function dmm_dcv_measure_setup()
	reset()
	dmm.measure.func = dmm.FUNC_DC_VOLTAGE
	dmm.measure.autorange = dmm.ON
end

--[[
	End DMM Setup and Control Functions
]]


--[[ #######################################################################
		MAIN CODE IS DEFINED HERE
]]-- #######################################################################
local instAddr2260 = "192.168.1.22" 	-- Remote instrument IP address
local instPort2260 = 2268 			 	-- Default ethernet port for 2260B
local ps2260InstId = nil 				

-- Intitialize overall tsp-net configuration...
reset()
tspnet.reset()
tspnet.timeout = 5.0 

-- Connect to remote LAN instuments...
ps2260InstId = tspnet_connect(instAddr2260, instPort2260, ps2260InstId)
print(ke2260_getidstring(ps2260InstId))
ps2260_power_supply_setup(ps2260InstId, 0.0, 1.0)
ps2260_set_output_state(ps2260InstId, 1)

for j = 1, 5 do
	ps2260_set_power_supply_output_levels(ps2260InstId, j, 1.0)
	delay(1.0)
	print(ps2260_measure_voltage(ps2260InstId))
	my_dcv = dmm.measure.read()
	waitcomplete()
	print(my_dcv)
end

ps2260_set_output_state(ps2260InstId, 0)

tspnet_disconnect(ps2260InstId)