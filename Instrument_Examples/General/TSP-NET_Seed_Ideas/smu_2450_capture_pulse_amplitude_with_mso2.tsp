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

function display_updates_01(ipaddr, msoid)
	display.clear()
	display.changescreen(display.SCREEN_USER_SWIPE)
	display.settext(display.TEXT1, "Connect:" .. ipaddr)
	delay(1.0)
	waitcomplete()
	local deltime = 0.05
	local dsptxt = "."
	for j = 1, 20 do
		display.settext(display.TEXT2, dsptxt)
		delay(deltime)
		dsptxt = string.format("%s.", dsptxt)
	end
	dsptxt = string.format("%s Success!!!", dsptxt)
	display.settext(display.TEXT2, dsptxt)
	
	delay(2.0)
	waitcomplete()
	display.clear()
	delay(1.0)
	display.settext(display.TEXT1, "Get instrument ID...")
	delay(1.0)
	display.settext(display.TEXT2, msoid)
	delay(2.0)
	
	display.clear()
	display.settext(display.TEXT1, "Apply scope settings...")
	delay(1.0)
end

function display_updates_02()
	display.clear()
	delay(1.0)
	display.changescreen(display.SCREEN_USER_SWIPE)
	display.settext(display.TEXT1, "Scope Measure")
	delay(1.0)
	waitcomplete()
	display.settext(display.TEXT2, "Enable amplitude measurement")
	delay(2.0)
end

function display_updates_03(inval)
	display.clear()
	delay(1.0)
	display.changescreen(display.SCREEN_USER_SWIPE)
	display.settext(display.TEXT1, string.format("Amplitude = %s V", inval))
	delay(3.0)
	waitcomplete()
	--display.settext(display.TEXT2, "Enable amplitude measurement")
	--delay(2.0)
	
	display_end_02()
end

function display_end_01()
	display.clear()
	delay(1.0)
	display.settext(display.TEXT1, string.format("TSP Power!"))
	delay(1.0)
	display.settext(display.TEXT2, string.format("Test"))
	delay(1.0)
	display.settext(display.TEXT2, string.format("Test Script "))
	delay(1.0)
	display.settext(display.TEXT2, string.format("Test Script Processor"))
end 

function display_end_02()
	display.clear()
	delay(1.0)
	
	display.settext(display.TEXT2, string.format("Test"))
	delay(1.0)
	display.clear()
	
	display.settext(display.TEXT2, string.format("Test Script"))
	delay(1.0)
	display.clear()
	
	display.settext(display.TEXT2, string.format("Test Script Processor"))
	delay(1.0)
	--display.clear()
	
	display.settext(display.TEXT1, string.format("TSP Power!"))
	delay(1.0)
	display.clear()
	
	local marquee_delay = 0.025
	display.settext(display.TEXT2, string.format("K"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Ke"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Kei"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keit"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keith"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithl"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithle"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, "))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A "))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A T"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Te"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tek"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tekt"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektr"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektro"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektron"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektroni"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektronix"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektronix "))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektronix C"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektronix Co"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektronix Com"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektronix Comp"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektronix Compa"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektronix Compan"))
	delay(marquee_delay)
	display.settext(display.TEXT2, string.format("Keithley, A Tektronix Company"))
	delay(marquee_delay)
end

--[[
	Start MSO5 Setup and Control Functions
]]
function mso5_getidstring(inst_id)
	--local myID = tspnet.idn(inst_id)
	local myID = tspnet_query(inst_id, "*IDN?", 5)
	delay(0.1)
	return myID
end

function mso5_setup_for_threshold_level_trigger(inst_id, channel, level, horz_scale)
	tspnet_write(inst_id, "*RST")
	delay(1.0)
	-- Configure the vertical settings...
	tspnet_write(inst_id, ":DISPLAY:WAVEVIEW1:CH" .. channel .. ":STATE 1")
	tspnet_write(inst_id, ":CH" .. channel .. ":SCAle " .. 0.5)
	tspnet_write(inst_id, ":CH" .. channel .. ":OFFSet " .. 2.0)
	tspnet_write(inst_id, ":CH" .. channel .. ":PROBEFUNC:EXTATTEN 1.0")
	
	-- Configure the horizontal settings...
	tspnet_write(inst_id, ":HORizontal:SCAle " .. horz_scale)
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

--[[
	Start MSO Add and capture measurement
]]
function mso5_add_and_capture_meas(inst_id)
	tspnet_write(inst_id, "MEASUrement:ADDMEAS AMPLITUDE")
	tspnet_write(inst_id, "MEASUrement:MEAS1:TYPe AMPLITUDE")
	tspnet_write(inst_id, "MEASUREMENT:MEAS1:SOURCE CH1")
	
	local ampl = tspnet_query(inst_id, "MEASUREMENT:MEAS1:RESUlts:CURRentacq:MEAN?", 13)
	return string.format("%0.4f", ampl)
end
--[[
	End MSO Add and capture measurement
]]

--[[ #######################################################################
		MAIN CODE IS DEFINED HERE
]]-- #######################################################################
local instAddrMSO5 = "192.168.1.57" 	-- Remote instrument IP address
local instPortMSO5 = 4000 			-- Default ethernet port for 2260B
local mso5InstId = nil 				

-- Intitialize overall tsp-net configuration...
reset()
tspnet.reset()
tspnet.timeout = 5.0 

-- Connect to remote LAN instuments...
local mso5InstId = tspnet_connect(instAddrMSO5, instPortMSO5, mso5InstId)
local msoid = mso5_getidstring(mso5InstId)

-- Provide some flashy information for the viewers
display_updates_01(instAddrMSO5, msoid)

mso5_setup_for_threshold_level_trigger(mso5InstId, 1, 2.5, 50e-3)
delay(1.0)

display.clear()
display.settext(display.TEXT1, "Source from SMU...")
delay(2.0)
display.changescreen(display.SCREEN_HOME)

-- Configure the SMU
smu_voltage_source_setup(4.0)
--delay(1.0)
smu_set_output_state(1)
local reading = smu.measure.read()
delay(1e-3)
smu_set_output_state(0)

display_updates_02()

local ampval = mso5_add_and_capture_meas(mso5InstId)
display_updates_03(ampval)

-- Disconnnect from remote LAN instruments...
tspnet_disconnect(mso5InstId)