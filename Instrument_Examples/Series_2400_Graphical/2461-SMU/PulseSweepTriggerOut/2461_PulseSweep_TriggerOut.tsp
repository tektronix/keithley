--[[
	
	Description:	This Model 2461 example shows you how to set up
	a pulsed voltage sweep that produces a trigger on a digital I/O pin
	when finished with the sweep. You can use this trigger to notify
	other instruments that the 2461 completed its pulse sweep.
	
	The Model 2461 voltage source outputs a pulse sweep from 1V to 5V 
	in 101 steps as the Model 2461 ammeter measures the resulting current
	through the DUT. The application is set up to make 10ms pulses with 
	90ms of off time; 45ms before each pulse and 45ms after each pulse 
	Once the measurements are made, the output is turned off.
	
	The Model 2461's pulse commands are utilized to generate the config
	lists used by the trigger model for pulsing, but the trigger model
	is replaced with one that produces the output trigger. The function
	pulse_delay_cal is used to compute the length of the constant delay
	block used to set the width of each pulse in the sweep. The computation
	is normally done by the instrument when the pulse commands build the
	trigger model, but the script must do it because the strandard trigger
	model is being erased and replaced for this example. The current
	and voltage readings are printed to the Instrument Console. You can
	copy and paste these readings into a spreadsheet for further analysis.
	
--]]
	
	
--Function to calculate the pulse width delay block's time
local function pulse_delay_calc(pulseWidth)

	--Gather status information from the the SMU
	local NPLC = smu.measure.nplc
	local line_freq = localnode.linefreq
	local sreadback = smu.source.readback
	local autoZero = smu.measure.autozero.enable
	local filter = smu.measure.filter.enable
	local filterType = smu.measure.filter.type
	local filterCount = smu.measure.filter.count
	local reading_count = 1
	
	if (filter == smu.ON and filterType == smu.FILTER_REPEAT_AVG) then
		reading_count = reading_count + filterCount - 1 --Account for the number of repeat filter readings
	else 
		filterCount = 1
	end
	
	if (autoZero == smu.ON and sreadback == smu.OFF) then
		reading_count = reading_count*3 --The SMU takes 3 readings if autozero is on
	elseif (autoZero == smu.ON and sreadback == smu.ON) then
		reading_count = reading_count*4 --The SMU takes 4 readings if autozero and source readback are on
	elseif (autoZero == smu.OFF and sreadback == smu.ON) then
		reading_count = reading_count*2 --The SMU takes 2 readings if source readback is on
	end
	
	
	--The delays in the meas_time calculation come from:
	--200us for reading post processing EVERY reading
	--repeat average filtering shaves 50us off of this time for every set of readings
	local meas_time = (1/line_freq)*NPLC*reading_count + 200e-6*reading_count - filterCount*50e-6
	
	
	--Calculate the(not quite finalized) final_delay by subtracting
	--calculated measure time and 80us of pulse output block overhead
	local final_delay = pulseWidth - meas_time - 80e-6
	
	
	if (sreadback == smu.ON) then
		final_delay = final_delay - .41e-3*filterCount --Source readback takes an extra 410us for every set of readings
	end
	if (autoZero == smu.ON) then
		final_delay = final_delay - 1.28e-3*filterCount --Autozero takes an extra 1.28ms for every set of readings
	end
	if(final_delay > 0) then
		return final_delay --Pass the final delay as an output
	else
		print("Measure time too long!") -- The measure time exceeds the desired pulse width
		return 0
	end
end	

--Reset the instrument
reset()
smu.source.func 						= smu.FUNC_DC_VOLTAGE 
smu.source.range						= 7
smu.measure.func 						= smu.FUNC_DC_CURRENT
smu.measure.sense 						= smu.SENSE_2WIRE
smu.measure.autorange 					= smu.ON
-- The instrument will select a best fixed range to fit the pulses

smu.source.readback 					= smu.ON
smu.measure.autozero.enable 			= smu.OFF
smu.measure.nplc						= .01
-- NPLC can be increased to improve measurement accuracy.
-- However, it has to remain small enough to fit the measurement
-- within the width of the settled part of the pulse.

--Set up the pulse parameters
local configListName = "myPulseSweep"
local biasLevel = 0					-- Bias level between pulses
local start = 1						-- Sweep start point
local stop = 5						-- Sweep end point
local points = 101					-- 101 points in the sweep
local pulseWidth = 10e-3				-- Pulse width
local MeasureEnable = smu.ON			-- Enables measurements on each pulse
local bufferName = defbuffer1			-- Buffer to save results
local pulse_delay = 45e-3				-- Delay before each pulse
local offTime = 45e-3					-- Off time after each pulse
local count = 1 						-- Number of times to repeat the pulse sweep
local xBiasLimit = 1e-3				-- Current limit between pulses
local xPulseLimit = 100e-3			-- Current limit during pulses
local failAbort = smu.OFF				-- Abort pulse sweep if current limit is hit
local dual = smu.OFF					-- Only sweep from 1V to 5V, but not back down again

--2461 Pulse Command
smu.source.pulsesweeplinear(configListName, biasLevel, start, stop, points, pulseWidth, MeasureEnable, bufferName, pulse_delay, offTime, count, xBiasLimit, xPulseLimit, failAbort, dual)

--Configure tsplink triggering

digio.line[1].mode 					= digio.MODE_TRIGGER_OUT
trigger.digout[1].logic 			= trigger.LOGIC_NEGATIVE
trigger.digout[1].stimulus 			= trigger.EVENT_NOTIFY1

--Configure the trigger model with TSP
trigger.model.load("Empty")
trigger.model.setblock(1, trigger.BLOCK_BUFFER_CLEAR, bufferName)
trigger.model.setblock(2, trigger.BLOCK_CONFIG_RECALL,"MeasmyPulseSweep", 1, "myPulseSweep", 1)
trigger.model.setblock(3, trigger.BLOCK_SOURCE_OUTPUT, smu.ON)
trigger.model.setblock(4, trigger.BLOCK_BRANCH_ALWAYS, 6)
trigger.model.setblock(5, trigger.BLOCK_CONFIG_NEXT, "myPulseSweep")
trigger.model.setblock(6, trigger.BLOCK_DELAY_CONSTANT, pulse_delay)
trigger.model.setblock(7, trigger.BLOCK_SOURCE_PULSE_OUTPUT, smu.ON)
trigger.model.setblock(8, trigger.BLOCK_DELAY_CONSTANT, pulse_delay_calc(pulseWidth))
trigger.model.setblock(9, trigger.BLOCK_MEASURE_DIGITIZE, bufferName)
trigger.model.setblock(10, trigger.BLOCK_SOURCE_PULSE_OUTPUT, smu.OFF)
trigger.model.setblock(11, trigger.BLOCK_DELAY_CONSTANT, offTime)
trigger.model.setblock(12, trigger.BLOCK_BRANCH_COUNTER, points, 5)
trigger.model.setblock(13, trigger.BLOCK_SOURCE_OUTPUT, smu.OFF)
trigger.model.setblock(14, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1)

--Run trigger model and wait for it to complete
trigger.model.initiate()
waitcomplete()

--Print Results
if defbuffer1.n == 0 then
	print("Buffer is empty\n")
else
	print("Current\tVoltage")
	for i=1,defbuffer1.n do
		print(string.format("%g\t%g", defbuffer1.sourcevalues[i], defbuffer1.readings[i]))
	end
end