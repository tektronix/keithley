--[[
	Title:		Pulse Width Modulation Script
	Author:		David Wyban
	Date: 		6/24/2011
	Desription:	The purpose of this script is to generate a pulse width
	modulated waveform for use in testing High Brightness LED modules.
	Users of this script should call the functions in the User Functions
	section.  Functions in the Utility Functions section are used by the
	User Functions to execute the test.

	System Setup:
		PWM_Test_Single()
			1x Model 2651A
		PWM_TEST_Dual()
			2x Model 2651A
			1x TSP-Link Cable
			
			Node 1: 2651A #1 (Master)
			Node 2: 2651A #2 (Slave)

	Revision History
	Ver. 1.00	6/24/2011
	Modified by: David Wyban
	Original Revision
]]--

--================
-- User Functions
--================
--[[	PWM_Test_Single()

	This function uses a single SMU to output a pulse width modulated waveform.
--]]
function PWM_Test_Single(pulseLevel, pulseLimit, frequency, dutyCycle, numPulses, specDelay)
	if (pulseLevel == nil) then pulseLevel = 1 end
	if (pulseLimit == nil) then pulseLimit = 1 end
	if (frequency == nil) then frequency = 100 end
	if (dutyCycle == nil) then dutyCycle = 1 end
	if (numPulses == nil) then numPulses = 10 end
	if (specDelay == nil) then specDelay = 0 end

	local pulsePeriod
	local pulseWidth
	local measDelay
	-- Calculate the timing parameters from the frequency and duty cycle
	pulsePeriod,pulseWidth,measDelay = CalculateTiming(frequency, dutyCycle)

	-- Do a quick check on the input parameters
	f,msg = SimpleRegionCheck(pulseLevel, pulseLimit, dutyCycle, 1)
	if (f == false) then
		print(msg)
		quit()
	end

	reset()
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCAMPS
	smua.sense						= smua.SENSE_REMOTE
	smua.source.autorangei			= 0
	smua.source.rangei				= pulseLevel
	smua.source.leveli				= 0
	-- Set the DC bias limit.  This is not the limit used during the pulses.
	smua.source.limitv				= 1
	
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= 0
	smua.measure.rangev				= pulseLimit
	-- The fast ADC allows us to place the measurements very close to the falling edge of
	-- the pulse allowing for settled measurements even when pulse widths are very small
	smua.measure.adc				= smua.ADC_FAST
	smua.measure.count				= 1
	smua.measure.interval			= 1e-6
	-- Uncomment the following lines to turn on measure filtering.  When enabled, the SMU
	-- will take multiple measurements and average them to produce a single reading.
	-- Because the Fast ADC can take one measurement every microsecond, several measurements
	-- can be aquired in a small time to produce an averaged reading.
	--smua.measure.filter.count		= 5
	--smua.measure.filter.enable		= smua.FILTER_ON

	-- This measure delay sets the delay between the measurement trigger being received
	-- and when the actual measurement(s) start.  This is set to 0 because we will be
	-- delaying the trigger itself and do not need additional delay.
	smua.measure.delay				= 0

	-- Setup the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode		= 1
	smua.nvbuffer1.collecttimestamps= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode		= 1
	smua.nvbuffer2.collecttimestamps= 1

	-- Configure the Trigger Model
	--============================

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numPulses > 1 and numPulses - 1 or 1
	trigger.timer[1].delay			= pulsePeriod
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	if (type(pulseWidth) == "table") then
		-- Use a delay list if the duty cycle will vary for each pulse
		trigger.timer[2].delaylist	= pulseWidth
	else
		-- else every pulse will be the same duty cycle
		trigger.timer[2].delay		= pulseWidth
	end
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= smua.trigger.SOURCE_COMPLETE_EVENT_ID

	-- Timer 3 controls the measurement
	trigger.timer[3].count			= 1
	if (type(measDelay) == "table") then
		-- If the duty cycle is variable then the measure delay will be as well
		trigger.timer[3].delaylist	= measDelay
	else
		trigger.timer[3].delay		= measDelay
	end
	trigger.timer[3].passthrough	= false
	trigger.timer[3].stimulus		= smua.trigger.SOURCE_COMPLETE_EVENT_ID

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.lineari(pulseLevel, pulseLevel, numPulses)
	smua.trigger.source.limitv		= pulseLimit
	smua.trigger.measure.action		= smua.ASYNC
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numPulses
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= trigger.timer[3].EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE

	-- Configure the Digital I/O trigger
	ConfigureSpectrometerTrigger(specDelay)

	-- Start the Test
	--===============
	-- Turn the output on
	smua.source.output				= 1
	-- Start the trigger model execution
	smua.trigger.initiate()

	-- While the trigger model is outputing the waveform and collecting the
	-- measurements, the script will scan the status model for any overruns
	-- that may occur as a result of using impropper settings.
	local ovr = false
	local msg = ""
	while ((status.operation.sweeping.condition ~= 0) and (ovr == false)) do
		ovr, msg = CheckForOverRun(localnode)
	end
	if (ovr == true) then
		smua.abort()
		print(msg)
	end
	-- Turn the output off
	smua.source.output				= 0
	-- Return the data
	PrintData()
