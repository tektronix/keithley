--[[
	Title:		2651A Demo Script
	Author:		David Wyban
	Date:		6/29/2010
	
	Description: The purpose of this script is to get up and running with the 2651A
	as quickly as possible. It contains several functions to output pulses using
	either the integrating ADC or the new fast ADC.
]]

--[[
	Function:	PulseI(start, stop, numpulse, limit, ton, period, nplc, wiremode)
	Summary:	This function outputs current pulses and takes a single measurement
	per pulse using the integrating ADC.  Set start = stop to output pulses of a 
	single level.
	
	Parameters:
		start:		The current level for the first pulse in the sweep
		stop:		The current level for the last pulse in the sweep
		numpulse:	The number of consecutive pulses to output
		limit:		The voltage limit of the pulses
		ton:		The width of the pulse in seconds
		period:		The length of a single pulse cycle in seconds
		nplc:		The NPLC setting for the integrating ADC to use
		wiremode:	Lets you select between local and remote sense.  Use 2 for local and 4 for remote.
	Example Usage:
		PulseI(50, 50, 1, 10, 500e-6, 100e-3, 0.01, 4)
]]
function PulseI(start, stop, numpulse, limit, ton, period, nplc, wiremode)
	if (start == nil) then start = 1e-3 end
	if (stop == nil) then stop = 1e-3 end
	if (numpulse == nil) then numpulse = 1 end
	if (limit == nil) then limit = 1 end
	if (ton == nil) then ton = 1e-3 end
	if (period == nil) then period = 100e-3 end
	if (nplc == nil) then nplc = 0.001 end
	if (wiremode == 4) then wiremode = smua.SENSE_REMOTE
	else wiremode = smua.SENSE_LOCAL end

	reset()
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCAMPS
	smua.sense						= wiremode
	smua.source.autorangev			= 0
	smua.source.autorangei			= 0
	smua.source.rangei				= math.max(math.abs(start), math.abs(stop))
	smua.source.leveli				= 0
	smua.source.limitv				= 1

	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= 0
	smua.measure.autorangei			= 0
	smua.measure.rangev				= limit
	smua.measure.rangei				= math.max(math.abs(start), math.abs(stop))
	smua.measure.nplc				= nplc
	smua.measure.delay				= (ton - ((1/60) * smua.measure.nplc)) - 60e-6

	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode		= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode		= 1

	-- Configure the Pulsed Sweep setup
	--=============================

	-- Configure timers
	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numpulse
	trigger.timer[1].delay			= period
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= ton
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= trigger.timer[1].EVENT_ID

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.lineari(start, stop, (numpulse >= 2) and numpulse or 2)
	smua.trigger.source.limitv		=  limit
	smua.trigger.measure.action		= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numpulse
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= 0
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE

	smua.source.output				= 1
	smua.trigger.initiate()
	waitcomplete()
	smua.source.output				= 0

	PrintData2()
end



--[[
	Function:	PulseIFast(start, stop, numpulse, limit, ton, period, measCount, wiremode)
	Summary:	This function outputs current pulses and takes a measurements using the
	high speed adc.  The high speed ADC will be configured for a 1 MS/s sample rate.
	Set start = stop to output pulses of a single level.
	
	Parameters:
		start:		The current level for the first pulse in the sweep
		stop:		The current level for the last pulse in the sweep
		numpulse:	The number of consecutive pulses to output
		limit:		The voltage limit of the pulse
		ton:		The width of the pulse in seconds
		period:		The length of a single pulse cycle in seconds
		measCount:	Sets th number of samples to take per pulse
		wiremode:	Lets you select between local and remote sense.  Use 2 for local and 4 for remote.
	Example Usage:
		PulseIFast(0, 50, 6, 10, 500e-6, 100e-3, 600, 4)
		PulseIFast(50, 50, 1, 10, 300e-6, 100e-3, 400, 4)
		PulseIFast(50, 50, 1, 10, 200e-6, 100e-3, 300, 4)
]]

