--[[

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This example is from the 2450 User's Manual. Check there for more details on running this example.

The following TSP code uses the trigger model to generate a drain family of curves on a FET using 
    two 2450 SMU instruments communicating with each other via TSP-Link.  The SMU at Node 1 is 
    connected to the gate and steps voltage from 2 to 5 volts in 4 steps.  The SMU at Node 2 is connected
    to the drain and sweeps voltage from 0 to 5 volts with 51 points at each step.

After the code is executed, the measurement results are displayed in the Instrument Console of Test
    Script Builder. From the Instrument Console, you can copy the data into a spreadsheet for graphing.

]]

--Reset the instruments and the TSP-Link connection, and clear the buffers.
tsplink.initialize()
reset()
--If the tsplink state is not online, print an error message and quit
state = tsplink.state
if state ~= "online" then
    print("Error:\n-Check that all SMUs have a different node number")
    print("-Check that all SMUs are connected correctly\n")
    return
end

--######################## Model 2450 #1 (gate) setup ################
steppoints = 4
--Set up the source function.
smu.source.configlist.create("stepVals")
smu.source.func = smu.FUNC_DC_VOLTAGE
smu.source.autorange = smu.ON
--Set up the measure function.
smu.measure.func = smu.FUNC_DC_CURRENT
smu.measure.autorange = smu.ON
smu.measure.terminals = smu.TERMINALS_REAR
--Set up TSP-Link triggering.
tsplink.line[1].reset()
tsplink.line[1].mode = tsplink.MODE_SYNCHRONOUS_MASTER
trigger.tsplinkout[1].stimulus = trigger.EVENT_NOTIFY1
--Populate the stepVals source config list, with source levels 2 V to 5 V
for i = 2, 5 do
    smu.source.level = i
    smu.source.configlist.store("stepVals")
end
--Set up the trigger model.
trigger.model.setblock(1, trigger.BLOCK_CONFIG_RECALL, "stepVals")
trigger.model.setblock(2, trigger.BLOCK_SOURCE_OUTPUT, smu.ON)
trigger.model.setblock(3, trigger.BLOCK_MEASURE)
trigger.model.setblock(4, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1)
trigger.model.setblock(5, trigger.BLOCK_WAIT, trigger.EVENT_TSPLINK1)
trigger.model.setblock(6, trigger.BLOCK_CONFIG_NEXT, "stepVals")
trigger.model.setblock(7, trigger.BLOCK_BRANCH_COUNTER, steppoints, 3)
trigger.model.setblock(8, trigger.BLOCK_SOURCE_OUTPUT, smu.OFF)

--########################## Model 2450 #2 (drain) setup ################
sweeppoints = 51
--Set up the source function.
node[2].smu.source.configlist.create("sweepVals")
node[2].smu.source.func = node[2].smu.FUNC_DC_VOLTAGE
node[2].smu.source.autorange = node[2].smu.ON
node[2].smu.source.ilimit.level = 100e-3
--Set up the measure function.
node[2].smu.measure.func = node[2].smu.FUNC_DC_CURRENT
node[2].smu.measure.autorange = node[2].smu.OFF
node[2].smu.measure.terminals = node[2].smu.TERMINALS_REAR
node[2].smu.measure.range = 100e-3
--Set up TSP-Link triggering.
node[2].tsplink.line[1].mode = node[2].tsplink.MODE_SYNCHRONOUS_ACCEPTOR
node[2].trigger.tsplinkout[1].stimulus = node[2].trigger.EVENT_NOTIFY1
--Populate the sweepVals source config list, with source levels
--0 V to 5 V in 100 mV steps
for i = 0, 5, 0.1 do
    node[2].smu.source.level = i
    node[2].smu.source.configlist.store("sweepVals")
end
--Set up the trigger model.
node[2].trigger.model.setblock(1, node[2].trigger.BLOCK_CONFIG_RECALL, "sweepVals")
node[2].trigger.model.setblock(2, node[2].trigger.BLOCK_SOURCE_OUTPUT, node[2].smu.ON)
node[2].trigger.model.setblock(3, node[2].trigger.BLOCK_WAIT, node[2].trigger.EVENT_TSPLINK1)
node[2].trigger.model.setblock(4, node[2].trigger.BLOCK_DELAY_CONSTANT, 0.01)
node[2].trigger.model.setblock(5, node[2].trigger.BLOCK_MEASURE)
node[2].trigger.model.setblock(6, node[2].trigger.BLOCK_CONFIG_NEXT, "sweepVals")
node[2].trigger.model.setblock(7, node[2].trigger.BLOCK_BRANCH_COUNTER, sweeppoints, 4)
node[2].trigger.model.setblock(8, node[2].trigger.BLOCK_NOTIFY, node[2].trigger.EVENT_NOTIFY1)
node[2].trigger.model.setblock(9, node[2].trigger.BLOCK_BRANCH_COUNTER, steppoints, 3)
node[2].trigger.model.setblock(10, node[2].trigger.BLOCK_SOURCE_OUTPUT,
node[2].smu.OFF)
--Start the trigger model for both SMUs and wait until it is complete
node[2].trigger.model.initiate()
trigger.model.initiate()
waitcomplete()
--Print the formatted readings.
if defbuffer1.n == 0 then
    print("\nNo readings in buffer\n")
else
    for k = 1, sweeppoints do
        print(
            string.format("%f\t%f\t\t%f\t%f\t\t%f\t%f\t\t%f\t%f",
                node[2].defbuffer1.sourcevalues[k], node[2].defbuffer1[k],
                node[2].defbuffer1.sourcevalues[k+sweeppoints], node[2].defbuffer1[k+sweeppoints],
                node[2].defbuffer1.sourcevalues[k+sweeppoints*2], node[2].defbuffer1[k+sweeppoints*2],
                node[2].defbuffer1.sourcevalues[k+sweeppoints*3], node[2].defbuffer1[k+sweeppoints*3]
            )
        )
    end
end