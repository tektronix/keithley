--[[

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This sequence of TSP commands will grade resistors into established bins of accuracy.

After the code executes, the data is displayed in the Instrument Console of Test Script Builder.

]]

-- Reset the instrument to default settings
reset()
-- Create a user-defined reading buffer that can store up to 1 million readings
bufferVar = buffer.make(1000000)
bufferVar.clear()
-- Set the measure function to 4-wire resistance
dmm.measure.func = dmm.FUNC_4W_RESISTANCE
-- Set the number of power line cycles 1 PLC
dmm.measure.nplc = 1
-- Immediately update autozero reference measurements and then disable the autozero function
dmm.measure.autozero.once()
-- Enable offset compensation for more accurate resistance reading
dmm.measure.offsetcompensation.enable = dmm.ON
-- Configure digital I/O lines 1 through 4 as digital outputs. These I/O lines are used to output binning code to component handler
digio.line[1].mode = digio.MODE_DIGITAL_OUT
digio.line[2].mode = digio.MODE_DIGITAL_OUT
digio.line[3].mode = digio.MODE_DIGITAL_OUT
digio.line[4].mode = digio.MODE_DIGITAL_OUT
-- Clear digital I/O lines to 0
digio.line[1].state = digio.STATE_LOW
digio.line[2].state = digio.STATE_LOW
digio.line[3].state = digio.STATE_LOW
digio.line[4].state = digio.STATE_LOW
-- Configure digital I/0 line 5 as a trigger input used to detect the start-of-test trigger from the component handler
digio.line[5].mode = digio.MODE_TRIGGER_IN
-- Set trigger detector to detect falling edge
trigger.digin[5].edge = trigger.EDGE_FALLING
-- Configure digital I/0 line 6 as a trigger output used to send an end-of-test trigger to the component handler
digio.line[6].mode = digio.MODE_TRIGGER_OUT
-- Output a falling edge trigger
trigger.digout[6].logic = trigger.LOGIC_NEGATIVE
-- Set width of output trigger pulse to 10 us
trigger.digout[6].pulsewidth = 10E-6
-- Trigger pulse is output when the Notify Block generates an event
trigger.digout[6].stimulus = trigger.EVENT_NOTIFY2
-- Load Component Binning trigger model template
-- See the Reference Manual for details on these settings
trigger.model.load("GradeBinning", 100, 5, 0.1, 0.1, 120, 80, 15, 4, 110, 90, 1, 105, 95, 2, 101, 99, 3, bufferVar)
-- Initiate trigger model and wait until finished
trigger.model.initiate()
waitcomplete()
-- Display on front panel USER swipe screen after binning test completes
display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT1, "Test Completed")