function PulseIFast(start, stop, numpulse, limit, ton, period, measCount, wiremode)
	if (start == nil) then start = 1e-3 end
	if (stop == nil) then stop = 1e-3 end
	if (numpulse == nil) then numpulse = 1 end
	if (limit == nil) then limit = 1 end
	if (ton == nil) then ton = 1e-3 end
	if (period == nil) then period = 100e-3 end
	if (measCount == nil) then measCount = ton*1e6 + 100 end
	if (wiremode == 4) then wiremode = smua.SENSE_REMOTE
	else wiremode = smua.SENSE_LOCAL end

	reset()
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCAMPS
	smua.sense						= wiremode
	smua.source.autorangev			= 0
	smua.source.autorangei			= 0
	smua.source.rangei				= math.max(math.abs(start), math.abs(stop))
	smua.source.leveli				= 0
	smua.source.limitv				= limit

	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= 0
	smua.measure.autorangei			= 0
	smua.measure.rangev				= limit
	smua.measure.rangei				= math.max(math.abs(start), math.abs(stop))
	smua.measure.nplc				= 0.001
	smua.measure.interval			= 0
	smua.measure.adc				= smua.ADC_FAST
	smua.measure.count				= measCount

	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode		= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode		= 1

	-- Configure the Pulsed Sweep setup
	--=============================

	-- Configure timers
	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numpulse
	trigger.timer[1].delay			= period
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= ton
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= trigger.timer[1].EVENT_ID

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.lineari(start, stop, (numpulse >= 2) and numpulse or 2)
	smua.trigger.source.limitv		=  limit
	smua.trigger.measure.action		= smua.ASYNC
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numpulse
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE

	smua.source.output				= 1
	smua.trigger.initiate()
	waitcomplete()
	smua.source.output				= 0

	PrintData2()
end



--[[
	Function:	PulseV(start, stop, numpulse, limit, ton, period, nplc, wiremode)
	Summary:	This function outputs voltage pulses and takes a single measurement
	per pulse using the integrating ADC.  Set start = stop to output pulses of a 
	single level.
	
	Parameters:
		start:		The voltage level for the first pulse in the sweep
		stop:		The voltage level for the last pulse in the sweep
		numpulse:	The number of consecutive pulses to output
		limit:		The current limit of the pulse
		ton:		The width of the pulse in seconds
		period:		The length of a single pulse cycle in seconds
		nplc:		The NPLC setting for the integrating ADC to use
		wiremode:	Lets you select between local and remote sense.  Use 2 for local and 4 for remote.
	Example Usage:
		PulseV(7, 7, 1, 50, 500e-6, 100e-3, 0.01, 4)
]]
function PulseV(start, stop, numpulse, limit, ton, period, nplc, wiremode)
	if (start == nil) then start = 1 end
	if (stop == nil) then stop = 1 end
	if (numpulse == nil) then numpulse = 1 end
	if (limit == nil) then limit = 1e-3 end
	if (ton == nil) then ton = 1e-3 end
	if (period == nil) then period = 100e-3 end
	if (nplc == nil) then nplc = 0.001 end
	if (wiremode == 4) then wiremode = smua.SENSE_REMOTE
	else wiremode = smua.SENSE_LOCAL end

	reset()
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCVOLTS
	smua.sense						= wiremode
	smua.source.autorangev			= 0
	smua.source.autorangei			= 0
	smua.source.rangev				= math.max(math.abs(start), math.abs(stop))
	smua.source.levelv				= 0
	smua.source.limiti				= 5

	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= 0
	smua.measure.autorangei			= 0
	smua.measure.rangev				= math.max(math.abs(start), math.abs(stop))
	smua.measure.rangei				= limit
	smua.measure.nplc				= nplc
	smua.measure.delay				= (ton - ((1/60) * smua.measure.nplc)) - 60e-6

	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode		= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode		= 1

	-- Configure the Pulsed Sweep setup
	--=============================

	-- Configure timers
	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numpulse
	trigger.timer[1].delay			= period
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= ton
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= trigger.timer[1].EVENT_ID

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.linearv(start, stop, (numpulse >= 2) and numpulse or 2)
	smua.trigger.source.limiti		= limit
	smua.trigger.measure.action		= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numpulse
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= 0
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE

	smua.source.output				= 1
	smua.trigger.initiate()
	waitcomplete()
	smua.source.output				= 0

	PrintData2()
