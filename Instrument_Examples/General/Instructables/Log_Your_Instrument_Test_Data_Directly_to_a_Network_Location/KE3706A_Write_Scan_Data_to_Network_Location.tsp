local echo_cmd = 0		-- Useful for debugging commands being sent to 
						-- remote instrument. 

--[[ ==============================================================================
	Start TSP-Net Function Wrappers ===============================================
]] -- =============================================================================
-- ================================================================================
-- Initialize connection between the instrument and remote host
function tspnet_connect(remote_ip, remote_port, host_id, initialization_string)
	host_id = tspnet.connect(remote_ip, 
							 remote_port, 
							 initialization_string)
							 
	if host_id == nil then return nil end
	
	tspnet_ipaddress = remote_ip
	tspnet.termination(host_id, tspnet.TERM_LF)
	
	return host_id
end

-- Send command to controlled remote instrument
function tspnet_write(host_id, command)
	tspnet.execute(host_id, command .. "\n")	
	if echo_cmd == 1 then
		print(command)
	end
end

-- Query data from the controlled instrument and return as a string
function tspnet_query(host_id, command, timeout)
	timeout = timeout or 5.0 --Use default timeout of 5 secs if not specified
	tspnet_write(host_id, command)
	
	while tspnet.readavailable(host_id) == 0 and timer.gettime() < timeout do
		delay(0.1)
	end
	return tspnet.read(host_id)
end

-- Terminate the connection between the master and subordinate instrument
function tspnet_disconnect(host_id)
	if host_id ~= nil then
		tspnet.disconnect(host_id)
		host_id = nil
	end
end
--[[ 
	End TSP-Net Function Wrappers 
]]--
--[[ 
	Start Scan Configuration Function Wrappers 
]]--
function configure_dcv_scan(nplc, dcv_range, use_input_divider, scan_interval, 
         scan_channels, scan_count)
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
        -- Establish the settings that will apply the interval between the start 
        -- of scans
    	trigger.timer[1].reset() 					-- Ensure the timer gets to a 
    												-- known relative time start 
    												-- point
        trigger.timer[1].count = 0 					-- No reapeating timer events
        trigger.timer[1].delay = scan_interval 		-- Apply the anticipated scan 
        											-- interval 
        trigger.timer[1].stimulus = scan.trigger.EVENT_MEASURE_COMP 
        trigger.timer[1].passthrough = false 		-- Trigger only initiates the 
        											-- delay
        trigger.blender[1].reset() 					-- Configure the blender 
        											-- stimulus...
        trigger.blender[1].orenable = true 			-- ... for OR'ing operation
        trigger.blender[1].stimulus[1] = trigger.timer[1].EVENT_ID 	-- ... to 
        											-- respond/notify upon a timer
        											-- event
        trigger.blender[1].stimulus[2] = scan.trigger.EVENT_SCAN_READY 	-- ... or
        											-- when then scan is ready 
        											-- (configured)
        scan.trigger.arm.stimulus = trigger.blender[1].EVENT_ID -- Key triggering 
        											-- off of the blender event
    end
    
    scan.create(scan_channels)					-- Create the scan 
    scan.scancount = scan_count 				-- Set the Scan Count
    reading_buffer = dmm.makebuffer(scan.scancount * scan.stepcount) -- Configure 
    																-- the buffer
    scan.background(reading_buffer) 			-- Execute Scan and save to buffer
    
    -- Update the instrument display
    display.clear()
    display.setcursor(1, 1)
    display.settext("KE3706A DCV Scan")
    display.setcursor(2, 1)
    display.settext("$BSend Data Direct to Server")
	return reading_buffer
end
--[[ 
	End Scan Configuration Function Wrappers 
]]--
-- ================================================================================
--[[ ******************************************************************************

		MAIN PROGRAM STARTS HERE 
		
***********************************************************************************
]]
scanchannels = "1001:1020"          -- Define the channels to scan here. Note the 
									-- following format possibilities...
                                    --   1001:10060 - All channels starting with 
                                    --     1001 and ending with 1060
                                    --   1001,1002,1004 - Just channels 1001, 
                                    --     1002, and 1004
                                    --   1007:1010,1021,1031:1040 - Channels 
                                    --     1007 through 1010, channel 1021, and 
                                    --     channels 1031 through 1040
rangedcv = 10                       -- Define the DCV range. If auto-ranging is
									--   desired, pass 0
useinputdivider = 1                 -- 1 = True; 0 = False
scancount = 3600*8                  -- Number of times to run the scan
scaninterval = 1                  	-- Delay between the start of each scan (if 
									-- needed)
nplc = 1

reading_buffer = configure_dcv_scan(nplc, rangedcv, useinputdivider, scaninterval, 
									scanchannels, scancount, reading_buffer)
channelcount = scan.stepcount
startindex = 1
endindex = channelcount
total_readings_count = 0
target = channelcount * scancount
delay(0.5)
data_string = ""

-- Intitialize overall tsp-net configuration...
tspnet.reset()
tspnet.timeout = 5.0

-- Establish variables for reomote connection
host_ipaddress = "192.168.1.111"	-- Enter your server IP address here
host_port = 60000
host_connection_id = nil
filename = os.date("data_%Y-%m-%d_%H-%M-%S.csv") -- timestamp the file name

-- Connect to the server/host
host_connection_id = tspnet_connect(host_ipaddress, 
									host_port, 
									host_connection_id, 
					 			    filename)

-- Extract readings while the scan is running....
while(total_readings_count < target) do
    vals = reading_buffer.n		
    
    -- wait unit the buffer is ready with as scan's worth of readings
    while(vals < endindex) do
        delay(0.1)
        vals = reading_buffer.n 
    end
    
    -- build the string of channels we want to write to the server
    for i = startindex, endindex, 1 do
    	if i == startindex then
    		data_string = reading_buffer.readings[i]
    	else
    		data_string = data_string .. "," .. reading_buffer.readings[i]
    	end
    end
    
    -- Send the scan data to the server
    tspnet_write(host_connection_id, data_string)
    
    -- Update the variables that handle the buffer indexing
    startindex = startindex + channelcount
    endindex = endindex + channelcount
    total_readings_count = total_readings_count + channelcount
end    


-- After the scanning is complete, notify the server that we are done 
-- and disconnect
tspnet_write(host_connection_id, "done")
tspnet_disconnect(host_connection_id)

display.clear()
display.setcursor(1, 1)
display.settext("KE3706A DCV Scan")
display.setcursor(2, 1)
display.settext("$RScanning $BComplete!!!")
