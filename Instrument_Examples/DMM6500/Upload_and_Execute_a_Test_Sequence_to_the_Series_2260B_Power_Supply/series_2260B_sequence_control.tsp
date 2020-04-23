local echo_cmd = 0
local seq_table = {}
local instAddr2260 = "" 	-- Remote instrument IP address
local instPort2260 = 2268 	-- Default ethernet port for 2260B
local ps2260InstId = nil 

-- Initialize connection between DAQ and controlled instrument
function tspnet_connect(remote_ip, remote_port, inst_id)
	inst_id = tspnet.connect(remote_ip, remote_port, "*RST")
	if inst_id == nil then return nil end
	tspnet_ipaddress = remote_ip
	tspnet.termination(inst_id, tspnet.TERM_LF)
	tspnet_write(inst_id, "*RST")
	return inst_id
end

-- Send command to controlled remote instrument
function tspnet_write(inst_id, command)
	tspnet.execute(inst_id, command .. "\n")
	if echo_cmd == 1 then
		print(command)
	end
end

-- Query data from the controlled instrument and return as a string
function tspnet_query(inst_id, command, timeout)
	timeout = timeout or 5.0 --Use default timeout of 5 secs if not specified
	tspnet_write(inst_id, command)
	--tspnet.execute(inst_id, command)
	--timer.cleartime()
	while tspnet.readavailable(inst_id) == 0 and timer.gettime() < timeout do
		delay(0.1)
	end
	return tspnet.read(inst_id)
end

-- Terminate the connection between the master and subordinate instrument
function tspnet_disconnect(inst_id)
	if inst_id ~= nil then
		tspnet.disconnect(inst_id)
		inst_id = nil
	end
end
--[[ 
	End TSP-Net Function Wrappers 
]]--

--[[ 
	Start Keithley 2260B Function Wrappers 
]]--
function ke2260_getidstring(inst_id)
	local myID = tspnet_query(inst_id, "*IDN?", 5)
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
	tspnet_write(inst_id, command)
end 

function ps2260_set_trigger_source(inst_id, trigger_source)
	local command = ""
	if trigger_source == 0 then
		command = "TRIG:TRAN:SOUR IMM"	-- voltage source
	elseif trigger_source == 1 then
		command = "TRIG:TRAN:SOUR BUS" 	-- current source
	end
	tspnet_write(inst_id, command)
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
function ps2260_set_voltage(inst_id, volt)
	tspnet_write(inst_id, "VOLT " .. tostring(volt))
end

-- Set 2260 Voltage Transient Level
function ps2260_set_voltage_transient(inst_id, transient_level)
	tspnet_write(inst_id, "SOUR:VOLT:LEV:TRIG " .. tostring(transient_level))
end

-- Set 2260 Voltage Slew Rate
function ps2260_set_voltage_slew(inst_id, slew, is_rising)
	if is_rising == 1 then
		tspnet_write(inst_id, "SOUR:VOLT:SLEW:RISE " .. tostring(slew))
	else
		tspnet_write(inst_id, "SOUR:VOLT:SLEW:FALL " .. tostring(slew))
	end
end

-- Set 2260 Voltage Rising Slew Rate
function ps2260_set_voltage_slew_rising(inst_id, slew)
	tspnet_write(inst_id, "SOUR:VOLT:SLEW:RISE " .. tostring(slew))
end

-- Set 2260 Voltage Falling Slew Rate
function ps2260_set_voltage_slew_falling(inst_id, slew)
	tspnet_write(inst_id, "SOUR:VOLT:SLEW:FALL " .. tostring(slew))
end

-- Set 2260 Transient Trigger
function ps2260_trigger_transient(inst_id)
	tspnet_write(inst_id, "INIT:NAME TRAN")
end

-- Set 2260 Current Limit
function ps2260_set_current(inst_id, curr)
	tspnet_write(inst_id, "CURR " .. tostring(curr))
end

-- Set 2260 Current Transient Level
function ps2260_set_current_transient(inst_id, curr)
	tspnet_write(inst_id, "SOUR:CURR:LEV:TRIG " .. tostring(curr))
end

-- Set 2260 Current Slew Rate
function ps2260_set_current_slew(inst_id, slew, is_rising)
	if is_rising == 1 then
		tspnet_write(inst_id, "SOUR:CURR:SLEW:RISE " .. tostring(slew))
	else
		tspnet_write(inst_id, "SOUR:CURR:SLEW:FALL " .. tostring(slew))
	end
end

-- Set 2260 Current Rising Slew Rate
function ps2260_set_current_slew_rising(inst_id, slew)
	tspnet_write(inst_id, "SOUR:CURR:SLEW:RISE " .. tostring(slew))
end

-- Set 2260 Current Falling Slew Rate
function ps2260_set_current_slew_falling(inst_id, slew)
	tspnet_write(inst_id, "SOUR:CURR:SLEW:FALL " .. tostring(slew))