end



--[[
	Function:	PulseVFast(start, stop, numpulse, limit, ton, period, measCount, wiremode)
	Summary:	This function outputs voltage pulses and takes a measurements using the
	high speed adc.  The high speed ADC will be configured for a 1 MS/s sample rate.
	Set start = stop to output pulses of a single level.
	
	Parameters:
		start:		The voltage level for the first pulse in the sweep
		stop:		The voltage level for the last pulse in the sweep
		numpulse:	The number of consecutive pulses to output
		limit:		The current limit of the pulse
		ton:		The width of the pulse in seconds
		period:		The length of a single pulse cycle in seconds
		measCount:	Sets th number of samples to take per pulse
		wiremode:	Lets you select between local and remote sense.  Use 2 for local and 4 for remote.
	Example Usage:
		PulseVFast(0, 7, 8, 50, 500e-6, 100e-3, 600, 4)
		PulseVFast(7, 7, 1, 50, 300e-6, 100e-3, 400, 4)
		PulseVFast(7, 7, 1, 50, 200e-6, 100e-3, 300, 4)
]]
function PulseVFast(start, stop, limit, ton, period, measCount, numpulse, wiremode)
	if (start == nil) then start = 1 end
	if (stop == nil) then stop = 1 end
	if (limit == nil) then limit = 1 end
	if (ton == nil) then ton = 1e-3 end
	if (period == nil) then period = 100e-3 end
	if (measCount == nil) then measCount = ton*1e6 + 100 end
	if (numpulse == nil) then numpulse = 1 end
	if (wiremode == 4) then wiremode = smua.SENSE_REMOTE
	else wiremode = smua.SENSE_LOCAL end

	reset()
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCVOLTS
	smua.sense						= wiremode
	smua.source.autorangev			= 0
	smua.source.autorangei			= 0
	smua.source.rangev				= math.max(math.abs(start), math.abs(stop))
	smua.source.levelv				= 0
	smua.source.limiti				= 5
	
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= 0
	smua.measure.autorangei			= 0
	smua.measure.rangei				= limit
	smua.measure.rangev				= math.max(math.abs(start), math.abs(stop))
	smua.measure.nplc				= 0.001
	smua.measure.interval			= 0
	smua.measure.adc				= smua.ADC_FAST
	smua.measure.count				= measCount

	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode		= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode		= 1

	-- Configure the Pulsed Sweep setup
	--=============================

	-- Configure timers
	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numpulse
	trigger.timer[1].delay			= period
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= ton
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= trigger.timer[1].EVENT_ID

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.linearv(start, stop, (numpulse >= 2) and numpulse or 2)
	smua.trigger.source.limiti		= limit
	smua.trigger.measure.action		= smua.ASYNC
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numpulse
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE

	smua.source.output				= 1
	smua.trigger.initiate()
--	waitcomplete()
	local ovr = false
	local msg = ""
	while ((status.operation.sweeping.condition ~= 0) and (ovr == false)) do
		ovr, msg = CheckForOverRun()
	end
	if (ovr == true) then smua.abort() print(msg) end

	smua.source.output				= 0

	PrintData2()
end



