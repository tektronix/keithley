--[[    `

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

The following TSP code performs a capacitor leakage measurement by sourcing 300 V and measuring
    the resulting leakage current. The Duration Loop trigger model template applies the voltage for 60
    seconds and makes measurements at 200 ms intervals. After the duration time, the capacitor is
    discharged at 0 V and the output is turned off.

After the code is executed, the measurement results are displayed in the Instrument Console of Test
    Script Builder. From the Instrument Console, you can copy the data into a spreadsheet for graphing.

]]

-- Reset the instrument, which also clears the buffer.
reset()
--smu. here
-- Set up the source function.
smu.source.func = smu.FUNC_DC_VOLTAGE
smu.source.ilimit.level = 10e-3
smu.source.level = 300
--smu. here
-- Set up measure function.
smu.measure.func = smu.FUNC_DC_CURRENT
smu.measure.terminals = smu.TERMINALS_REAR
smu.measure.autorange = smu.ON
smu.measure.nplc = 1
-- Turn on the output and initiate readings.
trigger.model.load("DurationLoop", 60, 0.2)
trigger.model.initiate()
-- Wait for the trigger model to complete.
waitcomplete()
-- Parse index and data into three columns.
print("Rdg #", "Time (s)", "Current (A)")
for i = 1, defbuffer1.n do
    print(i, defbuffer1.relativetimestamps[i], defbuffer1[i])
end
-- Discharge the device to 0 V and turn off the output.
smu.source.level = 0
delay(2)
smu.source.output = smu.OFF