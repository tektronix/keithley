--[[

tested with:  KEITHLEY INSTRUMENTS,MODEL 2461,04110442,1.7.1e

Purpose:  apply current pulse from 2461, delay xx usec, digitize I and V for 100usec, pulse off.
          from buffer stats, get average v.
          compute average sourced current from sourcevalues buffer elements
          compute R from avg(V)/avg(I) 

]]


--Reset the instrument
reset()
eventlog.clear()
trigger.model.load("Empty")


     --setup digital output
     digio.line[1].mode = digio.MODE_TRIGGER_OUT
     trigger.digout[1].pulsewidth = 10e-6
     trigger.digout[1].stimulus   = trigger.EVENT_NOTIFY2
     -- end setup digital output


-- create source config list for the current pulse and voltage limits
ConfigListNameSrc = "myPulseSrc"
smu.source.configlist.create(ConfigListNameSrc)

--Set the source to output current.
smu.source.func = smu.FUNC_DC_CURRENT
smu.source.readback = smu.ON        -- dual digitizers, so measure the current too
smu.source.range = 10
smu.source.level = 0
smu.source.vlimit.level = 1
smu.source.pulse.level = 10 
smu.source.pulse.vlimit.level = 2  -- voltage limit during the pulse

smu.source.configlist.store(ConfigListNameSrc)


-- create a measure config list
ConfigListNameMeas = "myPulseMeas"
smu.measure.configlist.create(ConfigListNameMeas)

--Set up the measure functions.
smu.digitize.func = smu.FUNC_DIGITIZE_VOLTAGE
smu.digitize.sense = smu.SENSE_4WIRE
smu.digitize.range = 2
smu.digitize.samplerate = 1e6
smu.digitize.aperture = smu.APERTURE_AUTO
defbuffer1.capacity = 100000  -- does not have to match the smaller acquistion we are doing

smu.measure.configlist.store(ConfigListNameMeas)

-- some vars
debug = 1
-- enter your desired measure duration;  number of samples (measCount) will be computed based on the sample rate in effect.
measDuration = 100e-6
measCount = measDuration * smu.digitize.samplerate
measDelay = 400e-6
-- pulse width will be measDelay + measDuration
if debug then print("Pulse Width: "..measDelay + measDuration) end


-- Timer for the measure delay
local N = 1
trigger.timer[N].enable = 0
trigger.timer[N].reset()
trigger.timer[N].clear()
trigger.timer[N].enable = 1
trigger.timer[N].delay = measDelay

trigger.timer[N].count = 1
trigger.timer[N].start.stimulus = trigger.EVENT_NOTIFY1
trigger.timer[N].start.generate = trigger.OFF  -- first tic only after timer elapses


-- program the trigger blocks
blockNumber = 1
trigger.model.setblock(blockNumber, trigger.BLOCK_BUFFER_CLEAR)

blockNumber = blockNumber + 1
trigger.model.setblock(blockNumber, trigger.BLOCK_SOURCE_OUTPUT, smu.ON)

blockNumber = blockNumber + 1
trigger.model.setblock(blockNumber, trigger.BLOCK_CONFIG_RECALL, ConfigListNameSrc, 1, ConfigListNameMeas, 1)

blockNumber = blockNumber + 1
trigger.model.setblock(blockNumber, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1)  -- starts timer1

blockNumber = blockNumber + 1
trigger.model.setblock(blockNumber, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY2)  -- strobe the digital output

blockNumber = blockNumber + 1
trigger.model.setblock(blockNumber, trigger.BLOCK_SOURCE_PULSE_OUTPUT, smu.ON)  -- start 10Amp pulse

blockNumber = blockNumber + 1
trigger.model.setblock(blockNumber, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY2)  -- strobe the digital output

blockNumber = blockNumber + 1  
trigger.model.setblock(blockNumber, trigger.BLOCK_WAIT, trigger.EVENT_TIMER1)  -- wait for measure delay

blockNumber = blockNumber + 1
trigger.model.setblock(blockNumber, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY2)  -- strobe the digital output

blockNumber = blockNumber + 1
trigger.model.setblock(blockNumber, trigger.BLOCK_MEASURE, defbuffer1, measCount)  -- 100 readings at 1MSample/sec

blockNumber = blockNumber + 1
trigger.model.setblock(blockNumber, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY2)  -- strobe the digital output
                    
blockNumber = blockNumber + 1                                          
trigger.model.setblock(blockNumber, trigger.BLOCK_SOURCE_PULSE_OUTPUT, smu.OFF)  --stop 10Amp pulse

blockNumber = blockNumber + 1
trigger.model.setblock(blockNumber, trigger.BLOCK_SOURCE_OUTPUT, smu.OFF)


---Initiate trigger model and wait until finished.
trigger.model.initiate()
waitcomplete()

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
display.settext(display.TEXT1, "Rds(ON):  "..string.format("%.5f",statsVar.mean/avg_src_val))
display.settext(display.TEXT2, "Avg Src Current: "..string.format("%.5f",avg_src_val))

if debug then
  print("Rds(ON):  "..string.format("%.5f",statsVar.mean/avg_src_val))
  print("Avg V:  "..string.format("%.5f",statsVar.mean))
  print("Avg I:  "..string.format("%.5f",avg_src_val))
end