end

--[[	PWM_Test_Dual()

	This function uses two SMUs connected together in parallel to ouput a pulse width
	modulated wavform.  By using two SMUs higher current levels/duty cycles can be achieved.
--]]
function PWM_Test_Dual(pulseLevel, pulseLimit, frequency, dutyCycle, numPulses, specDelay)
	if (pulseLevel == nil) then pulseLevel = 1 end
	if (pulseLimit == nil) then pulseLimit = 1 end
	if (frequency == nil) then frequency = 100 end
	if (dutyCycle == nil) then dutyCycle = 1 end
	if (numPulses == nil) then numPulses = 10 end
	if (specDelay == nil) then specDelay = 0 end

	local pulsePeriod
	local pulseWidth
	local measDelay

	-- Calculate the timing parameters from the frequency and duty cycle
	pulsePeriod,pulseWidth,measDelay = CalculateTiming(frequency, dutyCycle)

	-- Do a quick check on the input parameters
	f,msg = SimpleRegionCheck(pulseLevel, pulseLimit, dutyCycle, 2)
	if (f == false) then
		print(msg)
		quit()
	end

	-- Initialize the TSP-Link
	errorqueue.clear()
	tsplink.reset()
	errcode,errmsg,stat = errorqueue.next()
	if (errcode ~= 0) then
		print(errmsg)
		exit()
	end
	reset()
	ConfigureLocalSMU(pulseLevel, pulseLimit, pulsePeriod, pulseWidth, measDelay, numPulses)
	ConfigureRemoteSMU(pulseLevel, pulseLimit, pulsePeriod, pulseWidth, measDelay, numPulses)

	-- Start the Test
	--===============
	-- Turn the output on
	smua.source.output						= 1
	node[2].smua.source.output				= 1
	-- Start the trigger model execution
	node[2].smua.trigger.initiate()
	smua.trigger.initiate()

	-- While the trigger model is outputing the waveform and collecting the
	-- measurements, the script will scan the status model for any overruns
	-- that may occur as a result of using impropper settings.
	local ovr1 = false
	local ovr2 = false
	local msg1 = ""
	local msg2 = ""
	-- Loop until the sweep is either complete, or an overrun condition is detected
	while (((status.operation.sweeping.condition ~= 0) or (node[2].status.operation.sweeping.condition ~= 0)) and (ovr1 == false) and (ovr2 == false)) do
		ovr1, msg1 = CheckForOverRun(localnode)
		ovr2, msg2 = CheckForOverRun(node[2])
	end
	if ((ovr1 == true) or (ovr2 == true)) then
		smua.abort()
		node[2].smua.abort()
		print("SMU#1:", msg1)
		print("SMU#2:", msg2)
	end
	-- Turn the output off
	node[2].smua.source.output				= 0
	smua.source.output						= 0
	-- Return the data
	PrintDataDual()
end


