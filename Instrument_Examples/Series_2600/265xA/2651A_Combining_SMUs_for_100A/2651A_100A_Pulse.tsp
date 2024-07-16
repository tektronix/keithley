--[[
	Title:	2651A 100A Pulse
	Description:	The purpose of this script is to combine two 2651A
	units to produce 100A Pulses.  This script assumes you have 2x
	2651A units in a TSP-Link as nodes 1 and 2 and their outputs are
	connected in parallel.

	If you are not familiar with high current pulsing, consult Keithley Applications Engineering before attempting this test. It could damage you or your equipment.

	Written By: Keithley Applications Engineering

]]

function DualPulseInit()
	tsplink.reset()
	master	= smua
	slave	= node[2].smua
end



-- DualPulseI(60, 10, 700e-6, 2.8e-3, 1, 4)
function DualPulseI(level, limit, ton, period, numpulse, wiremode)
	if (level == nil) then level = 1e-3 end
	if (limit == nil) then limit = 1 end
	if (ton == nil) then ton = 1e-3 end
	if (period == nil) then period = 100e-3 end
	if (nplc == nil) then nplc = 0.001 end
	if (numpulse == nil) then numpulse = 1 end
	if (wiremode == 4) then wiremode = smua.SENSE_REMOTE
	else wiremode = smua.SENSE_LOCAL end
	measCount = ton * 1.5e6

	reset()

	-- Configure the Master SMU
	--=========================
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCAMPS
	smua.sense						= wiremode
	smua.source.autorangev			= 0
	smua.source.autorangei			= 0
	smua.source.rangei				= level/2
	smua.source.leveli				= 0
	smua.source.limitv				= limit
	
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= 0
	smua.measure.autorangei			= 0
	smua.measure.rangev				= limit
	smua.measure.rangei				= level/2
--	smua.measure.nplc				= nplc
	smua.measure.adc				= smua.ADC_FAST
	smua.measure.interval			= 0
	smua.measure.count				= measCount
--	smua.measure.delay				= (ton - ((1/60) * smua.measure.nplc)) - 60e-6

	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode		= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode		= 1

	-- Configure Trigger Model
	--------------------------
	tsplink.trigger[1].clear()
	tsplink.trigger[1].mode			= tsplink.TRIG_EITHER

	-- Configure timers
	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numpulse - 1
	trigger.timer[1].delay			= period
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= ton
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= trigger.timer[1].EVENT_ID

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.lineari(level/2, level/2, 2)
	smua.trigger.source.limitv		=  limit
	smua.trigger.measure.action		= smua.ASYNC--smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numpulse
	smua.trigger.arm.stimulus		= tsplink.trigger[1].EVENT_ID
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE

	--========================
	-- Configure the Salve SMU
	--========================
	slave.reset()
	slave.source.func				= slave.OUTPUT_DCAMPS
	slave.sense						= slave.SENSE_LOCAL--wiremode
	slave.source.autorangev			= 0
	slave.source.autorangei			= 0
	slave.source.rangei				= level/2
	slave.source.leveli				= 0
	slave.source.limitv				= limit
	
	slave.measure.autozero			= slave.AUTOZERO_ONCE
	slave.measure.autorangev		= 0
	slave.measure.autorangei		= 0
	slave.measure.rangev			= limit
	slave.measure.rangei			= level/2
--	slave.measure.nplc				= nplc
	slave.measure.adc				= slave.ADC_FAST
	slave.measure.interval			= 0
	slave.measure.count				= measCount
