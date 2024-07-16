--[[
	Title:			IV Curves Example Script
	Date:			12/6/2010
	Description:	This script will perform a IdVd Sweep Step Vg test to
	collect a series of characteristic IV Curves on a MOSFET or IGBT device
	and will return the data in an Excel compatible	format for graphing and
	analysis.
	
	TSP-Link Configuration:
	Node 1: 2651A
	Node 2: 26xxA
	Node 3: 2651A

	Master Node: Node 1

	Revision History:
	12/6/2010 - Version 1.0
	David Wyban
	Initial Revision
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
	IRFP240
		IV_Curves(4, 10, 13, 0, 10, 101, 300e-6, 30e-3, 50, 0.001)
		IV_Curves(4, 10, 13, 0, 20, 101, 300e-6, 30e-3, 50, 0.001)
	IGBT
		IV_Curves(6, 12, 7, 0, 10, 101, 300e-6, 30e-3, 50, 0.005)
		IV_Curves(6, 12, 7, 0, 10, 101, 1e-3, 100e-3, 50, 0.01)
--]]
function IV_Curves(gstart, gstop, gsteps, dstart, dstop, dsteps, pulseWidth, pulsePeriod, pulseLimit, nplc)
	if (nplc == nil) then nplc = 0.001 end
	reset()
	tsplink.reset()

	-- Configure the Drain SMU(2651A)
	---------------------------------
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCVOLTS
	smua.sense						= smua.SENSE_REMOTE

	smua.source.rangev				= math.max(math.abs(dstart), math.abs(dstop))
	-- Select the source range that is large enough to fit all values of the sweep
	smua.source.levelv				= 0 -- Sets the drain bias level
	smua.source.limiti				= 5

	smua.measure.rangev				= smua.source.rangev
	smua.measure.rangei				= (pulseLimit == "off") and 50 or pulseLimit
	-- Select a measure range large enough to fit pulses up to the current limit

	smua.measure.nplc				= nplc
	smua.measure.delay				= (pulseWidth - ((1/localnode.linefreq) * smua.measure.nplc)) - 60e-6
	-- Set the measure delay so that the measurement is
	-- taken at the end of the pulse before the falling edge
	smua.measure.autozero			= smua.AUTOZERO_ONCE

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= (dsteps <= 1) and 1 or (dsteps - 1)
	-- If dsteps <= 1 then use 1 for the count else use dsteps - 1
	trigger.timer[1].delay			= pulsePeriod
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= tsplink.trigger[1].EVENT_ID
	trigger.timer[1].clear()

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= pulseWidth -- 2e-6
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= smua.trigger.SOURCE_COMPLETE_EVENT_ID--trigger.timer[1].EVENT_ID
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
	-- TSP-Link Trigger 1 is used by the 2651A to tell the 26xxA to step
	-- the gate and for the 26xxA to tell the 2651A when it has completed
	-- the step.

	tsplink.trigger[2].clear()
	tsplink.trigger[2].mode			= tsplink.TRIG_FALLING
	tsplink.trigger[2].stimulus		= smua.trigger.SWEEP_COMPLETE_EVENT_ID
	-- TSP-Link Trigger 2 is used by the 2651A to tell the 26xxA that it
	-- has completed the drain sweep and it is OK for the 26xxA to continue.

	-- Debug code
	------------------------
	trigger.blender[1].orenable = true
	trigger.blender[1].stimulus[1] = trigger.timer[1].EVENT_ID
	trigger.blender[1].stimulus[2] = smua.trigger.SOURCE_COMPLETE_EVENT_ID 
	trigger.blender[1].stimulus[3] = smua.trigger.MEASURE_COMPLETE_EVENT_ID 
	trigger.blender[1].stimulus[4] = trigger.timer[2].EVENT_ID
	--trigger.blender[1].stimulus[4] = smua.trigger.PULSE_COMPLETE_EVENT_ID
	trigger.blender[1].clear()

	digio.trigger[1].mode = digio.TRIG_FALLING
	digio.trigger[1].pulsewidth = 3e-6
	digio.trigger[1].stimulus = trigger.blender[1].EVENT_ID
	digio.trigger[1].clear()
	-------------------------
	-- End Debug Code

	-- Prepare the Drain SMU (2651A) reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collectsourcevalues	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collectsourcevalues	= 1


	-- Configure the Gate SMU(26xxA)
	--------------------------------
	node[2].smua.reset()
	node[2].smua.source.func				= node[2].smua.OUTPUT_DCVOLTS
	node[2].smua.sense						= node[2].smua.SENSE_REMOTE
	node[2].smua.source.levelv				= 0
	node[2].smua.source.limiti				= 100e-3
	node[2].smua.measure.delay				= 300e-6	-- Give gate 300us to settle
	-- Do not need to configure any additional measure settings.
	-- Timing is not critical on the gate so autorange will do.
	node[2].smua.source.highc = 1

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

	-- Configure 26xxA TSP-Link Triggers
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
	node[2].smua.source.output		= 1		smua.source.output				= 1
	
	node[2].smua.trigger.initiate()	-- Start the 26xxA's trigger model
	smua.trigger.initiate()			-- Start the 2651A's trigger model

	waitcomplete()	-- Wait until the sweeps are complete	
	
	-- Outputs off
	smua.source.output				= 0	
	node[2].smua.source.output		= 0

	-- Return the data
	PrintIVcurveData(gsteps, dsteps)
