--[[    

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

The following TSP code uses the trigger model to generate a drain family of curves on a FET using 
    two 2470 SMU instruments communicating with each other via TSP-Link.  The SMU at Node 1 is 
    connected to the gate and steps voltage from 2 to 5 volts in 4 steps.  The SMU at Node 2 is connected
    to the drain and sweeps voltage from 0 to 5 volts with 51 points at each step.

After the code is executed, the measurement results are displayed in the Instrument Console of Test
    Script Builder. From the Instrument Console, you can copy the data into a spreadsheet for graphing.

]]

--######################## Settings and TSP-Link setup ################
local gateVstart = 2
local gateVstop = 5
local gateStepSize = 1
local gateIlimit = 1e-3

local drainVstart = 0
local drainVstop = 5
local drainStepSize = 0.1
local drainIlimit = 1e-3

-- Reset the instruments and the TSP-Link connection, and clear the buffers.
tsplink.initialize()
reset()
-- If the tsplink state is not online, print an error message and quit
state = tsplink.state
if state ~= "online" then
    print("Error:\n-Check that all SMUs have a different node number")
    print("-Check that all SMUs are connected correctly\n")
    return
end
-- Set up the TSP-Link node shortcuts.
local gate = node[1]
local drain = node[2]

--######################## Model 2470 #1 (gate) setup ################
-- Set up the source function.
gate.smu.source.configlist.create("stepVals")
gate.smu.source.func = gate.smu.FUNC_DC_VOLTAGE
gate.smu.source.autorange = gate.smu.ON
gate.smu.source.ilimit.level = gateIlimit
-- Set up the measure function.
gate.smu.measure.func = gate.smu.FUNC_DC_CURRENT
gate.smu.measure.autorange = gate.smu.ON
gate.smu.measure.terminals = gate.smu.TERMINALS_REAR
-- Set up TSP-Link triggering.
tsplink.line[1].reset()
gate.tsplink.line[1].mode = gate.tsplink.MODE_SYNCHRONOUS_MASTER
gate.trigger.tsplinkout[1].stimulus = gate.trigger.EVENT_NOTIFY1
-- Populate the stepVals source config list, with source levels 2 V to 5 V
for i = gateVstart, gateVstop, gateStepSize do
    gate.smu.source.level = i
    gate.smu.source.configlist.store("stepVals")
end
local stepPoints = (gateVstop - gateVstart) * (1 / gateStepSize) + 1
-- Set up the trigger model.
gate.trigger.model.setblock(1, trigger.BLOCK_CONFIG_RECALL, "stepVals")
gate.trigger.model.setblock(2, trigger.BLOCK_SOURCE_OUTPUT, gate.smu.ON)
gate.trigger.model.setblock(3, trigger.BLOCK_MEASURE_DIGITIZE)
gate.trigger.model.setblock(4, trigger.BLOCK_NOTIFY, gate.trigger.EVENT_NOTIFY1)
gate.trigger.model.setblock(5, trigger.BLOCK_WAIT, gate.trigger.EVENT_TSPLINK1)
gate.trigger.model.setblock(6, trigger.BLOCK_CONFIG_NEXT, "stepVals")
gate.trigger.model.setblock(7, trigger.BLOCK_BRANCH_COUNTER, stepPoints, 3)
gate.trigger.model.setblock(8, trigger.BLOCK_SOURCE_OUTPUT, gate.smu.OFF)

--########################## Model 2470 #2 (drain) setup ################
-- Set up the source function.
drain.smu.source.configlist.create("sweepVals")
drain.smu.source.func = drain.smu.FUNC_DC_VOLTAGE
drain.smu.source.autorange = drain.smu.ON
drain.smu.source.ilimit.level = drainIlimit
-- Set up the measure function.
drain.smu.measure.func = drain.smu.FUNC_DC_CURRENT
drain.smu.measure.autorange = drain.smu.OFF
drain.smu.measure.terminals = drain.smu.TERMINALS_REAR
drain.smu.measure.range = drainIlimit
-- Set up TSP-Link triggering.
drain.tsplink.line[1].mode = drain.tsplink.MODE_SYNCHRONOUS_ACCEPTOR
drain.trigger.tsplinkout[1].stimulus = drain.trigger.EVENT_NOTIFY1
-- Populate the sweepVals source config list, with source levels
-- 0 V to 5 V in 100 mV steps
for i = drainVstart, drainVstop, drainStepSize do
    drain.smu.source.level = i
    drain.smu.source.configlist.store("sweepVals")
end
local sweepPoints = (drainVstop - drainVstart) * (1 / drainStepSize) + 1
-- Set up the trigger model.
drain.trigger.model.setblock(1, drain.trigger.BLOCK_CONFIG_RECALL, "sweepVals")
drain.trigger.model.setblock(2, drain.trigger.BLOCK_SOURCE_OUTPUT, drain.smu.ON)
drain.trigger.model.setblock(3, drain.trigger.BLOCK_WAIT, drain.trigger.EVENT_TSPLINK1)
drain.trigger.model.setblock(4, drain.trigger.BLOCK_DELAY_CONSTANT, 0.01)
drain.trigger.model.setblock(5, drain.trigger.BLOCK_MEASURE_DIGITIZE)
drain.trigger.model.setblock(6, drain.trigger.BLOCK_CONFIG_NEXT, "sweepVals")
drain.trigger.model.setblock(7, drain.trigger.BLOCK_BRANCH_COUNTER, sweepPoints, 4)
drain.trigger.model.setblock(8, drain.trigger.BLOCK_NOTIFY, drain.trigger.EVENT_NOTIFY1)
drain.trigger.model.setblock(9, drain.trigger.BLOCK_BRANCH_COUNTER, stepPoints,3)
drain.trigger.model.setblock(10, drain.trigger.BLOCK_SOURCE_OUTPUT, drain.smu.OFF)

-- Start the trigger model for both SMUs and wait until it is complete
drain.trigger.model.initiate()
gate.trigger.model.initiate()
print("Test Running...")
waitcomplete()
-- Print the formatted readings.
if defbuffer1.n == 0 then
    print("\nNo readings in buffer\n")
else
    print(string.format("drainV,\tdrainI(1),\t\tdrainV,\tdrainI(2),\t\tdrainV,\tdrainI(3),\t\tdrainV,\tdrainI(4)"))
    for k = 1, sweepPoints do
        print(
            string.format("%f,\t%f,\t\t%f,\t%f,\t\t%f,\t%f,\t\t%f,\t%f",
                drain.defbuffer1.sourcevalues[k], drain.defbuffer1[k],
                drain.defbuffer1.sourcevalues[k+sweepPoints], drain.defbuffer1[k+sweepPoints],
                drain.defbuffer1.sourcevalues[k+sweepPoints*2], drain.defbuffer1[k+sweepPoints*2],
                drain.defbuffer1.sourcevalues[k+sweepPoints*3], drain.defbuffer1[k+sweepPoints*3]
            )
        )
    end
end