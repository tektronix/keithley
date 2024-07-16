--[[
	Title:			KE26XXB Pulsed Sweep Single

	Description:	This example demonstrates how to output a pulsed sweep
		on a single SMU channel.  This script performs a linear sweep but
		can easily be modified to perform log or list sweeps.
		There are two functions contained in this script.  One function
		performs a pulsed voltage sweep while the other performs a pulsed
		current sweep.
		At the conclusion of the sweeps the data is returned to the
		instrument console in a format that is compatible for copy and
		paste into Microsoft Excel.

	Equipment Needed:
		1x Series 2600B SourceMeter instrument

	Script Functions:
		PulsedSweepVSingle(start, stop, numPoints, pulseWidth, pulsePeriod, limitI, nplc, remoteSense)
		PulsedSweepISingle(start, stop, numPoints, pulseWidth, pulsePeriod, limitV, nplc, remoteSense)
--]]

--[[
	Name:	PulsedSweepVSingle(start, stop, numPoints, pulseWidth, pulsePeriod, limitI, nplc, remoteSense)
	
	Description:
		This function performs a pulsed linear voltage sweep on a single SMU channel.

	Parameters:
		start:			The voltage level of the first step in the sweep in volts
		stop:			The voltage level of the last step in the sweep in volts
		numPoints:		The number of points in the sweep
		pulseWidth:		The width of the pulse in seconds
		pulsePeriod:	The time from the start of one pulse to the start of the next pulse
		limitI:			The current limit of the pulse in amps
		nplc:			The measurment aperture setting in PLCs where 1 PLC = 1/60 s for 60Hz power
		remoteSense		Set to true to enable 4-Wire (Kelvin) measurements or to false for 2-Wire measurements

	Notes:
		After calling this function you will need to press the TRIG button
		on the instrument's front panel to trigger the sweep to start.
		The code can easily be modified to trigger off other sources as
		well.

	Example Usage:
		PulsedSweepVSingle(0, 10, 11, 1e-3, 5e-3, 0.1, 0.001, false)
--]]
function PulsedSweepVSingle(start, stop, numPoints, pulseWidth, pulsePeriod, limitI, nplc, remoteSense)
	reset()
	smua.reset()
	smua.source.func					= smua.OUTPUT_DCVOLTS
	if remoteSense == true then
		smua.sense						= smua.SENSE_REMOTE
	else
		smua.sense						= smua.SENSE_LOCAL
	end
	smua.source.autorangev			= smua.AUTORANGE_OFF
	smua.source.rangev				= math.max(math.abs(start), math.abs(stop))
	smua.source.levelv				= 0
	-- Set the DC bias limit.  This is not the limit used during the pulses.
	smua.source.limiti				= 0.1

	-- Disabling Auto-Ranging and Auto-Zero ensures accurate and consistent timing
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangei			= smua.AUTORANGE_OFF
	smua.measure.rangei				= limitI
	smua.measure.nplc				= nplc
	-- A timer will be used to control the measure delay so set the built-in delay to 0
	smua.measure.delay				= 0

	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps= 1

	-- Configure the Trigger Model
	--============================
	-- Pressing the TRIG button on the front panel will trigger the sweep to start
	display.trigger.clear()

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numPoints > 1 and numPoints - 1 or 1
	trigger.timer[1].delay			= pulsePeriod
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= display.trigger.EVENT_ID

	-- Timer 2 controls the measure delay
	trigger.timer[2].count			= 1
	-- Set the measure delay long enough so that measurements start after the pulse
	-- has settled, but short enough that it fits within the width of the pulse.
	trigger.timer[2].delay			= pulseWidth - (1/localnode.linefreq)*nplc - 60e-6
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= trigger.timer[1].EVENT_ID
	
	-- Timer 3 controls the pulse width
	trigger.timer[3].count			= 1
	trigger.timer[3].delay			= pulseWidth
	trigger.timer[3].passthrough	= false
	trigger.timer[3].stimulus		= trigger.timer[1].EVENT_ID

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.linearv(start, stop, numPoints)
	smua.trigger.source.limiti		= limitI
	smua.trigger.measure.action		= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numPoints
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[3].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE
	--==============================
	-- End Trigger Model Configuration

	smua.source.output				= smua.OUTPUT_ON

	-- Start the trigger model execution
	smua.trigger.initiate()
	-- Sweep will not start TRIG button is pressed

	-- Wait until the sweep has completed
	waitcomplete()
	smua.source.output				= smua.OUTPUT_OFF

	-- Print the data back to the Console in tabular format
	print("Time\tVoltage\tCurrent")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x])
	end
