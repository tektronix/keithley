-- tested with 2450, firmware 1.7.16a

readings_captured = 0


function config_smu(src_level, current_limit)

     smu.measure.func = smu.FUNC_DC_CURRENT
     
     -- active source function
     smu.source.func = smu.FUNC_DC_VOLTAGE
     smu.measure.func = smu.FUNC_DC_CURRENT
     
     -- change source limit while still in default auto range
     smu.source.ilimit.level  = current_limit
     -- now set a fixed measure range
     smu.measure.range = current_limit
     
     -- number of power line cycles of A/D integration
     -- for now, setting to fastest
     smu.measure.nplc = 0.01
     smu.measure.autozero.enable = smu.OFF
     smu.source.range = src_level
     
     smu.source.level = 0  -- initial value when blue light turns on

end  -- function




-- config a timer to use a delay list 
-- list allows easy variable duration dwell times
function config_timer(numberSrcValues)


     -- Timer to control sweep rate
     local N = 1
     trigger.timer[N].enable = 0
     trigger.timer[N].reset()
     trigger.timer[N].clear()
     

     durationList = {}  -- duration in seconds
     
     -- initialize each point in duration list to same value
     for i = 1, numberSrcValues do
        durationList[i] = 0.003  -- 3 msec seems to be the fastest we can do
		--# at timer of 1 msec = not relible operation.  Expect 555 readings;  stalled at 293
		--# slow to 2 msec = stalled at 507 readings
		--# slot to 3 msec = success
     end  -- for loop
     
     -- if you want variable timing
     -- over-write a few of the durations with different values
     -- per your required logic
     --durationList[1] = 1
     
     
     trigger.timer[N].delaylist = durationList

     trigger.timer[N].count = numberSrcValues - 1
     trigger.timer[N].start.stimulus = trigger.EVENT_NOTIFY1
     trigger.timer[N].start.generate = trigger.OFF
     trigger.timer[N].enable = 1  -- enable the timer after all settings
     
     --setup digital output
     digio.line[1].mode = digio.MODE_TRIGGER_OUT
     trigger.digout[1].pulsewidth = 100e-6
     trigger.digout[1].stimulus   = trigger.EVENT_NOTIFY1

end  -- function


-- builds a ramping config list
function build_config_list(start, stop, num_pts)

-- when building list, turn the output off else the source values will occur at the output
  if smu.source.output == smu.ON then
     smu.source.output = smu.OFF
  end -- if
     

     --smu.source.configlist.delete("ESD_SOURCE_LIST")
     smu.source.configlist.create("ESD_SOURCE_LIST")
     
     smu.source.range = math.max(start, stop)
     
     -- add some points to dwell at initial start value
     for i = 1, 5 do
        smu.source.level = start
        smu.source.configlist.store("ESD_SOURCE_LIST")
     end  --for loop

     

     step_size = (start - stop)/(num_pts - 1)
     for i = 1, num_pts do
        smu.source.level = start - step_size * (i-1)  -- decrease the value
        smu.source.configlist.store("ESD_SOURCE_LIST")
     end -- loop
     
     -- add some values to dwell at the stop level
     for i = 1, 5 do
        smu.source.level = stop
        smu.source.configlist.store("ESD_SOURCE_LIST")
     end  --for loop
     
     -- add some values to take us from brown out back to normal Vbatt
     for i = 1, num_pts do
        smu.source.level = stop + step_size * (i-1)  -- increase the value
        smu.source.configlist.store("ESD_SOURCE_LIST")
     end -- loop
     
     -- add some values at the last sourced value
     for i = 1, 5 do
        smu.source.level = start
        smu.source.configlist.store("ESD_SOURCE_LIST")
     end  --for loop

end -- function


