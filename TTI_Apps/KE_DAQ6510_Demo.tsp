--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

DAQ6510 Demo script
]]


--[[ 
	Start DAQ6510 Function Wrappers 
]]--
function configure_daq_scan()
	channel.setdmm("101,110,115,120", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE, dmm.ATTR_MEAS_REF_JUNCTION, dmm.REFJUNCT_INTERNAL)
	channel.setdmm("101,115,120", dmm.ATTR_MEAS_LIMIT_ENABLE_1, dmm.ON, dmm.ATTR_MEAS_LIMIT_HIGH_1, 30)
	channel.setdmm("110", dmm.ATTR_MEAS_LIMIT_ENABLE_1, dmm.ON, dmm.ATTR_MEAS_LIMIT_HIGH_1, 27)
	channel.setlabel("101", "Reg1")
	channel.setlabel("110", "ASIC")
	channel.setlabel("115", "Q5")
	channel.setlabel("120", "Encls")
	display.watchchannels = "101,110,115,120"
	scan.create("101,110,115,120")
	scan.scancount = 30
	scan.scaninterval = 1.000e+00
end

function trigger_daq_scan()
	trigger.model.initiate()
end

function wait_for_scan_complete()
	present_state, n = trigger.model.state() -- state, present block number
	--STATE_RUNNING, IDLE, WAITING, EMPTY, FAILED, ABORTING, ABORTED, BUILDING
	while present_state == trigger.STATE_WAITING or present_state == trigger.STATE_RUNNING do
		delay(0.5)
		present_state, n = trigger.model.state() -- state, present block number
	end 
end
--[[ 
	End DAQ6510 Function Wrappers 
]]--

--[[ 
	Start Supplementary Functions 
]]--
function display_transitions(scenario)
	display.settext(display.TEXT1, "")
	display.settext(display.TEXT2, "")
	if scenario == 1 then
		display.changescreen(display.SCREEN_USER_SWIPE)
		delay(0.5)
		display.settext(display.TEXT1, "Channel Settings")
		delay(1.0)
		display.settext(display.TEXT2, "Wide variety of functionality")
		delay(4.0)
		display.changescreen(display.SCREEN_CHANNEL_SCAN)
	elseif scenario == 2 then
		display.changescreen(display.SCREEN_USER_SWIPE)
		delay(0.5)
		display.settext(display.TEXT1, "Channel Statistics")
		delay(1.0)
		display.settext(display.TEXT2, "View stats on each channel")
		delay(4.0)
		display.changescreen(display.SCREEN_STATS_SWIPE)
	elseif scenario == 3 then
		display.changescreen(display.SCREEN_USER_SWIPE)
		delay(0.5)
		display.settext(display.TEXT1, "Reading Table")
		delay(1.0)
		display.settext(display.TEXT2, "View all buffered data in one UI") -- 32 chars max
		delay(4.0)
		display.changescreen(display.SCREEN_READING_TABLE)
	elseif scenario == 4 then
		display.changescreen(display.SCREEN_USER_SWIPE)
		delay(0.5)
		display.settext(display.TEXT1, "Histogram View")
		delay(1.0)
		display.settext(display.TEXT2, "View per channel in bar charts")
		delay(4.0)
		display.changescreen(display.SCREEN_HISTOGRAM)
	elseif scenario == 5 then
		display.changescreen(display.SCREEN_USER_SWIPE)
		delay(0.5)
		display.settext(display.TEXT1, "Limits and Alarms")
		delay(1.0)
		display.settext(display.TEXT2, "Active progress/alerts on the UI")
		delay(4.0)
		display.changescreen(display.SCREEN_SCAN_SWIPE)
	end
end

function check_if_rear()
	while dmm.terminals ~= dmm.TERMINALS_REAR do
		result = display.input.prompt(display.BUTTONS_OKCANCEL, "TERMINALS must be set to REAR")
		if result == display.BUTTON_CANCEL then 
			display.clear()
			exit() 
		end
	end
end

--[[ 
	End Supplementary Functions 
]]--

--[[ 
	Start Main Program
]]--
-- Intitialize overall system...
reset()
check_if_rear()

-- Configure the DAQ6510 scan...
configure_daq_scan()

display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT1, "DAQ6510 Demo")
display.settext(display.TEXT2, "Operation & Features Overview")
delay(5.0)

display.changescreen(display.SCREEN_SCAN_SWIPE)
delay(1.0)



stepv = 2.5
setv = stepv
for j = 1, 5 do
	if j ~= 1 then
		trigger_daq_scan()
	end	
	display_transitions(j)
	if j ~= 1 then
		wait_for_scan_complete()
		delay(5.0)
	else
		delay(10.0)
	end
end

-- Conclude by presenting graphing views...
-- We don't use the loop anymore so we don't initiate any more scans
display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT1, "Graphing")
display.settext(display.TEXT2, "View up to 20 chans in one chart")
delay(7.0)
display.changescreen(display.SCREEN_GRAPH_SWIPE)
delay(7.0)
display.changescreen(display.SCREEN_GRAPH)
delay(7.0)
display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT2, "Use cursors to frame your data")
delay(7.0)
display.changescreen(display.SCREEN_GRAPH)
delay(30.0)

-- And some background self-promotion
display.settext(display.TEXT1, "")
display.settext(display.TEXT2, "")
display.changescreen(display.SCREEN_USER_SWIPE)
beeper.beep(0.1, 3500)
delay(0.1)
beeper.beep(0.1, 3500)
delay(0.1)
beeper.beep(0.1, 3500)
delay(0.1)
delay(0.2)
display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT1, "The Keithley DAQ6510")
delay(2.0)
display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT2, "Touch")
delay(1.0)
display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT2, "Touch - Test")
delay(1.0)
display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT2, "Touch - Test - Invent!")
