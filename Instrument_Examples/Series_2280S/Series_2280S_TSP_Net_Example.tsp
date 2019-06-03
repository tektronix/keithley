--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Script Name: Series_2280S_TSP_Net_Example.tsp

This example illustrates the use of a Keithley 2280S or 2281S
over a LAN connection with the TSP-Net commands. In this example
	1. The controlling TSP-enabled instrument will establish a
	   sockets-based connection to the 2280S at the provided IP
	   address and port number.
	2. Extract the instrument ID from the supply and display it
	   on the User Swipe screen of the TSP instrument. 
	3. Loop setting the voltage and current levels of the power
	   supply then querying the measured values of the supply; 
	   the queried values are displayed on the User Swipe screen. 
	4. The controlling TSP-enabled instrument will release the
	   connection to the power supply. 
	   
To use, the 2280S must have its LAN port connected to the same network 
as the controlling TSP-enabled instrument. Works with:
	a. DMM7510, DMM6500, and DAQ6510
	b. 2450, 2460, 2461, and 2470 SMUs
	c. Series 2600B SourceMeters
	d. Series 3706A Switching & Multimeter System
	
-- ********************************************************************************
HISTORY
=======
2019-05-29	JJB		Initial creation based on a series of pre-existing examples. 


-- ********************************************************************************
]]
--[[ 
	Start TSP-Net Function Wrappers 
]]--
-- Initialize connection between DAQ and controlled instrument
function tspnet_init(remote_ip, remote_port, tsp_net_inst_id)
	tsp_net_inst_id = tspnet.connect(remote_ip, remote_port, "*RST\n")
	if tsp_net_inst_id == nil then return nil end
	tspnet_ipaddress = remote_ip
	tspnet.termination(tsp_net_inst_id, tspnet.TERM_LF)
	tspnet_send(tsp_net_inst_id, "*RST")
	return tsp_net_inst_id
end

-- Send command to controlled remote instrument
function tspnet_send(tsp_net_inst_id, command)
	tspnet.execute(tsp_net_inst_id, command)
end

-- Query data from the controlled instrument and return as a string
function tspnet_query(tsp_net_inst_id, command, timeout)
	timeout = timeout or 5.0 --Use default timeout of 5 secs if not specified
	tspnet.execute(tsp_net_inst_id, command)
	timer.cleartime()
	while tspnet.readavailable(tsp_net_inst_id) == 0 and timer.gettime() < timeout do
	delay(0.1)
	end
	return tspnet.read(tsp_net_inst_id)
end

-- Terminate the connection between the master and subordinate instrument
function tspnet_destroy(tsp_net_inst_id)
	if tsp_net_inst_id ~= nil then
		tspnet.disconnect(tsp_net_inst_id)
		tsp_net_inst_id = nil
	end
end
--[[ 
	End TSP-Net Function Wrappers 
]]--

--[[ 
	Start Keithley 228xB Function Wrappers 
]]--
function ke2280_connect(instrument_id, ip_address, ip_port, timeout)
	return tspnet_init(ip_address, ip_port, instrument_id)
end 

function ke2280_set_measurement_format(instrument_id)
	tspnet_send(instrument_id, "FORM:ELEM \"READ\"")
	delay(0.1)
end 

function ke2280_disconnect(instrument_id)
	tspnet_destroy(instrument_id)
end 

function ke2280_getidstring(instrument_id)
	local my_id_string = tspnet_query(instrument_id, "*IDN?", 5)
	delay(0.1)
	return my_id_string
end

-- Set 2280 Voltage
function ke2280_set_voltage(instrument_id, volt)
	tspnet_send(instrument_id, "VOLT " .. tostring(volt))
	delay(0.1)
end

-- Set 2280 Current Limit
function ke2280_set_current(instrument_id, curr)
	tspnet_send(instrument_id, "CURR " .. tostring(curr))
	delay(0.1)
end