--[[
	Function:	SweepFET(gstart, gstop, gsteps, start, stop, steps, ton, period, limit, nplc)
	Summary:	This function performs a IV test on a FET, IGBT or other transitor type semiconductor
	device.  This function will collect the data necessary to generate a series of IV curves for
	varying gate voltages.
	This function requires smua of a 2602A to connect to the gate of the device while the 2651A
	connects to the drain.  The 2602A should be configured as node 2 while the 2651A is configured
	as node 1.  The 2651A should be used as the master node.
	This function requires 4-Wire connections.
	
	Parameters:
		gtart:		The voltage level to set the gate at for the first IV curve
		gstop:		The voltage level to set the gate at for the last IV curve
		gsteps:		The number of gate voltage steps in the test sequence (the number of IV curves)
		start:		The voltage level for the first pulse in the sweep across the drain
		stop:		The voltage level for the last pulse in the sweep across the drain
		steps:		The number of steps in the sweep across the drain
		ton:		The width of the drain pulse in seconds
		period:		The length of a single pulse cycle in seconds
		limit:		The current limit of the pulses across the drain
		nplc:		The NPLC setting to use for measurements on the drain
	Example Usage:
		SweepFET(1, 9, 9, 0, 10, 51, 500e-6, 100e-3, 50, 0.01)
		SweepFET(5, 6.5, 7, 0, 20, 21, 500e-6, 100e-3, 10, 0.01)
]]
function SweepFET(gstart, gstop, gsteps, start, stop, steps, ton, period, limit, nplc)
	if (gstart == nil) then start = 0 end
	if (gstop == nil) then stop = 5 end
	if (gsteps == nil) then steps = 6 end
	if (start == nil) then start = 0 end
	if (stop == nil) then stop = 1 end
	if (steps == nil) then steps = 11 end
	if (ton == nil) then ton = 1e-3 end
	if (period == nil) then period = 100e-3 end
	if (limit == nil) then limit = 1 end
	if (limit > 20) then dclimit = 20 else dclimit = limit end
	if (nplc == nil) then nplc = 0.001 end

	tsplink.reset()
	reset()
	node[2].reset()
	node[2].display.screen			= node[2].display.SMUA
	node[2].display.smua.measure.func	= node[2].display.MEASURE_DCAMPS
	gate = node[2].smua

	-- Config Gate SMU
	gate.reset()
	gate.source.func				= gate.OUTPUT_DCVOLTS
	stepg = (gstop-gstart)/(gsteps-1)

	-- Prep Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode		= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode		= 1

	for x=1,gsteps do
	
		-- Config Sweep SMU
		smua.reset()
		smua.source.func				= smua.OUTPUT_DCVOLTS
		smua.sense						= smua.SENSE_REMOTE
		smua.source.autorangev			= 0
		smua.source.autorangei			= 0
		smua.source.rangev				= math.max(math.abs(start), math.abs(stop))
		smua.source.rangei				= limit
		smua.source.levelv				= 0
		smua.source.leveli				= 0
		smua.source.limiti				= dclimit
		smua.source.limitv				= 20
		
		smua.measure.autozero			= smua.AUTOZERO_ONCE
		smua.measure.autorangev			= 0
		smua.measure.autorangei			= 0
		smua.measure.rangev				= math.max(math.abs(start), math.abs(stop))
		smua.measure.rangei				= limit
		smua.measure.nplc				= nplc
		smua.measure.delay				= (ton - ((1/60) * smua.measure.nplc)) - 60e-6

		-- Configure the Pulsed Sweep setup
		--=================================

		-- Configure timers
		-- Timer 1 controls the pulse period
		trigger.timer[1].count			= steps
		trigger.timer[1].delay			= period
		trigger.timer[1].passthrough	= true
		trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID

		-- Timer 2 controls the pulse width
		trigger.timer[2].count			= 1
		trigger.timer[2].delay			= ton
		trigger.timer[2].passthrough	= false
		trigger.timer[2].stimulus		= trigger.timer[1].EVENT_ID

		-- Configure SMU Trigger Model for Sweep
		smua.trigger.source.linearv(start, stop, steps)
		smua.trigger.source.limiti		= limit
		smua.trigger.measure.action		= smua.ENABLE
		smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
		smua.trigger.endpulse.action	= smua.SOURCE_IDLE
		smua.trigger.endsweep.action	= smua.SOURCE_IDLE
		smua.trigger.count				= steps
		smua.trigger.arm.stimulus		= 0
		smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
		smua.trigger.measure.stimulus	= 0
		smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
		smua.trigger.source.action		= smua.ENABLE

		gate.source.output				= 1
		smua.source.output				= 1

			gate.source.levelv			= gstart + stepg*(x-1)
			gate.measure.i()
			smua.trigger.initiate()
			waitcomplete()

		gate.source.levelv				= 0
		smua.source.output				= 0
		gate.source.output				= 0
	end

	PrintData2()
