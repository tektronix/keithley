--[[

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

The TSP code in this example sets the Model 2450 to the source voltage function and measure
    current function. The voltage source is set to 1 V and the source limit is set to 460 mA. The voltage,
    current, and relative timestamp values are returned. Measurements are made until the voltage
    reaches the set level. During the test, these measurements are shown on the USER swipe screen at
    the bottom of the screen.

]]

--Reset the instrument, which clears the buffer.
reset()
--Source settings.
smu.source.func = smu.FUNC_DC_VOLTAGE
smu.source.offmode = smu.OFFMODE_HIGHZ
smu.source.level = 1
smu.source.range = 2
smu.source.readback = smu.ON
smu.source.ilimit.level = 460e-3
--Measure settings.
smu.measure.func = smu.FUNC_DC_CURRENT
smu.measure.range = 460e-3
smu.measure.sense = smu.SENSE_4WIRE
--Set the voltage limit at which the battery will stop discharging.
--Set the variable for the number of iterations.
voltLimit = 1.0
iteration = 1
--Turn on the source output.
smu.source.output = smu.ON
--Change the display to the USER swipe screen.
display.changescreen(display.SCREEN_USER_SWIPE)
--Keep taking readings in the while loop until the measured voltage
--is equal to the voltage limit.
while true do
    --Take a reading and get the current, voltage, and relative
    --timestamp values.
    curr = smu.measure.read(defbuffer1)
    volt = defbuffer1.sourcevalues[iteration]
    time = defbuffer1.relativetimestamps[iteration]
    hours = time/3600
    --Print the number of completed cycles, the voltage, and the time
    --for the iteration. Display information on the front panel.
    print("Completed Cycles: ", iteration, "Voltage: ", volt, "Time:", time)
    display.settext(display.TEXT1, string.format("Voltage = %.4fV", volt))
    display.settext(display.TEXT2, string.format("Current = %.2fA,".."Time = %.2fHrs", curr, hours))
    --Increment the number of iterations and wait 10 seconds.
    --Compare the measured voltage to the voltage limit.
    --Exit the loop if the voltage limit has been reached.
    if volt <= voltLimit then
        break
    end
    iteration = iteration + 1
    delay(10)
end
--Turn the output off when the voltage limit is reached.
smu.source.output = smu.OFF
--Print the measured values in a four-column format.
print("\nIteration:\tCurrent:\tVoltage:\tTime:\n")
for i = 1, defbuffer1.n do
    print(i, "\t", defbuffer1[i], "\t", defbuffer1.sourcevalues[i], "\t", defbuffer1.relativetimestamps[i])
end