--===================
-- Utility Functions
--===================
function ConfigureLocalSMU(pulseLevel, pulseLimit, pulsePeriod, pulseWidth, measDelay, numPulses)
	smua.reset()
	smua.source.func				= smua.OUTPUT_DCAMPS
	smua.sense						= smua.SENSE_REMOTE
	smua.source.autorangei			= 0
	smua.source.rangei				= pulseLevel/2
	smua.source.leveli				= 0
	-- Set the DC bias limit.  This is not the limit used during the pulses.
	smua.source.limitv				= 1
	smua.source.offmode				= smua.OUTPUT_NORMAL
	smua.source.offfunc				= smua.OUTPUT_DCVOLTS
	smua.source.offlimiti			= 1e-3
	
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= 0
	smua.measure.rangev				= pulseLimit
	-- The fast ADC allows us to place the measurements very close to the falling edge of
	-- the pulse allowing for settled measurements even when pulse widths are very small
	smua.measure.adc				= smua.ADC_FAST
	smua.measure.count				= 1
	smua.measure.interval			= 1e-6
	-- Uncomment the following lines to turn on measure filtering.  When enabled, the SMU
	-- will take multiple measurements and average them to produce a single reading.
	-- Because the Fast ADC can take one measurement every microsecond, several measurements
	-- can be aquired in a small time to produce an averaged reading.
	--smua.measure.filter.count		= 5
	--smua.measure.filter.enable		= smua.FILTER_ON

	-- This measure delay sets the delay between the measurement trigger being received
	-- and when the actual measurement(s) start.  This is set to 0 because we will be
	-- delaying the trigger itself and do not need additional delay.
	smua.measure.delay				= 0

	-- Setup the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode		= 1
	smua.nvbuffer1.collecttimestamps= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode		= 1
	smua.nvbuffer2.collecttimestamps= 1

	-- Configure the Trigger Model
	--============================

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= (numPulses > 1) and numPulses - 1 or 1
	trigger.timer[1].delay			= pulsePeriod
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	if (type(pulseWidth) == "table") then
		-- Use a delay list if the duty cycle will vary for each pulse
		trigger.timer[2].delaylist	= pulseWidth
	else
		-- else every pulse will be the same duty cycle
		trigger.timer[2].delay		= pulseWidth
	end
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= smua.trigger.SOURCE_COMPLETE_EVENT_ID

	-- Timer 3 controls the measurement delay
	trigger.timer[3].count			= 1
	if (type(measDelay) == "table") then
		-- If the duty cycle is variable then the measure delay will be as well
		trigger.timer[3].delaylist	= measDelay
	else
		trigger.timer[3].delay		= measDelay
	end
	trigger.timer[3].passthrough	= false
	trigger.timer[3].stimulus		= smua.trigger.SOURCE_COMPLETE_EVENT_ID

	-- TSP-Link Trigger 1 is used to synchronize the SMUs by telling
	-- the second SMU when to pulse.
	tsplink.trigger[1].clear()
	tsplink.trigger[1].mode			= tsplink.TRIG_FALLING
	tsplink.trigger[1].stimulus		= trigger.timer[1].EVENT_ID
	
	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.lineari(pulseLevel/2, pulseLevel/2, numPulses)
	smua.trigger.source.limitv		= pulseLimit
	smua.trigger.measure.action		= smua.ASYNC
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= numPulses
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= trigger.timer[3].EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE
end

