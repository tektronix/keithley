--[[
	Title:			IV Curves Example Script

	Description:	This script will perform a series of IV Curves on a
	MOSFET or IGBT device and will return the data in a Microsoft Excel
	compatible format for graphing and analysis.
	
	TSP-Link Configuration:
	Node 1: 2651A
	Node 2: 26xxA

	Master Node: Node 1
]]

--[[
	IV_Curves(gstart, gstop, gsteps, dstart, dstop, dsteps, pulseWidth, pulsePeriod, pulseLimit)
	
	Description:	This function will perform a series of pulsed sweeps
	on a MOSFET or IGBT device to generate a series of IV Curves that
	characterize the device.  Note: To avoid device	oscillations, a
	series resistor on the gate terminal of the	device may be required.
	
	Parameters:
		gstart:		The starting voltage of the gate sweep
		gstop:		The ending voltage of the gate sweep
		gsteps:		The number of steps in the gate sweep
		dstart:		The starting voltage of the drain sweep
		dstop:		The ending voltage of the drain sweep
		dsteps:		The number of steps in the drain sweep
		pulseWidth:	The width of the drain pulse in seconds
		pulsePeriod:The time in seconds between the start of consecutive drain pulses in the sweep
		pulseLimit:	The current limit in Amps of the drain pulse

	Example Usage:
		IV_Curves(5, 9, 5, 0, 10, 21, 300e-6, 30e-3, 50)
--]]
function IV_Curves(gstart, gstop, gsteps, dstart, dstop, dsteps, pulseWidth, pulsePeriod, pulseLimit)
	reset()
	tsplink.reset()

	-- Configure the Drain SMU(2651A)
	---------------------------------
	smua.reset()
	smua.source.func		= smua.OUTPUT_DCVOLTS
	smua.sense				= smua.SENSE_REMOTE

	smua.source.rangev		= math.max(math.abs(dstart), math.abs(dstop))
	-- Select the source range that is large enough to fit all values of the sweep
	smua.source.levelv		= 0 -- Sets the drain bias level
	smua.source.limiti		= 5

	smua.measure.rangev		= smua.source.rangev
	smua.measure.rangei		= (pulseLimit == "off") and 50 or pulseLimit
	-- Select a measure range large enough to fit pulses up to the current limit

	smua.measure.autozero	= smua.AUTOZERO_ONCE
	smua.measure.nplc		= 0.001
	-- NPLC can be increased to improve measurement accuracy.
	-- However, it should remain small enough to fit the measurement
	-- within the width of the settled part of the pulse.
	smua.measure.delay		= (pulseWidth - ((1/localnode.linefreq) * smua.measure.nplc)) - 50e-6
	-- Set the measure delay so that the measurement is
	-- taken at the end of the pulse before the falling edge

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= (dsteps <= 1) and 1 or (dsteps - 1)
	-- If dsteps <= 1 then use 1 for the count else use dsteps - 1
	trigger.timer[1].delay			= pulsePeriod
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= tsplink.trigger[1].EVENT_ID
	trigger.timer[1].clear()

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= pulseWidth - 3e-6
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= smua.trigger.SOURCE_COMPLETE_EVENT_ID
	trigger.timer[2].clear()

	-- Configure Drain SMU(2651A) trigger model
	smua.trigger.source.linearv(dstart, dstop, dsteps)
	smua.trigger.source.limiti		= pulseLimit
	smua.trigger.measure.action		= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.arm.count			= gsteps
	smua.trigger.count				= dsteps
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= 0
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE

	-- Configure TSP-Link Triggers
	tsplink.trigger[1].clear()
	tsplink.trigger[1].mode			= tsplink.TRIG_SYNCHRONOUSM
	tsplink.trigger[1].stimulus		= smua.trigger.ARMED_EVENT_ID
	-- TSP-Link Trigger 1 is used by the 2651A to command the 26xxA
	-- to step the gate and for the 26xxA to report to the 2651A
	-- that it has completed the step.

	tsplink.trigger[2].clear()
	tsplink.trigger[2].mode			= tsplink.TRIG_FALLING
	tsplink.trigger[2].stimulus		= smua.trigger.SWEEP_COMPLETE_EVENT_ID
	-- TSP-Link Trigger 2 is used by the 2651A to command the 26xxA that
	-- it has completed the drain sweep and that the 26xxA continue.

	-- Prepare the Drain SMU (2651A) reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collectsourcevalues	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collectsourcevalues	= 1


	-- Configure the Gate SMU(26xxA)
	--------------------------------
	node[2].smua.reset()
	node[2].smua.source.func		= node[2].smua.OUTPUT_DCVOLTS
	node[2].smua.sense				= node[2].smua.SENSE_REMOTE
	node[2].smua.source.levelv		= 0
	node[2].smua.source.limiti		= 100e-3
	node[2].smua.measure.delay		= 300e-6	-- Give gate 300us to settle
	-- Do not need to configure any additional measure settings.
	-- Timing is not critical on the gate so autorange will do.

	node[2].smua.source.highc		= 0
	-- If you find the gate to be unstable even with a gate resistor in place
	-- changing highc to 1 can improve stability.

	-- Configure Gate SMU(26xxA) Trigger Model
	node[2].smua.trigger.source.linearv(gstart, gstop, gsteps)
	node[2].smua.trigger.source.limiti		= 100e-3
	node[2].smua.trigger.measure.action		= node[2].smua.ENABLE
	node[2].smua.trigger.measure.iv(node[2].smua.nvbuffer1, node[2].smua.nvbuffer2)
	node[2].smua.trigger.endpulse.action	= smua.SOURCE_HOLD
	node[2].smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	node[2].smua.trigger.count				= gsteps
	node[2].smua.trigger.arm.stimulus		= 0
	node[2].smua.trigger.source.stimulus	= node[2].tsplink.trigger[1].EVENT_ID
	node[2].smua.trigger.measure.stimulus	= 0
	node[2].smua.trigger.endpulse.stimulus	= node[2].tsplink.trigger[2].EVENT_ID
	node[2].smua.trigger.source.action		= smua.ENABLE

	-- Configure Model 26xxA TSP-Link Triggers
	node[2].tsplink.trigger[1].clear()
	node[2].tsplink.trigger[1].mode			= node[2].tsplink.TRIG_SYNCHRONOUSA
	node[2].tsplink.trigger[1].stimulus		= node[2].smua.trigger.MEASURE_COMPLETE_EVENT_ID

	node[2].tsplink.trigger[2].clear()
	node[2].tsplink.trigger[2].mode			= node[2].tsplink.TRIG_FALLING

	-- Prepare the Gate SMU (26xxA) reading buffers
	node[2].smua.nvbuffer1.clear()
	node[2].smua.nvbuffer1.collectsourcevalues	= 1
	node[2].smua.nvbuffer2.clear()
	node[2].smua.nvbuffer2.collectsourcevalues	= 1

	-- The SMUs are configured and ready to run the test

	-- Outputs on
	node[2].smua.source.output		= 1	
	smua.source.output				= 1
	
	-- Start the 26xxA's trigger model
	node[2].smua.trigger.initiate()

	-- Start the 2651A's trigger model
	smua.trigger.initiate()

	waitcomplete()	-- Wait until the sweeps are complete	
	
	-- Outputs off
	smua.source.output				= 0	
	node[2].smua.source.output		= 0

	-- Return the data
	PrintIVcurveData(gsteps, dsteps)
