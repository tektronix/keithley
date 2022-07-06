chunk_size = 100
start_index = 1
end_index = 1
buffer_capacity_gb = 0
accumulated_readings = 0

function configure_tsp_link_trigger(is_master, tsp_line)
	tsplink.line[tsp_line].mode = tsplink.MODE_TRIGGER_OPEN_DRAIN

	if is_master == 1 then          -- the master node needs its TSP line capable of outputting a trigger event
		trigger.tsplinkout[tsp_line].stimulus = trigger.EVENT_NOTIFY1
	end
end

function configure_measure(do_voltage, measure_range, aperture_time)
	-- configure DMM integrated measurement
	if do_voltage == 1 then
		dmm.measure.func = dmm.FUNC_DC_VOLTAGE
	else
		dmm.measure.func = dmm.FUNC_DC_CURRENT
	end
	dmm.measure.range = measure_range
	dmm.measure.autorange = dmm.OFF
	dmm.measure.autozero.enable = dmm.OFF
	dmm.measure.autodelay = dmm.DELAY_OFF
	--dmm.measure.nplc = 0.06
	dmm.measure.aperture = aperture_time    -- we use aperature time since streaming is more concerned with
	                                        -- capturing data with time alignment and less concerned with
	                                        -- accuracy/uncertainty
end

function configure_digitize(do_voltage, measure_range, sample_rate)
	-- configure DMM digitized measurement
	if do_voltage == 1 then
		dmm.digitize.func = dmm.FUNC_DIGITIZE_VOLTAGE
	else
		dmm.digitize.func = dmm.FUNC_DIGITIZE_CURRENT
	end
	dmm.digitize.range = measure_range
	dmm.digitize.samplerate = sample_rate
end

function configure_buffer(buffer_capacity)
	-- set up reading buffers
	defbuffer1.capacity = 10
	defbuffer2.capacity = 10
	samplebuff = buffer.make(buffer_capacity, buffer.STYLE_STANDARD)
	samplebuff.fillmode = buffer.FILL_CONTINUOUS
	display.activebuffer = samplebuff

    buffer_capacity_gb = buffer_capacity
	-- set for 32-bit data size extraction, single-precision floating point
	format.data = format.REAL32
	waitcomplete()
end

function configure_trigger_model(is_master, data_extract_size)
	trigger.model.load("Empty")
	trigger.model.setblock(1, trigger.BLOCK_BUFFER_CLEAR, samplebuff)
	if is_master == 1 then          -- the master will issue the TSP trigger to itself and subordinates
		trigger.model.setblock(2, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1)
		trigger.model.setblock(3, trigger.BLOCK_WAIT, trigger.EVENT_TSPLINK1)
		trigger.model.setblock(4, trigger.BLOCK_DELAY_CONSTANT, 0)
		trigger.model.setblock(5, trigger.BLOCK_MEASURE_DIGITIZE, samplebuff, 1)
		trigger.model.setblock(6, trigger.BLOCK_BRANCH_ALWAYS, 5)
	else                            -- subordinates must wait on the master trigger notification
		trigger.model.setblock(2, trigger.BLOCK_WAIT, trigger.EVENT_TSPLINK1)
		trigger.model.setblock(3, trigger.BLOCK_DELAY_CONSTANT, 0)
		trigger.model.setblock(4, trigger.BLOCK_MEASURE_DIGITIZE, samplebuff, 1)
		trigger.model.setblock(5, trigger.BLOCK_BRANCH_ALWAYS, 4)
	end

	chunk_size = data_extract_size
	end_index = chunk_size

	waitcomplete()
end

function set_display(my_screen, text1, text2)
	if (my_screen == 0) then	-- HOME
        display.changescreen(display.SCREEN_HOME)
    elseif (my_screen == 1) then -- PROCESSING
        display.changescreen(display.SCREEN_PROCESSING)
    elseif (my_screen == 2) then	-- USER with text
        display.changescreen(display.SCREEN_USER_SWIPE)
        display.settext(display.TEXT1, text1)
        display.settext(display.TEXT2, text2)
    end
end

function get_data()
	-- check for data ready
	alt_index = buffer.getstats(samplebuff).n
	while (alt_index - accumulated_readings) < chunk_size do
		delay(0.0005)
		alt_index = buffer.getstats(samplebuff).n
	end

    -- send a set of data back to the caller
	printbuffer(start_index, end_index, samplebuff.readings, samplebuff.relativetimestamps)

    -- updated our indices in preparation for the next extraction
    accumulated_readings = accumulated_readings + chunk_size
	start_index = math.mod(start_index + chunk_size, buffer_capacity_gb)
	end_index = start_index + chunk_size - 1
end

function do_beep(duration, frequency)
	beeper.beep(duration, frequency)
end

print("functions loaded")