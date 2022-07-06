-- ************************************************************
-- Copyright 2019 Tektronix, Inc.
-- See www.tek.com/sample-license for licensing terms.
-- ************************************************************

-- *******************************************Communication Functions**********************************************************
-- initialize constant value(s) and global vairable(s)
local F4T_port = 5025				-- F4T default ethernet port
local F4T_ip = nil	-- F4T default IP address
local F4T_idString = '"Watlow Electric"'	-- F4T ID string
local tspnet_instID = nil			-- F4T tsp instrument ID
local connection_status = nil

-- Initialize connection between DAQ and controlled instrument
function tspnet_init(remote_ip, remote_port)
	tspnet.timeout = 5.0
	tspnet.reset()
	tspnet_instID = tspnet.connect(remote_ip, remote_port, "*RST\n")
	if tspnet_instID == nil then return nil	end
	tspnet_ipaddress = remote_ip
	tspnet.termination(tspnet_instID, tspnet.TERM_LF)
	
	tspnet_send("*RST")
	return tspnet_instID
end

-- Terminate connection between DAQ and controlled instrument
function tspnet_destroy()
	if tspnet_instID ~= nil then
		tspnet.disconnect(tspnet_instID)
		tspnet_instID = nil
	end
end

-- Send TSP command from DAQ to controlled instrument
function tspnet_send(command)
	tspnet.execute(tspnet_instID, command)
end

-- Query data from controlled instrument to DAQ
function tspnet_query(command, timeout)
	timeout = timeout or 5.0	--Use default timeout of 5 secs if not specified
	tspnet.execute(tspnet_instID, command)
	timer.cleartime()
	
	while tspnet.readavailable(tspnet_instID) == 0 and timer.gettime() < timeout do
		delay(0.1)
	end
	return tspnet.read(tspnet_instID)
end
-- *******************************************Control Functions**********************************************************
-- Initiate connection between DAQ and F4T
function F4T_ConnectToController(ipAddr, portNumber)
	local connection_status = tspnet_init(ipAddr, portNumber)	
	delay(0.1)
	return connection_status
end

-- Terminate connection between DAQ and F4T
function F4T_TerminateController()
	tspnet_destroy()
end

-- Get F4T's instrument ID
function F4T_GetIdString()
	local myID = tspnet_query("*IDN?\n", 5)
	delay(1)
	return myID
end

-- Set F4T's Tempearture Set Point to a specific temperature
function F4T_SetTemperatureSP(tempSP)
	tspnet_send(":SOURCE:CLOOP1:SPOINT " .. tostring(tempSP) .. "\n")
	delay(0.1)
end

-- Get F4T's Tempearture Set Point 
function F4T_GetTemperatureSP()
	tempSP = tspnet_query(":SOURCE:CLOOP1:SPOINT?\n")
	delay(0.1)
	return tempSP
end

-- Get F4T current temperature 
function F4T_GetTemperature()
	temp = tspnet_query("SOURCE:CLOOP1:PVALUE?\n", 5)
	delay(0.1)
	temp = string.format("%.3f", temp)
	return temp
end

-- Activate F4T temperature output to chamber
function F4T_TempOutput_Activate()
	tspnet_send(":OUTPUT1:STATE ON\n")
	delay (0.1)
end

-- Deactivate F4T temperature output to chamber
function F4T_TempOutput_Deactivate()
	tspnet_send(":OUTPUT1:STATE OFF\n")
	delay (0.1)
end

-- Set ramping on set point change
function F4T_SetRamp_SP()
	tspnet_send(":SOURCE:CLOOP1:RACTION SETPOINT\n")
	delay (0.1)
end

-- Set ramp rate scale to minutes
function F4T_SetRampScale_M()
	tspnet_send(":SOURCE:CLOOP1:RSCALE MINUTES\n")
	delay (0.1)
end

-- Set ramp rate
function F4T_SetRampRate(rampRate)
	tspnet_send(":SOURCE:CLOOP1:RRATE " .. tostring(rampRate) .. "\n")
	delay (0.1)
end

function F4T_GetRampRate() 
	rampRate = tspnet_query(":SOURCE:CLOOP1:RRATE?\n")
	delay(0.1)
	return rampRate
