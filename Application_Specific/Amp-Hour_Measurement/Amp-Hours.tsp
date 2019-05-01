--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Written by: Keithley Applications Engineering (Clary)

This script measures current to calculate either Ampere-hours (charge) or Watt-hours (energy).   

After starting the script, you must use the front panel to select whether to measure Amp-hours
or Watt-hours. You must then select the sample rate and current range (this script uses the 
DMM6500's digitizer, so a fixed range is required). The measurement immediately begins in an
infinite loop. You can press the TRIGGER key to exit to loop and end the script.

For Amp-hours, the total Amp-hours, average current, and elapsed time are continually updated
on the front panel display. An ampHrsBuffer is created and keeps track of cumulative Amp-hours.

For Watt-hours, the DC Bias voltage must be entered, it is not measured.  The total Watt-
hours and average current are continually updated on the front panel display. A wattHrsBuffer
is created and used to keep track of cumulative Watt-hours.



]]

-- ************************* FUNCTIONS **************************
function setup_DMM6500_buffer(BufSize)
	dciBuffer = buffer.make(BufSize, buffer.STYLE_STANDARD)
	dciBuffer.clear()
	buffer.clearstats(dciBuffer)
	dciBuffer.capacity = 1 * BufSize
	dciBuffer.fillmode = buffer.FILL_CONTINUOUS
end -- function

function setup_DMM6500_measure(sampleRate, measRange) -- Setup master function
	-- setup our refilling buffer
	setup_DMM6500_buffer(sampleRate) -- BufSize = sampleRate = 1 second of buffering
	opc()
	-- setup measure type, ranges, etc.
	dmm.digitize.func = dmm.FUNC_DIGITIZE_CURRENT
	opc()
	dmm.digitize.range = measRange
	
	dmm.digitize.samplerate = sampleRate
	dmm.digitize.aperture = dmm.APERTURE_AUTO
	-- Changing count is optional. The reading buffer capacity is the determining factor
	dmm.digitize.count = 1 -- CANNOT be zero; 1 to 55Million
	-- control the swipe screen
	display.clear()
	display.changescreen(display.SCREEN_USER_SWIPE)
	-- clear any existing trigger blocks
	trigger.clear()
	
	trigger.model.load("Empty")
	opc()
	-- Define a trigger model that will capture until we push front panel trigger button
	trigger.model.setblock(1, trigger.BLOCK_BUFFER_CLEAR, dciBuffer)
	trigger.model.setblock(2, trigger.BLOCK_DELAY_CONSTANT, 0)
	trigger.model.setblock(3, trigger.BLOCK_DIGITIZE, dciBuffer, trigger.COUNT_INFINITE)
	trigger.model.setblock(4, trigger.BLOCK_WAIT, trigger.EVENT_DISPLAY) -- wait until the TRIGGER key is pressed
	trigger.model.setblock(5, trigger.BLOCK_DIGITIZE, dciBuffer, trigger.COUNT_STOP) -- stop making digitized measurements
	opc()
end -- function

function my_dmm6500_waitcomplete(useWattHrs, dcvVal) -- Main loop, exit with Trigger button
	local i = 1
	local cbIndex = 1
	local tempVal = 0
	local t1 = 0
	local t2 = 0
	local runtime = 0	-- get a starting baseline...
	
	-- timer.clear()		-- necessary??? what happens when timer counter variable overflows or rolls over?
	t1 = timer.gettime()
	-- check trigger model state on Amp-Hr meter (DMM6500)
	present_state, n = trigger.model.state() -- state, present block number
	-- STATE_RUNNING, IDLE, WAITING, EMPTY, FAILED, ABORTING, ABORTED, BUILDING
	while present_state == (trigger.STATE_WAITING or trigger.STATE_RUNNING) do
		reading_stats = buffer.getstats(dciBuffer)
		i_avg = reading_stats.mean
		-- runtime = dciBuffer.relativetimestamps[dciBuffer.n]
		t2 = timer.gettime()
		runtime = runtime + (t2 - t1)		-- calculate the difference in reported seconds and add to the runtime
		t1 = t2								-- shift the last time reading over
		-- get and remove the hours from the runtime
		hrs = math.floor(runtime/3600)
		rt2 = runtime - hrs * 3600
		-- get and remove the minutes from the runtime
		min = math.floor(rt2/60)
		secs = rt2 - (min * 60)
		-- get the remaining seconds
		
		AmpHrs = i_avg * runtime/3600
		if useWattHrs == 0 then
			-- display.settext(display.TEXT1, string.format("Amp-Hrs: %.4e", AmpHrs));
			-- display.settext(display.TEXT2, string.format("Avg. I: %.3e A", i_avg));
			-- 27-Aug-2018 ALC replace with new User Screen Info
			display.settext(display.TEXT1, "AHr|AvgI|Time(h:m:s)")
			-- display.settext(display.TEXT2, string.format("%.4f", AmpHrs).."|"..string.format("%.4f", i_avg).."|"..string.format("%.2f", runtime))
			display.settext(display.TEXT2, string.format("%.4f", AmpHrs).."|"..string.format("%.4f", i_avg).."|"..string.format("%d:%d:%.2f", hrs, min, secs))
			tempVal = AmpHrs
			buffer.write.reading(ampHrsBuffer, tempVal, runtime)
		else
			WattHrs = AmpHrs * dcvVal
			display.settext(display.TEXT1, string.format("Watt-Hrs: %.4e", WattHrs));
			display.settext(display.TEXT2, string.format("Avg. I: %.6e A", i_avg));
			tempVal = WattHrs
			buffer.write.reading(wattHrsBuffer, tempVal, runtime)
		end
		delay(1)
		i = i + 1
		present_state, n = trigger.model.state() -- update the trigger model state var
	end -- while loop
