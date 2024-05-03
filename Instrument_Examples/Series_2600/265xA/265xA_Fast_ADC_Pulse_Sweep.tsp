--[[
	Title: Fast ADC Pulse Sweep
	
	Description: This script performs a high power pulse sweep using the
	fast ADC to measure.

]]

-- SweepV(0, 5, 11, 200e-6, 20e-3, 20)
function SweepV(start, stop, steps, ton, period, limit)
	if (start == nil) then start = 0 end
	if (stop == nil) then stop = 1 end
	if (steps == nil) then steps = 11 end
	if (ton == nil) then ton = 1e-3 end
	if (period == nil) then period = 100e-3 end
	if (limit == nil) then limit = 1 end
	if (limit > 20) then dclimit = 20 else dclimit = limit end

	reset()
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCVOLTS
	smua.sense						= smua.SENSE_REMOTE
	smua.source.autorangev			= 0
	smua.source.autorangei			= 0
	smua.source.rangev				= 10
	smua.source.rangei				= limit
	smua.source.levelv				= 0
	smua.source.leveli				= 0
	smua.source.limiti				= dclimit
	smua.source.limitv				= 10
	
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= 0
	smua.measure.autorangei			= 0
	smua.measure.rangev				= 10
	smua.measure.rangei				= limit
	smua.measure.adc				= smua.ADC_FAST
	smua.measure.interval			= 0
	smua.measure.count				= 300

	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode		= 1
	smua.nvbuffer2.clear()

	-- Configure the Pulsed Sweep setup
	--=============================

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
	smua.trigger.measure.action		= smua.ASYNC--smua.ENABLE
	smua.trigger.measure.i(smua.nvbuffer1)--, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= steps
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE


	smua.source.output				= 1
	smua.trigger.initiate()
	waitcomplete()
	smua.source.output				= 0
end


-- SimpleSweepV(0, 5, 11, 200e-6, 20e-3)
function SimpleSweepV(start, stop, steps, ton, period)
	if (start == nil) then start = 0 end
	if (stop == nil) then stop = 5 end
	if (steps == nil) then steps = 11 end
	if (ton == nil) then ton = 1e-3 end
	if (period == nil) then period = 100e-3 end
	
	stepv = (stop-start)/(steps-1)

	smua.reset()
	smua.source.func				= smua.OUTPUT_DCVOLTS
	smua.sense						= smua.SENSE_LOCAL
	smua.source.autorangev			= 0
	smua.source.autorangei			= 0
	smua.source.rangev				= 20
	smua.source.rangei				= 10
	smua.source.levelv				= 0
	smua.source.leveli				= 0
	smua.source.limiti				= 10
	smua.source.limitv				= 20
	
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= 0
	smua.measure.autorangei			= 0
	smua.measure.rangev				= 20
	smua.measure.rangei				= 10
	smua.measure.adc				= smua.ADC_FAST
	smua.measure.interval			= 0
	smua.measure.count				= 300

	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode		= 1
--	smua.nvbuffer2.clear()

	smua.source.output				= 1
	print("Output on!")
	delay(0.1)
	for x=1,steps do
		print("x=", x, "Level=", start+(x*stepv))
		smua.source.levelv			= start + stepv*(x-1)
		delay(ton)
		smua.measure.i(smua.nvbuffer1)
		smua.source.levelv			= 0
		delay(period - ton)
	end
	smua.source.output				= 0
end



function PrintBuffer()
	printbuffer(1, smua.nvbuffer1.n, smua.nvbuffer1)
end

function PrintData()
	for i=1,smua.nvbuffer1.n do
		print(smua.nvbuffer1[i])
	end
end
