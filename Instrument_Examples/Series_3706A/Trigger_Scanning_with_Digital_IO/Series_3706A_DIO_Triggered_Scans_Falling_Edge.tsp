-- ************************************************************
-- Copyright 2019 Tektronix, Inc.
-- See www.tek.com/sample-license for licensing terms.
-- ************************************************************

function scan_dio_trigger(scan_list, my_range, scan_count)
	reset()														-- Reset
	dmm.func = dmm.TWO_WIRE_OHMS								-- Set measurement function
	dmm.nplc = 1												-- Set NPLC
	dmm.range = my_range										-- Set Range
	dmm.configure.set("my2wres")								-- Save Configuration
	dmm.setconfig(scan_list,"my2wres")							-- Assign configuration to channels
	
	-- Establish the settings for the Digital I/O lines such that line 2 is
	-- armed and waiting for the scan start trigger event. Additionally, line
	-- 1 is configured such that when scan execution completes a response 
	-- trigger event is issued to the controller. 
	digio.trigger[2].mode = digio.TRIG_FALLING					-- Configure Digital I/O line for falling edge input
	digio.trigger[2].clear()									-- Clear Digital line 2
	digio.trigger[1].stimulus = scan.trigger.EVENT_MEASURE_COMP	-- Configure Digital line[1] to scan channel ready output
	digio.trigger[1].mode = digio.TRIG_FALLING					-- Configure Digital I/O line for falling edge output
	digio.trigger[1].pulsewidth = 0.001							-- Configure output width
	
	-- The scan.bypass attribute allows unit to fall through the channel stimulus the first time
	-- through the trigger model.  This is useful if you have two unit in external trigger
	-- mode, one needs to go first to "prime the pump".  
	-- by turning bypass off, 3706 will wait for a trigger BEFORE taking the first measurement
	scan.bypass = scan.OFF										-- Turns scan bypass off, it is on by default
	--scan.trigger.channel.stimulus = digio.trigger[2].EVENT_ID	-- Configure Scan Channel Stimulus to Digital [2]
	scan.trigger.arm.stimulus = digio.trigger[2].EVENT_ID
	scan.create(scan_list)										-- Create Scan
	scan.scancount = scan_count									-- Pass scan count from function call
	
	number_of_channels = scan.stepcount							-- Extract the number of channels in the established scan lis
	reading_buffer = dmm.makebuffer(scan_count * number_of_channels)	-- Configure Buffer
	
	scan.execute(reading_buffer)								-- Execute Scan
	
end

function extract_readings(start_index, end_index)
	printbuffer(start_index,end_index, reading_buffer.readings)	-- Print readings/measurements in buffer
																-- Note that other elements can be included
																-- such as:
																--	1. .relativetiimestamps
																--	2. .channels
																--  3. .units
																--
																-- For a full list of options, see the bufferVar
																-- options listed in the Reference Manual. 
end

-- Test the script function
myrange = 200
scancount = 30
res2w_scan_list = "1001:1020"
scan_dio_trigger(res2w_scan_list, myrange, scancount)