end

function F4T_RampOFF()
	tspnet_send(":SOURCE:CLOOP1:RACTION OFF\n")
	delay (0.1)
end

function F4T_GetTemperatureUnits()
	tempUnits = tspnet_query(":UNIT:TEMPERATURE?\n")
	delay(0.1)
	return tempUnits
end

function F4T_SetTemperatureUnits(isDegC)
	if isDegC > 0 then
		tspnet_send(":UNIT:TEMPERATURE C\n")
	else
		tspnet_send(":UNIT:TEMPERATURE F\n")
	end
	delay (0.1)
end

--retrieve the F4T IP address from the config file or create a new one
function F4T_GetIP()
	if usb_exist == 1 then
		-- Open + read ip config file
		file_check = fs.is_file("/usb1/F4T_IP.ini")
		if file_check == true then
			ip_file = file.open("/usb1/F4T_IP.ini", file.MODE_READ)
			F4T_ip = file.read(ip_file, file.READ_ALL)
			file.close(ip_file)
		elseif F4T_ip == nil or file_check == false then
			--allow user to set target IP address and create new ip config file
			F4T_ip = display.input.string("Set target IP address", display.SFORMAT_IP_ADDRESS)	 
			ip_file = file.open("/usb1/F4T_IP.ini", file.MODE_WRITE)
			file.write(ip_file, F4T_ip)
			file.close(ip_file)
		end
	else
		display.settext(display.TEXT1, "Please insert a")
		display.settext(display.TEXT2, "thumbdrive into the front panel")
		tspnet_destroy()
	end
end

-- A function that tests the connection between DAQ and F4T
function test_connection()
	-- connect DAQ to F4T	
	connection_status = F4T_ConnectToController(F4T_ip, F4T_port)
	display.waitevent(1)
	print (connection_status)
	
	-- check for initial tsp connection
	if connection_status == nil then
		display.changescreen(display.SCREEN_USER_SWIPE)
		display.settext(display.TEXT1, "Connection failed")
		display.settext(display.TEXT2, "Please check the connection")
		return 0
	else 
		-- query F4T's ID string
		query_idString = F4T_GetIdString()
		print (query_idString)
		
		-- change to user swipe screen
		display.changescreen(display.SCREEN_USER_SWIPE)
		
		-- check for query ID string nil value
		if query_idString == nil or query_idString == "" then
			display.settext(display.TEXT1, "Failed to query ID")
			display.settext(display.TEXT2, "Please restart F4T")
			
			-- terminate connection to controller
			F4T_TerminateController()
			return 0
		else 
			-- get manufacturer and model number from ID string
			-- controller's name is formated as follows: manufactuer, model and serial number, firmware level.
			-- each variable is separeted by a comma ","
			-- the manufactuer_model variable is getting the manufactuer by getting the index of 
			-- the first comma ","
			_, endPosition = string.find(query_idString, ",")
			manufacturer_model = string.sub(query_idString, 1, endPosition-1)
			
			-- if the manufactuer and model name are not matched
			if manufacturer_model != F4T_idString then
				display.settext(display.TEXT1, "Connection failed")
				display.settext(display.TEXT2, "This isn't a Watlow F4T")
				
				-- terminate connection to controller
				F4T_TerminateController()
				return 0
			else
				display.settext(display.TEXT1, "Connection success")
				display.settext(display.TEXT2, manufacturer_model)
				return 1
			end
		end
	end
end

