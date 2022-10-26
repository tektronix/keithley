--[[

***********************************************************
*** Copyright 2020 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************


tested with:  KEITHLEY INSTRUMENTS,MODEL 2461,04110442,1.7.1e

Purpose:  apply current pulse from 2461, delay xx usec, digitize I and V for 100usec, pulse off.
          from buffer stats, get average v.
          Option to repeat N times (RepeatCount)
          compute average sourced current from sourcevalues buffer elements
          compute R from avg(V)/avg(I) 
          
          2461 10Amp Pulsing has pulse width and duty cycle limits enforced by firmware:
             max PW using 10Amp range = 1msec
             max Duty Cycle for 10Amp range and compliance of 20V or less = 10%
             max Duty Cycel for 10Amp range and compliance >20V = 5%
             
             At lower currents/watts, different timing is possible.

]]



function config_digital_line()

	     --setup digital output to strobe when NOTIFY2 event occurs
	     digio.line[1].mode = digio.MODE_TRIGGER_OUT
	     trigger.digout[1].pulsewidth = 10e-6
	     trigger.digout[1].stimulus   = trigger.EVENT_NOTIFY2
	    
end   -- function


-- create source config list for the current pulse and voltage limits
function createSourceConfigList(ConfigListNameSrc, irange, pulseLevel, pulseLimit)
		smu.source.configlist.create(ConfigListNameSrc)
		
		--Set the source to output current.
		smu.source.func = smu.FUNC_DC_CURRENT
		smu.source.readback = smu.ON        -- dual digitizers, so measure the current too
		smu.source.range = irange
		smu.source.level = 0
		smu.source.vlimit.level = 1
		smu.source.pulse.level = pulseLevel
		smu.source.pulse.vlimit.level = pulseLimit  -- voltage limit during the pulse
		
		smu.source.configlist.store(ConfigListNameSrc)

end  -- function

function appendSourceConfigList(ConfigListNameSrc, pulseLevel, pulseLimit)

		smu.source.pulse.level = pulseLevel
		smu.source.pulse.vlimit.level = pulseLimit  -- voltage limit during the pulse
		smu.source.configlist.store(ConfigListNameSrc)
		
end  -- function



-- create a measure config list
function createMeasureConfigList(ConfigListNameMeas, vrange, sampleRate)

		smu.measure.configlist.create(ConfigListNameMeas)
		
		--Set up the measure functions.
		smu.digitize.func = smu.FUNC_DIGITIZE_VOLTAGE
		smu.digitize.sense = smu.SENSE_4WIRE
		smu.digitize.range = vrange
		smu.digitize.samplerate = sampleRate
		smu.digitize.aperture = smu.APERTURE_AUTO
		defbuffer1.capacity = 100000  -- does not have to match the smaller acquistion we are doing
		
		smu.measure.configlist.store(ConfigListNameMeas)

end  -- function


function config_pulse_timers(pulsePeriodTime, NumPulses, measDelayTime, pulseWidthTime)

		-- ***********************   CONFIG TIMERS *************************
		
		-- for single pulse, this one not so important
		-- but for multiple pulses, this timer will
		-- manage the duty cycle
		pulsePeriod = trigger.timer[1]
		pulsePeriod.enable = 0
		pulsePeriod.reset()
		pulsePeriod.clear()
		pulsePeriod.enable = 1
		pulsePeriod.delay = pulsePeriodTime
		
		pulsePeriod.count = NumPulses   -- or how many entries in the source config list
		pulsePeriod.start.stimulus = trigger.EVENT_NOTIFY1  -- raised by our trigger blocks
		pulsePeriod.start.generate = trigger.OFF
		
		
		-- Timer for the measure delay
		measDelay = trigger.timer[2]
		measDelay.enable = 0
		measDelay.reset()
		measDelay.clear()
		measDelay.enable = 1
		measDelay.delay = measDelayTime
		
		measDelay.count = 1
		measDelay.start.stimulus = trigger.EVENT_TIMER1  -- pulseperiod timer
		measDelay.start.generate = trigger.OFF  -- first tic only after timer elapses
		
		
		
		-- control when pulse output turns off
		pulseWidth = trigger.timer[3]
		pulseWidth.enable = 0
		pulseWidth.reset()
		pulseWidth.clear()
		pulseWidth.enable = 1
		pulseWidth.delay = pulseWidthTime
		
		pulseWidth.count = 1
		pulseWidth.start.stimulus = trigger.EVENT_TIMER1  -- pulseperiod timer
		pulseWidth.start.generate = trigger.OFF
		
		-- ***********************   END TIMERS *************************

