--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This example is from the 2450 User's Manual. Check there for more details on running this example.

In this example, the code steps the gate-source voltage, sweeps the drain-source voltage at each
    step, and measures the drain-source current. The parameters for this example are

]]

--Reset the instruments and the TSP-Link connection, and clear the buffers.
tsplink.initialize()
reset()
node[2].reset()
--If the TSP-Link state is not online, print an error message and quit.
state = tsplink.state
if state ~= "online" then
    print("Error:\n-Check that all SMUs have a different node number")
    print("-Check that all SMUs are connected correctly\n")
    return
end
--Set the number of sweep points (also used for printing).
num = 51

--######################## Model 2450 #1 (drain) setup ################
--Set up the source function.
smu.source.func = smu.FUNC_DC_VOLTAGE
smu.source.ilimit.level = 300e-3
smu.source.autorange = smu.ON
--Set up the measure function.
smu.measure.func = smu.FUNC_DC_CURRENT
smu.measure.autorange = smu.ON
smu.measure.terminals = smu.TERMINALS_REAR
--Set up a linear sweep.
smu.source.sweeplinear("MOSFET", 0, 5, num, 0.001)

--########################## Model 2450 #2 (gate) setup ################
--Set up the source function.
node[2].smu.source.func = node[2].smu.FUNC_DC_VOLTAGE
node[2].smu.source.autorange = node[2].smu.ON
node[2].smu.source.ilimit.level = 100e-3
--Set up the measure function.
node[2].smu.measure.func = node[2].smu.FUNC_DC_CURRENT
node[2].smu.measure.autorange = node[2].smu.ON
node[2].smu.measure.terminals = node[2].smu.TERMINALS_REAR
--Turn the stepper output on.
node[2].smu.source.output = node[2].smu.ON
readings = {}
sourcevalues = {}
iteration = 0
steppoints = 4
--Set the stepper V level, delay, start sweep, and wait to complete.
for i = 2, 5 do
    node[2].smu.source.level = i
    delay(0.01)
    trigger.model.initiate()
    waitcomplete()
    for j = 1, num do
        readings[j+iteration*num] = defbuffer1[j]
        sourcevalues[j+iteration*num] = defbuffer1.sourcevalues[j]
    end
    iteration = iteration+1
end
--Turn the stepper output off.
node[2].smu.source.output = node[2].smu.OFF
--Print the formatted readings.
if defbuffer1.n == 0 then
print("\nNo readings in buffer\n")
else
    for k = 1, num do
        print(string.format("%f\t%f\t\t%f\t%f\t\t%f\t%f\t\t%f\t%f", sourcevalues[k], readings[k], sourcevalues[k+num], readings[k+num], sourcevalues[k+num*2], readings[k+num*2], sourcevalues[k+num*3], readings[k+num*3]))
    end
end