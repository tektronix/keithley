--[[
	Title:			Fast ADC Usage

	Description:	This script is designed to output pulses and
	capture	both the current and the voltage of the pulse using
	the fast ADC of the Model 2651A High Power System SourceMeter
	instrument.

	Equipment Needed:
		1x 2651A
]]

--[[
	Name:	CapturePulseV(pulseLevel, pulseWidth, pulseLimit,
							numPulses)
	Description:
		This function outputs voltage pulses with a 1% duty cycle and
	performs measurements using the fast ADC to capture each pulse in
	its entirety.  At the conclusion of the pulse train, the data is
	returned to the instrument console in a Microsoft Excel
	compatible format.

	Parameters:
		pulseLevel:		The voltage level of the pulse in volts
		pulseWidth:		The width of the pulse in seconds
						100e-6 <= pulseWidth <= 4e-3
		pulseLimit:		The current limit of the pulse in amps
		numPulses:		The number of pulses to output

	Example Usage:
		CapturePulseV(5, 300e-6, 50, 5)
]]
function CapturePulseV(pulseLevel, pulseWidth, pulseLimit, numPulses)
	if (numPulses == nil) then numPulses = 1 end

	-- Configure the SMU
	reset()
	smua.reset()
	smua.source.func			= smua.OUTPUT_DCVOLTS
	smua.sense					= smua.SENSE_REMOTE
	smua.source.rangev			= pulseLevel
	smua.source.levelv			= 0		-- The bias level
	smua.source.limiti			= 5		-- The DC Limit
	smua.measure.autozero		= smua.AUTOZERO_ONCE

	-- Use a measure range that is as large as the biggest
	-- possible pulse
	smua.measure.rangei			= pulseLimit
	smua.measure.rangev			= pulseLevel

	-- Select the fast ADC for measurements
	smua.measure.adc			= smua.ADC_FAST

	-- Set the time between measurements.  1us is the smallest
	smua.measure.interval		= 1e-6

	-- Set the measure count to be 1.25 times the width of the pulse
	-- to ensure we capture the entire pulse plus falling edge.
	smua.measure.count			=
					(pulseWidth / smua.measure.interval) * 1.25

	-- Prepare the reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps	= 1
	smua.nvbuffer1.collectsourcevalues	= 0
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps	= 1
	smua.nvbuffer2.collectsourcevalues	= 0
	-- Can't use source values with async measurements

	-- Configure the Pulsed Sweep setup
	-----------------------------------
	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numPulses - 1
	-- -- 1% Duty Cycle
	trigger.timer[1].delay			= pulseWidth / 0.01
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= pulseWidth - 3e-6
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		=
				smua.trigger.SOURCE_COMPLETE_EVENT_ID


	-- Configure SMU Trigger Model for Sweep/Pulse Output
	-----------------------------------------------------
	-- Pulses will all be the same level so set start and stop to
	-- the same value and the number of points in the sweep to 2
	smua.trigger.source.linearv(pulseLevel, pulseLevel, 2)
	smua.trigger.source.limiti		= pulseLimit
	smua.trigger.measure.action		= smua.ASYNC
	-- We want to start the measurements before the source action takes
	-- place so we must configure the ADC to operate asynchronously of
	-- the rest of the SMU trigger model actions
	
	-- Measure I and V during the pulse
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)

	-- Return the output to the bias level at the end of the pulse/sweep
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numPulses
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE


	smua.source.output				= 1
	smua.trigger.initiate()
	waitcomplete()
	smua.source.output				= 0

	PrintPulseData()
end

--[[
	Name:	CapturePulseI(pulseLevel, pulseWidth, pulseLimit,
				numPulses)
	Description:
		This function outputs current pulses with a 1% duty cycle and
	performs measurements using the fast ADC to capture each pulse in
	its entirety.  At the conclusion of the pulse train, the data is
	returned to the instrument console in a Microsoft Excel compatible
	format.

	Parameters:
		pulseLevel:		The current level of the pulse in amps
		pulseWidth:		The width of the pulse in seconds
						100e-6 <= pulseWidth <= 4e-3
		pulseLimit:		The voltage limit of the pulse in volts
		numPulses:		The number of pulses to output

	Example Usage:
		CapturePulseI(50, 300e-6, 10, 5)
]]
function CapturePulseI(pulseLevel, pulseWidth, pulseLimit, numPulses)
	if (numPulses == nil) then
		numPulses = 1
	end

	-- Configure the SMU
	reset()
	smua.reset()
	smua.source.func			= smua.OUTPUT_DCAMPS
	smua.sense					= smua.SENSE_REMOTE
	smua.source.rangei			= pulseLevel
	smua.source.leveli			= 0		-- The bias level
	smua.source.limitv			= 10	-- The DC Limit
	smua.measure.autozero		= smua.AUTOZERO_ONCE

	-- Use a measure range that is as large as the biggest
	-- possible pulse
	smua.measure.rangev			= pulseLimit
	smua.measure.rangei			= pulseLevel

	-- Select the fast ADC for measurements
	smua.measure.adc			= smua.ADC_FAST

	-- Set the time between measurements.  1us is the smallest
	smua.measure.interval		= 1e-6

	-- Set the measure count to be 1.25 times the width of the pulse
	-- to ensure we capture the entire pulse plus falling edge.
	smua.measure.count			=
					(pulseWidth / smua.measure.interval) * 1.25

	-- Prepare the reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps	= 1
	smua.nvbuffer1.collectsourcevalues	= 0
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps	= 1
	smua.nvbuffer2.collectsourcevalues	= 0
	-- Can't use source values with async measurements

	-- Configure the Pulsed Sweep setup
	-----------------------------------
	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numPulses - 1
	-- 1% Duty Cycle
	trigger.timer[1].delay			= pulseWidth / 0.01 
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= pulseWidth - 3e-6
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		=
				smua.trigger.SOURCE_COMPLETE_EVENT_ID


	-- Configure SMU Trigger Model for Sweep/Pulse Output
	-----------------------------------------------------
	-- Pulses will all be the same level so set start and stop to
	-- the same value and the number of points in the sweep to 2
	smua.trigger.source.lineari(pulseLevel, pulseLevel, 2)
	smua.trigger.source.limitv		= pulseLimit
	smua.trigger.measure.action		= smua.ASYNC
	-- We want to start the measurements before the source action takes
	-- place so we must configure the ADC to operate asynchronously of
	-- the rest of the SMU trigger model actions
	
	-- Measure I and V during the pulse
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)

	-- Return the output to the bias level at the end of the pulse
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numPulses
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE


	smua.source.output				= 1
	smua.trigger.initiate()
	waitcomplete()
	smua.source.output				= 0

	PrintPulseData()
end

--[[
	Name:	PrintPulseData()
	Description;
		This function prints the data contained in smua.nvbuffer1 and
	smua.nvbuffer2 in an format that is copy and paste compatible with
	Microsoft Excel.
]]
function PrintPulseData()
	print("Timestamp\tVoltage\tCurrent")
	for i=1, smua.nvbuffer1.n do
		print(string.format("%g\t%g\t%g",
							smua.nvbuffer1.timestamps[i],
							smua.nvbuffer2[i],
							smua.nvbuffer1[i]))
	end
end
