--[[
***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

The following TSP commands make insulation resistance measurements by sourcing 300 V and
    measuring the resistance. The Simple Loop trigger model template is used to make
    10 measurements at 100 ms intervals. After the code is executed, the measurement results are
    displayed in the Instrument Console of Test Script Builder.

]]

-- Reset the instrument
reset()
-- Set up the source function.
smu.source.func = smu.FUNC_DC_VOLTAGE
smu.source.ilimit.level = 1e-3
smu.source.level = 300
-- Set up the measure function
smu.measure.func = smu.FUNC_DC_CURRENT
smu.measure.unit = smu.UNIT_OHM
smu.measure.terminals = smu.TERMINALS_REAR
smu.measure.autorange = smu.ON
smu.measure.nplc = 1
-- Turn on the source output and take readings.
trigger.model.load("SimpleLoop", 10, 0.1)
smu.source.output = smu.ON
trigger.model.initiate()
-- Wait for the measurements to complete.
waitcomplete()
-- Parse index and the data into three columns.
print("Rdg #", "Time (s)", "Resistance (Ohm)")
for i = 1, defbuffer1.n do
    print(i, defbuffer1.relativetimestamps[i], defbuffer1[i])
end
-- Turn off the output.
smu.source.output = smu.OFF