end -- function

function get_amphrs() -- Update numbers to display
present_state, n = trigger.model.state()
reading_stats = buffer.getstats(dciBuffer)
runtime = dciBuffer.relativetimestamps[dciBuffer.n]
i_avg = reading_stats.mean
AmpHrs = i_avg * runtime/3600
end -- function

function set_dci_range()
	if (dmm.terminals == dmm.TERMINALS_REAR) then
		  -- offer 10Amp Range too
		optionID = display.input.option("Select current range", "1A", "100mA", "10mA", "1mA",
		"100uA", "10uA", "10A")
	else
		-- if front terminals, do not offer 10Amp range
		optionID = display.input.option("Select current range", "1A", "100mA", "10mA", "1mA",
		"100uA", "10uA")
	end  -- if
	if optionID == display.BUTTON_OPTION1 then -- 1A
		return 1.0
	elseif optionID == display.BUTTON_OPTION2 then -- 100mA
		return 100e-3
	elseif optionID == display.BUTTON_OPTION3 then -- 10mA
		return 10e-3
	elseif optionID == display.BUTTON_OPTION4 then -- 1mA
		return 1e-3
	elseif optionID == display.BUTTON_OPTION5 then -- 100uA
		return 100e-6
	elseif optionID == display.BUTTON_OPTION6 then -- 10uA
		return 10e-6
	elseif optionID == display.BUTTON_OPTION7 then -- 10A
		return 10
	end
end -- function

function set_output_hrs_format() -- Get Calculation setting from user
	optionID = display.input.option("Select Computation Option", "Amp-Hours", "Watt-Hours")
	if optionID == display.BUTTON_OPTION1 then -- Amp-Hrs
		return 0
	elseif optionID == display.BUTTON_OPTION2 then -- Watt-Hrs
		return 1
	end
end -- function

function get_user_sample_rate()
	return display.input.number("Sample Rate", display.NFORMAT_INTEGER, 50000, 1000, 125000)
end -- function

function get_user_dcv_value()
	-- for the watt-hours, have the user input the applied voltage to their device
	local dcvVal = display.input.number("DCV Level Applied", display.NFORMAT_DECIMAL, 3.25, 0.0, 24.0)
    if dcvVal == nil then exit() end
    return dcvVal
end -- function


-- ************************* MAIN PROGRAM **************************
-- local a,b = math.modf(os.clock())
-- a = timer.gettime()
-- delay(1.234)
-- b = timer.gettime()
-- c = string.format("Elapsed time: %f s", (b-a))
-- print(c)

reset() -- reset the DMM6500
eventlog.clear()
-- set default sample_rate and current_range
local sample_rate = 15e3
local DMMcurrentMeasRange = 0.01
local dcvVal = 0.0
-- downsize the default buffers to ensure room for the new ones
defbuffer1.capacity = 10
defbuffer2.capacity = 10
-- let us size this for 1 sample per second for up to 30 days: 60*60*24*30 = 2,592,000
local hrsFormat = set_output_hrs_format()
if hrsFormat == 0 then -- provide semi-acceptable units to be visible on the graph and in the reading table
    ampHrsBuffer = buffer.make(2592000, buffer.STYLE_WRITABLE)
    buffer.write.format(ampHrsBuffer, buffer.UNIT_AMP, buffer.DIGITS_6_5)
else
    wattHrsBuffer = buffer.make(2592000, buffer.STYLE_WRITABLE)
    buffer.write.format(wattHrsBuffer, buffer.UNIT_WATT, buffer.DIGITS_6_5)
end
if hrsFormat == 1 then
    dcvVal = get_user_dcv_value()
end
dmm.digitize.func = dmm.FUNC_DIGITIZE_CURRENT
dmm.digitize.range = DMMcurrentMeasRange

sample_rate = get_user_sample_rate()-- let the user select the sample rate to use
DMMcurrentMeasRange = set_dci_range()-- let the user select the current range to use
setup_DMM6500_measure(sample_rate, DMMcurrentMeasRange)
-- start our DMM6500 High Speed Digitizing
trigger.model.initiate()
delay(0.5) -- allow some data to accumulate....
-- start the DMM6500 Amp-Hr status reporting loop
-- Press TRIGGER button to exit the loop
my_dmm6500_waitcomplete(hrsFormat, dcvVal)
-- clean up DMM6500 (Amp-Hr)
trigger.model.abort()