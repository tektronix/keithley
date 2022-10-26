--[[
    From the 2470 User's Manual

    The following script demonstrates using the 2470 to measure 
    insulator resistance. Insulation resistance is typically performed
    between traces on a printed circuit board or between conductors in 
    cables and connectors. 
    
    This script sets the 2470 to source 700 V and makes 10 
    resistance readings with a 100 ms interval time. Once 
    the measurements are made, the output is turned off.
]]

-- Reset the instrument
reset()

-- Set up the source function.
smu.source.func = smu.FUNC_DC_VOLTAGE
smu.source.ilimit.level = 1e-3
smu.source.level = 700

-- Set up the measure function
smu.measure.func = smu.FUNC_DC_CURRENT
smu.measure.unit = smu.UNIT_OHM
smu.terminals = smu.TERMINALS_REAR
smu.measure.autorange = smu.ON
smu.measure.nplc = 1

-- Turn on the source output and make readings.
trigger.model.load("SimpleLoop", 10, 0.1)
smu.source.output = smu.ON
trigger.model.initiate()

-- Wait for the measurements to complete.
waitcomplete()

-- Turn off the output.
smu.source.output = smu.OFF

-- Parse index and the data into three columns.
print("Rdg #", "Time (s)", "Resistance (Ohm)")
for i = 1, defbuffer1.n do
print(i, defbuffer1.relativetimestamps[i], defbuffer1[i])
end