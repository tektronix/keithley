--[[

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This sequence of TSP commands makes 100 low-resistance measurements by sourcing current and
    measuring resistance. In this example, the source current magnitude and limit voltage are set
    automatically. It uses remote commands to change the front-panel display to show the GRAPH swipe
    screen. This allows you to view numeric data at the top of the screen and graphic data at the bottom
    of the screen. After the code executes, the data is displayed in the Instrument Console of Test Script
    Builder.

]]

--Reset the instrument to the default settings
reset()
--Configure the Simple Loop trigger model template to make 100 readings.
trigger.model.load("SimpleLoop", 100)
--Change the view on the front panel to the GRAPH swipe screen.
display.changescreen(display.SCREEN_GRAPH_SWIPE)
--Set to measure resistance, use 4-wire sense,
--and offset compensation.
smu.measure.func = smu.FUNC_RESISTANCE
smu.measure.sense = smu.SENSE_4WIRE
smu.measure.offsetcompensation = smu.ON
--Turn on the output
smu.source.output = smu.ON
--Initiate trigger model and wait until finished.
trigger.model.initiate()
waitcomplete()
--Turn off output
smu.source.output = smu.OFF
--Read the resistance and time values from defbuffer1.
print("Resistance:\tTime:")
for i = 1, 100 do
print(string.format("%f\t%f", defbuffer1[i], defbuffer1.relativetimestamps[i]))
end