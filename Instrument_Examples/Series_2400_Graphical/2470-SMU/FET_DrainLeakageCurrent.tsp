--[[
    From the 2470 User's Manual

    A drain leakage current measurement on a FET requires only one 2470. 
    For this measurement, the gate-source potential must be 0 V, so the 
    gate and source connection pins are shorted together. The SMU is 
    connected between the drain and source to apply a bias voltage. 
    To change this measurement to a gate leakage current measurement, 
    you can short the drain and source together and connect the 2470 
    between the gate and source to apply a bias voltage.

    The following TSP code performs a drain leakage measurement on a FET 
    by sourcing 600 V and measuring the resulting leakage current. The 
    DurationLoop trigger model template applies the voltage for 60 s and 
    makes measurements at 200 ms intervals. After the code is executed, 
    the measurement results are displayed in the Instrument Console of Test
    Script Builder. From the Instrument Console, you can copy the data 
    into a spreadsheet for graphing.
]]


-- Reset the instrument, which also clears the buffer.
reset()

-- Set up the source function.
smu.source.func = smu.FUNC_DC_VOLTAGE
smu.source.ilimit.level = 10e-3
smu.source.level = 600

-- Set up measure function.
smu.measure.func = smu.FUNC_DC_CURRENT
smu.terminals = smu.TERMINALS_REAR
smu.measure.autorange = smu.ON
smu.measure.nplc = 1

-- Turn on the output and initiate readings.
trigger.model.load("DurationLoop", 60, 0.2)
trigger.model.initiate()

-- Wait for the trigger model to complete.
waitcomplete()
smu.source.output = smu.OFF