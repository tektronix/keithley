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
	Start DMM Setup and Control Functions
]]
function dmm_acv_measure_setup()
	reset()
	dmm.measure.func = dmm.FUNC_AC_VOLTAGE
	dmm.measure.autorange = dmm.ON
	dmm.measure.detectorbandwidth = dmm.DETECTBW_300HZ
end

function dmm_freq_measure_setup()
	dmm.measure.func = dmm.FUNC_ACV_FREQUENCY
	dmm.measure.threshold.autorange = dmm.OFF
	dmm.measure.threshold.range = 10
	dmm.measure.aperture = 200e-3 
end
--[[
	End DMM Setup and Control Functions
]]

--[[
	Start AFG31k Setup and Control Functions
]]
function afg31k_getidstring(inst_id)
	--local myID = tspnet.idn(inst_id)
	local myID = tspnet_query(inst_id, "*IDN?", 5)
	delay(0.1)
	return myID
end

function afg31k_setup_for_sine_output(inst_id, frequency, amplitude, offset, phase_degrees)
	tspnet_write(inst_id, "*RST")
	delay(1.0)
	-- Configure the vertical settings...
	tspnet_write(inst_id, "SOURce:FUNCtion SIN")
	tspnet_write(inst_id, "OUTPut:IMPedance INFinity")
	tspnet_write(inst_id, "SOURce:VOLTage:UNIT VRMS")
	tspnet_write(inst_id, "FREQuency " .. frequency)
	tspnet_write(inst_id, "VOLTage:AMPlitude " .. amplitude)
	tspnet_write(inst_id, "VOLTage:OFFset " .. offset)
	tspnet_write(inst_id, "PHASE:ADJUST " .. phase_degrees .. "DEG")
end 

function afg31k_set_output_state(inst_id, my_state)
	if my_state == 1 then
		tspnet_write(inst_id, "OUTPut ON")
	else
		tspnet_write(inst_id, "OUTPut OFF")
	end
end 
--[[
	End AFG31k Setup and Control Functions
]]


--[[ #######################################################################
		MAIN CODE IS DEFINED HERE
]]-- #######################################################################
local instAddrAfg31k = "192.168.1.31" 	-- Remote instrument IP address
local instPortAfg31k = 5025 			-- Default ethernet port for 2260B
local afg31kInstId = nil 				
local frequency = 1000
local rms_amplitude = 2.0
local dc_offset = 0.0
local phase_shift_degrees = 0.0

-- Intitialize overall tsp-net configuration...
reset()
tspnet.reset()
tspnet.timeout = 5.0 

-- Connect to remote LAN instuments...
afg31kInstId = tspnet_connect(instAddrAfg31k, instPortAfg31k, afg31kInstId)
print(afg31k_getidstring(afg31kInstId))
afg31k_setup_for_sine_output(afg31kInstId, frequency, rms_amplitude, 
							 dc_offset, phase_shift_degrees)
afg31k_set_output_state(afg31kInstId, 1)

-- Configure the DMM to measure ACV then Frequency
dmm_acv_measure_setup()
print(dmm.measure.read())

dmm_freq_measure_setup()
print(dmm.measure.read())

-- Hold the signal, take a measurement and print, disable the AFG31k output
delay(1.0)
afg31k_set_output_state(afg31kInstId, 0)

-- Disconnnect from remote LAN instruments...
tspnet_disconnect(afg31kInstId)