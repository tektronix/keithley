--[[
	Title:			Parallel IV Open Lab Script
	Date:			5/13/2011
	
	Description:	This script uses two 2651As
	wired together in parallel to source voltage with currents up to 95A.

	If you are not familiar with high current, consult Keithley Applications 
	Engineering before attempting this test. It could damage you or your equipment.

	!!! Warning !!!!
	This script is an incredibly simplified version of a complete Parallel IV
	script.  It is not gaurenteed to work with all input values passed to it
	not does it incorporate any major parameter or error checking therefore
	SMU/DUT safety cannot be ensured with this script.  Because of these
	things it is therefore not recommended that this script be given to
	customers without appropriate modification/customer attention from a
	Keithley Applications Engineer.

	TSP-Link Configuration:
	Node 1: 2651A
	Node 2: 2651A
	Node 3: 26XXA

	Master Node: Node 1

	Revision History:
	5/13/2011 - Version 1.0
	David Wyban
	Initial Revision
]]


--[[
	DualSMUIVcurves(gstart, gstop, gsteps, dstart, dstop, dsteps, pulseWidth, pulsePeriod)
	
	Description:	This function will perform a series of pulsed sweeps
	on a MOSFET or IGBT device to generate a series of IV Curves that
	characterize the device.  It will use two 2651A SMUs in parallel to
	reach currents of up to 95A.  Note: This function uses only the
	100A(50A x 2) range for source and measure.
	Note: To avoid device oscillations, a series resistor on the gate
	terminal of the device may be required.
	
	Parameters:
		gstart:		The starting voltage of the gate sweep
		gstop:		The ending voltage of the gate sweep
		gsteps:		The number of steps in the gate sweep
		dstart:		The starting voltage of the drain sweep
		dstop:		The ending voltage of the drain sweep
		dsteps:		The number of steps in the drain sweep
		pulseWidth:	The width of the drain pulse in seconds
		pulsePeriod:The time in seconds between the start of consecutive drain pulses in the sweep

	Example Usage:
		DualSMUIVcurves(6, 8.5, 6, 0, 5, 51, 300e-6, 30e-3)
--]]
function DualSMUIVcurves(gstart, gstop, gsteps, dstart, dstop, dsteps, pulseWidth, pulsePeriod)
	local _nplc = 0.005
	reset()
	tsplink.reset()

	-- Configure the Drain V-SMU(2651A)
	---------------------------------
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCVOLTS

	-- Configure the proper output off configuration
	smua.source.offmode				= smua.OUTPUT_NORMAL
	smua.source.offfunc				= smua.OUTPUT_DCVOLTS
	smua.source.offlimiti			= 1e-3
	smua.sense						= smua.SENSE_REMOTE

	smua.source.rangev				= math.max(math.abs(dstart), math.abs(dstop))
	-- Select the source range that is large enough to fit all values of the sweep
	smua.source.levelv				= 0 -- Sets the drain bias level
	smua.source.limiti				= 5

	smua.measure.rangev				= smua.source.rangev
	smua.measure.rangei				= 50
	-- Select a measure range large enough to fit pulses up to the current limit

	smua.measure.nplc				= _nplc
	smua.measure.delay				= (pulseWidth - ((1/localnode.linefreq) * smua.measure.nplc)) - 20e-6
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
	trigger.timer[2].stimulus		= smua.trigger.SOURCE_COMPLETE_EVENT_ID
	trigger.timer[2].clear()

	-- Configure Drain V-SMU(2651A #1) trigger model
	smua.trigger.source.linearv(dstart, dstop, dsteps)
	smua.trigger.source.limiti		= 50
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
	--*************************
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
	--**************************
	-- End Debug Code


	-- Prepare the Drain V-SMU (2651A) reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collectsourcevalues	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collectsourcevalues	= 1
--===================================================================================


-- Configure the Drain I-SMU(2651A #2)
	---------------------------------
	node[2].smua.reset()
	node[2].smua.source.func				= node[2].smua.OUTPUT_DCAMPS

	-- Configure the proper output off configuration
	node[2].smua.source.offmode				= node[2].smua.OUTPUT_NORMAL
	node[2].smua.source.offfunc				= node[2].smua.OUTPUT_DCAMPS
	node[2].smua.source.offlimitv			= 40
	node[2].smua.sense						= node[2].smua.SENSE_REMOTE

	node[2].smua.source.rangei				= 50
	-- Select the source range that is large enough to fit all values of the sweep
	node[2].smua.source.leveli				= 0 -- Sets the drain bias level
	node[2].smua.source.limitv				= 10

	node[2].smua.measure.rangei				= node[2].smua.source.rangei
	node[2].smua.measure.rangev				= 10
	-- Select a measure range large enough to fit pulses up to the current limit

	node[2].smua.measure.nplc				= _nplc
	node[2].smua.measure.delay				= (pulseWidth - ((1/node[2].linefreq) * node[2].smua.measure.nplc)) - 20e-6
	-- Set the measure delay so that the measurement is
	-- taken at the end of the pulse before the falling edge
	node[2].smua.measure.autozero			= node[2].smua.AUTOZERO_ONCE

	-- Timer 2 controls the pulse width
	node[2].trigger.timer[2].count			= 1
	node[2].trigger.timer[2].delay			= pulseWidth - 4e-6
	node[2].trigger.timer[2].passthrough	= false
	node[2].trigger.timer[2].stimulus		= node[2].smua.trigger.SOURCE_COMPLETE_EVENT_ID
	node[2].trigger.timer[2].clear()

	-- Configure Drain I-SMU(2651A #2) trigger model
	node[2].smua.trigger.source.lineari(45, 45, dsteps)
	node[2].smua.trigger.source.limitv		= 10
	node[2].smua.trigger.measure.action		= node[2].smua.ENABLE
	node[2].smua.trigger.measure.iv(node[2].smua.nvbuffer1, node[2].smua.nvbuffer2)
	node[2].smua.trigger.endpulse.action	= node[2].smua.SOURCE_IDLE
	node[2].smua.trigger.endsweep.action	= node[2].smua.SOURCE_IDLE
	node[2].smua.trigger.arm.count			= gsteps
	node[2].smua.trigger.count				= dsteps
	node[2].smua.trigger.arm.stimulus		= 0
	node[2].smua.trigger.source.stimulus	= node[2].tsplink.trigger[3].EVENT_ID
	node[2].smua.trigger.measure.stimulus	= 0
	node[2].smua.trigger.endpulse.stimulus	= node[2].trigger.timer[2].EVENT_ID
	node[2].smua.trigger.source.action		= node[2].smua.ENABLE

	-- Configure TSP-Link Triggers
	node[2].tsplink.trigger[3].clear()
	node[2].tsplink.trigger[3].mode			= node[2].tsplink.TRIG_FALLING
--	node[3].tsplink.trigger[3].stimulus		= node[3].smua.trigger.ARMED_EVENT_ID
	-- TSP-Link Trigger 3 is used by 2651A #2 to receive triggers from 2651A #1
	-- to tell it when to start the pulse

	-- Prepare the Drain I-SMU (2651A #2) reading buffers
	node[2].smua.nvbuffer1.clear()
	node[2].smua.nvbuffer1.collectsourcevalues	= 1
	node[2].smua.nvbuffer2.clear()
	node[2].smua.nvbuffer2.collectsourcevalues	= 1
--===================================================================================


	-- Configure the Gate SMU(26xxA)
	--------------------------------
	node[3].smua.reset()
	node[3].smua.source.func				= node[3].smua.OUTPUT_DCVOLTS
	node[3].smua.sense						= node[3].smua.SENSE_REMOTE
	node[3].smua.source.levelv				= 0
	node[3].smua.source.limiti				= 100e-3
	node[3].smua.measure.delay				= 300e-6	-- Give gate 300us to settle
	-- Do not need to configure any additional measure settings.
	-- Timing is not critical on the gate so autorange will do.
	node[3].smua.source.highc = 0

	-- Configure Gate SMU(26xxA) Trigger Model
	node[3].smua.trigger.source.linearv(gstart, gstop, gsteps)
	node[3].smua.trigger.source.limiti		= 100e-3
	node[3].smua.trigger.measure.action		= node[3].smua.ENABLE
	node[3].smua.trigger.measure.iv(node[3].smua.nvbuffer1, node[3].smua.nvbuffer2)
	node[3].smua.trigger.endpulse.action	= smua.SOURCE_HOLD
	node[3].smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	node[3].smua.trigger.count				= gsteps
	node[3].smua.trigger.arm.stimulus		= 0
	node[3].smua.trigger.source.stimulus	= node[3].tsplink.trigger[1].EVENT_ID
	node[3].smua.trigger.measure.stimulus	= 0
	node[3].smua.trigger.endpulse.stimulus	= node[3].tsplink.trigger[2].EVENT_ID
	node[3].smua.trigger.source.action		= smua.ENABLE

	-- Configure 26xxA TSP-Link Triggers
	node[3].tsplink.trigger[1].clear()
	node[3].tsplink.trigger[1].mode			= node[3].tsplink.TRIG_SYNCHRONOUSA
	node[3].tsplink.trigger[1].stimulus		= node[3].smua.trigger.MEASURE_COMPLETE_EVENT_ID

	node[3].tsplink.trigger[2].clear()
	node[3].tsplink.trigger[2].mode			= node[3].tsplink.TRIG_FALLING

	-- Prepare the Gate SMU (26xxA) reading buffers
	node[3].smua.nvbuffer1.clear()
	node[3].smua.nvbuffer1.collectsourcevalues	= 1
	node[3].smua.nvbuffer2.clear()
	node[3].smua.nvbuffer2.collectsourcevalues	= 1

	-- The SMUs are configured and ready to run the test

	-- Outputs on
	node[3].smua.source.output		= 1
	node[2].smua.source.output		= 1
	smua.source.output				= 1
	
	node[3].smua.trigger.initiate()	-- Start the 26xxA's trigger model
	node[2].smua.trigger.initiate()	-- Start the 2651A #2s trigger model
	smua.trigger.initiate()			-- Start the 2651A #1s trigger model

	waitcomplete()	-- Wait until the sweeps are complete	
	
	-- Outputs off
	smua.source.output				= 0	
	node[2].smua.source.output		= 0
	node[3].smua.source.output		= 0

	-- Return the data
	PrintIVcurveDataDual(gsteps, dsteps)
end

--[[
	DualSMUPulseV(pulseLevel, pulseWidth)
	
	Description:	This function will output a single voltage pulse and
	capture the pulse with the Fast ADC then return the readings in a
	format that is cut-and-paste compatible with Microsoft Excel.  This
	function uses two 2651A SMUs in parallel to reach currents of up to 95A.
	Note: This function uses only the 100A(50A x 2) range for source and
	measure.

	Parameters:
		pulseLevel:	The voltage to pulse
		pulseWidth:	The width of the drain pulse in seconds

	Example Usage:
		DualSMUPulseV(6, 300e-6)
--]]
function DualSMUPulseV(pulseLevel, pulseWidth)
	reset()
	tsplink.reset()

	-- Configure the V-SMU(2651A #1)
	--------------------------------
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCVOLTS

	-- Configure the proper output off configuration
	smua.source.offmode				= smua.OUTPUT_NORMAL
	smua.source.offfunc				= smua.OUTPUT_DCVOLTS
	smua.source.offlimiti			= 1e-3
	smua.sense						= smua.SENSE_REMOTE
--	smua.sense						= smua.SENSE_LOCAL

	smua.source.rangev				= pulseLevel
	smua.source.levelv				= 0 -- Sets the bias level
	smua.source.limiti				= 5

	smua.measure.rangev				= smua.source.rangev
	smua.measure.rangei				= 50

	smua.measure.adc				= smua.ADC_FAST
	smua.measure.delay				= 0
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.interval			= 1e-6
	smua.measure.count				= pulseWidth * 1e6 + 200

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= 1
	trigger.timer[1].delay			= 100e-3
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= tsplink.trigger[1].EVENT_ID
	trigger.timer[1].clear()

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= pulseWidth - 4e-6
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= smua.trigger.SOURCE_COMPLETE_EVENT_ID
	trigger.timer[2].clear()

	-- Configure V-SMU(2651A #1) trigger model
	smua.trigger.source.linearv(pulseLevel, pulseLevel, 2)
	smua.trigger.source.limiti		= 50
	smua.trigger.measure.action		= smua.ASYNC
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.arm.count			= 1
	smua.trigger.count				= 1
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE

	-- Configure TSP-Link Triggers
	tsplink.trigger[1].clear()
	tsplink.trigger[1].mode			= tsplink.TRIG_FALLING
	tsplink.trigger[1].stimulus		= smua.trigger.ARMED_EVENT_ID
	-- TSP-Link Trigger 1 is used by the 2651A #1 to tell the 2651A #2
	-- to start the pulse.

	-- Prepare the V-SMU (2651A) reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collectsourcevalues	= 0
	smua.nvbuffer1.collecttimestamps	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collectsourcevalues	= 0
	smua.nvbuffer2.collecttimestamps	= 1
--===================================================================================


-- Configure the I-SMU(2651A #2)
	----------------------------
	node[2].smua.reset()
	node[2].smua.source.func				= node[2].smua.OUTPUT_DCAMPS

	-- Configure the proper output off configuration
	node[2].smua.source.offmode				= node[2].smua.OUTPUT_NORMAL
	node[2].smua.source.offfunc				= node[2].smua.OUTPUT_DCAMPS
	node[2].smua.source.offlimitv			= 40
	node[2].smua.sense						= node[2].smua.SENSE_REMOTE
--	node[2].smua.sense						= node[2].smua.SENSE_LOCAL

	node[2].smua.source.rangei				= 50
	node[2].smua.source.leveli				= 0 -- Sets the bias level
	node[2].smua.source.limitv				= 10

	node[2].smua.measure.rangei				= node[2].smua.source.rangei
	node[2].smua.measure.rangev				= 10

	node[2].smua.measure.adc				= node[2].smua.ADC_FAST
	node[2].smua.measure.delay				= 0
	node[2].smua.measure.autozero			= node[2].smua.AUTOZERO_ONCE
	node[2].smua.measure.interval			= 1e-6
	node[2].smua.measure.count				= pulseWidth * 1e6 + 200
	
	-- Timer 2 controls the pulse width
	node[2].trigger.timer[2].count			= 1
	node[2].trigger.timer[2].delay			= pulseWidth - 4e-6
	node[2].trigger.timer[2].passthrough	= false
	node[2].trigger.timer[2].stimulus		= node[2].smua.trigger.SOURCE_COMPLETE_EVENT_ID
	node[2].trigger.timer[2].clear()

	-- Configure I-SMU(2651A #2) trigger model
	node[2].smua.trigger.source.lineari(45, 45, 2)
	node[2].smua.trigger.source.limitv		= 10
	node[2].smua.trigger.measure.action		= node[2].smua.ASYNC
	node[2].smua.trigger.measure.iv(node[2].smua.nvbuffer1, node[2].smua.nvbuffer2)
	node[2].smua.trigger.endpulse.action	= node[2].smua.SOURCE_IDLE
	node[2].smua.trigger.endsweep.action	= node[2].smua.SOURCE_IDLE
	node[2].smua.trigger.arm.count			= 1
	node[2].smua.trigger.count				= 1
	node[2].smua.trigger.arm.stimulus		= 0
	node[2].smua.trigger.source.stimulus	= node[2].tsplink.trigger[1].EVENT_ID
	node[2].smua.trigger.measure.stimulus	= node[2].tsplink.trigger[1].EVENT_ID
	node[2].smua.trigger.endpulse.stimulus	= node[2].trigger.timer[2].EVENT_ID
	node[2].smua.trigger.source.action		= node[2].smua.ENABLE

	-- Configure TSP-Link Triggers
	node[2].tsplink.trigger[1].clear()
	node[2].tsplink.trigger[1].mode			= node[2].tsplink.TRIG_FALLING
	-- TSP-Link Trigger 1 is used by 2651A #2 to receive triggers from 2651A #1
	-- to tell it when to start the pulse

	-- Prepare the I-SMU (2651A #2) reading buffers
	node[2].smua.nvbuffer1.clear()
	node[2].smua.nvbuffer1.collectsourcevalues	= 0
	node[2].smua.nvbuffer1.collecttimestamps	= 1
	node[2].smua.nvbuffer2.clear()
	node[2].smua.nvbuffer2.collectsourcevalues	= 0
	node[2].smua.nvbuffer2.collecttimestamps	= 1
--===================================================================================

	-- The SMUs are configured and ready to run the test

	-- Outputs on
	node[2].smua.source.output		= 1
	smua.source.output				= 1
	
	node[2].smua.trigger.initiate()	-- Start the 2651A #2s trigger model
	smua.trigger.initiate()			-- Start the 2651A #1s trigger model

	waitcomplete()	-- Wait until the sweeps are complete	
	
	-- Outputs off
	smua.source.output				= 0	
	node[2].smua.source.output		= 0

	-- Return the data
	PrintFastIVDataDual()
end

function PrintIVcurveDataDual(gsteps, dsteps)
	line1 = ""
	line2 = ""
	for i=1,gsteps do
		line1 = line1 .. string.format("Vgs = %0.2f\t%g\t%g\t", node[3].smua.nvbuffer1.sourcevalues[i], node[3].smua.nvbuffer2[i], node[3].smua.nvbuffer1[i])
		line2 = line2 .. "Source Value\tVoltage\tCurrent\t"
	end
	print(line1)
	print(line2)
	for i=1, dsteps do
		line = ""
		for j=1, gsteps do
			line = line .. string.format("%g\t%g\t%g\t", smua.nvbuffer1.sourcevalues[(j-1)*dsteps + i], (smua.nvbuffer2[(j-1)*dsteps + i] + node[2].smua.nvbuffer2[(j-1)*dsteps + i])/2, (smua.nvbuffer1[(j-1)*dsteps + i] + node[2].smua.nvbuffer1[(j-1)*dsteps + i]))
		end
		print(line)
	end
end

function PrintFastIVDataDual()
	print("\r\nTimestamps\tCombined Voltage\tCombined Current\tVoltage SMU1\tCurrent SMU1\tVoltage SMU2\tCurrent SMU2")
	local combinedV
	local combinedI
	for i=1,smua.nvbuffer1.n do
		combinedV = (smua.nvbuffer2[i] + node[2].smua.nvbuffer2[i])/2
		combinedI = smua.nvbuffer1[i] + node[2].smua.nvbuffer1[i]
		print(string.format("%g\t%g\t%g\t%g\t%g\t%g\t%g", smua.nvbuffer1.timestamps[i], combinedV, combinedI, smua.nvbuffer2[i], smua.nvbuffer1[i], node[2].smua.nvbuffer2[i], node[2].smua.nvbuffer1[i]))
	end
end