end





function PrintData()
	for i=1,smua.nvbuffer1.n do
		print(smua.nvbuffer1[i])
	end
end

function PrintData2()
	print("Current Readings\tVoltage Readings")
	for i=1,smua.nvbuffer1.n do
		print(smua.nvbuffer1[i], smua.nvbuffer2[i])
	end
end



-- Utility Functions
function CheckForOverRun()
	-- Check SMUA Trigger Overruns
	if (bit.bitand(status.operation.instrument.smua.trigger_overrun.condition, 2) == 2) then
		return true, "smua arm trigger is overrun"
	end
	if (bit.bitand(status.operation.instrument.smua.trigger_overrun.condition, 4) == 4) then
		return true, "smua source trigger is overrun"
	end
	if (bit.bitand(status.operation.instrument.smua.trigger_overrun.condition, 8) == 8) then
		return true, "smua measure trigger is overrun"
	end
	if (bit.bitand(status.operation.instrument.smua.trigger_overrun.condition, 16) == 16) then
		return true, "smua endpulse trigger is overrun"
	end

	-- Check SMUB Trigger Overruns
	-- if (bit.bitand(status.operation.instrument.smub.trigger_overrun.condition, 2) == 2) then
		-- return true, "smub arm trigger is overrun"
	-- end	
	-- if (bit.bitand(status.operation.instrument.smub.trigger_overrun.condition, 4) == 4) then
		-- return true, "smub source trigger is overrun"
	-- end
	-- if (bit.bitand(status.operation.instrument.smub.trigger_overrun.condition, 8) == 8) then
		-- return true, "smub measure trigger is overrun"
	-- end
	-- if (bit.bitand(status.operation.instrument.smub.trigger_overrun.condition, 16) == 16) then
		-- return true, "smub endpulse trigger is overrun"
	-- end

	-- Check Timers for Overrun
	for CFORi=1,8 do
		if (trigger.timer[CFORi].overrun == true) then
			return true, string.format("Timer %d trigger is overrun", CFORi)
		end
	end
	
	-- Check Blenders for Overrun
	for CFORi=1,4 do
		if (trigger.blender[CFORi].overrun == true) then
			return true, string.format("blender %d trigger is overrun", CFORi)
		end
	end

	-- Check TSP-Link Triggers for Overrun
	for CFORi=1,3 do
		if (tsplink.trigger[CFORi].overrun == true) then
			return true, string.format("TSP-Link trigger %d is overrun", CFORi)
		end
	end

	-- Check DIGIO Triggers for Overrun
	for CFORi=1,14 do
		if (digio.trigger[CFORi].overrun == true) then
			return true, string.format("digio trigger %d is overrun", CFORi)
		end
	end

	-- Check LAN Triggers for Overrun
	for CFORi=1,8 do
		if (lan.trigger[CFORi].overrun == true) then
			return true, string.format("LAN trigger %d is overrun", CFORi)
		end
	end

	return false, "no overrun detected"
end