end


--[[
	PrintIVcurveData(gsteps, dsteps)
	
	Description:	This function will output the data collected by
	the IV_Curves() function in a Microsoft Excel compatible format.
	For each step of the gate, this function will output three
	columns containing the drain sweep data as well as the gate data
	in the first row.
	
	Parameters:
		gsteps:	The number of steps in the gate sweep
		dsteps:	The number of steps in the drain sweep

	Example Usage:
		PrintIVcurveData(5, 21)
--]]
function PrintIVcurveData(gsteps, dsteps)
	line1 = ""
	line2 = ""
	for i = 1,gsteps do
		line1 = line1 .. string.format("Vgs = %0.2f\t%g\t%g\t",
							node[2].smua.nvbuffer1.sourcevalues[i],
							node[2].smua.nvbuffer2[i],
							node[2].smua.nvbuffer1[i])
		line2 = line2 .. "Source Value\tVoltage\tCurrent\t"
	end
	print(line1)
	print(line2)
	for i = 1, dsteps do
		line = ""
		for j = 1, gsteps do
			line = line .. string.format("%g\t%g\t%g\t",
							smua.nvbuffer1.sourcevalues[(j - 1) * dsteps + i],
							smua.nvbuffer2[(j - 1) * dsteps + i],
							smua.nvbuffer1[(j - 1) * dsteps + i])
		end
		print(line)
	end
end
