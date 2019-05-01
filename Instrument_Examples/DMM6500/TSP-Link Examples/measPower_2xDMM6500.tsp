--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This example is from the DMM6500's User's Manual. Check there for more details on running this example.

See the DMM6500 User's Manual for details on using this TSP command sequence.

This TSP-Link example demonstrates how to configure two DMM6500 instruments to use TSP-Link
    to measure the power consumed by a Bluetooth (R) low energy (BLE) device.

One DMM6500 digitizes voltage while the other instrument digitizes current. 
    Using TSP-Link, these measurements are made simultaneously and the results
    communicated between the two instruments. Using TSP scripting, the average power consumption
    during the test period is calculated.

After the code executes, the data is displayed in the Instrument Console of Test Script Builder
    as well as the USER swipe screen of both DMM6500s.

]]

-- Initiate the TSP-Link network
tsplink.initialize()
-- Set a delay of 0.5 seconds.
delay(0.5)
-- Reset master instrument at node 1
node[1].reset()
-- Set up TSP-Link trigger line 1 to trigger the subordinate node digitizer.
node[1].tsplink.line[1].mode = tsplink.MODE_TRIGGER_OPEN_DRAIN
node[1].trigger.tsplinkout[1].stimulus = trigger.EVENT_NOTIFY1
-- Set up digitize voltage function settings.
node[1].dmm.digitize.func = dmm.FUNC_DIGITIZE_VOLTAGE
node[1].dmm.digitize.samplerate = 5000
-- Set up digitize voltage range based on voltage applying to the BLE device.
node[1].dmm.digitize.range = 10
-- Set up reading buffers.
node[1].defbuffer1.capacity = 50000
-- Set up trigger model.
node[1].trigger.model.setblock(1, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1)
node[1].trigger.model.setblock(2, trigger.BLOCK_WAIT, trigger.EVENT_TSPLINK1)
node[1].trigger.model.setblock(3, trigger.BLOCK_MEASURE_DIGITIZE, defbuffer1, 50000)
-- Reset instrument at node 2.
node[2].reset()
-- Set up TSP-Link trigger line 1 to receive a trigger from master node.
node[2].tsplink.line[1].mode = node[2].tsplink.MODE_TRIGGER_OPEN_DRAIN
-- Set up digitize current function settings.
node[2].dmm.digitize.func = node[2].dmm.FUNC_DIGITIZE_CURRENT
node[2].dmm.digitize.samplerate = 5000
-- Set up digitize current range based on maximum current the BLE device can draw.
node[2].dmm.digitize.range = 1
-- Set up reading buffers.
node[2].defbuffer1.capacity = 50000
-- Set up trigger model.
node[2].trigger.model.setblock(1, node[2].trigger.BLOCK_WAIT, node[2].trigger.EVENT_TSPLINK1)
node[2].trigger.model.setblock(2, node[2].trigger.BLOCK_MEASURE_DIGITIZE, defbuffer1, 50000)
-- Show graph of measurements on swipe screens.
node[1].display.changescreen(node[1].display.SCREEN_GRAPH_SWIPE)
node[2].display.changescreen(node[2].display.SCREEN_GRAPH_SWIPE)
delay(1.0)
-- Initiate trigger model on both instruments.
node[2].trigger.model.initiate()
trigger.model.initiate()
-- Wait for test to complete.
waitcomplete()
-- Retrieve buffer statistics.
voltage_buffer = node[1].defbuffer1
voltage_stats = node[1].buffer.getstats(voltage_buffer)
avgVolt = voltage_stats.mean
print(avgVolt .. " Volts")
current_buffer = node[2].defbuffer1
current_stats = node[2].buffer.getstats(current_buffer)
avgCurr = current_stats.mean
print(avgCurr .. " Amps")
-- Print results to the USER swipe screen.
node[1].display.changescreen(display.SCREEN_USER_SWIPE)
node[1].display.settext(display.TEXT1, "AVG V: " .. string.format("%.2e", avgVolt) .. " V")
node[1].display.settext(display.TEXT2, "Average Power: Calculating... ")
node[2].display.changescreen(display.SCREEN_USER_SWIPE)
node[2].display.settext(display.TEXT1, "AVG I: " .. string.format("%.2e", avgCurr) .. " A")
node[2].display.settext(display.TEXT2, "Average Power: Calculating... ")
-- Calculate power using reading index-based method.
power_total = 0
num_readings = current_buffer.n
-- Iterate through each current and voltage reading, and calculate power.
for i = 1, num_readings do
    current = current_buffer.readings[i]
    voltage = voltage_buffer.readings[i]
    -- Keep track of the total power
    power_total = power_total + current*voltage
end
-- Find average power by dividing total power by the number of readings.average_power = power_total / num_readings
print(average_power .. " Watts")
-- Print results to USER swipe screen.
node[1].display.changescreen(display.SCREEN_USER_SWIPE)
node[1].display.settext(display.TEXT2, "Average Power: ".. string.format("%8f",average_power) .. " W")
node[2].display.settext(display.TEXT2, "Average Power: ".. string.format("%8f",average_power) .. " W")