--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This example is from the DMM7510's User's Manual. Check there for more details on running this example.

This example code demonstrates how to configure the Model DMM7510 and Model 3706A-S 
    System Switch to interact through TSP-Link. The application measures different types 
    of signals on multiple channels in multiple slots of a Model 3706A-S.

This is a common production test setup that monitors a variety of signals. These signals are 
    typicallyrouted through a switch that can accommodate the performance and throughput of the 
    test requirement.

The example includes:
* 30 channels that measure DC voltage at two different ranges in slot 1
* 10 channels that measure AC voltage in slot 1
* 20 channels that measure 4-wire resistance in slot 4

The Model 3706A-S used in this test includes two multiplexer cards and screw terminal blocks:
* Model 3721 Dual 1x20 Channel Multiplexer Card and Model 3721-ST Screw Terminal Block (slot 1)
* Model 3724 Dual 1x30 FET Multiplexer Card and Model 3724-ST Screw Terminal Block (slot 4)

]]

-- Initialize the TSP-Link network, where node 1 is Model 3706A-S and node 2 is Model DMM7510
tsplink.initialize()
-- If the TSP-Link state is not online, print an error message and quit
state = tsplink.state
print(state)
if state ~= "online" then
    print("Error:\n-Check that all instruments have a different node number")
    print("-Check that all instruments are connected correctly\n")
    return
end
-- Reset both instruments to the default settings
node[1].reset() -- node 1 is Model 3706A-S
node[2].reset() -- node 2 is Model DMM7510
--[[
Create a configuration list on Model DMM7510 named "myScanConfigList"
Index 1 is DCV 100 mV range, 10 channel
Index 2 is DCV 10 V range, 20 channel
Index 3 is ACV 1 V range, 9 channel
Index 4 is Resistance 4W, 20 channel
]]
node[2].dmm.measure.configlist.create("myScanConfigList")
node[2].dmm.measure.func = node[2].dmm.FUNC_DC_VOLTAGE
node[2].dmm.measure.range = 10
node[2].dmm.measure.nplc = 1
node[2].dmm.measure.configlist.store("myScanConfigList") --index1
node[2].dmm.measure.func = node[2].dmm.FUNC_DC_VOLTAGE
node[2].dmm.measure.range = 1000
node[2].dmm.measure.autozero.enable = node[2].dmm.OFF
node[2].dmm.measure.configlist.store("myScanConfigList") --index2
node[2].dmm.measure.func = node[2].dmm.FUNC_AC_VOLTAGE
node[2].dmm.measure.range = 10
-- node[2].dmm.measure.autozero.enable = node[2].dmm.OFF
node[2].dmm.measure.configlist.store("myScanConfigList") --index3
node[2].dmm.measure.func = node[2].dmm.FUNC_4W_RESISTANCE
node[2].dmm.measure.autorange = dmm.ON
node[2].dmm.measure.autozero.enable = node[2].dmm.OFF
node[2].dmm.measure.configlist.store("myScanConfigList") --index4
-- Handshaking between the Model DMM7510 and Model 3706A-S
-- Configure Model DMM7510 TSP-Link line 1 to input trigger from Model 3706A-S
node[2].tsplink.line[1].mode = node[2].tsplink.MODE_TRIGGER_OPEN_DRAIN --input from Model 3706A-S
-- Configure Model DMM7510 TSP-Link line 2 to output trigger to Model 3706A-S
node[2].tsplink.line[2].mode = node[2].tsplink.MODE_TRIGGER_OPEN_DRAIN --output to Model 3706A-S
-- Clear Model DMM7510 TSP-Link event detectors
node[2].trigger.tsplinkin[1].clear()
node[2].trigger.tsplinkin[2].clear()
-- Configure Model DMM7510 TSP-Link line 1 input trigger to detect falling edge triggers
node[2].trigger.tsplinkin[1].edge = node[2].trigger.EDGE_FALLING
-- Configure Model DMM7510 TSP-Link line 1 output trigger to output negative pulses at 10 us pulse width when NOTIFY1 event is detected
node[2].trigger.tsplinkout[2].logic = node[2].trigger.LOGIC_NEGATIVE
node[2].trigger.tsplinkout[2].pulsewidth = 10e-6
node[2].trigger.tsplinkout[2].stimulus = node[2].trigger.EVENT_NOTIFY1
-- Configure Model 3706A-S TSP-Link line 1 to output trigger to Model DMM7510
node[1].tsplink.trigger[1].mode = node[1].tsplink.TRIG_FALLING --output to Model DMM7510
-- Configure Model 3706A-S TSP-Link line 2 to input trigger from Model DMM7510
node[1].tsplink.trigger[2].mode = node[1].tsplink.TRIG_FALLING --input from Model DMM7510
-- Clear Model 3706A-S TSP-Link event detectors
node[1].tsplink.trigger[1].clear()
node[1].tsplink.trigger[2].clear()
-- Configure scan start stimulus to and input trigger on TSP-Link line 2
node[1].scan.trigger.arm.stimulus = 0
node[1].scan.trigger.channel.stimulus = node[1].tsplink.trigger[2].EVENT_ID
node[1].tsplink.trigger[1].stimulus = node[1].scan.trigger.EVENT_CHANNEL_READY
node[1].scan.create("")
-- Create a scan list
muxChannels = {}
muxChannels[1] = "1001:1020" --DCV 1
muxChannels[2] = "1021:1030" --DCV 2
muxChannels[3] = "1031:1040" --ACV
muxChannels[4] = "4001:4020" --4W RES
muxChannelsCount = {}
lastcount = 0
node[1].channel.setpole("4001:4020", 4)
node[1].channel.setbackplane("1001:1020", "1911")
node[1].channel.setbackplane("1021:1030", "1921")
node[1].channel.setbackplane("1031:1040", "1921")
node[1].channel.setbackplane("slot4", "4911,4922")
-- Get channel count for each measurement configuration
for i = 1, table.getn(muxChannels) do
    node[1].scan.add(muxChannels[i])
    muxChannelsCount[i] = node[1].scan.stepcount - lastcount
    lastcount = node[1].scan.stepcount
