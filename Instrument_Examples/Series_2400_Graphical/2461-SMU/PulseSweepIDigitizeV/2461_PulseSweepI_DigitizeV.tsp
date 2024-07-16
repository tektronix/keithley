--[[
	
	Description:	This Model 2461 example shows you how to set up
	a pulsed current sweep that starts at -10mA and stop at 10mA	
	The Model 2461 current source creates 201 pulses and is constantly
	taking digitizer readings at a rate of 500,000 samples per second. 
	The application is set up to make 500us pulses with 500us of off 
	time after each pulse. 
	
	The Model 2461's pulse commands are used to generate the trigger model
	necessary for pulsing. All of the source and measure settings are
	configured before the pulse command (smu.source.pulsesweeplinear)
	is sent to the instrument. The pulse command accepts a lot of arguments
	so the the arguments are stored in variables to make them easier to
	read.
	
--]]


--Reset the instrument
reset()

--Source settings
smu.source.func = smu.FUNC_DC_CURRENT	
smu.source.range = 10e-3
smu.source.readback = smu.ON


--Digitize settings
smu.digitize.func = smu.FUNC_DIGITIZE_VOLTAGE
smu.digitize.sense = smu.SENSE_4WIRE
smu.digitize.range = 20
smu.digitize.samplerate = 500000
defbuffer1.capacity = 1000000

--Pulse command parameters
local configListName = "myPulseSweep"
local bias_level = 0 					-- Bias level between pulses
local start = -10e-3 					-- Sweep start point
local stop = 10e-3 					-- Sweep end point
local points = 201 					-- 201 points in the sweep
local pulse_width = 500e-6 			-- Pulse width
local MeasureEnable = smu.ON 			-- Enables digitized measurements
local bufferName = defbuffer1 		-- Buffer to save results 
local pulse_delay = 0 				-- Delay before each pulse
local offTime = 500e-6 				-- Off time after each pulse
local count = 1 						-- Number of times to repeat the pulse sweep
local xBiasLimit = 2 					-- Voltage limit between pulses
local xPulseLimit = 20 				-- Voltage limit during pulses
local failAbort = smu.ON 				-- Abort pulse sweep if voltage limit is hit
local dual = smu.OFF 					-- Only sweep from -10ma to 10ma, but not back down again

--Pulse command
smu.source.pulsesweeplinear(configListName, bias_level, start, stop, points, pulse_width, MeasureEnable, bufferName, pulse_delay, offTime, count, xBiasLimit, xPulseLimit, failAbort, dual)

--Intiate trigger model to start pulse sweep
trigger.model.initiate()
waitcomplete()