end

--[[
	Name:	PulsedSweepISingle(start, stop, numPoints, pulseWidth, pulsePeriod, limitV, nplc, remoteSense)
	
	Description:
		This function performs a pulsed linear current sweep on a single SMU channel.

	Parameters:
		start:			The current level of the first step in the sweep in amps
		stop:			The current level of the last step in the sweep in amps
		numPoints:		The number of points in the sweep
		pulseWidth:		The width of the pulse in seconds
		pulsePeriod:	The time from the start of one pulse to the start of the next pulse
		limitI:			The voltage limit of the pulse in volts
		nplc:			The measurment aperture setting in PLCs where 1 PLC = 1/60 s for 60Hz power
		remoteSense		Set to true to enable 4-Wire (Kelvin) measurements or to false for 2-Wire measurements

	Notes:
		After calling this function you will need to press the TRIG button
		on the instrument's front panel to trigger the sweep to start.
		The code can easily be modified to trigger off other sources as
		well.

	Example Usage:
		PulsedSweepISingle(0, 10e-3, 11, 1e-3, 5e-3, 10, 0.001, false)
--]]
function PulsedSweepISingle(start, stop, numPoints, pulseWidth, pulsePeriod, limitV, nplc, remoteSense)
	reset()
	smua.reset()
	smua.source.func					= smua.OUTPUT_DCAMPS
	if remoteSense == true then
		smua.sense						= smua.SENSE_REMOTE
	else
		smua.sense						= smua.SENSE_LOCAL
	end
	smua.source.autorangei			= smua.AUTORANGE_OFF
	smua.source.rangei				= math.max(math.abs(start), math.abs(stop))
	smua.source.leveli				= 0
	-- Set the DC bias limit.  This is not the limit used during the pulses.
	smua.source.limitv				= 1

	-- Disabling Auto-Ranging and Auto-Zero ensures accurate and consistent timing
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= smua.AUTORANGE_OFF
	smua.measure.rangev				= limitV
	smua.measure.nplc				= nplc
	-- A timer will be used to control the measure delay so set the built-in delay to 0
	smua.measure.delay				= 0

	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps= 1

	-- Configure the Trigger Model
	--============================
	-- Pressing the TRIG button on the front panel will trigger the sweep to start
	display.trigger.clear()

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numPoints > 1 and numPoints - 1 or 1
	trigger.timer[1].delay			= pulsePeriod
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= display.trigger.EVENT_ID

	-- Timer 2 controls the measure delay
	trigger.timer[2].count			= 1
	-- Set the measure delay long enough so that measurements start after the pulse
	-- has settled, but short enough that it fits within the width of the pulse.
	trigger.timer[2].delay			= pulseWidth - (1/localnode.linefreq)*nplc - 60e-6
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= trigger.timer[1].EVENT_ID

	-- Timer 3 controls the pulse width
	trigger.timer[3].count			= 1
	trigger.timer[3].delay			= pulseWidth
	trigger.timer[3].passthrough	= false
	trigger.timer[3].stimulus		= trigger.timer[1].EVENT_ID

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.lineari(start, stop, numPoints)
	smua.trigger.source.limitv		= limitV
	smua.trigger.measure.action		= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numPoints
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[3].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE
	--==============================
	-- End Trigger Model Configuration

	smua.source.output				= smua.OUTPUT_ON

	-- Start the trigger model execution
	smua.trigger.initiate()
	-- Sweep will not start until the TRIG button is pressed

	-- Wait until the sweep has completed
	waitcomplete()
	smua.source.output				= smua.OUTPUT_OFF

	-- Print the data back to the Console in tabular format
	print("Time\tVoltage\tCurrent")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x])
	end
end