-- A Function that creates a .csv file in the thumbdrive and stores data from the scanned_data buffer into this new file
function create_and_save_csv(file_name, scanned_data, scanned_channel, number_of_scanned_channel, i, temperature_list, channel_meas_function, scanCount)
	local csv_file = file.open("/usb1/" .. file_name, file.MODE_APPEND)
	local channel_unit = "Set Point Temperature"
	local data_in_row = nil
	local channels = number_of_scanned_channel
	
	for i = 1, number_of_scanned_channel do
		channel_unit = channel_unit .. ", Channel " .. scanned_channel[i] .. " "
		
		if channel_meas_function[i] == dmm.FUNC_DC_VOLTAGE then
			channel_unit = channel_unit .. "(V)"
		elseif channel_meas_function[i] == dmm.FUNC_AC_VOLTAGE then
			channel_unit = channel_unit .. "(ACV)"			
		elseif channel_meas_function[i] == dmm.FUNC_DC_CURRENT then
			channel_unit = channel_unit .. "(A)"
		elseif channel_meas_function[i] == dmm.FUNC_AC_CURRENT then
			channel_unit = channel_unit .. "(AC)"
		elseif channel_meas_function[i] == dmm.FUNC_TEMPERATURE then
			channel_unit = channel_unit .. "(C)"
		elseif channel_meas_function[i] == dmm.FUNC_RESISTANCE or channel_meas_function[i] == dmm.FUNC_4W_RESISTANCE then
			channel_unit = channel_unit .. "(Ohm)"
		elseif channel_meas_function[i] == dmm.FUNC_CAPACITANCE then
			channel_unit = channel_unit .. "(F)"
		elseif channel_meas_function[i] == dmm.FUNC_DIODE then
			channel_unit = channel_unit .. "(Pass)"
		elseif channel_meas_function[i] == dmm.FUNC_CONTINUITY then
			channel_unit = channel_unit .. "(Cont)"	
		elseif channel_meas_function[i] == dmm.FUNC_ACV_FREQUENCY then
			channel_unit = channel_unit .. "(Hz)"
		elseif channel_meas_function[i] == dmm.FUNC_ACV_PERIOD then
			channel_unit = channel_unit .. "(s)"	
		elseif channel_meas_function[i] == dmm.FUNC_DCV_RATIO then
			channel_unit = channel_unit .. "(Ratio)"	
		end
	end
	
	channel_unit = channel_unit .. "\n"
	
	-- write temperature + channel unit header to .csv file
	print(channel_unit)
	file.write(csv_file, channel_unit)
	
	for k = 1, scanCount do 
		data_in_row = temperature_list
	end
	for j = 1, (number_of_scanned_channel * scanCount) do
		data_in_row = data_in_row .. ", " .. scanned_data[i][j]
		if j == channels then
			data_in_row = data_in_row .. "\n"
			channels = channels + number_of_scanned_channel
		end
	end
	channels = number_of_scanned_channel
	file.write(csv_file, data_in_row)
	file.close(csv_file)
end

-- A function that converts normal unit to "buffer" unit used in the buffer.write.format() command
function buffer_unit_conversion(unit)
	buffer_unit = {}
	if unit == "Volt DC" then
		buffer_unit = buffer.UNIT_VOLT
	elseif unit == "Volt AC" then
		buffer_unit = buffer.UNIT_VOLT_AC
	elseif unit == "Ohm" then
		buffer_unit = buffer.UNIT_OHM
	elseif unit == "Amp DC" then
		buffer_unit = buffer.UNIT_AMP
	elseif unit == "Amp AC" then
		buffer_unit = buffer.UNIT_AMP_AC
	elseif unit == "Celsius" then
		buffer_unit = buffer.UNIT_CELSIUS
	elseif unit == "Fahrenheit" then
		buffer_unit = buffer.UNIT_FAHRENHEIT	
	elseif unit == "Farad" then
		buffer_unit = buffer.UNIT_FARAD
	elseif unit == "Hertz" then
		buffer_unit = buffer.UNIT_HERTZ
	elseif unit == "Second" then
		buffer_unit = buffer.UNIT_SECOND
	elseif unit == "Ratio" then
		buffer_unit = buffer.UNIT_RATIO
	end
	return buffer_unit
end

-- A function that display exit text
function display_exit_text()
	-- change to user swipe screen
	display.changescreen(display.SCREEN_USER_SWIPE)
	display.settext(display.TEXT1, "Program exited.")
	display.settext(display.TEXT2, "")
end	
	
-- *******************************************MAIN CODE**********************************************************
local prompt_ID, result = nil
prompt_ID = display.BUTTON_YES
local test_status = nil
local number_of_scanned_channel = 0
local scanned_channel = {}
local scanCount = 1
local channel_meas_function = {}
local file_name = nil
local scanned_data = {}
local exit_command = 0
local temperature_list = {}
local initial_chamber_temperature = nil
local max_number_of_channel1 = nil      --maximum number of scannable channels on a single card
local max_number_of_channel2 = nil
local number_of_temperature = 0
local wait_time = {}
local wait_time_sec = {}
local ramp_rate = {}
local final_temp = nil
local final_ramp = nil
--local value = {}
--local sec = {}
--local milisec = {}
local tempUnits = ""