end  -- function


function load_trigger_blocks(ConfigListNameSrc, ConfigListNameMeas, measCount, RepeatCount)

send_strobes = false

		blockNumber = 1
		trigger.model.setblock(blockNumber, trigger.BLOCK_BUFFER_CLEAR)
		
		blockNumber = blockNumber + 1
		trigger.model.setblock(blockNumber, trigger.BLOCK_SOURCE_OUTPUT, smu.ON)
		
		blockNumber = blockNumber + 1
		trigger.model.setblock(blockNumber, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1)  -- starts timer1, PW Timer
		
		blockNumber = blockNumber + 1
		branchBackToHere = blockNumber
		trigger.model.setblock(blockNumber, trigger.BLOCK_CONFIG_NEXT, ConfigListNameSrc, ConfigListNameMeas)
		
		blockNumber = blockNumber + 1  
		trigger.model.setblock(blockNumber, trigger.BLOCK_WAIT, trigger.EVENT_TIMER1)  -- wait for pulse period timer
		
		if send_strobes then
		blockNumber = blockNumber + 1
		trigger.model.setblock(blockNumber, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY2)  -- strobe the digital output
		end
		
		blockNumber = blockNumber + 1
		trigger.model.setblock(blockNumber, trigger.BLOCK_SOURCE_PULSE_OUTPUT, smu.ON)  -- start 10Amp pulse
		
		blockNumber = blockNumber + 1  
		trigger.model.setblock(blockNumber, trigger.BLOCK_WAIT, trigger.EVENT_TIMER2)  -- wait for measure delay
		
		if send_strobes then
		blockNumber = blockNumber + 1
		trigger.model.setblock(blockNumber, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY2)  -- strobe the digital output
		end
		
		blockNumber = blockNumber + 1
		trigger.model.setblock(blockNumber, trigger.BLOCK_MEASURE, defbuffer1, measCount)  -- 100 readings at 1MSample/sec
		
		if send_strobes then
		blockNumber = blockNumber + 1
		trigger.model.setblock(blockNumber, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY2)  -- strobe the digital output
		end
		
		blockNumber = blockNumber + 1  
		trigger.model.setblock(blockNumber, trigger.BLOCK_WAIT, trigger.EVENT_TIMER3)  -- wait for pulse width timer
		             
		blockNumber = blockNumber + 1                                          
		trigger.model.setblock(blockNumber, trigger.BLOCK_SOURCE_PULSE_OUTPUT, smu.OFF)  --stop 10Amp pulse
		
		if send_strobes then
		blockNumber = blockNumber + 1
		trigger.model.setblock(blockNumber, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY2)  -- strobe the digital output
		end
		
		blockNumber = blockNumber + 1
		trigger.model.setblock(blockNumber, trigger.BLOCK_BRANCH_COUNTER, RepeatCount, branchBackToHere)
		
		blockNumber = blockNumber + 1
		trigger.model.setblock(blockNumber, trigger.BLOCK_SOURCE_OUTPUT, smu.OFF)
		
		-- assert SRQ


end  -- function


function handle_data(debug_flag)

		statsVar = buffer.getstats(defbuffer1)
		
		-- compute mean source value
		-- we have source readback on
		src_val_sum = 0
		for i = 1, defbuffer1.n do
		   src_val_sum = src_val_sum + defbuffer1.sourcevalues[i]
		end  -- for loop
		avg_src_val = src_val_sum / defbuffer1.n
		
		
		
		display.clear()
		display.changescreen(display.SCREEN_USER_SWIPE)
		
		rds = string.format("%.5f",statsVar.mean/avg_src_val)
		display.settext(display.TEXT1, "Rds(ON):  "..rds)
		
		display.settext(display.TEXT2, "Avg Src Current: "..string.format("%.5f",avg_src_val))
		
		if debug_flag then
		  print("Rds(ON):  "..string.format("%.5f",statsVar.mean/avg_src_val))
		  print("Avg V:  "..string.format("%.5f",statsVar.mean))
		  print("Avg I:  "..string.format("%.5f",avg_src_val))
		end
		
		return rds

