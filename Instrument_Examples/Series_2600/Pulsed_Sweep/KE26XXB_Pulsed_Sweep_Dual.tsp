--[[
	Title:			KE26XXB Pulsed Sweep Dual

	Description:	This example demonstrates how to synchronize pulsed
		sweeps between two SMU channels on a dual channel Series 2600B
		SourceMeter instrument.  This example performs linear sweeps but
		can easily be modified to perform log or list sweeps.  This
		example also programs both SMUs to source the same levels
		however, this can also easily be modified for each SMU to output
		different levels.
		There are two functions contained in this example script.  One
		function outputs pulsed voltage sweeps while the other performs
		pulsed current sweeps.
		At the conclusion of the sweeps the data is returned to the
		instrument console in a format that is compatible for copy and
		paste into Microsoft Excel.

	Equipment Needed:
		1x Dual Channel Series 2600B SourceMeter instrument

	Script Functions:
		PulsedSweepVDual(start, stop, numPoints, pulseWidth, pulsePeriod, limitI, nplc, remoteSense)
		PulsedSweepIDual(start, stop, numPoints, pulseWidth, pulsePeriod, limitV, nplc, remoteSense)
]]

--[[
	Name:	PulsedSweepVDual(start, stop, numPoints, pulseWidth, pulsePeriod, limitI, nplc, remoteSense)
	
	Description:
		This function performs synchronized pulsed linear voltage sweeps
		on dual SMU channels.

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
		PulsedSweepVDual(0, 10, 11, 1e-3, 5e-3, 0.1, 0.001, false)
]]
function PulsedSweepVDual(start, stop, numPoints, pulseWidth, pulsePeriod, limitI, nplc, remoteSense)
	reset()
	-- Configure Channel A Settings
	--=============================
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
	-- A timer will be used to set the measure delay and synchronize the measurement
	-- between the two SMUs so set the built in delay to 0.
	smua.measure.delay				= 0
	
	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps= 1
	--=============================
	-- End Channel A Settings

	-- Configure Channel B Settings
	--=============================
	smub.reset()
	smub.source.func					= smub.OUTPUT_DCVOLTS
	if remoteSense == true then
		smub.sense						= smub.SENSE_REMOTE
	else
		smub.sense						= smub.SENSE_LOCAL
	end
	smub.source.autorangev			= 0
	smub.source.rangev				= math.max(math.abs(start), math.abs(stop))
	smub.source.levelv				= 0
	-- Set the DC bias limit.  This is not the limit used during the pulses.
	smub.source.limiti				= 0.1

	-- Disabling Auto-Ranging and Auto-Zero ensures accurate and consistent timing
	smub.measure.autozero			= smua.AUTOZERO_ONCE
	smub.measure.autorangei			= 0
	smub.measure.rangei				= limitI
	smub.measure.nplc				= nplc
	-- A timer will be used to set the measure delay and synchronize the measurement
	-- between the two SMUs so set the built in delay to 0.
	smub.measure.delay				= 0

	-- Prepare the Reading Buffers
	smub.nvbuffer1.clear()
	smub.nvbuffer1.collecttimestamps= 1
	smub.nvbuffer2.clear()
	smub.nvbuffer2.collecttimestamps= 1
	--=============================
	-- End Channel B Settings

	-- Configure the Trigger Model
	--============================
	-- Pressing the TRIG button on the front panel will trigger the sweep to start
	display.trigger.clear()

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numPoints > 1 and numPoints - 1 or 1
	trigger.timer[1].delay			= pulsePeriod
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= display.trigger.EVENT_ID

	-- Timer 2 controls the measurement
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

	-- Configure SMUA Trigger Model for Sweep
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

	-- Configure SMUB Trigger Model for Sweep
	smub.trigger.source.linearv(start, stop, numPoints)
	smub.trigger.source.limiti		= limitI
	smub.trigger.measure.action		= smub.ENABLE
	smub.trigger.measure.iv(smub.nvbuffer1, smub.nvbuffer2)
	smub.trigger.endpulse.action	= smub.SOURCE_IDLE
	smub.trigger.endsweep.action	= smub.SOURCE_IDLE
	smub.trigger.count				= numPoints
	smub.trigger.arm.stimulus		= 0
	smub.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smub.trigger.measure.stimulus	= trigger.timer[2].EVENT_ID
	smub.trigger.endpulse.stimulus	= trigger.timer[3].EVENT_ID
	smub.trigger.source.action		= smub.ENABLE
	--==============================
	-- End Trigger Model Configuration

	smua.source.output				= smua.OUTPUT_ON
	smub.source.output				= smub.OUTPUT_ON

	-- Start the trigger model execution
	smua.trigger.initiate()
	smub.trigger.initiate()
	-- Sweep will not start until the TRIG button is pressed

	-- Wait until the sweep has completed
	waitcomplete()
	smua.source.output				= smua.OUTPUT_OFF
	smub.source.output				= smub.OUTPUT_OFF
	
	-- Print the data back to the Console in tabular format
	print("Time\tSMUA Voltage\tSMUA Current\tSMUB Voltage\tSMUB Current")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x], smub.nvbuffer2[x], smub.nvbuffer1[x])
	end
end