--	slave.measure.delay				= (ton - ((1/60) * slave.measure.nplc)) - 60e-6

	slave.nvbuffer1.clear()
	slave.nvbuffer1.appendmode		= 1
	slave.nvbuffer2.clear()
	slave.nvbuffer2.appendmode		= 1

	-- Configure Trigger Model
	--------------------------
	node[2].tsplink.trigger[1].clear()
	node[2].tsplink.trigger[1].mode	= node[2].tsplink.TRIG_EITHER
	-- Configure timers
	-- Timer 1 controls the pulse period
	node[2].trigger.timer[1].count			= numpulse - 1
	node[2].trigger.timer[1].delay			= period
	node[2].trigger.timer[1].passthrough	= true
	node[2].trigger.timer[1].stimulus		= node[2].smua.trigger.ARMED_EVENT_ID

	-- Timer 2 controls the pulse width
	node[2].trigger.timer[2].count			= 1
	node[2].trigger.timer[2].delay			= ton
	node[2].trigger.timer[2].passthrough	= false
	node[2].trigger.timer[2].stimulus		= node[2].trigger.timer[1].EVENT_ID

	-- Configure SMU Trigger Model for Sweep
	slave.trigger.source.lineari(level/2, level/2, 2)
	slave.trigger.source.limitv		= limit
	slave.trigger.measure.action	= slave.ASYNC--slave.ENABLE
	slave.trigger.measure.iv(slave.nvbuffer1, slave.nvbuffer2)
	slave.trigger.endpulse.action	= slave.SOURCE_IDLE
	slave.trigger.endsweep.action	= slave.SOURCE_IDLE
	slave.trigger.count				= numpulse
	slave.trigger.arm.stimulus		= node[2].tsplink.trigger[1].EVENT_ID
	slave.trigger.source.stimulus	= node[2].trigger.timer[1].EVENT_ID
	slave.trigger.measure.stimulus	= node[2].trigger.timer[1].EVENT_ID
	slave.trigger.endpulse.stimulus	= node[2].trigger.timer[2].EVENT_ID
	slave.trigger.source.action		= slave.ENABLE


	smua.source.output				= 1
	slave.source.output				= 1
	smua.trigger.initiate()
	slave.trigger.initiate()
	tsplink.trigger[1].assert()
	waitcomplete()
	smua.source.output				= 0
	slave.source.output				= 0
	
	-- for x=1,smua.nvbuffer1.n do
		-- print(smua.nvbuffer1[x], smua.nvbuffer2[x])
	-- end
end


-- DualPulseI_Train(48, 10, 200e-6, 1e-3, 5, 4)
function DualPulseI_Train(level, limit, ton, period, numpulse, wiremode)
	if (level == nil) then level = 1e-3 end
	if (limit == nil) then limit = 1 end
	if (ton == nil) then ton = 1e-3 end
	if (period == nil) then period = 100e-3 end
	if (nplc == nil) then nplc = 0.001 end
	if (numpulse == nil) then numpulse = 1 end
	if (wiremode == 4) then wiremode = smua.SENSE_REMOTE
	else wiremode = smua.SENSE_LOCAL end

	local measCount = 5000

	reset()

	-- Configure the Master SMU
	--=========================
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCAMPS
	smua.sense						= smua.SENSE_REMOTE
	smua.source.autorangev			= 0
	smua.source.autorangei			= 0
	smua.source.rangei				= level/2
	smua.source.leveli				= 0
	smua.source.limitv				= limit
	
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= 0
	smua.measure.autorangei			= 0
	smua.measure.rangev				= limit
	smua.measure.rangei				= level/2
--	smua.measure.nplc				= nplc
	smua.measure.adc				= smua.ADC_FAST
	smua.measure.interval			= 0
	smua.measure.count				= measCount
--	smua.measure.delay				= (ton - ((1/60) * smua.measure.nplc)) - 60e-6

	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode		= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode		= 1

	-- Configure Trigger Model
	--------------------------
	tsplink.trigger[1].clear()
	tsplink.trigger[1].mode			= tsplink.TRIG_EITHER

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
	smua.trigger.source.lineari(level/2, level/2, 2)
	smua.trigger.source.limitv		=  limit
	smua.trigger.measure.action		= smua.ASYNC--smua.ENABLE
	smua.trigger.measure.v(smua.nvbuffer1)--, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numpulse
	smua.trigger.arm.stimulus		= tsplink.trigger[1].EVENT_ID
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= smua.trigger.ARMED_EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE

	--========================
	-- Configure the Salve SMU
	--========================
	slave.reset()
	slave.source.func				= slave.OUTPUT_DCAMPS
	slave.sense						= wiremode
	slave.source.autorangev			= 0
	slave.source.autorangei			= 0
	slave.source.rangei				= level/2
	slave.source.leveli				= 0
	slave.source.limitv				= limit
	
	slave.measure.autozero			= slave.AUTOZERO_ONCE
	slave.measure.autorangev		= 0
	slave.measure.autorangei		= 0
	slave.measure.rangev			= limit
	slave.measure.rangei			= level/2