file_name = "F4T_buffer_" .. localnode.gettime() .. ".csv"

-- change to User Swipe Screen and clear all messages in this swipe screen
display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT1, "")
display.settext(display.TEXT2, "")

-- Check USB 
usb_exist = file.usbdriveexists()

if usb_exist == 1 then
	--retrieve F4T IP address from config file on USB
	F4T_GetIP()
		
	while connection_status == nil do
		display.changescreen(display.SCREEN_USER_SWIPE)
		display.settext(display.TEXT1, "Please Wait ...")
		display.settext(display.TEXT2, "Checking the connection")
		
		-- test LAN connection
		test_status = test_connection()
		
		if test_status == 0 then
			--allow user to set target IP address and create new ip config file
			F4T_ip = display.input.string("Set target IP address", display.SFORMAT_IP_ADDRESS)	 
			ip_file = file.open("/usb1/F4T_IP.ini", file.MODE_WRITE)
			file.write(ip_file, F4T_ip)
			file.close(ip_file)
		end
	end
	
	if test_status == 1 then
		-- check if user wants to monitor chamber temperature or DUT temperature
		monitor_option = display.input.option("Monitor Temperature of:", "Primary Sensor", "Chamber")
		display.waitevent(1)
		
		if monitor_option == display.BUTTON_OPTION1 then
			monitor_channel = "101"    --channel thermocouple is intalled on
			pre_scan_monitor_channel = 1  	--channel thermocouple is intalled on
			DUT = 1
		elseif monitor_option == display.BUTTON_OPTION2 then
			monitor_channel = nil   --channel thermocouple is intalled on
			pre_scan_monitor_channel = nil  	--channel thermocouple is intalled on
			DUT = 0
		else
			exit_command = 1
			display_exit_text()
			tspnet_destroy()
		end
	
		-- Create the scan
		scan.create("") 		-- restart scan list
		
		card1_idString = slot[1].idn
		card2_idString = slot[2].idn
		
		--get the model number of each card, which is the first segment of the ID string
		if card1_idString != "Empty Slot" then
			_, endPosition1 = string.find(card1_idString, ",")
			card1_model = string.sub(card1_idString, 1, endPosition1-1)
			
			if card1_model == "7700" or card1_model == "7706" or card1_model == "7710" then
				max_number_of_channel1 = 20
			elseif card1_model == "7701" or card1_model == "7703" or card1_model == "7707" then
				max_number_of_channel1 = 32
			elseif card1_model == "7705" or card1_model == "7702" or card1_model == "7708" then
				max_number_of_channel1 = 40
			else
				display.settext(display.TEXT1, "Script supports")
				display.settext(display.TEXT2, "cards 7700-7708, and 7710")
			end
		
		else
			display.settext(display.TEXT1, "Please insert")
			display.settext(display.TEXT2, "a switch card into slot 1")
		end
		
		if card2_idString != "Empty Slot" then
			_, endPosition2 = string.find(card2_idString, ",")
			card2_model = string.sub(card2_idString, 1, endPosition2-1)
			
			if card2_model == "7700" or card2_model == "7706" or card2_model == "7710" then
				max_number_of_channel2 = 20
			elseif card2_model == "7701" or card2_model == "7703" or card2_model == "7707" then
				max_number_of_channel2 = 32
			elseif card2_model == "7705" or card2_model == "7702" or card2_model == "7708" then
				max_number_of_channel2 = 40
			else
				display.settext(display.TEXT1, "Script supports")
				display.settext(display.TEXT2, "cards 7700-7708, and 7710")
			end
		end
		
		if card1_model != nil then
			-- get scan functions from slot 1
			for i = 1, max_number_of_channel1 do 
				measure_function = channel.getdmm("101:1" .. max_number_of_channel1, dmm.ATTR_MEAS_FUNCTION)[i] 
			
				-- count the number of channels with measure functions and add that channel to scan list
				if i != pre_scan_monitor_channel and measure_function != dmm.FUNC_NONE and measure_function != nil then
					number_of_scanned_channel = number_of_scanned_channel + 1
					if i < 10 then
						table.insert(scanned_channel, "10" .. i)
					else
						table.insert(scanned_channel, "1" .. i)
					end
					table.insert(channel_meas_function, measure_function)	
					
					-- add that channel to scan list
					if i < 10 then
						scan.add("10" .. i)
					else
						scan.add("1" .. i)
					end
				end
			end
		end
		
		if card2_model != nil then
			-- get scan functions from slot 2
			for i = 1, max_number_of_channel2 do 
				measure_function = channel.getdmm("201:2" .. max_number_of_channel2, dmm.ATTR_MEAS_FUNCTION)[i] 
			
				-- count the number of channels with measure functions and add that channel to scan list
				if measure_function != dmm.FUNC_NONE and measure_function != nil then
					number_of_scanned_channel = number_of_scanned_channel + 1
					if i < 10 then
						table.insert(scanned_channel, "20" .. i)
					else
						table.insert(scanned_channel, "2" .. i)
					end
					table.insert(channel_meas_function, measure_function)	
					
					-- add that channel to scan list
					if i < 10 then
						scan.add("20" .. i)
					else
						scan.add("2" .. i)
					end
				end
			end
		end
		
		print (scanned_channel)
		print (channel_meas_function)
		print (number_of_scanned_channel)
	end
