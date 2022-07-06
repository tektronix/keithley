readings_captured = 0

function do_setup(rng, sample_rate, bufferSize)
    reset()
	
	tsplink.line[1].mode = tsplink.MODE_TRIGGER_OPEN_DRAIN
	trigger.tsplinkout[1].stimulus = trigger.EVENT_NOTIFY1
	
    dmm.digitize.func = dmm.FUNC_DIGITIZE_CURRENT
    dmm.digitize.range = rng
    dmm.digitize.samplerate = sample_rate
    format.data = format.REAL32
	
	defbuffer2.capacity = 10
	defbuffer1.capacity = bufferSize
    
    trigger.model.setblock(1, trigger.BLOCK_NOTIFY, 
							  trigger.EVENT_NOTIFY1)
                              
    trigger.model.setblock(2, trigger.BLOCK_WAIT, 
							  trigger.EVENT_TSPLINK1)
                              
    trigger.model.setblock(3, trigger.BLOCK_DIGITIZE, 
							  defbuffer1, bufferSize)
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
    trigger.model.initiate()
    print("ok")
	delay(0.25)
	--trigger.tsplinkout[1].assert()
end

function get_data(buffSize)
	chunker = 249
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
	printbuffer(index1, index2, defbuffer1.readings)
	readings_captured = readings_captured + chunker
end

print("functions loaded")