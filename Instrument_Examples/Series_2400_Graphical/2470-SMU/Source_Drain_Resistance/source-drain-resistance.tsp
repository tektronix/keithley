--[[

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

The following TSP commands make source-drain resistance measurements, R_DS(On), using two 2470 SMU
    instruments communicating with each other via TSP-Link.  The SMU at Node 1 is connected to
    the gate to sweep voltage. The SMU at Node 2 is connected to the drain and applies 
    a bias voltage while measuring current to obtain the source-drain resistance as a function 
    of applied gate voltage.

After the code is executed, the measurement results are displayed in the Instrument Console of Test
    Script Builder. From the Instrument Console, you can copy the data into a spreadsheet for graphing.

]]

--######################## Settings and TSP-Link setup ################
local gateVstart = 2 
local gateVstop = 5 
local gateStepSize = 0.1

local drainV = 10
local drainIlimit = 0.1

-- Reset the instruments and the TSP-Link connection, and clear the buffers.
tsplink.initialize()
reset()
-- If the tsplink state is not online, print an error message and quit
local state = tsplink.state
if state ~= "online" then
    print("Error:\n-Check that all SMUs have a different node number")
    print("-Check that all SMUs are connected correctly\n")
    return
end
-- Set up TSP-Link node shortcuts.
local gate = node[1]
local drain = node[2]

--######################## 2470 SMU #1 (gate) setup ################
-- Set up the source function.
gate.smu.source.configlist.create("stepVals")
gate.smu.source.func = gate.smu.FUNC_DC_VOLTAGE
gate.smu.source.autorange = gate.smu.ON
-- Set up the measure function.
gate.smu.measure.func = gate.smu.FUNC_DC_CURRENT
gate.smu.measure.autorange = gate.smu.ON
gate.smu.measure.terminals = gate.smu.TERMINALS_REAR
-- Set up TSP-Link triggering.
gate.tsplink.line[1].reset()
gate.tsplink.line[1].mode = gate.tsplink.MODE_SYNCHRONOUS_MASTER
gate.trigger.tsplinkout[1].stimulus = gate.trigger.EVENT_NOTIFY1
-- Populate the stepVals source config list, with source levels gateVstart volts to gateVstop volts
for i = gateVstart, gateVstop, gateStepSize do
    gate.smu.source.level = i
    gate.smu.source.configlist.store("stepVals")
end
local stepPoints = (gateVstop - gateVstart) * (1 / gateStepSize) + 1
-- Set up the trigger model.
gate.trigger.model.setblock(1, gate.trigger.BLOCK_CONFIG_RECALL, "stepVals")
gate.trigger.model.setblock(2, gate.trigger.BLOCK_SOURCE_OUTPUT, gate.smu.ON)
gate.trigger.model.setblock(3, gate.trigger.BLOCK_MEASURE_DIGITIZE)
gate.trigger.model.setblock(4, gate.trigger.BLOCK_NOTIFY, gate.trigger.EVENT_NOTIFY1)
gate.trigger.model.setblock(5, gate.trigger.BLOCK_WAIT, gate.trigger.EVENT_TSPLINK1)
gate.trigger.model.setblock(6, gate.trigger.BLOCK_CONFIG_NEXT, "stepVals")
gate.trigger.model.setblock(7, gate.trigger.BLOCK_BRANCH_COUNTER, stepPoints, 3)
gate.trigger.model.setblock(8, gate.trigger.BLOCK_SOURCE_OUTPUT, gate.smu.OFF)

--######################## 2470 SMU #2 (drain) setup ################
-- Set up the source function.
drain.smu.source.func = drain.smu.FUNC_DC_VOLTAGE
drain.smu.source.ilimit.level = drainIlimit
drain.smu.source.level = drainV
-- Set up measure function.
drain.smu.measure.func = drain.smu.FUNC_DC_CURRENT
drain.smu.measure.terminals = drain.smu.TERMINALS_REAR
drain.smu.measure.autorange = drain.smu.ON
drain.smu.measure.nplc = 1
drain.smu.measure.unit = drain.smu.UNIT_OHM
-- Set up TSP-Link triggering.
drain.tsplink.line[1].mode = drain.tsplink.MODE_SYNCHRONOUS_ACCEPTOR
drain.trigger.tsplinkout[1].stimulus = drain.trigger.EVENT_NOTIFY1
-- Set up the trigger model.
drain.trigger.model.setblock(1, drain.trigger.BLOCK_SOURCE_OUTPUT, drain.smu.ON)
drain.trigger.model.setblock(2, drain.trigger.BLOCK_WAIT, drain.trigger.EVENT_TSPLINK1)
drain.trigger.model.setblock(3, drain.trigger.BLOCK_DELAY_CONSTANT, 0.01)
drain.trigger.model.setblock(4, drain.trigger.BLOCK_MEASURE_DIGITIZE)
drain.trigger.model.setblock(5, drain.trigger.BLOCK_NOTIFY, drain.trigger.EVENT_NOTIFY1)
drain.trigger.model.setblock(6, drain.trigger.BLOCK_BRANCH_COUNTER, stepPoints, 2)
drain.trigger.model.setblock(7, drain.trigger.BLOCK_SOURCE_OUTPUT, drain.smu.OFF)

--######################## Start test ################
-- Start the trigger model for both SMUs and wait until it is complete.
gate.trigger.model.initiate()
drain.trigger.model.initiate()
print("Test Running...")
waitcomplete()
-- Print the formatted readings.
if drain.defbuffer1.n == 0 then
    print("\nNo readings in buffer\n")
else
    print("Index,".."\t".."gateV,".."\t".."R_DS")
    for k = 1, stepPoints do
        print(
            string.format("%d,\t%1.5f,\t%1.6E",
                k, gate.defbuffer1.sourcevalues[k], drain.defbuffer1.readings[k]
            )
        )
    end
end