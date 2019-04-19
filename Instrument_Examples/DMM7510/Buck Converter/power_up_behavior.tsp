--[[

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This example is from the DMM7510's User's Manual. Check there for more details on running this example.

This sequence of TSP commands analyzes the power up voltage behavior of a DC buck converter
    by configuring an analog trigger at 3V, rising slope, and digitizing voltage around the 
    trigger level.

]]

-- Reset the instrument to default settings
reset()
-- Create a local variable to store the number of samples
numofsamples = 10000
-- Set the measure function to digitize voltage to capture the power-up behavior
dmm.digitize.func = dmm.FUNC_DIGITIZE_VOLTAGE
-- Voltage range must be fixed when using digitize voltage
dmm.digitize.range = 10
-- Set the sample rate to 1 Msample per second to capture any small glitch
dmm.digitize.samplerate = 1e6
-- Set aperture to auto to get the highest accuracy measurement for the sampling rate configured
dmm.digitize.aperture = dmm.APERTURE_AUTO
-- Changing count is optional. The reading buffer capacity determines the actual count.
dmm.digitize.count = 1
-- Set the input impedance to auto so it selects 10 G for the 10 V range
dmm.digitize.inputimpedance = dmm.IMPEDANCE_AUTO
-- Set the buffer size to the number of samples to capture both pre and post triggered data
defbuffer1.capacity = numofsamples
-- Clear buffer
defbuffer1.clear()
-- Select analog edge trigger to capature the power-up behavior
dmm.digitize.analogtrigger.mode = dmm.MODE_EDGE
-- Set edge slope to detect a rising edge
dmm.digitize.analogtrigger.edge.slope = dmm.SLOPE_RISING
-- Set edge level trigger to 3 V for the 5 V steady-state output
dmm.digitize.analogtrigger.edge.level = 3
-- Change to the graph display
display.changescreen(display.SCREEN_GRAPH)
-- Define a trigger model that will capture 50% pre and 50% post triggered data
trigger.model.setblock(1,trigger.BLOCK_DIGITIZE, defbuffer1, trigger.COUNT_INFINITE)
trigger.model.setblock(2,trigger.BLOCK_WAIT, trigger.EVENT_ANALOGTRIGGER)
trigger.model.setblock(3,trigger.BLOCK_DIGITIZE, defbuffer1, numofsamples/2)
trigger.model.initiate()
-- Waits for the trigger model to finish collecting data before proceeding
waitcomplete()
print("test ended")