function ConfigureRemoteSMU(pulseLevel, pulseLimit, pulsePeriod, pulseWidth, measDelay, numPulses)
	node[2].smua.reset()
	node[2].smua.source.func				= node[2].smua.OUTPUT_DCAMPS
	node[2].smua.sense						= node[2].smua.SENSE_REMOTE
	node[2].smua.source.autorangei			= 0
	node[2].smua.source.rangei				= pulseLevel/2
	node[2].smua.source.leveli				= 0
	-- Set the DC bias limit.  This is not the limit used during the pulses.
	node[2].smua.source.limitv				= 1
	node[2].smua.source.offmode				= node[2].smua.OUTPUT_NORMAL
	node[2].smua.source.offfunc				= node[2].smua.OUTPUT_DCAMPS
	node[2].smua.source.offlimitv			= 40
	
	node[2].smua.measure.autozero			= node[2].smua.AUTOZERO_ONCE
	node[2].smua.measure.autorangev			= 0
	node[2].smua.measure.rangev				= pulseLimit
	-- The fast ADC allows us to place the measurements very close to the falling edge of
	-- the pulse allowing for settled measurements even when pulse widths are very small
	node[2].smua.measure.adc				= node[2].smua.ADC_FAST
	node[2].smua.measure.count				= 1
	node[2].smua.measure.interval			= 1e-6
	-- Uncomment the following lines to turn on measure filtering.  When enabled, the SMU
	-- will take multiple measurements and average them to produce a single reading.
	-- Because the Fast ADC can take one measurement every microsecond, several measurements
	-- can be aquired in a small time to produce an averaged reading.
	--node[2].smua.measure.filter.count		= 5
	--node[2].smua.measure.filter.enable		= node[2].smua.FILTER_ON

	-- This measure delay sets the delay between the measurement trigger being received
	-- and when the actual measurement(s) start.  This is set to 0 because we will be
	-- delaying the trigger itself and do not need additional delay.
	node[2].smua.measure.delay				= 0

	-- Setup the Reading Buffers
	node[2].smua.nvbuffer1.clear()
	node[2].smua.nvbuffer1.appendmode		= 1
	node[2].smua.nvbuffer1.collecttimestamps= 1
	node[2].smua.nvbuffer2.clear()
	node[2].smua.nvbuffer2.appendmode		= 1
	node[2].smua.nvbuffer2.collecttimestamps= 1

	-- Configure the Trigger Model
	--============================

	-- Timer 2 controls the pulse width
	node[2].trigger.timer[2].count			= 1
	if (type(pulseWidth) == "table") then
		-- Use a delay list if the duty cycle will vary for each pulse
		node[2].trigger.timer[2].delaylist	= pulseWidth
	else
		-- else every pulse will be the same duty cycle
		node[2].trigger.timer[2].delay		= pulseWidth
	end
	node[2].trigger.timer[2].passthrough	= false
	node[2].trigger.timer[2].stimulus		= node[2].smua.trigger.SOURCE_COMPLETE_EVENT_ID

	-- Timer 3 controls the measurement delay
	node[2].trigger.timer[3].count			= 1
	if (type(measDelay) == "table") then
		-- If the duty cycle is variable then the measure delay will be as well
		node[2].trigger.timer[3].delaylist	= measDelay
	else
		node[2].trigger.timer[3].delay		= measDelay
	end
	node[2].trigger.timer[3].passthrough	= false
	node[2].trigger.timer[3].stimulus		= node[2].smua.trigger.SOURCE_COMPLETE_EVENT_ID

	-- TSP-Link Trigger 1 is used to synchronize the SMUs.  SMU #2 receives
	-- its trigger to pulse from SMU #1
	node[2].tsplink.trigger[1].clear()
	node[2].tsplink.trigger[1].mode			= node[2].tsplink.TRIG_FALLING
	-- Release the trigger line when the pulse is complete
	node[2].tsplink.trigger[1].stimulus		= 0

	-- Configure SMU Trigger Model for Sweep
	node[2].smua.trigger.source.lineari(pulseLevel/2, pulseLevel/2, numPulses)
	node[2].smua.trigger.source.limitv		= pulseLimit
	node[2].smua.trigger.measure.action		= node[2].smua.ASYNC
	node[2].smua.trigger.measure.iv(node[2].smua.nvbuffer1, node[2].smua.nvbuffer2)
	node[2].smua.trigger.endpulse.action	= node[2].smua.SOURCE_IDLE
	node[2].smua.trigger.endsweep.action	= node[2].smua.SOURCE_IDLE
	node[2].smua.trigger.count				= numPulses
	node[2].smua.trigger.arm.stimulus		= 0
	node[2].smua.trigger.source.stimulus	= node[2].tsplink.trigger[1].EVENT_ID
	node[2].smua.trigger.measure.stimulus	= node[2].trigger.timer[3].EVENT_ID
	node[2].smua.trigger.endpulse.stimulus	= node[2].trigger.timer[2].EVENT_ID
	node[2].smua.trigger.source.action		= node[2].smua.ENABLE