-- Get 2280 Active Voltage Output
function ke2280_get_voltage(instrument_id, range, digits)
	local voltage_str = ""
	local command_str = "MEAS:VOLT?"
	
	if range ~= nil then
		command_str = command_str .. " " .. tostring(range)
	end 
	
	if digits ~= nil then
		command_str = command_str .. ", " .. tostring(digits)
	end 
	command_str = command_str
	voltage_str = tspnet_query(instrument_id, command_str) 
	delay(0.1)
	return tonumber(voltage_str)
end

-- Get 2280 Active Current Output
function ke2280_get_current(instrument_id, range, digits)
	local current_str = ""
	local command_str = "MEAS:CURR?"
	
	if range ~= nil then
		command_str = command_str .. " " .. tostring(range)
	end 
	
	if digits ~= nil then
		command_str = command_str .. ", " .. tostring(digits)
	end 
	command_str = command_str --.. "\n"
	current_str = tspnet_query(instrument_id, command_str)
	delay(0.1)
	return tonumber(current_str)
end

-- Set 2280 Output State 
function ke2280_set_outputstate(instrument_id, my_state)
	if my_state == 0 then
		tspnet_send(instrument_id, "OUTP OFF\n")
	else
		tspnet_send(instrument_id, "OUTP ON\n")
	end
	delay(0.1)
end

-- Check Output State
function ke2280_query_output_state(instrument_id)
	query_output = tspnet_query(instrument_id, "OUTP?")
	delay(0.1)
	return tonumber(query_output)
end

--[[ 
	End Keithley 2280S Function Wrappers 
]]--

-- ********************************************************************************
--     MAIN CODE STARTS HERE
-- ********************************************************************************
-- Initialize constant values and/or global vairables
local ip_address_228xS = "192.168.1.28" -- Remote instrument IP address
local ip_port_228xS = 5025 	-- Default ethernet port for 228xS
local ps2280_inst_id = nil	-- note that this one should be set as a global to use thoughout
							-- the test program
local my_id = ""
local voltage_set = 1.0
local current_set = 0.1
local my_voltage = 0.0
local my_current = 0					
					
-- Intitialize overall tsp-net configuration...
reset()
tspnet.reset()
tspnet.timeout = 5.0 

-- Connect to the power supply and get its instrument ID string
ps2280_inst_id = ke2280_connect(ps2280_inst_id, ip_address_228xS, ip_port_228xS)
local my_id = ke2280_getidstring(ps2280_inst_id)
ke2280_set_measurement_format(ps2280_inst_id)

-- Change to User Swipe screen, clear all messages, and update with instrument ID
display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT1, "Instrument ID: ")
display.settext(display.TEXT2, my_id)
delay(1.0)

-- Enable the power supply output...
ke2280_set_outputstate(ps2280_inst_id, 1)

for i = 1, 5 do
	-- Apply power supply output settings...
	ke2280_set_voltage(ps2280_inst_id, voltage_set)
	ke2280_set_current(ps2280_inst_id, current_set)
	delay(1.0)
	
	-- Query the measured output voltage and display on the master
	-- node's User Swipe screen.
	my_voltage = ke2280_get_voltage(ps2280_inst_id)
	display.settext(display.TEXT1, "Supplied Voltage:")
	display.settext(display.TEXT2, string.format("%f", my_voltage))
	delay(1.0)
	
	-- Query the measured output current and display on the master
	-- node's User Swipe screen.
	my_current = ke2280_get_current(ps2280_inst_id)
	display.settext(display.TEXT1, "Supplied Current:")
	display.settext(display.TEXT2, string.format("%f", my_current))
	delay(1.0)
	
	-- Increment the output settings...
	voltage_set = voltage_set + 1.0
	current_set = current_set + 0.1
end 

-- Disable the power supply output...
ke2280_set_outputstate(ps2280_inst_id, 0)

-- Release the LAN connection to the power supply
ke2280_disconnect(ps2280_inst_id)