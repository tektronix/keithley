-- ************************************************************
-- Copyright 2019 Tektronix, Inc.
-- See www.tek.com/sample-license for licensing terms.
-- ************************************************************

function configure_dcv_scan(nplc, dcv_range, use_input_divider, scan_interval, scan_channels, scan_count)
	reset()
    dmm.func = dmm.DC_VOLTS 			-- Set measurement function
    dmm.nplc = nplc 					-- Set NPLC
    if dcv_range < 0.001 then			-- Set Range
    	dmm.autorange = dmm.ON 
    else
        dmm.autorange = dmm.OFF
        dmm.range = dcv_range 	
    end							
    
    dmm.autodelay = dmm.ON 			 	-- Ensure Auto Delay is enabled
    dmm.autozero = dmm.ON  				-- Enable Auto Zero
    if use_input_divider == 1 then		-- Apply the 10M input divider as needed
    	dmm.inputdivider = dmm.ON					
    else
    	dmm.inputdivider = dmm.OFF 
	end
	
    dmm.configure.set("mydcvolts") 	 	-- Save Configuration
    dmm.setconfig(scan_channels, "mydcvolts")	-- Assign configuration to channels
    
    channel.connectrule = channel.BREAK_BEFORE_MAKE 
    
    if scan_interval > 0.1 then
        -- Establish the settings that will apply the interval between the start of scans
    	trigger.timer[1].reset() 					-- Ensure the timer gets to a known relative time start point
        trigger.timer[1].count = 0 					-- No reapeating timer events
        trigger.timer[1].delay = scan_interval 		-- Apply the anticipated scan interval 
        trigger.timer[1].stimulus = scan.trigger.EVENT_MEASURE_COMP 
        trigger.timer[1].passthrough = false 		-- Trigger only initiates the delay
        trigger.blender[1].reset() 										-- Configure the blender stimulus...
        trigger.blender[1].orenable = true 								-- ... for OR'ing operation
        trigger.blender[1].stimulus[1] = trigger.timer[1].EVENT_ID 		-- ... to respond/notify upon a timer event
        trigger.blender[1].stimulus[2] = scan.trigger.EVENT_SCAN_READY 	-- ... or when then scan is ready (configured)
        scan.trigger.arm.stimulus = trigger.blender[1].EVENT_ID 		-- Key triggering off of the blender event
    end
    
    scan.create(scan_channels)					-- Create the scan 
    scan.scancount = scan_count 				-- Set the Scan Count
    reading_buffer = dmm.makebuffer(scan.scancount * scan.stepcount) 	-- Configure Buffer
    scan.background(reading_buffer) 			-- Execute Scan and save to buffer
	return reading_buffer
end

function write_data_to_usb(output_data_path, data_string)
	-- Because the original code example was writing to a file on the controlling PC
	-- and could do so independent of the instrument scanning, this could slow scan
	-- operations down for fast scan rates. Before adding this functionality, consider
	-- what is needed by the end user first. 
end

--[[ ******************************************************************************************

		MAIN PROGRAM STARTS HERE 
		
******************************************************************************************   ]]
scanchannels = "1001:1060"          -- Define the channels to scan here. Note the following format possibilities...
                                    --   1001:10060 - All channels starting with 1001 and ending with 1060
                                    --   1001,1002,1004 - Just channels 1001, 1002, and 1004
                                    --   1007:1010,1021,1031:1040 - Channels 1007 through 1010, channel 1021, and channels 1031 through 1040
rangedcv = 10                       -- Define the DCV range. If auto-ranging is desired, pass 0
useinputdivider = 1                 -- 1 = True; 0 = False
scancount = 100                     -- Number of times to run the scan
scaninterval = 0                  	-- Delay between the start of each scan (if needed)
nplc = 1

reading_buffer = configure_dcv_scan(nplc, rangedcv, useinputdivider, scaninterval, scanchannels, scancount)


channelcount = scan.stepcount
startindex = 1
endindex = channelcount
total_readings_count = 0
target = channelcount * scancount
delay(0.5)

-- Extract readings while the scan is running....
while(total_readings_count < target) do
    vals = reading_buffer.n		-- print???
    
    while(vals < endindex) do
        delay(0.1)
        vals = reading_buffer.n -- print???
    end
      
    data_string = printbuffer(startindex, endindex, reading_buffer.readings)
    print(data_string)
    --Write_Data(output_data_path, data_string)
    startindex = startindex + channelcount
    endindex = endindex + channelcount
    total_readings_count = total_readings_count + channelcount
end       