end  -- function


function config_test(pw, dutycycle, DesiredMeasTime, smu_digitize_rate, numPulses, pulseHeight, expectedR, debug)

-- compute params
local v_limit_during_pulse = (expectedR * pulseHeight) * 1.2  -- give 20% headroom on expected v

local srcRange = pulseHeight     -- what source range to use 10A, 7A, 5A, 4A, 1A, 100mA, etc.

-- compute other vars based on the entered values
local measCount = DesiredMeasTime * smu_digitize_rate
local pulsePeriodDuration = pw / (dutycycle / 100)   -- 10% duty cycle for 10Amp range and 20 or less vlimit
local overhead = 20e-6  -- TODO - do I need this?
local measDelayDuration = pw - DesiredMeasTime - overhead
if debug then 
        print("Meas Delay: "..measDelayDuration)
        print("Pulse Period: "..pulsePeriodDuration)
        print("Pulse Width: "..pw)
        print("number of source values: "..numPulses)
end


-- config smu
local ConfigListNameSrc = "myPulseSrc"
local ConfigListNameMeas = "myPulseMeas"

       -- config digital output to give us timing marks
       config_digital_line()
      
	   -- create config lists
	   --function createSourceConfigList(ConfigListNameSrc, irange, pulseLevel, pulseLimit)
	   createSourceConfigList(ConfigListNameSrc, srcRange, pulseHeight, v_limit_during_pulse)
	   
	   -- for future use in case the appendSourceConfigList is used for Pulsed Sweeps
	   -- how many entries are in our source config list = number of pulses
	   --RepeatCount = smu.source.configlist.size(ConfigListNameSrc)
	   
	   --function createMeasureConfigList(ConfigListNameMeas, vrange, sampleRate)
	   createMeasureConfigList(ConfigListNameMeas, v_limit_during_pulse, smu_digitize_rate)
	   
	   --function config_pulse_timers(pulsePeriodTime, NumPulses, measDelayTime, pulseWidthTime)
	   config_pulse_timers(pulsePeriodDuration, numPulses, measDelayDuration, pw)
	  
	   -- load trigger model
	   --function load_trigger_blocks(ConfigListNameSrc, ConfigListNameMeas, measCount, RepeatCount)
	   load_trigger_blocks(ConfigListNameSrc, ConfigListNameMeas, measCount, numPulses)



end  -- function

function run_test(debug_flag)

	---Initiate trigger model and wait until finished.
	trigger.model.initiate()
	waitcomplete()  -- comment this out and wait SRQ if calling from Python
	
	return handle_data(debug_flag)  -- return the Rds(ON) value

end  -- function


-- *****************************************************************
-- *****************       Main Program Below    *******************
-- *****************************************************************

local first_run = true

if first_run then
		  --Reset the instrument
		reset()
		eventlog.clear()
		status.clear()
		trigger.model.load("Empty")
		
end  -- if


-- *******  Enter some paramter values
local debug = true
--  *****************   Pulse Timing  ******************
--  enter your desired measure duration, pulse width and duty cycle
--  number of samples (measCount) will be computed based on the sample rate in effect.
local measDuration = 100e-6
local pulseWidthDuration = 540e-6
local DutyCyclePct = 10
local digitizeRate = 1e6
--  *********************  Pulse Analog info ***********
--  enter pulse analog info
--  ***************  Pulse Amplitude and Compliance Limits
local RepeatCount = 6  -- for signal averaging, Rds(ON) based on average of averages
local pulseHeight = 10  -- how many amps
local Max_Expected_R = 0.105   -- influence voltage measure range

-- call our config functions with the entered parameters
--function config_test(pw, dutycycle, DesiredMeasTime, smu_digitize_rate, numPulses, pulseHeight, expectedR, debug)
config_test(pulseWidthDuration, DutyCyclePct, 
            measDuration, digitizeRate, 
            RepeatCount, pulseHeight, Max_Expected_R, 
            debug)


print( run_test(debug) )