--[[
	Name:	PulsedSweepIDual(start, stop, numPoints, pulseWidth, pulsePeriod, limitV, nplc, remoteSense)
	
	Description:
		This function performs synchronized pulsed linear current sweeps
		on dual SMU channels.

	Parameters:
		start:			The current level of the first step in the sweep in amps
		stop:			The current level of the last step in the sweep in amps
		numPoints:		The number of points in the sweep
		pulseWidth:		The width of the pulse in seconds
		pulsePeriod:	The time from the start of one pulse to the start of the next pulse
		limitV:			The voltage limit of the pulse in volts
		nplc:			The measurment aperture setting in PLCs where 1 PLC = 1/60 s for 60Hz power
		remoteSense		Set to true to enable 4-Wire (Kelvin) measurements or to false for 2-Wire measurements

	Notes:
		After calling this function you will need to press the TRIG button
		on the instrument's front panel to trigger the sweep to start.
		The code can easily be modified to trigger off other sources as
		well.

	Example Usage:
		PulsedSweepIDual(0, 10e-3, 11, 1e-3, 5e-3, 10, 0.001, false)
]]
function PulsedSweepIDual(start, stop, numPoints, pulseWidth, pulsePeriod, limitV, nplc, remoteSense)
	reset()
	-- Configure Channel A Settings
	--=============================
	smua.reset()
	smua.source.func					= smua.OUTPUT_DCAMPS
	if remoteSense == true then
		smua.sense						= smua.SENSE_REMOTE
	else
		smua.sense						= smua.SENSE_LOCAL
	end
	smua.source.autorangei			= 0
	smua.source.rangei				= math.max(math.abs(start), math.abs(stop))
	smua.source.leveli				= 0
	-- Set the DC bias limit.  This is not the limit used during the pulses.
	smua.source.limitv				= 10

	-- Disabling Auto-Ranging and Auto-Zero ensures accurate and consistent timing
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= 0
	smua.measure.rangev				= limitV
	smua.measure.nplc				= nplc
	-- A timer will be used to set the measure delay and synchronize the measurement
	-- between the two SMUs so set the built in delay to 0.
	smua.measure.delay				= 0
	
	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps= 1
	--=============================
	-- End Channel A Settings

	-- Configure Channel B Settings
	--=============================
	smub.reset()
	smub.source.func					= smub.OUTPUT_DCAMPS
	if remoteSense == true then
		smub.sense						= smub.SENSE_REMOTE
	else
		smub.sense						= smub.SENSE_LOCAL
	end
	smub.source.autorangei			= 0
	smub.source.rangei				= math.max(math.abs(start), math.abs(stop))
	smub.source.leveli				= 0
	-- Set the DC bias limit.  This is not the limit used during the pulses.
	smub.source.limitv				= 10

	-- Disabling Auto-Ranging and Auto-Zero ensures accurate and consistent timing
	smub.measure.autozero			= smua.AUTOZERO_ONCE
	smub.measure.autorangev			= 0
	smub.measure.rangev				= limitV
	smub.measure.nplc				= nplc
	-- A timer will be used to set the measure delay and synchronize the measurement
	-- between the two SMUs so set the built in delay to 0.
	smub.measure.delay				= 0

	-- Prepare the Reading Buffers
	smub.nvbuffer1.clear()
	smub.nvbuffer1.collecttimestamps= 1
	smub.nvbuffer2.clear()
	smub.nvbuffer2.collecttimestamps= 1
	--=============================
	-- End Channel B Settings

	-- Configure the Trigger Model
	--============================
	-- Pressing the TRIG button on the front panel will trigger the sweep to start
	display.trigger.clear()

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numPoints > 1 and numPoints - 1 or 1
	trigger.timer[1].delay			= pulsePeriod
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= display.trigger.EVENT_ID

	-- Timer 2 controls the measurement
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

	-- Configure SMUA Trigger Model for Sweep
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

	-- Configure SMUB Trigger Model for Sweep
	smub.trigger.source.lineari(start, stop, numPoints)
	smub.trigger.source.limitv		= limitV
	smub.trigger.measure.action		= smub.ENABLE
	smub.trigger.measure.iv(smub.nvbuffer1, smub.nvbuffer2)
	smub.trigger.endpulse.action	= smub.SOURCE_IDLE
	smub.trigger.endsweep.action	= smub.SOURCE_IDLE
	smub.trigger.count				= numPoints
	smub.trigger.arm.stimulus		= 0
	smub.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smub.trigger.measure.stimulus	= trigger.timer[2].EVENT_ID
	smub.trigger.endpulse.stimulus	= trigger.timer[3].EVENT_ID
	smub.trigger.source.action		= smub.ENABLE
	--==============================
	-- End Trigger Model Configuration

	smua.source.output				= smua.OUTPUT_ON
	smub.source.output				= smub.OUTPUT_ON

	-- Start the trigger model execution
	smua.trigger.initiate()
	smub.trigger.initiate()
	-- Sweep will not start until the TRIG button is pressed

	-- Wait until the sweep has completed
	waitcomplete()
	smua.source.output				= smua.OUTPUT_OFF
	smub.source.output				= smub.OUTPUT_OFF
	
	-- Print the data back to the Console in tabular format
	print("Time\tSMUA Voltage\tSMUA Current\tSMUB Voltage\tSMUB Current")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x], smub.nvbuffer2[x], smub.nvbuffer1[x])
	end
end