end

-- Set 2260 Output State ON
function ps2260_set_output_state(inst_id, my_state)
	if my_state == 0 then
		tspnet_write(inst_id, "OUTP OFF")
	else
		tspnet_write(inst_id, "OUTP ON")
	end
end

-- Set 2260 priority
function ps2260_set_output_priority(inst_id, my_priority)
	if my_priority == 0 then
		tspnet_write(inst_id, "OUTP:MODE CVHS")	-- for CV high-speed
	elseif my_priority == 1 then 
		tspnet_write(inst_id, "OUTP:MODE CCHS")	-- for CC high-speed
	elseif my_priority == 2 then 
		tspnet_write(inst_id, "OUTP:MODE CVLS")	-- for CV slew rate
	elseif my_priority == 3 then 
		tspnet_write(inst_id, "OUTP:MODE CCLS")	-- for CC slew rate
	end
end

function ps2260_set_slew_rate(inst_id, my_slew)
	tspnet_write(inst_id, "SOUR:VOLT:SLEW:RISE " .. my_slew)
end

function ps2260_measure_voltage(inst_id)
	--local myID = tspnet.idn(inst_id)
	--tspnet_write(inst_id, "FORM:ELEM \"READ\"")
	local my_volts = tspnet_query(inst_id, ":MEAS:VOLT?", 5)
	return my_volts
end

function ps2260_execute_test_sequence()
	-- Establish the source mode = CV
	ps2260_set_supply_function(ps2260InstId, 0)
	ps2260_set_trigger_source(ps2260InstId, 0)
	-- max out the current slew rate settings so they do not hold back the s
	ps2260_set_current_slew(ps2260InstId, "MAX", 1)
	ps2260_set_current_slew(ps2260InstId, "MAX", 0)
	local v_level = 0
	local i_limit = 22
	local priority_mode = 0
	local slew = "MAX"
	local duration = 0
	local is_rising_slew = 0
	local n = 0
	for key, value in pairs(seq_table) do
		local temp_table = stringSplit(value, ",")
		if temp_table[2] == nil then
			-- added this in case the user has an extra \n at the end of the file
			break
		else
			timer.cleartime()
			v_level = temp_table[2]
			i_limit = temp_table[3]
			duration = tonumber(temp_table[4])
			priority_mode = tonumber(temp_table[5])
			slew = temp_table[6]
			is_rising_slew = tonumber(temp_table[7])
			-- Set the slew priority
			ps2260_set_output_priority(ps2260InstId, priority_mode)
			
			-- Set the slew rate
			ps2260_set_voltage_slew(ps2260InstId, slew, is_rising_slew)
			
			-- Apply the (current) trasient limit 
			ps2260_set_current_transient(ps2260InstId, i_limit)
			
			-- Apply the (voltage) transient level
			ps2260_set_voltage_transient(ps2260InstId, v_level)
			
			-- Trigger the transient
			ps2260_trigger_transient(ps2260InstId)
			dt = timer.gettime()
			delaytime = duration - dt
			if delaytime < 0 then
				delaytime = 0.001
			end
			-- Loop for the applied duration in milliseconds
			while n < duration do
				delay(0.001)
				n = n + 1
			end
			n = 0
		end
		
	end	
end
--[[ 
	End Keithley 2260B Function Wrappers 
]]--

function do_beep(duration, frequency, count)
	for i = 1, count do
		beeper.beep(duration, frequency)
		delay(0.1)
	end
end

-- Given a string and a pattern will return an array of strings
function stringSplit(str, inSplitPattern, outResults )
	if not outResults then
		outResults = { }
    end
    
	local theStart = 1
	local theSplitStart, theSplitEnd = string.find(str, inSplitPattern, theStart)
	
    while theSplitStart do
	    table.insert(outResults, string.sub(str, theStart, theSplitStart-1))
	    theStart = theSplitEnd + 1
	    theSplitStart, theSplitEnd = string.find( str, inSplitPattern, theStart)
    end
    
    table.insert(outResults, string.sub(str, theStart))
    
	return outResults
end

function append_test_to_global_table(comma_delimited_test_step)
	if comma_delimited_test_step ~= nil then
		table.insert(seq_table, comma_delimited_test_step)
	end
end 

function connect_to_2260B(ip_address)
	-- Intitialize overall tsp-net configuration...
	tspnet.reset()
	tspnet.timeout = 5.0 
	
	-- Connect to remote LAN instuments...
	ps2260InstId = tspnet_connect(ip_address, instPort2260, ps2260InstId)
end

function disconnect_from_2260B()
	tspnet_disconnect(ps2260InstId)
end

function enable_2260B_output(volts, amps, state)
	ps2260_power_supply_setup(ps2260InstId, volts, amps)
	ps2260_set_output_state(ps2260InstId, state)
end

print("Loaded!!!")