end

-- check for thumbdrive and channel measurement functions 
if usb_exist == 0 then 
	display.settext(display.TEXT1, "Please insert a")
	display.settext(display.TEXT2, "thumbdrive into the front panel")
	tspnet_destroy()
else
	if number_of_scanned_channel == 0  then
		display.settext(display.TEXT1, "Please set measure")
		display.settext(display.TEXT2, "functions to the channels")
		tspnet_destroy()
	end
end

-- Extract the presently programmed temperature units to allow the program to respond in kind. 
tempUnits = F4T_GetTemperatureUnits()
print(tempUnits)
-- Ensure that the temperature controller is communicating values in deg C over the LAN connection...
F4T_SetTemperatureUnits(1)
	
-- if the channels are set, the connection is good, and a usb is inserted
if test_status == 1 and usb_exist == 1 and number_of_scanned_channel > 0 and exit_command == 0 then	
	-- reset and set defbuffer1 buffer's capacity to 100000 
	defbuffer2.clear()
	defbuffer2.capacity = 10
	defbuffer1.clear()
	defbuffer1.capacity = 7000000
	
	if DUT == 1 then
		-- monitor temperature in channel 101
		channel.setdmm(monitor_channel, dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE)
		
		delay(0.5)
	end
	
	-- ask user to input number of Set Point temperatures
	number_of_temperature = display.input.number("Enter number of SP temperatures", display.NFORMAT_INTEGER, 1, 1, 10)

	-- if user wants to exit from "Enter number of tempratures" dialog
	if number_of_temperature == nil then
		exit_command = 1
		display_exit_text()
		F4T_TerminateController()
	end
	
	if exit_command == 0 then
		--ask user if they would like to implement a settle time 
		ramping_choice, result = display.input.prompt(display.BUTTONS_YESNO, "Would you like to apply a custom Ramp Rate for each Set Point?")
		if ramping_choice == display.BUTTON_YES then
			ramping = 1
		else
			ramping = 0
		end
	end
	
	-- if user wants to keep continuing after "Enter number of temperatures" dialog
	if number_of_temperature and wait_time != nil then 
		--set point temperature parameters
		default = 25
		minimum = -75
		maximum = 65
		tempunit = "C"
		
		delay(0.5)	
		-- ask user to enter an array of Set Point temperatures
		for i = 1, number_of_temperature do
			temperature_list[i] = display.input.number ("Enter SP" .. i .. " Temperature (" .. tempunit .. ")", display.NFORMAT_DECIMAL, default, minimum, maximum)	
			-- if user want to exit in "Enter SP temprature #i" dialog
			if temperature_list[i] == nil then 
				exit_command = 1
				display_exit_text()
				break 
			end
			-- ask user to input length of delay after SP Temp is met before scan starts
			wait_time[i] = display.input.number("Enter SP" .. i .. " Soak Time (min)", display.NFORMAT_DECIMAL, 15, 0)
			
			-- if user wants to exit from "Enter delay time" dialog
			if wait_time[i] == nil then
				exit_command = 1
				display_exit_text()
				break
			else
				--convert delay value to seconds
				wait_time_sec[i] = wait_time[i] * 60
			end
			
			if ramping == 1 then
				F4T_SetRamp_SP()
				F4T_SetRampScale_M()
				
				-- ask user to input ramp rate for each SP
				ramp_rate[i] = display.input.number ("Enter SP" .. i .. " Ramp Rate (" .. tempunit .. "/min)", display.NFORMAT_DECIMAL, 1, 1, 30)	
				-- if user want to exit script from dialog
				if ramp_rate[i] == nil then 
					exit_command = 1
					display_exit_text()
					break 
				end
			end
		end
		
		if exit_command == 0 then
			--ask user for SP tolerance in degrees C
			tolerance = display.input.number ("SP Temperature Tolerance (deg)", display.NFORMAT_DECIMAL, 3, 0, 5)	
			-- if user want to exit in "Enter SP temprature #i" dialog
			if tolerance == nil then 
				exit_command = 1
				display_exit_text()
			end
		end
		
		if exit_command == 0 then
			--ask user if they would like to implement a settle time 
			final_choice, result = display.input.prompt(display.BUTTONS_YESNO, "Would you like to apply a final ending temperature?")
			display.waitevent(1)
			if final_choice == display.BUTTON_YES then
				final_temp = display.input.number("Enter Final Temperature (" .. tempunit .. ")", display.NFORMAT_DECIMAL, 23, minimum, maximum)
				if ramping == 1 then
					final_ramp = display.input.number("Enter Final Ramp Rate (" .. tempunit .. "/min)", display.NFORMAT_DECIMAL, 1, 1, 30)
				end
			end
		elseif exit_command == 1 then
			F4T_TerminateController()
		end
		
		-- if user wants to keep continuing after "Enter SP temperature #i" dialog
		if exit_command == 0 and DUT == 1 then
			--permanent_buffer = buffer.make(2900000, buffer.STYLE_WRITABLE_FULL)
			
			--change active buffer back to defbuffer1
			display.activebuffer = defbuffer1
			
			-- get initial chamber temperature 
			channel.close(monitor_channel)
			delay(0.5)
			initial_chamber_temperature = dmm.measure.read()
		
			for i = 1, number_of_temperature do
				-- get +/- 0.5% range margin of error to hit SP temperature
				upper_limit = temperature_list[i] + tolerance	
				lower_limit = temperature_list[i] - tolerance				
				
				-- set Set Point temperature and activate temperature output
				F4T_SetTemperatureSP(temperature_list[i])
				if ramping == 1 then
					F4T_SetRampRate(ramp_rate[i])
				end
				F4T_TempOutput_Activate()
				delay(1)
					
				-- get initial chamber temperature 
				channel.close(monitor_channel)
				delay(0.5)
				initial_chamber_temperature = dmm.measure.read()
				display.changescreen(display.SCREEN_USER_SWIPE)
				
				--initial_chamber_temperature < temperature_list[i]
				while initial_chamber_temperature > upper_limit or initial_chamber_temperature < lower_limit do
					initial_chamber_temperature = dmm.measure.read()
					
					display.settext(display.TEXT1, "DUT Status:")
					display.settext(display.TEXT2, "Waiting to reach " ..temperature_list[i].. "(" .. tempunit .. ")")
				end
				
				--initial_chamber_temperature >= temperature_list[i]
				if initial_chamber_temperature < upper_limit and initial_chamber_temperature > lower_limit then
					display.changescreen(display.SCREEN_USER_SWIPE)
					display.settext(display.TEXT1, "Set Point " ..i.. " Met")
					display.settext(display.TEXT2, "Soaking for " .. wait_time[i] .. "(min)")
					
					delay(wait_time_sec[i])
				end
				
				--  view scan in progress
				display.changescreen(display.SCREEN_SCAN_SWIPE)
				
				-- trigger pre-scan monitor
				trigger.model.initiate()
				waitcomplete()
				scanState, scanCount, stepCount = scan.state()	
				printbuffer(1, (number_of_scanned_channel * scanCount), defbuffer1)
				
				-- append data from defbuffer1 to a permanent storage buffer
		--		for j = 1, (number_of_scanned_channel * scanCount) do
		--			value[j] = defbuffer1.readings[j]
		--			sec[j] = defbuffer1.seconds[j]
		--			milisec[j] = defbuffer1.fractionalseconds[j] 
		--			unit = buffer_unit_conversion(defbuffer1.units[j])
		--			buffer.write.format(permanent_buffer, unit, buffer.DIGITS_6_5, buffer.UNIT_CELSIUS) 
		--		end 

				--get data from multiple scans
		--		for k = 1, scanCount do
		--			for j = 1, number_of_scanned_channel do
		--				buffer.write.reading(permanent_buffer, value[k], temperature_list[i], sec[k], milisec[k], buffer.STAT_ORIGIN, scanned_channel[j])
		--			end
		--		end
				
				-- save data in defbuffer1 into an appendable array
				scanned_data[i] = {}
				for j = 1, (number_of_scanned_channel * scanCount) do
					table.insert(scanned_data[i], defbuffer1[j])
				end
				
				-- if user does not exit anytime in the program 
				if exit_command == 0 then 
					usb_exist = file.usbdriveexists()
					-- if the thumbdrive is still insterted in front panel 
					if usb_exist == 1 then
						-- save data into a csv file and store into the inserted thumbdrive
						create_and_save_csv(file_name, scanned_data, scanned_channel, number_of_scanned_channel, i, temperature_list[i], channel_meas_function, scanCount)
					end
				end
			end
		elseif exit_command == 0 and DUT == 0 then
		--	permanent_buffer = buffer.make(2900000, buffer.STYLE_WRITABLE_FULL)
	
			for i = 1, number_of_temperature do
				-- get +/- 0.5% range margin of error to hit SP temperature
				upper_limit = temperature_list[i] + tolerance	
				upper_limit = tostring(upper_limit)
				lower_limit = temperature_list[i] - tolerance	
				lower_limit = tostring(lower_limit)			
				
				-- set Set Point temperature and activate temperature output
				F4T_SetTemperatureSP(temperature_list[i])
				if ramping == 1 then
					F4T_SetRampRate(ramp_rate[i])
				end
				F4T_TempOutput_Activate()
				delay(1)
				display.changescreen(display.SCREEN_USER_SWIPE)
					
				-- get initial chamber temperature 
				initial_chamber_temperature = F4T_GetTemperature()
				
				--initial_chamber_temperature < temperature_list[i]
				while initial_chamber_temperature > upper_limit or initial_chamber_temperature < lower_limit do
					initial_chamber_temperature = F4T_GetTemperature()
					
					display.settext(display.TEXT1, "Chamber Status:")
					display.settext(display.TEXT2, "Process Value: " .. initial_chamber_temperature .. "(" .. tempunit .. ")")
				end
				
				--initial_chamber_temperature >= temperature_list[i]
				if initial_chamber_temperature < upper_limit and initial_chamber_temperature > lower_limit then
					display.changescreen(display.SCREEN_USER_SWIPE)
					display.settext(display.TEXT1, "Set Point " ..i.. " Met")
					display.settext(display.TEXT2, "Soaking for " .. wait_time[i] .. "(min)")
					
					delay(wait_time_sec[i])
				end
				
				--  view scan in progress
				display.changescreen(display.SCREEN_SCAN_SWIPE)
				
				-- trigger pre-scan monitor
				trigger.model.initiate()
				waitcomplete()
				scanState, scanCount, stepCount = scan.state()	
				printbuffer(1, (number_of_scanned_channel * scanCount), defbuffer1)
				
					-- append data from defbuffer1 to a permanent storage buffer
		--		for j = 1, (number_of_scanned_channel * scanCount) do
		--			value[j] = defbuffer1.readings[j]
		--			sec[j] = defbuffer1.seconds[j]
		--			milisec[j] = defbuffer1.fractionalseconds[j] 
		--			unit = buffer_unit_conversion(defbuffer1.units[j])
		--			buffer.write.format(permanent_buffer, unit, buffer.DIGITS_6_5, buffer.UNIT_CELSIUS) 
		--		end 

				--get data from multiple scans
		--		for k = 1, scanCount do
		--			for j = 1, number_of_scanned_channel do
		--				buffer.write.reading(permanent_buffer, value[k], temperature_list[i], sec[k], milisec[k], buffer.STAT_ORIGIN, scanned_channel[j])
		--			end
		--		end
		
				-- save data in defbuffer1 into an appendable array
				scanned_data[i] = {}
				for j = 1, (number_of_scanned_channel * scanCount) do
					table.insert(scanned_data[i], defbuffer1[j])
				end
				
				-- if user does not exit anytime in the program 
				if exit_command == 0 then 
					usb_exist = file.usbdriveexists()
					-- if the thumbdrive is still insterted in front panel 
					if usb_exist == 1 then
						-- save data into a csv file and store into the inserted thumbdrive
						create_and_save_csv(file_name, scanned_data, scanned_channel, number_of_scanned_channel, i, temperature_list[i], channel_meas_function, scanCount)
					end
				end
			end		
		end
		
		--wait until chamber reaches ambient temperature before killing program
		if final_temp != nil then
			if DUT == 1 then
				-- get initial chamber tempreature 
				channel.close(monitor_channel)
				delay(0.5)
				initial_chamber_temperature = dmm.measure.read()
				display.changescreen(display.SCREEN_USER_SWIPE)
				
				-- set Set Point temperature and activate temperature output
				F4T_SetTemperatureSP(final_temp)
				if ramping == 1 then
					F4T_SetRampRate(final_ramp)
				end
				F4T_TempOutput_Activate()
				delay(1)
				
				-- get +/- 0.5% range margin of error to hit SP temperature
				upper_final_limit = final_temp + tolerance	
				lower_final_limit = final_temp - tolerance	
				
				while initial_chamber_temperature > upper_final_limit or initial_chamber_temperature < lower_final_limit do
					initial_chamber_temperature = dmm.measure.read()
					
					display.settext(display.TEXT1, "DUT Status:")
					display.settext(display.TEXT2, "Waiting to reach " ..final_temp.. "(" .. tempunit .. ")")
				end
			elseif DUT == 0 then
				-- get initial chamber tempreature 
				initial_chamber_temperature = F4T_GetTemperature()
				display.changescreen(display.SCREEN_USER_SWIPE)
				
				-- set Set Point temperature and activate temperature output
				F4T_SetTemperatureSP(final_temp)
				if ramping == 1 then
					F4T_SetRampRate(final_ramp)
				end
				F4T_TempOutput_Activate()
				delay(1)
				
				-- get +/- 0.5% range margin of error to hit SP temperature
				upper_final_limit = final_temp + tolerance	
				lower_final_limit = final_temp - tolerance	
				upper_final_limit = tostring(upper_final_limit)
				lower_final_limit = tostring(lower_final_limit)
				
				while initial_chamber_temperature > upper_final_limit or initial_chamber_temperature < lower_final_limit do
					initial_chamber_temperature = F4T_GetTemperature()
					
					display.settext(display.TEXT1, "Chamber Status:")
					display.settext(display.TEXT2, "Process Value: " .. initial_chamber_temperature .. "(" .. tempunit .. ")")
				end
			end
		end
		
		F4T_TempOutput_Deactivate()
		F4T_RampOFF()
		delay(1)
		
		-- create a .csv file and save data to this .csv file 
		for i = 1, number_of_temperature do
			for j = 1, (number_of_scanned_channel * scanCount) do
				print (scanned_data[i][j])
			end
		end
			
		-- display a message to let user know the test is done
		display.input.prompt(display.BUTTONS_OK, "Scan is finished. Data is saved to thumbdrive in " .. file_name)
		
		display.changescreen(display.SCREEN_USER_SWIPE)
		display.settext(display.TEXT1, "Program terminated.")
		display.settext(display.TEXT2, file_name)
	end
end

tspnet_destroy()