--[[ 
	Start TSP-Net Function Wrappers 
]]--
-- Initialize connection between DAQ and controlled instrument
function tspnet_connect(remote_ip, remote_port, tspNetInstId)
	tspNetInstId = tspnet.connect(remote_ip, remote_port, "*RST\n")
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
	Start 2281S Setup and Control Functions
]]
function ps2281s_getidstring(inst_id)
	--local myID = tspnet.idn(inst_id)
	local myID = tspnet_query(inst_id, "*IDN?", 5)
	delay(0.1)
	return myID
end

function ps2281s_power_supply_setup(inst_id, voltage_level, current_level)
	ps2281S_set_supply_function(inst_id, 0)
	ps2281S_set_power_supply_output_levels(inst_id, voltage_level, current_level)
end 

function ps2281s_set_output_state(inst_id, my_state)
	if my_state == 1 then
		tspnet_write(inst_id, ":OUTP:STAT ON")
	else
		tspnet_write(inst_id, ":OUTP:STAT OFF")
	end
end 

function ps2281S_set_supply_function(inst_id, activeFunc)
	if activeFunc == 0 then
		-- Set to Power Supply
		tspnet_write(inst_id, ":ENTR:FUNC POW")
	elseif activeFunc == 1 then
		-- Set to Battery Test
		tspnet_write(inst_id, ":ENTRFUNC TEST")
	elseif activeFunc == 2 then
		-- Set to Battery Simulator
		tspnet_write(inst_id, ":ENTR:FUNC SIM")
	else
		-- What should be done if the input value is invalid?
	end
end

function ps2281S_set_power_supply_output_levels(inst_id, v_level, i_limit)
	command = ":SOUR:VOLT:LEV:IMM:AMPL " .. tostring(v_level)
	tspnet_write(inst_id, command)
	command = ":SOUR:CURR:LEV:IMM:AMPL " .. tostring(i_limit)
	tspnet_write(inst_id, command)
	--tspnet_write(inst_id, "INIT")
end

function ps2281S_measure_voltage(inst_id)
	--local myID = tspnet.idn(inst_id)
	tspnet_write(inst_id, "FORM:ELEM \"READ\"")
	local my_volts = tspnet_query(inst_id, ":MEAS:VOLT?", 5)
	delay(0.1)
	return my_volts
end
--[[
	End 2281S Setup and Control Functions
]]

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
local instAddr2281S = "192.168.1.28" 	-- Remote instrument IP address
local instPort2281S = 5025 			-- Default ethernet port for 2260B
local ps2281SInstId = nil 				

-- Intitialize overall tsp-net configuration...
reset()
tspnet.reset()
tspnet.timeout = 5.0 

-- Connect to remote LAN instuments...
ps2281SInstId = tspnet_connect(instAddr2281S, instPort2281S, ps2281SInstId)
print(ps2281s_getidstring(ps2281SInstId))
ps2281s_power_supply_setup(ps2281SInstId, 0.0, 1.0)
ps2281s_set_output_state(ps2281SInstId, 1)

for j = 1, 5 do
	ps2281S_set_power_supply_output_levels(ps2281SInstId, j, 1.0)
	delay(1.0)
	print(ps2281S_measure_voltage(ps2281SInstId))
	my_dcv = dmm.measure.read()
	waitcomplete()
	print(my_dcv)
end

ps2281s_set_output_state(ps2281SInstId, 0)

tspnet_disconnect(ps2281SInstId)