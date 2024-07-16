--[[This particular example shows how to generate a current pulse train.
In particular, this code generates 10 pulses with a magnitude of 6 A and a pulse width
of 1 ms.  The pulse period is 4 ms and the load that is used is 1 ohm.  More information
about this tsp code can be found in the View This First document.
]]

reset()

--[[Set Up Pulse parameters
            *biaslevel: the offset current for the pulse train
            *pulselevel: the amplitude current of each pulse (from zero, not bias level)
            *biaswidth: the time at the bias level
            *pulsewidth: the time at amplitude level for each pulse
            *points: total number of pulses
            *limit: the source limit level
]]

--User specified test parameters:
local biaslevel = 0
local pulselevel = 6
local biaswidth = 3e-3
local pulsewidth = 1e-3
local period = pulsewidth + biaswidth
local points = 10
local limit = 7

--Set to current source and set up source config list
smu.source.configlist.create("OutputList")
smu.source.func = smu.FUNC_DC_CURRENT
smu.source.readback = smu.OFF

--Set up measure commands
smu.measure.func = smu.FUNC_DC_VOLTAGE
smu.measure.nplc = 0.01       
smu.measure.autozero.once()

smu.measure.terminals = smu.TERMINALS_FRONT
smu.measure.range = limit
smu.measure.sense = smu.SENSE_4WIRE
    
local measuredelay = pulsewidth -((1/localnode.linefreq)*smu.measure.nplc + 450e-6)
if measuredelay < 50e-6 then measuredelay = 50e-6 end
      
-- Set the source range large enough to fit both the bias and level.
smu.source.range = math.max(math.abs(biaslevel), math.abs(pulselevel))
smu.source.delay = 0
smu.source.vlimit.level = limit

--Set to pulselevel (amplitude) and save to list
smu.source.level = pulselevel
smu.source.configlist.store("OutputList")

--Set to biaslevel and save to list
smu.source.level = biaslevel
smu.source.configlist.store("OutputList")

--Setup Timers
-- Use timer[1] to control the Period of the pulse train
trigger.timer[1].reset()
trigger.timer[1].start.generate = trigger.ON
trigger.timer[1].delay = period
trigger.timer[1].count = points - 1   -- Effective count will be points because trigger.timer[1].start.generate = trigger.ON

-- Use timer[2] to control the Pulse Width of the pulses
trigger.timer[2].reset()
trigger.timer[2].start.stimulus = trigger.EVENT_TIMER1
trigger.timer[2].start.generate = trigger.OFF
trigger.timer[2].delay = pulsewidth
trigger.timer[2].count = 1
trigger.timer[2].enable = trigger.ON

--Trigger model setup
trigger.model.setblock(1, trigger.BLOCK_BUFFER_CLEAR)
trigger.model.setblock(2, trigger.BLOCK_SOURCE_OUTPUT, smu.ON)
trigger.model.setblock(3, trigger.BLOCK_WAIT, trigger.EVENT_TIMER1)
trigger.model.setblock(4, trigger.BLOCK_CONFIG_RECALL, "OutputList")
trigger.model.setblock(5, trigger.BLOCK_DELAY_CONSTANT, measuredelay)
trigger.model.setblock(6, trigger.BLOCK_MEASURE_DIGITIZE)
trigger.model.setblock(7, trigger.BLOCK_WAIT, trigger.EVENT_TIMER2)
trigger.model.setblock(8, trigger.BLOCK_CONFIG_NEXT, "OutputList")
trigger.model.setblock(9, trigger.BLOCK_BRANCH_COUNTER, points, 3)
trigger.model.setblock(10, trigger.BLOCK_SOURCE_OUTPUT, smu.OFF)

--Start the trigger model
defbuffer1.clear()
trigger.model.initiate()
delay(0.001)
trigger.timer[1].enable = trigger.ON
waitcomplete()
