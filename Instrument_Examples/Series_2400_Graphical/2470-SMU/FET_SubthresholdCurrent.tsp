--[[
    From the 2470 User's Manual

    The following TSP code uses the trigger model to find the subthreshold 
    swing, S, of a FET using two 2470s communicating with each other using 
    TSP-Link. The SMU at Node 1 is connected to the gate and steps voltage 
    from 0 V to 5 V. The SMU at Node 2 is connected to the drain and applies 
    a bias voltage while measuring current.

    After the measurement is complete, a simple numerical exponential fit is 
    found and the subthreshold swing, S, is taken as the inverse of the 
    exponential slope. The result and measurement data is displayed in the 
    Instrument Console of Test Script Builder. From the Instrument Console, 
    you can copy the data into a spreadsheet for graphing.

]]

--######################## Settings and TSP-Link setup ################
local gateVstart = 0
local gateVstop = 5
local gateStepSize = 0.1
local gateIlimit = 0.1

local drainV = 10
local drainIlimit = 0.1
-- Fit settings - The slope is calculated between these gateV points.
-- fitHighV should be less than or equal to the threshold voltage.
local fitLowV = 2
local fitHighV = 3.5

-- Reset the instruments and the TSP-Link connection and clear the buffers.
tsplink.initialize()
reset()

-- If the tsplink state is not online, print an error message and quit.
state = tsplink.state
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
gate.smu.source.ilimit.level = gateIlimit

-- Set up the measure function.
gate.smu.measure.func = gate.smu.FUNC_DC_CURRENT
gate.smu.measure.autorange = gate.smu.ON
gate.smu.terminals = gate.smu.TERMINALS_REAR

-- Set up TSP-Link triggering.
gate.tsplink.line[1].reset()
gate.tsplink.line[1].mode = gate.tsplink.MODE_SYNCHRONOUS_MASTER
gate.trigger.tsplinkout[1].stimulus = gate.trigger.EVENT_NOTIFY1

-- Populate the stepVals source config list with source levels gateVstart volts to gateVstop volts.
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
drain.smu.terminals = drain.smu.TERMINALS_REAR
drain.smu.measure.autorange = drain.smu.ON

-- Set up TSP-Link triggering.
drain.tsplink.line[1].mode = drain.tsplink.MODE_SYNCHRONOUS_ACCEPTOR
drain.trigger.tsplinkout[1].stimulus = drain.trigger.EVENT_NOTIFY1

-- Set up the trigger model.
drain.trigger.model.setblock(1, drain.trigger.BLOCK_SOURCE_OUTPUT, drain.smu.ON)
drain.trigger.model.setblock(2, drain.trigger.BLOCK_WAIT,
drain.trigger.EVENT_TSPLINK1)
drain.trigger.model.setblock(3, drain.trigger.BLOCK_DELAY_CONSTANT, 0.01)
drain.trigger.model.setblock(4, drain.trigger.BLOCK_MEASURE_DIGITIZE)
drain.trigger.model.setblock(5, drain.trigger.BLOCK_NOTIFY,
drain.trigger.EVENT_NOTIFY1)
drain.trigger.model.setblock(6, drain.trigger.BLOCK_BRANCH_COUNTER, stepPoints, 2)
drain.trigger.model.setblock(7, drain.trigger.BLOCK_SOURCE_OUTPUT, drain.smu.OFF)

--######################## Start test ################

-- Start the trigger model for both SMUs and wait until it is complete.
gate.trigger.model.initiate()
drain.trigger.model.initiate()
print("Test Running...")
waitcomplete()
if drain.defbuffer1.n == 0 or gate.defbuffer1.n == 0 then
    print("\nNo readings in buffer\n")
    return
end

-- Perform basic exponential fit
local diffHighV, diffLowV = 9.9e37, 9.9e37
local fitHighIndex = 0
local fitLowIndex = 0
local gateV = 0
local gateHighV = 0
local gateLowV = 0

-- Find actual gate voltage (and indexes) closest to fitHighV and fitLowV
for i = 1, gate.defbuffer1.n do
    gateV = gate.defbuffer1.sourcevalues[i]
    if math.abs(gateV - fitHighV) < diffHighV then
        diffHighV = math.abs(gateV - fitHighV)
        gateHighV = gateV
        fitHighIndex = i
    end
    if math.abs(gateV - fitLowV) < diffLowV then
        diffLowV = math.abs(gateV - fitLowV)
        gateLowV = gateV
        fitLowIndex = i
    end
end

-- Find drain current and natural log of current at the two fit voltages
local drainHighI = drain.defbuffer1.readings[fitHighIndex]
local drainLowI = drain.defbuffer1.readings[fitLowIndex]
local ln_drainHighI = math.log(drainHighI)
local ln_drainLowI = math.log(drainLowI)

-- Find subthreshold swing, S, inverse of subthreshold slope, multiply by 1000 for mV/dec
local diffgateV = gateHighV - gateLowV
local diff_ln_drainI = ln_drainHighI - ln_drainLowI
local S = (diffgateV / diff_ln_drainI) * 1000

-- Print the results
print(string.format("Subthreshold Swing = %.4f mV/decade", S))
print(string.format("High current in fit = %.6E A, low current in fit = %.6E A", drainHighI, drainLowI))
print("Index,".."\t".."gateV (V),".."\t".."drainI (A)")
for k = 1, stepPoints do
    print(
        string.format("%d,\t%.5f,\t%.6E",
        k, gate.defbuffer1.sourcevalues[k], drain.defbuffer1.readings[k]
        )
    )
end