end
-- Define the number of times the scan will run
node[1].scan.scancount = 1
node[1].scan.bypass = node[1].scan.ON
node[1].scan.mode = node[1].scan.MODE_FIXED_ABR
--[[
Create a Model DMM7510 trigger model that will wait for an input trigger from the Model 
3760A-S indicating a channel is closed before making a measurement. An output trigger 
will be sent to the Model 3706A-S from the Model DMM7510 upon completing the measurement 
before closing another the channel.
]]
node[2].defbuffer1.capacity = node[1].scan.stepcount
node[2].trigger.model.setblock(1, node[2].trigger.BLOCK_CONFIG_RECALL, "myScanConfigList", 1)
node[2].trigger.model.setblock(2, node[2].trigger.BLOCK_WAIT, node[2].trigger.EVENT_TSPLINK1)
node[2].trigger.model.setblock(3, node[2].trigger.BLOCK_MEASURE)
node[2].trigger.model.setblock(4, node[2].trigger.BLOCK_NOTIFY, node[2].trigger.EVENT_NOTIFY1)
node[2].trigger.model.setblock(5, node[2].trigger.BLOCK_BRANCH_COUNTER, muxChannelsCount[1], 2)
node[2].trigger.model.setblock(6, node[2].trigger.BLOCK_CONFIG_NEXT, "myScanConfigList")
node[2].trigger.model.setblock(7, node[2].trigger.BLOCK_WAIT, node[2].trigger.EVENT_TSPLINK1)
node[2].trigger.model.setblock(8, node[2].trigger.BLOCK_MEASURE)
node[2].trigger.model.setblock(9, node[2].trigger.BLOCK_NOTIFY, node[2].trigger.EVENT_NOTIFY1)
node[2].trigger.model.setblock(10, node[2].trigger.BLOCK_BRANCH_COUNTER, muxChannelsCount[2], 7)
node[2].trigger.model.setblock(11, node[2].trigger.BLOCK_CONFIG_NEXT, "myScanConfigList")
node[2].trigger.model.setblock(12, node[2].trigger.BLOCK_WAIT, node[2].trigger.EVENT_TSPLINK1)
node[2].trigger.model.setblock(13, node[2].trigger.BLOCK_MEASURE)
node[2].trigger.model.setblock(14, node[2].trigger.BLOCK_NOTIFY, node[2].trigger.EVENT_NOTIFY1)
node[2].trigger.model.setblock(15, node[2].trigger.BLOCK_BRANCH_COUNTER, muxChannelsCount[3], 12)
node[2].trigger.model.setblock(16, node[2].trigger.BLOCK_CONFIG_NEXT, "myScanConfigList")
node[2].trigger.model.setblock(17, node[2].trigger.BLOCK_WAIT, node[2].trigger.EVENT_TSPLINK1)
node[2].trigger.model.setblock(18, node[2].trigger.BLOCK_MEASURE)
node[2].trigger.model.setblock(19, node[2].trigger.BLOCK_NOTIFY, node[2].trigger.EVENT_NOTIFY1)
node[2].trigger.model.setblock(20, node[2].trigger.BLOCK_BRANCH_COUNTER, muxChannelsCount[4], 17)
-- Initiate trigger models on both Model 3706A-S and Model DMM7510 and wait until finished
node[2].trigger.model.initiate()
-- To guarantee that the Model DMM7510 trigger model is at WAIT block (block 2)
delay(2)
node[1].scan.background()
waitcomplete()
-- Open all channels on slot 1 and 4
node[1].channel.open("slot1, slot4")