end

function ConfigureSpectrometerTrigger(specDelay)
	-- Digital I/O line 1 triggers the spectrometer measurements
	-- Timer 4 puts a delay between the start of the pulse train and the
	-- output of the digital IO trigger on Digital I/O line 1
	digio.trigger[1].clear()
	digio.trigger[1].mode		= digio.TRIG_FALLING

	-- If the delay value is > 0 then configure a timer to provide the delay
	if specDelay > 0 then
		trigger.timer[4].count			= 1
		trigger.timer[4].delay			= specDelay
		trigger.timer[4].passthrough	= false
		trigger.timer[4].stimulus		= smua.trigger.ARMED_EVENT_ID

		digio.trigger[1].stimulus		= trigger.timer[4].EVENT_ID
	else
		-- Else bypass the timer and trigger the digital I/O immediately
		-- Configure the Digital I/O pin that will trigger the spectrometer
		digio.trigger[1].stimulus		= smua.trigger.ARMED_EVENT_ID
	end
end

function CheckForOverRun(pNode)
	-- Check SMUA Trigger Overruns
	if (bit.bitand(pNode.status.operation.instrument.smua.trigger_overrun.condition, 2) == 2) then
		return true, "smua arm trigger is overrun"
	end
	if (bit.bitand(pNode.status.operation.instrument.smua.trigger_overrun.condition, 4) == 4) then
		return true, "smua source trigger is overrun"
	end
	if (bit.bitand(pNode.status.operation.instrument.smua.trigger_overrun.condition, 8) == 8) then
		return true, "smua measure trigger is overrun"
	end
	if (bit.bitand(pNode.status.operation.instrument.smua.trigger_overrun.condition, 16) == 16) then
		return true, "smua endpulse trigger is overrun"
	end

	local CFORi = 0
	-- Check Timers for Overrun
	if (pNode.status.operation.instrument.trigger_timer.trigger_overrun.condition > 0) then
		return true, string.format("Timer trigger is overrun: 0x%x", CFORi)
	end
	
	-- Check Blenders for Overrun
	if (pNode.status.operation.instrument.trigger_blender.trigger_overrun.condition > 0) then
		return true, string.format("blender trigger is overrun: 0x%x", CFORi)
	end

	-- Check TSP-Link Triggers for Overrun
	if (pNode.status.operation.instrument.tsplink.trigger_overrun.condition > 0) then
		return true, string.format("TSP-Link trigger is overrun: 0x%x", CFORi)
	end

	-- Check DIGIO Triggers for Overrun
	if (pNode.status.operation.instrument.digio.trigger_overrun.condition > 0) then
		return true, string.format("digio trigger is overrun: 0x%x", CFORi)
	end

	-- Check LAN Triggers for Overrun
	if (pNode.status.operation.instrument.lan.trigger_overrun.condition > 0) then
		return true, string.format("LAN trigger is overrun: 0x%x", CFORi)
	end

	return false, "no overrun detected"
end

function PrintData()
	print("Timestamp\tVoltage\tCurrent")
	for i=1,smua.nvbuffer1.n do
		print(smua.nvbuffer1.timestamps[i], smua.nvbuffer2[i], smua.nvbuffer1[i])
	end
end

function PrintDataDual()
	local voltage
	local current
	print("Timestamp\tVoltage\tCurrent")
	for i=1,smua.nvbuffer1.n do
		voltage = (smua.nvbuffer2[i] + node[2].smua.nvbuffer2[i])/2
		current = smua.nvbuffer1[i] + node[2].smua.nvbuffer1[i]
		print(smua.nvbuffer1.timestamps[i], voltage, current)
	end
end

