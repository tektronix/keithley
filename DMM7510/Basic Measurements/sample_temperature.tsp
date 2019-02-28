--[[

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This sequence of TSP commands makes a 1440 temperature measurements 60s apart, i.e. one reading a 
    minute for one day.

After the code executes, the data is displayed in the Instrument Console of Test Script Builder.

]]

-- Reset the instrument to the default settings
reset()
-- Establish variables to make a measurement every 60 seconds 1440 times (24 hours)
MeasCount = 1440
MeasInterval = 60
-- Set to measure temperature
dmm.measure.func = dmm.FUNC_TEMPERATURE
-- Configure to measure 4-wire RTD
dmm.measure.transducer = dmm.TRANS_FOURRTD
-- Enable the detection of open leads
dmm.measure.opendetector = dmm.ON
-- Select 4-wire RTD type to be a PT100 sensor
dmm.measure.fourrtd = dmm.RTD_PT100
-- Set the number of power line cycles to 1
dmm.measure.nplc = 1
-- Enable offset compensation for more accurate readings
dmm.measure.offsetcompensation.enable = dmm.ON
-- Display the GRAPH swipe screen
display.changescreen(display.SCREEN_GRAPH_SWIPE)
-- Set up timer 1
trigger.timer[1].reset()
-- Timer delays each time the timer is triggered
trigger.timer[1].delay = MeasInterval
-- Set the notify 1 event to trigger the start of timer
trigger.timer[1].start.stimulus = trigger.EVENT_NOTIFY1
-- Generate the timer event once when the timer delay elapses
trigger.timer[1].start.generate = trigger.OFF
-- Enable the timer to perform delay operation
trigger.timer[1].enable = trigger.ON
-- Wait for TRIGGER key press from front panel to start trigger model
trigger.model.setblock(1, trigger.BLOCK_WAIT, trigger.EVENT_DISPLAY)
-- Send notify to start the timer
trigger.model.setblock(2, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1)
-- Make a measurement and store the reading in default buffer
trigger.model.setblock(3, trigger.BLOCK_MEASURE, defbuffer1)
-- Wait for timer delay to elapse
trigger.model.setblock(4, trigger.BLOCK_WAIT, trigger.EVENT_TIMER1)
-- Go to block 2 for the number of times set by MeasCount
trigger.model.setblock(5, trigger.BLOCK_BRANCH_COUNTER, MeasCount, 2)
-- Initiate trigger model and wait until finished
trigger.model.initiate()
display.clear()
-- Display a message on the USER swipe screen to indicate test in progress
display.settext(display.TEXT1, "Test in progress...")
waitcomplete()
-- Display a message on the user swipe screen to indicate test completion
display.clear()
display.settext(display.TEXT1, "Test complete.")
-- Print the temperature readings and the corresponding timestamps
printbuffer(1,defbuffer1.n,defbuffer1)
printbuffer(1,defbuffer1.n,defbuffer1.relativetimestamps)