function config_trigger_model(number_src_pts)

     block_num = 1
     trigger.model.setblock(block_num, trigger.BLOCK_BUFFER_CLEAR, defbuffer1)
    
     block_num = block_num + 1
     trigger.model.setblock(block_num, trigger.BLOCK_SOURCE_OUTPUT, smu.ON)
          
     block_num = block_num + 1
     trigger.model.setblock(block_num, trigger.BLOCK_CONFIG_RECALL, "ESD_SOURCE_LIST", 1)  -- source first value
     
     block_num = block_num + 1
     trigger.model.setblock(block_num, trigger.BLOCK_MEASURE)
     
     block_num = block_num + 1
     trigger.model.setblock(block_num, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1)  -- start timer1

     block_num = block_num + 1
     branch_TO_HERE = block_num
     trigger.model.setblock(block_num, trigger.BLOCK_WAIT, trigger.EVENT_TIMER1)  -- wait for timer tic
     
     block_num = block_num + 1
     trigger.model.setblock(block_num, trigger.BLOCK_CONFIG_NEXT, "ESD_SOURCE_LIST")
     
     block_num = block_num + 1
     trigger.model.setblock(block_num, trigger.BLOCK_MEASURE)
     
     block_num = block_num + 1
     trigger.model.setblock(block_num, trigger.BLOCK_BRANCH_COUNTER, number_src_pts - 1, branch_TO_HERE)  -- branch back to wait for timer
     
     block_num = block_num + 1
     trigger.model.setblock(block_num, trigger.BLOCK_SOURCE_OUTPUT, smu.OFF)  -- output off

end  -- function




--function do_setup(rng, sample_rate, bufferSize, do_current)
function do_setup(start_voltage, stop_voltage, number_of_pts_in_ramp, repeat_count)

    --[[
	
	   do_setup() taken from the DMM6500 Streaming example on github
	   
	   
	]]--
	
    reset()
	errorqueue.clear()
	
	tsplink.line[1].mode = tsplink.MODE_TRIGGER_OPEN_DRAIN
	trigger.tsplinkout[1].stimulus = trigger.EVENT_NOTIFY1
	
	format.data = format.REAL32  -- binary format for data
	
	
	-- config_smu will set fixed V and I ranges based on the values we pass
	--config_smu(src_level, current_limit)
	config_smu(math.max(start_voltage, stop_voltage), 0.1)  

	
			  
	-- this funtion builds a list of src values
	-- start to stop and back to start
	-- a few repeated values at start, stop and back at start
	build_config_list(start_voltage, stop_voltage, number_of_pts_in_ramp)
	

	-- update number of points for actual size of source config list
	number_of_pts = smu.source.configlist.size("ESD_SOURCE_LIST")

	
	--config_timer(numberSrcValues)
	-- right now is hard coded for 50msec tic interval --> ~20Hz rate
	config_timer(number_of_pts * repeat_count)

	--config_trigger_model(number_src_pts)
	config_trigger_model(number_of_pts * repeat_count)
	
	defbuffer2.capacity = 10  -- second buffer to minimum size
	defbuffer1.capacity = number_of_pts * repeat_count
							  
							  
    waitcomplete()
    print("ok")
end

function chng_scrn(my_screen)
	--[[ Make certain that the DMMs are showing UIs that
		 do not require processor power for updates which
		 could slow operations down.
	]]
	if my_screen == 0 then
		display.changescreen(display.SCREEN_HOME)
	elseif my_screen == 1 then
		display.changescreen(display.SCREEN_PROCESSING)
	elseif my_screen == 2 then
		display.changescreen(display.SCREEN_STATS_SWIPE)
	end
	waitcomplete()
	print("ok")
end

function trig()
    readings_captured = 0
	--smu.source.output = smu.ON
    trigger.model.initiate()
    print("ok")
	delay(0.25)
	--trigger.tsplinkout[1].assert()
end

function get_data(buffSize)
	chunker = 25
    --while buffer.getstats(defbuffer1).n - readings_captured < 200 do
	while (buffer.getstats(defbuffer1).n - readings_captured) < chunker do
        delay(0.001)
    end
    local index1 = math.mod(readings_captured, buffSize) + 1
    local index2 = index1 + (chunker - 1)			-- was 199
	if index2 > buffSize then
		index2 = buffSize
	end
    --print(scpi.execute(':TRAC:DATA? ' .. index1 .. ', ' .. index2 .. ', \"defbuffer1\"'))
	printbuffer(index1, index2, defbuffer1.relativetimestamps, defbuffer1.sourcevalues, defbuffer1.readings)
    --printbuffer(index1, index2, defbuffer1.readings)
	readings_captured = readings_captured + chunker
end

print("functions loaded")