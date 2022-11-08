--[[
 Generate a voltage pulse by toggling between two source levels.

 Use source configuration list to define the two source values, ranges, etc.
 Use a measure config list to influence measure related settings.

 use timer object and trigger blocks to load the configuration list at the desired time intervals.
 The timer will use delay list of two values to provide PW and Duty Cycle control.

 Important Sequence of Code: building the source config list
 first load the pulse on or pulse high value
 second load the pulse off or pulse low value = quiescent value

 When source is turned on (blue light) the settings from last defined source config
 list entry will be applied (unless we add code to change this logic).


 Tested with: KEITHLEY INSTRUMENTS,MODEL 2461,04110442,1.7.12b
			  KEITHLEY INSTRUMENTS,MODEL 2450,04451269,1.7.7b
 Tested with: 1Kohm resistor - 2Wire connections

 With a SMU current measurement: fastest pulse is ~4msec  -- TODO verify this
 With SMU source only, no measure: fastest pulse is ~ 750usec   -- TODO verify this


]]--
-- create source config list for the current pulse and voltage limits
function createSourceConfigList(ConfigListNameSrc, vrange, pulseLevel, pulseLimit)
	smu.source.configlist.create(ConfigListNameSrc)
	--Set the source to output current.
	smu.source.func = smu.FUNC_DC_VOLTAGE
	smu.source.readback = smu.OFF
	smu.source.autodelay = smu.OFF
	smu.source.range = vrange
	smu.source.level = pulseLevel
	smu.source.ilimit.level = pulseLimit
	smu.source.configlist.store(ConfigListNameSrc)
end -- function

function appendSourceConfigList(ConfigListNameSrc, pulseLevel, pulseLimit)
	smu.source.level = pulseLevel
	smu.source.ilimit.level = pulseLimit
	smu.source.configlist.store(ConfigListNameSrc)
end -- function

function createMeasureConfigList(ConfigListNameMeas, measRange)

	smu.measure.configlist.create(ConfigListNameMeas)
	
	smu.measure.func = smu.FUNC_DC_CURRENT
	smu.measure.nplc = 0.01   -- setting this to minimum value
	smu.measure.sense = smu.SENSE_2WIRE
	smu.measure.range = measRange
	smu.measure.autorange = smu.OFF
	smu.measure.autozero.enable = smu.OFF

	smu.measure.configlist.store(ConfigListNameMeas)
end -- function

function load_trigger_blocks(NumPulses, ConfigListNameSrc, ConfigListNameMeas)

	trigger.model.load("Empty") --load an empty trigger model as to clear all trigger model blocks
	
	-- set this up to wait for the timer to know when to load the src config list value
	-- measure only after the ton part
	blockNumber = 1
	trigger.model.setblock(blockNumber, trigger.BLOCK_BUFFER_CLEAR)
	blockNumber = blockNumber + 1
	trigger.model.setblock(blockNumber, trigger.BLOCK_SOURCE_OUTPUT, smu.ON)
	-- SMU src value is from last configured src level will be applied
	blockNumber = blockNumber + 1
	trigger.model.setblock(blockNumber, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1) -- starts timer1
	blockNumber = blockNumber + 1
	branchBackToHere = blockNumber
	trigger.model.setblock(blockNumber, trigger.BLOCK_WAIT, trigger.EVENT_TIMER1)
	-- ton source level
	blockNumber = blockNumber + 1
	trigger.model.setblock(blockNumber, trigger.BLOCK_CONFIG_NEXT, ConfigListNameSrc,
	ConfigListNameMeas)
	blockNumber = blockNumber + 1
	trigger.model.setblock(blockNumber, trigger.BLOCK_MEASURE, defbuffer1, 1)
	-- wait for the toff signal from timer
	blockNumber = blockNumber + 1
	trigger.model.setblock(blockNumber, trigger.BLOCK_WAIT, trigger.EVENT_TIMER1)
	-- toff source level
	blockNumber = blockNumber + 1
	trigger.model.setblock(blockNumber, trigger.BLOCK_CONFIG_NEXT, ConfigListNameSrc,
	ConfigListNameMeas)
	-- if number of pulses not yet achieved, branch back
	blockNumber = blockNumber + 1
	trigger.model.setblock(blockNumber, trigger.BLOCK_BRANCH_COUNTER, NumPulses, branchBackToHere)
	blockNumber = blockNumber + 1
	trigger.model.setblock(blockNumber, trigger.BLOCK_DELAY_CONSTANT, 10e-3)
	blockNumber = blockNumber + 1
	trigger.model.setblock(blockNumber, trigger.BLOCK_SOURCE_OUTPUT, smu.OFF)
	
end -- function

function config_timer_and_digio(NumPulses, toff, ton)
	-- setup a timer
	trigger.timer[1].enable = 0
	trigger.timer[1].reset()
	trigger.timer[1].clear()
	trigger.timer[1].delaylist = {toff, ton} -- durations
	-- period = toff + ton
	trigger.timer[1].count = NumPulses * 2 -- two strobes per pulse
	trigger.timer[1].start.stimulus = trigger.EVENT_NOTIFY1 -- raised by our trigger blocks
	trigger.timer[1].start.generate = trigger.OFF
	trigger.timer[1].enable = 1
	
	-- optionally setup digital IO to give us a timing mark
	--setup digital output to strobe for each timer "tic"
	digio.line[1].mode = digio.MODE_TRIGGER_OUT
	trigger.digout[1].pulsewidth = 10e-6
	trigger.digout[1].stimulus = trigger.EVENT_TIMER1
	
end -- function


-- **************** Pseudo Code Below to use our Functions******************
reset()
errorqueue.clear()
PulseCount = 4
PulseWidth = 5e-3
PulsePeriod = 20e-3
voltageRange = 20
pulseHeight = 5
pulseOffLevel = 0
CurrentLimit = 0.1


--config_timer_and_digio(NumPulses, toff, ton)
config_timer_and_digio(PulseCount, (PulsePeriod - PulseWidth ), PulseWidth)

--createSourceConfigList(ConfigListNameSrc, vrange, pulseLevel, pulseLimit)
createSourceConfigList("mySrcList", voltageRange, pulseHeight, CurrentLimit) -- ton value
--appendSourceConfigList(ConfigListNameSrc, pulseLevel, pulseLimit)
appendSourceConfigList("mySrcList", pulseOffLevel, CurrentLimit) -- toff value
-- since last loaded, it will be the sourced value when blue light is turned on

--createMeasureConfigList(ConfigListNameMeas, measRange)
createMeasureConfigList("myMeasList", CurrentLimit)

--load_trigger_blocks(NumPulses, ConfigListNameSrc, ConfigListNameMeas)
load_trigger_blocks(PulseCount, "mySrcList", "myMeasList")


-- to run the configured test

-- optional refresh of auto zero offsets
smu.measure.autozero.once()


trigger.model.initiate()
waitcomplete() -- if calling from Python and using *OPC? or SRQ, don't use this line; it blocks

print_data = true
if print_data then
	printbuffer(1, defbuffer1.n, defbuffer1.readings, defbuffer1.sourcevalues)
end -- if

print_data_again = true
if print_data_again then
  print()
  for i = 1, defbuffer1.n do
 	print(i..","..defbuffer1.readings[i])
  end -- for loop
end -- if