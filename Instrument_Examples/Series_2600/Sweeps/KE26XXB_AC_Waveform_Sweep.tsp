--[[
	Title:			KE26XXB AC Waveform Sweep

	Description:	This example demonstrates how to output an AC Waveform
		with the Series 2600B System SourceMeter instruments.  This
		example script shows how to use the math capabilities of the TSP
		scripting engine to generate a table of source values representing
		a sine wave to use as the list values for a list sweep.  This
		script also shows how to configure the Series 2600B trigger model
		to output this waveform with consistent timing.
		At the conclusion of the sweeps the data is returned to the
		instrument console in a format that is compatible for copy and
		paste into Microsoft Excel.

	Equipment Needed:
		1x Series 2600B SourceMeter instrument

	Script Functions:
		AC_Waveform_Sweep(Vrms, numCycles, frequency, limitI)
--]]

--[[
	Name:	AC_Waveform_Sweep(Vrms, numCycles, frequency, limitI)
	
	Description:
		This function demonstrates how to configure the SMU to output a
		AC waveform using the list sweep function.
		At the conclusion of the sweep the collected data is printed back
		to the instrument console in a format that is compatible for copy
		and paste into Microsoft Excel.

	Parameters:
		Vrms:		The desired RMS voltage of the sinewave
		numCycles:	The number of sinewave cycles to output
		frequency:	The frequency of the sinewave
		limitI:		The current limit of the output

	Notes:
		RMS voltage is smaller than peak voltage.  RMS voltage must be set
		low enough that peak voltage fits within the maximum voltage
		source range of the SourceMeter instrument.
		Maximum frequency is approximately 1000 Hz depending on the
		quality of sine wave desired.

	Example Usage:
		AC_Waveform_Sweep(12, 2, 60, 100e-3)
--]]
function AC_Waveform_Sweep(Vrms, numCycles, frequency, limitI)
	reset()

	-- Generate the source values
	local Vpp				= Vrms * math.sqrt(2)
	local sourceValues		= {} 
	local pointsPerCycle	= 7200 / frequency
	local numDataPoints		= pointsPerCycle * numCycles

	for i=1, numDataPoints do
		sourceValues[i]		= (Vpp * math.sin(i * 2 * math.pi / pointsPerCycle))
	end

	-- Configure the SMU ranges
	smua.reset()
	smua.source.settling		= smua.SETTLE_FAST_POLARITY
	smua.source.autorangev		= smua.AUTORANGE_OFF
	smua.source.autorangei		= smua.AUTORANGE_OFF
	smua.source.rangev			= Vpp
	smua.source.limiti			= limitI

	smua.measure.autorangev		= smua.AUTORANGE_OFF
	smua.measure.autorangei		= smua.AUTORANGE_OFF
	smua.measure.autozero		= smua.AUTOZERO_OFF
	-- Voltage will be measured on the same range as the source range
	smua.measure.rangei			= limitI
	smua.measure.nplc			= 0.001

	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps	= 1

	-- Configure the trigger model
	--============================
	
	-- Timer 1 controls the time between source points
	trigger.timer[1].delay = (1 / 7200)
	trigger.timer[1].passthrough = true
	trigger.timer[1].stimulus = smua.trigger.ARMED_EVENT_ID
	trigger.timer[1].count = numDataPoints - 1

	-- Configure the SMU trigger model
	smua.trigger.source.listv(sourceValues)
	smua.trigger.source.limiti		= limitI
	smua.trigger.measure.action		= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_HOLD
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numDataPoints
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= 0
	smua.trigger.endpulse.stimulus	= 0
	smua.trigger.source.action		= smua.ENABLE
	-- Ready to begin the test

	smua.source.output					= smua.OUTPUT_ON
	-- Start the trigger model execution
	smua.trigger.initiate()
	-- Wait until the sweep has completed
	waitcomplete()
	smua.source.output					= smua.OUTPUT_OFF

	-- Print the data back to the Console in tabular format
	print("Time\tVoltage\tCurrent")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x])
	end
end