--	slave.measure.nplc				= nplc
	slave.measure.adc				= slave.ADC_FAST
	slave.measure.interval			= 0
	slave.measure.count				= measCount
--	slave.measure.delay				= (ton - ((1/60) * slave.measure.nplc)) - 60e-6

	slave.nvbuffer1.clear()
	slave.nvbuffer1.appendmode		= 1
	slave.nvbuffer2.clear()
	slave.nvbuffer2.appendmode		= 1

	-- Configure Trigger Model
	--------------------------
	node[2].tsplink.trigger[1].clear()
	node[2].tsplink.trigger[1].mode			= node[2].tsplink.TRIG_EITHER

	-- Timer 1 controls the pulse period
	node[2].trigger.timer[1].count			= numpulse
	node[2].trigger.timer[1].delay			= period
	node[2].trigger.timer[1].passthrough	= true
	node[2].trigger.timer[1].stimulus		= slave.trigger.ARMED_EVENT_ID

	-- Timer 2 controls the pulse width
	node[2].trigger.timer[2].count			= 1
	node[2].trigger.timer[2].delay			= ton
	node[2].trigger.timer[2].passthrough	= false
	node[2].trigger.timer[2].stimulus		= node[2].trigger.timer[1].EVENT_ID

	-- Configure SMU Trigger Model for Sweep
	slave.trigger.source.lineari(level/2, level/2, 2)
	slave.trigger.source.limitv			=  limit
	slave.trigger.measure.action		= slave.ASYNC--slave.ENABLE
	slave.trigger.measure.v(slave.nvbuffer1)--, slave.nvbuffer2)
	slave.trigger.endpulse.action		= slave.SOURCE_IDLE
	slave.trigger.endsweep.action		= slave.SOURCE_IDLE
	slave.trigger.count					= numpulse
	slave.trigger.arm.stimulus			= node[2].tsplink.trigger[1].EVENT_ID
	slave.trigger.source.stimulus		= node[2].trigger.timer[1].EVENT_ID
	slave.trigger.measure.stimulus		= slave.trigger.ARMED_EVENT_ID
	slave.trigger.endpulse.stimulus		= node[2].trigger.timer[2].EVENT_ID
	slave.trigger.source.action			= slave.ENABLE


	smua.source.output				= 1
	slave.source.output				= 1
	smua.trigger.initiate()
	slave.trigger.initiate()
	tsplink.trigger[1].assert()
	waitcomplete()
	smua.source.output				= 0
	slave.source.output				= 0
	
	-- for x=1,smua.nvbuffer1.n do
		-- print(smua.nvbuffer1[x], smua.nvbuffer2[x])
	-- end
end



function PrintData()
	for i=1,smua.nvbuffer1.n do
		print(smua.nvbuffer1[i])
	end
end


