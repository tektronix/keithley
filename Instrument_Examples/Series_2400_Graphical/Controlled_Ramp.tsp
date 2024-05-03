--[[
Purpose:    Use a Timer to control the rate of the Source + Measure.
            Want a controlled V/sec ramp rate
            Implements custom version of smu.source.sweeplinear()
            As written: dual sweeps 100 pts from 0-1V with 100ms at each point

Tested with: KEITHLEY INSTRUMENTS,MODEL 2450,04615364,1.7.12b
Written By: Keithley Applications Engineering (Andrea Clary)

Keep in mind the source resolution of the voltage range.
    2V range has 50uV resolution
    20V range has 500uV resolution

For best timing control:
-Use fixed source and measure ranges
-Turn off auto zero; perhaps update auto zero just before executing the
sweep
-Adjust the value of smu.measure.nplc to allow measurements to complete
within the allowed time at each source level
-Source read back is on by default = extra measurment. Turn off.

-Set fixed current measure range based on current limit.
-Current range may need to be higher for faster scan rates;
-Lower ranges will impose more settling time.

-Build a source config list containing the list of source levels for the
ramp.
-Build trigger blocks that will recall a value from source config list and
measure
-Use a timer object to control the rate at which the trigger blocks execute.
]]

-- ************************* Functions Here **********************

function config_smu(src_range, current_limit, nplc)
    smu.measure.func = smu.FUNC_DC_CURRENT
    smu.source.func = smu.FUNC_DC_VOLTAGE
    smu.source.range = src_range
    smu.source.ilimit.level = current_limit
    smu.source.readback = smu.OFF
    smu.measure.range = current_limit
    smu.measure.autorange = smu.OFF -- for best timing control, use fixed range
    -- other measure related settings
    smu.measure.nplc = nplc
    smu.measure.sense = smu.SENSE_2WIRE
    smu.measure.autozero.enable = smu.OFF
end -- function

function build_config_list(start, stop, num_pts)
    -- when building list, turn the output off else the source values will occur at the output
    if smu.source.output == smu.ON then
        smu.source.output = smu.OFF
    end -- if
    smu.source.configlist.create("MY_SOURCE_LIST")
    smu.source.range = math.max(start, stop)
    step_size = (stop - start)/(num_pts - 1)
    -- ramp up
    for i = 1, num_pts do
        smu.source.level = start + step_size * (i-1)
        smu.source.configlist.store("MY_SOURCE_LIST")
    end -- loop
    -- ramp down
    for i = 1, num_pts do
        smu.source.level = stop - step_size * (i-1) -- increase the value
        smu.source.configlist.store("MY_SOURCE_LIST")
    end -- loop
end -- function

function build_trigger_blocks(num_src_values)
    trigger.model.load("Empty")
    
    blockNumber = 1
    trigger.model.setblock(blockNumber, trigger.BLOCK_BUFFER_CLEAR, defbuffer1)
    
    blockNumber = blockNumber + 1
    trigger.model.setblock(blockNumber, trigger.BLOCK_CONFIG_RECALL, "MY_SOURCE_LIST", 1)
    
    blockNumber = blockNumber + 1
    trigger.model.setblock(blockNumber, trigger.BLOCK_SOURCE_OUTPUT, smu.ON)
    
    blockNumber = blockNumber + 1
    trigger.model.setblock(blockNumber, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1) -- starts timer1
    
    blockNumber = blockNumber + 1
    branchToHere = blockNumber -- ***** loop back to this block number *******
    trigger.model.setblock(blockNumber, trigger.BLOCK_WAIT, trigger.EVENT_TIMER1)
    
    blockNumber = blockNumber + 1
    -- acquire one sample into buffer
    trigger.model.setblock(blockNumber, trigger.BLOCK_MEASURE_DIGITIZE, defbuffer1, 1)
    
    blockNumber = blockNumber + 1
    trigger.model.setblock(blockNumber, trigger.BLOCK_CONFIG_NEXT, "MY_SOURCE_LIST")
    
    blockNumber = blockNumber + 1
    -- branch back if still have values in source list
    trigger.model.setblock(blockNumber, trigger.BLOCK_BRANCH_COUNTER, num_src_values, branchToHere)
    
    blockNumber = blockNumber + 1
    -- all done, turn blue light off
    trigger.model.setblock(blockNumber, trigger.BLOCK_SOURCE_OUTPUT, smu.OFF)
end -- function

function config_timer(timer_tic_interval, how_many_tics)
    -- Timer to control sweep rate
    local N = 1
    trigger.timer[N].enable = 0
    trigger.timer[N].reset()
    trigger.timer[N].clear()
    trigger.timer[N].enable = 1
    trigger.timer[N].delay = timer_tic_interval
    trigger.timer[N].count = how_many_tics
    trigger.timer[N].start.stimulus = trigger.EVENT_NOTIFY1
    trigger.timer[N].start.generate = trigger.OFF -- tic only when timer elapses
end -- function

-- ************************* Main Program Here **********************
    reset()
    eventlog.clear()

    start_voltage = 0
    stop_voltage = 1
    number_of_pts = 100
    SampleInterval = 0.1 -- need to compute this for desired V/sec ramp rate and number of points
    AD_overhead = 10e-3
    AD_integration = (SampleInterval - AD_overhead) * localnode.linefreq
    if AD_integration > 1 then AD_integration = 1 end
    if AD_integration < 0.01 then
        AD_integration = 0.01
        print("Logic error.... interval too fast")
    end

    --print("integration: "..AD_integration)

    --config_smu(src_range, current_limit, nplc)
    config_smu(2, 10e-3, AD_integration)

    --build_config_list(start, stop, num_pts)
    build_config_list(start_voltage, stop_voltage, number_of_pts)
    number_src_values = smu.source.configlist.size("MY_SOURCE_LIST")

    --config_timer(timer_tic_interval, how_many_tics)
    config_timer(SampleInterval, number_src_values)

    --build_trigger_blocks(num_src_values)
    build_trigger_blocks(number_src_values)

    -- update auto zero
    smu.measure.autozero.once()

    -- run the trigger model
    trigger.model.initiate()
    waitcomplete()
    print(string.format("Ramp Duration from Time Stamps: %0.2f seconds", defbuffer1.relativetimestamps[defbuffer1.n] - defbuffer1.relativetimestamps[1] ))
    
    print_data = false
    if print_data then
        for i = 1, defbuffer1.n do
            print(defbuffer1.relativetimestamps[i]..","..defbuffer1.sourcevalues[i]..","..defbuffer1.readings[i])
        end -- for loop
    end -- if