function CalculateTiming(frequency, dutyCycle)
	local pulsePeriod				= 1/frequency
	local pulseWidth
	local measDelay

	-- If duty cycle was a table then we need to create delay lists for the timers
	if (type(dutyCycle)=="table") then
		pulseWidth	= {}
		measDelay	= {}
		for i=1,table.getn(dutyCycle) do
			if ((dutyCycle[i] > 99) or (dutyCycle[i] < 0.01)) then
				print(string.format("Error: dutyCycle[%d] must be between 0.01% and 99%.", i))
				exit()
			end
			-- Calculate pulse width from period and duty cycle.  Subtract 3us of overhead
			pulseWidth[i]	= pulsePeriod  * (dutyCycle[i]/100) - 3e-6
			-- Set measure delay so measurement happen 10us before the falling edge of the pulse
			measDelay[i]	= pulseWidth[i] - 10e-6 
		end
	else	-- Duty cycle was a single value so we only need a single delay value for the timers
		if ((dutyCycle > 99) or (dutyCycle < 0.01)) then
			print("Error: dutyCycle must be between 0.01% and 99%.")
			exit()
		end
		pulseWidth			= pulsePeriod  * (dutyCycle/100) - 3e-6
		measDelay			= pulseWidth - 10e-6
	end
	return pulsePeriod, pulseWidth, measDelay
end

function SimpleRegionCheck(pulseLevel, pulseLimit, dutyCycle, SMUs)
	-- This function only serves as a quick check that the entered parameters are
	-- within the max allowable duty cycles for the operating regions.  This function
	-- does not check that the pulse widths are within the maximums as well.

	local pLev = math.abs(pulseLevel)
	f = true
	msg = "Checks passed."
	if ((pulseLimit >= 10e-3) and (pulseLimit <= 10)) then
		if ((pLev > 30*SMUs) and (dutyCycle > 35)) then
			msg = string.format("Duty Cycle too high for pulse region 5.  Duty cycle must be 35%% or less for pulse levels above %dA.", 30*SMUs)
			f = false
		elseif (((pLev > 20*SMUs) and (pLev <= 30*SMUs)) and (dutyCycle > 50)) then
			msg = string.format("Duty Cycle too high for pulse region 2.  Duty cycle must be 50%% or less for pulse levels between %dA and %dA.", 20*SMUs, 30*SMUs)
			f = false
		end
	elseif ((pulseLimit > 10) and (pulseLimit <= 20)) then
		if ((pLev > 20*SMUs) and (dutyCycle > 10)) then
			msg = string.format("Duty Cycle too high for pulse region 6.  Duty cycle must be 10%% or less for pulse levels above %dA.", 20*SMUs)
			f = false
		elseif (((pLev > 10*SMUs) and (pLev <= 20*SMUs)) and (dutyCycle > 40)) then
			msg = string.format("Duty Cycle too high for pulse region 3.  Duty cycle must be 40%% or less for pulse levels between %dA and %dA.", 10*SMUs, 20*SMUs)
			f = false
		end
	elseif (pulseLimit > 20) and (pulseLimit <= 40) then
		if ((pLev > 10*SMUs) and (dutyCycle > 1)) then
			msg = string.format("Duty Cycle too high for pulse region 7.  Duty cycle must be 1%% or less for pulse levels above %dA.", 10*SMUs)
			f = false
		elseif (((pLev > 5*SMUs) and (pLev <= 10*SMUs)) and (dutyCycle > 40)) then
			msg = string.format("Duty Cycle too high for pulse region 4.  Duty cycle must be 40%% or less for pulse levels between %dA and %dA.", 5*SMUs, 10*SMUs)
			f = false
		end
	else
		msg = "Error: pulseLimit out of range.  pulseLimit must be between 10mV and 40V."
		f = false
	end

	return f,msg
end


--PWM_Test_Single(1, 2, 100, 1, 10, 0)
-- duty = {20, 40, 60, 80, 60, 40, 20, 40, 60}
--PWM_Test_Single(20, 10, 1000, duty, 9, 1e-3)
--PWM_Test_Dual(40, 10, 1000, duty, 9, 1e-3)