end


--[[
	IV_CurvesDual(gstart, gstop, gsteps, dstart, dstop, dsteps, pulseWidth, pulsePeriod, pulseLimit)
	
	Description:	This function will perform a series of pulsed sweeps
	on a MOSFET or IGBT device to generate a series of IV Curves that
	characterize the device.  It will use two 2651A SMUs in parallel to
	reach currents of up to 100A. Note: To avoid device oscillations, a
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
		IV_CurvesDual(6, 8.5, 6, 0, 5, 42, 300e-6, 30e-3, 100)
--]]
function IV_CurvesDual(gstart, gstop, gsteps, dstart, dstop, dsteps, pulseWidth, pulsePeriod, pulseLimit)
	local _nplc = 0.001
	reset()
	tsplink.reset()

	-- Configure the Drain V-SMU(2651A)
	---------------------------------
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCVOLTS
	smua.sense						= smua.SENSE_REMOTE

	smua.source.rangev				= math.max(math.abs(dstart), math.abs(dstop))
	-- Select the source range that is large enough to fit all values of the sweep
	smua.source.levelv				= 0 -- Sets the drain bias level
	smua.source.limiti				= 5

	smua.measure.rangev				= smua.source.rangev
	smua.measure.rangei				= pulseLimit/2 --(pulseLimit == "off") and 50 or pulseLimit
	-- Select a measure range large enough to fit pulses up to the current limit

	smua.measure.nplc				= _nplc
	smua.measure.delay				= (pulseWidth - ((1/localnode.linefreq) * smua.measure.nplc)) - 60e-6
	-- Set the measure delay so that the measurement is
	-- taken at the end of the pulse before the falling edge
	smua.measure.autozero			= smua.AUTOZERO_ONCE

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= (dsteps <= 1) and 1 or (dsteps - 1)
	-- If dsteps <= 1 then use 1 for the count else use dsteps - 1
	trigger.timer[1].delay			= pulsePeriod
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= tsplink.trigger[1].EVENT_ID
	trigger.timer[1].clear()

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= pulseWidth - 4e-6
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= smua.trigger.SOURCE_COMPLETE_EVENT_ID--trigger.timer[1].EVENT_ID
	trigger.timer[2].clear()

	-- Configure Drain V-SMU(2651A #1) trigger model
	smua.trigger.source.linearv(dstart, dstop, dsteps)
	smua.trigger.source.limiti		= pulseLimit/2
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
	-- TSP-Link Trigger 1 is used by the 2651A to tell the 26xxA to step
	-- the gate and for the 26xxA to tell the 2651A when it has completed
	-- the step.

	tsplink.trigger[2].clear()
	tsplink.trigger[2].mode			= tsplink.TRIG_FALLING
	tsplink.trigger[2].stimulus		= smua.trigger.SWEEP_COMPLETE_EVENT_ID
	-- TSP-Link Trigger 2 is used by the 2651A to tell the 26xxA that it
	-- has completed the drain sweep and it is OK for the 26xxA to continue.

	tsplink.trigger[3].clear()
	tsplink.trigger[3].mode			= tsplink.TRIG_FALLING
	tsplink.trigger[3].stimulus		= trigger.timer[1].EVENT_ID
	-- TSP-Link Trigger 3 is used by 2651A #1 to tell 2651A #2 to output the pulse


	-- Debug code
	------------------------
	trigger.blender[1].orenable = true
	trigger.blender[1].stimulus[1] = trigger.timer[1].EVENT_ID
	trigger.blender[1].stimulus[2] = smua.trigger.SOURCE_COMPLETE_EVENT_ID 
	trigger.blender[1].stimulus[3] = smua.trigger.MEASURE_COMPLETE_EVENT_ID 
	trigger.blender[1].stimulus[4] = trigger.timer[2].EVENT_ID
	--trigger.blender[1].stimulus[4] = smua.trigger.PULSE_COMPLETE_EVENT_ID
	trigger.blender[1].clear()

	digio.trigger[1].mode = digio.TRIG_FALLING
	digio.trigger[1].pulsewidth = 3e-6
	digio.trigger[1].stimulus = trigger.blender[1].EVENT_ID
	digio.trigger[1].clear()
	-------------------------
	-- End Debug Code


	-- Prepare the Drain V-SMU (2651A) reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collectsourcevalues	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collectsourcevalues	= 1


	
--===================================================================================
-- Configure the Drain I-SMU(2651A #2)
	---------------------------------
	node[3].smua.reset()
	node[3].smua.source.func				= node[3].smua.OUTPUT_DCAMPS
	node[3].smua.sense						= node[3].smua.SENSE_REMOTE

	node[3].smua.source.rangei				= pulseLimit/2--math.max(math.abs(dstart), math.abs(dstop))
	-- Select the source range that is large enough to fit all values of the sweep
	node[3].smua.source.leveli				= 0 -- Sets the drain bias level
	node[3].smua.source.limitv				= 10

	node[3].smua.measure.rangei				= node[3].smua.source.rangei
	node[3].smua.measure.rangev				= 10
	-- Select a measure range large enough to fit pulses up to the current limit

	node[3].smua.measure.nplc				= _nplc
	node[3].smua.measure.delay				= (pulseWidth - ((1/node[3].linefreq) * node[3].smua.measure.nplc)) - 60e-6
	-- Set the measure delay so that the measurement is
	-- taken at the end of the pulse before the falling edge
	node[3].smua.measure.autozero			= node[3].smua.AUTOZERO_ONCE

	-- Timer 2 controls the pulse width
	node[3].trigger.timer[2].count			= 1
	node[3].trigger.timer[2].delay			= pulseWidth - 4e-6
	node[3].trigger.timer[2].passthrough	= false
	node[3].trigger.timer[2].stimulus		= node[3].smua.trigger.SOURCE_COMPLETE_EVENT_ID
	node[3].trigger.timer[2].clear()

	-- Configure Drain I-SMU(2651A #2) trigger model
	node[3].smua.trigger.source.lineari(pulseLimit/2, pulseLimit/2, dsteps)
	node[3].smua.trigger.source.limitv		= 10
	node[3].smua.trigger.measure.action		= node[3].smua.ENABLE
	node[3].smua.trigger.measure.iv(node[3].smua.nvbuffer1, node[3].smua.nvbuffer2)
	node[3].smua.trigger.endpulse.action	= node[3].smua.SOURCE_IDLE
	node[3].smua.trigger.endsweep.action	= node[3].smua.SOURCE_IDLE
	node[3].smua.trigger.arm.count			= gsteps
	node[3].smua.trigger.count				= dsteps
	node[3].smua.trigger.arm.stimulus		= 0
	node[3].smua.trigger.source.stimulus	= node[3].tsplink.trigger[3].EVENT_ID
	node[3].smua.trigger.measure.stimulus	= 0
	node[3].smua.trigger.endpulse.stimulus	= node[3].trigger.timer[2].EVENT_ID
	node[3].smua.trigger.source.action		= node[3].smua.ENABLE

	-- Configure TSP-Link Triggers
	node[3].tsplink.trigger[3].clear()
	node[3].tsplink.trigger[3].mode			= node[3].tsplink.TRIG_FALLING
--	node[3].tsplink.trigger[3].stimulus		= node[3].smua.trigger.ARMED_EVENT_ID
	-- TSP-Link Trigger 3 is used by 2651A #2 to receive triggers from 2651A #1
	-- to tell it when to start the pulse

	-- Prepare the Drain I-SMU (2651A #2) reading buffers
	node[3].smua.nvbuffer1.clear()
	node[3].smua.nvbuffer1.collectsourcevalues	= 1
	node[3].smua.nvbuffer2.clear()
	node[3].smua.nvbuffer2.collectsourcevalues	= 1
--===================================================================================


	-- Configure the Gate SMU(26xxA)
	--------------------------------
	node[2].smua.reset()
	node[2].smua.source.func				= node[2].smua.OUTPUT_DCVOLTS
	node[2].smua.sense						= node[2].smua.SENSE_REMOTE
	node[2].smua.source.levelv				= 0
	node[2].smua.source.limiti				= 100e-3
	node[2].smua.measure.delay				= 300e-6	-- Give gate 300us to settle
	-- Do not need to configure any additional measure settings.
	-- Timing is not critical on the gate so autorange will do.
	node[2].smua.source.highc = 1

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

	-- Configure 26xxA TSP-Link Triggers
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
	node[3].smua.source.output		= 1
	smua.source.output				= 1
	
	node[2].smua.trigger.initiate()	-- Start the 26xxA's trigger model
	node[3].smua.trigger.initiate()	-- Start the 2651A #2s trigger model
	smua.trigger.initiate()			-- Start the 2651A #1s trigger model

	waitcomplete()	-- Wait until the sweeps are complete	
	
	-- Outputs off
	smua.source.output				= 0	
	node[3].smua.source.output		= 0
	node[2].smua.source.output		= 0

	-- Return the data
	PrintIVcurveDataDual(gsteps, dsteps)
end


--[[
	PrintIVcurveData(gsteps, dsteps)
	
	Description:	This function will output the data collected by the
	IV_Curves() function in an Excel compatible format.  For each step of
	the gate, this function will output three columns containing the
	drain sweep data as well as the gate data in the first row.
	
	Parameters:
		gsteps:	The number of steps in the gate sweep
		dsteps:	The number of steps in the drain sweep

	Example Usage:
		PrintIVcurveData(5, 21)
--]]
function PrintIVcurveData(gsteps, dsteps)
	line1 = ""
	line2 = ""
	for i=1,gsteps do
		line1 = line1 .. string.format("Vgs = %0.2f\t%g\t%g\t", node[2].smua.nvbuffer1.sourcevalues[i], node[2].smua.nvbuffer2[i], node[2].smua.nvbuffer1[i])
		line2 = line2 .. "Source Value\tVoltage\tCurrent\t"
	end
	print(line1)
	print(line2)
	for i=1, dsteps do
		line = ""
		for j=1, gsteps do
			line = line .. string.format("%g\t%g\t%g\t", smua.nvbuffer1.sourcevalues[(j-1)*dsteps + i], smua.nvbuffer2[(j-1)*dsteps + i], smua.nvbuffer1[(j-1)*dsteps + i])
		end
		print(line)
	end
end

function PrintIVcurveDataDual(gsteps, dsteps)
	line1 = ""
	line2 = ""
	for i=1,gsteps do
		line1 = line1 .. string.format("Vgs = %0.2f\t%g\t%g\t", node[2].smua.nvbuffer1.sourcevalues[i], node[2].smua.nvbuffer2[i], node[2].smua.nvbuffer1[i])
		line2 = line2 .. "Source Value\tVoltage\tCurrent\t"
	end
	print(line1)
	print(line2)
	for i=1, dsteps do
		line = ""
		for j=1, gsteps do
			line = line .. string.format("%g\t%g\t%g\t", smua.nvbuffer1.sourcevalues[(j-1)*dsteps + i], (smua.nvbuffer2[(j-1)*dsteps + i] + node[3].smua.nvbuffer2[(j-1)*dsteps + i])/2, (smua.nvbuffer1[(j-1)*dsteps + i] + node[3].smua.nvbuffer1[(j-1)*dsteps + i]))
		end
		print(line)
	end
end

function Print2(gsteps, dsteps)
	line1 = ""
	line2 = ""
	for i=1,gsteps do
		line1 = line1 .. string.format("Vgs = %0.2f\t%g\t", node[2].smua.nvbuffer1.sourcevalues[i], node[2].smua.nvbuffer1[i])
		line2 = line2 .. "Voltage\tCurrent\t"
	end
	print(line1)
	print(line2)
	for i=1, dsteps do
		line = ""
		for j=1, gsteps do
			line = line .. string.format("%g\t%g\t", smua.nvbuffer2[(j-1)*dsteps + i], smua.nvbuffer1[(j-1)*dsteps + i])
		end
		print(line)
	end
end

function Print2Dual(gsteps, dsteps)
	line1 = ""
	line2 = ""
	for i=1,gsteps do
		line1 = line1 .. string.format("Vgs = %0.2f\t%g\t", node[2].smua.nvbuffer1.sourcevalues[i], node[2].smua.nvbuffer1[i])
		line2 = line2 .. "Voltage\tCurrent\t"
	end
	print(line1)
	print(line2)
	for i=1, dsteps do
		line = ""
		for j=1, gsteps do
			line = line .. string.format("%g\t%g\t", (smua.nvbuffer2[(j-1)*dsteps + i] + node[3].smua.nvbuffer2[(j-1)*dsteps + i])/2, (smua.nvbuffer1[(j-1)*dsteps + i] + node[3].smua.nvbuffer1[(j-1)*dsteps + i]))
		end
		print(line)
	end
end

function DumpBuffers(gsteps, dsteps)
		line1 = ""
	line2 = ""
	for i=1,gsteps do
		line1 = line1 .. string.format("Vgs = %0.2f\t%g\t\t\t\t\t", node[2].smua.nvbuffer1.sourcevalues[i], node[2].smua.nvbuffer1[i])
		line2 = line2 .. "V1\tI1\tV2\tI2\tVdual\tIdual\t"
	end
	print(line1)
	print(line2)
	for i=1, dsteps do
		line = ""
		for j=1, gsteps do
			line = line .. string.format("%g\t%g\t%g\t%g\t%g\t%g\t", smua.nvbuffer2[(j-1)*dsteps + i], smua.nvbuffer1[(j-1)*dsteps + i], node[3].smua.nvbuffer2[(j-1)*dsteps + i], node[3].smua.nvbuffer1[(j-1)*dsteps + i], (smua.nvbuffer2[(j-1)*dsteps + i] + node[3].smua.nvbuffer2[(j-1)*dsteps + i])/2, (smua.nvbuffer1[(j-1)*dsteps + i] + node[3].smua.nvbuffer1[(j-1)*dsteps + i]))
		end
		print(line)
	end
end
