--[[
 Generates a single voltage pulse and measures current during the pulse.
 This script is designed for instruments that do not have a dedicated pulse mode
 i.e. NOT the 2461 SMU. 

 Pulsing should always be done with the trigger model, use this script
 as a starting point for your work.

 Tested with: KEITHLEY INSTRUMENTS,MODEL 2450,04451269,1.7.7b
 Tested with: 1Kohm resistor - 2Wire connections

 With 2450 and current measurement: pulse is ~ 1.6msec
 With 2450 source only, no measure: pulse is ~ 1.2msec
]]--

reset()
errorqueue.clear()

-- Source Settings
smu.source.func = smu.FUNC_DC_VOLTAGE
smu.source.readback = smu.OFF
smu.source.autodelay = smu.OFF
smu.source.range = 20
smu.source.ilimit.level = 1
smu.source.level = 1
smu.source.delay = 0

-- Measure Settings
smu.measure.func = smu.FUNC_DC_CURRENT
smu.measure.autorange = smu.OFF
smu.measure.autozero.enable = smu.OFF
-- smu.measure.autozero.once() -- Perform this immediately before testing begins as a best practice
smu.measure.nplc = 0.01 -- 1 nplc = 16.67ms at 60Hz, so 0.01 = 0.167ms/167us = minimum nplc
smu.measure.range = 1
smu.measure.sense = smu.SENSE_2WIRE

-- Perform pulse
smu.measure.autozero.once()
trigger.model.load("Empty")
trigger.model.setblock(1, trigger.BLOCK_BUFFER_CLEAR)
trigger.model.setblock(2, trigger.BLOCK_SOURCE_OUTPUT, smu.ON)
trigger.model.setblock(3, trigger.BLOCK_MEASURE_DIGITIZE, defbuffer1, 1) -- Remove this block for a faster pulse, but without a measurement
trigger.model.setblock(4, trigger.BLOCK_SOURCE_OUTPUT, smu.OFF)
trigger.model.initiate()
waitcomplete()

-- Print results 
printbuffer(1, defbuffer1.n, defbuffer1.sourcevalues, defbuffer1.readings)