-- TriggerTestV(5, 1e-3, 500e-6, 10e-3, 2, 2)
-- This function was meant to try a new method of trigger timing and it doesn't seem
-- to work so don't bother using this function unless you modify it first.
function TriggerTestV(level, limit, ton, period, numpulse, wiremode)
	if (level == nil) then level = 1e-3 end
	if (limit == nil) then limit = 1 end
	if (ton == nil) then ton = 1e-3 end
	if (period == nil) then period = 100e-3 end
	if (nplc == nil) then nplc = 0.001 end
	if (numpulse == nil) then numpulse = 1 end
	if (wiremode == 4) then wiremode = smua.SENSE_REMOTE
	else wiremode = smua.SENSE_LOCAL end

	DualPulseInit()
	reset()

	-- Configure the Master SMU
	--=========================
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCAMPS
	smua.sense						= smua.SENSE_REMOTE
	smua.source.autorangev			= 0
	smua.source.autorangei			= 0
	smua.source.rangev				= level
	smua.source.levelv				= 0
	smua.source.limiti				= limit
	
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= 0
	smua.measure.autorangei			= 0
	smua.measure.rangei				= limit
	smua.measure.rangev				= level
	smua.measure.nplc				= nplc
	smua.measure.delay				= (ton - ((1/60) * smua.measure.nplc)) - 60e-6

	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode		= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode		= 1

	-- Configure Trigger Model
	--------------------------
	tsplink.trigger[1].mode			= tsplink.TRIG_RISINGM
	tsplink.trigger[1].clear()
	tsplink.trigger[1].release()
	tsplink.trigger[1].stimulus		= trigger.timer[1].EVENT_ID

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numpulse
	trigger.timer[1].delay			= period
	trigger.timer[1].passthrough	= false
	trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= ton
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= tsplink.trigger[1].EVENT_ID

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.linearv(level, level, 2)
	smua.trigger.source.limiti		=  limit
	smua.trigger.measure.action		= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numpulse
	smua.trigger.arm.stimulus		= display.trigger.EVENT_ID
	smua.trigger.source.stimulus	= tsplink.trigger[1].EVENT_ID
	smua.trigger.measure.stimulus	= 0
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE

	--========================
	-- Configure the Salve SMU
	--========================
	slave.reset()
	slave.source.func				= slave.OUTPUT_DCVOLTS
	slave.sense						= wiremode
	slave.source.autorangev			= 0
	slave.source.autorangei			= 0
	slave.source.rangev				= level
	slave.source.levelv				= 0
	slave.source.limiti				= limit
	
	slave.measure.autozero			= slave.AUTOZERO_ONCE
	slave.measure.autorangev		= 0
	slave.measure.autorangei		= 0
	slave.measure.rangei			= limit
	slave.measure.rangev			= level
	slave.measure.nplc				= nplc
	slave.measure.delay				= (ton - ((1/60) * slave.measure.nplc)) - 60e-6

	slave.nvbuffer1.clear()
	slave.nvbuffer1.appendmode		= 1
	slave.nvbuffer2.clear()
	slave.nvbuffer2.appendmode		= 1

	-- Configure Trigger Model
	--------------------------
	node[2].tsplink.trigger[1].mode			= node[2].tsplink.TRIG_RISINGA
	node[2].tsplink.trigger[1].clear()
	node[2].tsplink.trigger[1].release()

	-- Timer 1 controls the pulse width.  (Period is done by the TSP-Link Trigger)
	node[2].trigger.timer[1].count			= 1
	node[2].trigger.timer[1].delay			= period
	node[2].trigger.timer[1].passthrough	= true
	node[2].trigger.timer[1].stimulus		= node[2].tsplink.trigger[1].EVENT_ID


	-- Configure SMU Trigger Model for Sweep
	slave.trigger.source.linearv(level, level, 2)
	slave.trigger.source.limiti			=  limit
	slave.trigger.measure.action		= slave.ENABLE
	slave.trigger.measure.iv(slave.nvbuffer1, slave.nvbuffer2)
	slave.trigger.endpulse.action		= slave.SOURCE_IDLE
	slave.trigger.endsweep.action		= slave.SOURCE_IDLE
	slave.trigger.count					= numpulse
	slave.trigger.arm.stimulus			= 0
	slave.trigger.source.stimulus		= node[2].tsplink.trigger[1].EVENT_ID
	slave.trigger.measure.stimulus		= 0
	slave.trigger.endpulse.stimulus		= node[2].trigger.timer[1].EVENT_ID
	slave.trigger.source.action			= slave.ENABLE


	smua.source.output				= 1
	slave.source.output				= 1
	smua.trigger.initiate()
	slave.trigger.initiate()
--	delay(0.1)
--	tsplink.trigger[1].assert()
	waitcomplete()
	smua.source.output				= 0
	slave.source.output				= 0
	
	-- for x=1,smua.nvbuffer1.n do
		-- print(smua.nvbuffer1[x], smua.nvbuffer2[x])
	-- end
end

