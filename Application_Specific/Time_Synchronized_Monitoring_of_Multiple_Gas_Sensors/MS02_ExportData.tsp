--[[
	
Script: Synchronized Measurement of Sensors Across TSP Nodes - Exporting Data
Written by: Keithley Applications Engineering (Josh Brown)
`
***********************************************************
*** Copyright 2023 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************
]]

function export_data_to_usb_drive()
	-- Check for presence of USB drive
	if (file.usbdriveexists() == 1) then
		response = display.BUTTON_YES
	else
		response = display.input.prompt(display.BUTTONS_YESNO, "Insert a USB flash drive.\nPress Yes to write data or No to not write data.")
	end
	
	if (response == display.BUTTON_YES) then
		if (file.usbdriveexists() == 1) then
			filename = os.date("/usb1/data_%Y-%m-%d_%H-%M-%S.csv") 			-- timestamp the file name
			filenumber = file.open(filename, file.MODE_WRITE)
			
			file.write(filenumber, "Relative Time,Node 1 Readings,Node 2 Readings,Node 3 Readings,Node 4 Readings,Node 5 Readings,Node 6 Readings,Node 7 Readings,Node 8 Readings\n")
			
			-- Print out the measured values in a two-column format.
			--print("\nIteration:\tReading:\tNode 1:\tNode 2:\tNode 3:\tNode 4:\Node 5:\tNode 6:\tNode 7:\tNode 8: \n")
			
			-- Determine if there is an imbalance in data points; capture only the lowest quantity to avoid error
			-- exposed on the front panel. There's a tendency for the master node to be one reading behind the 
			-- rest of the nodes. 
			local n1 = node[1].defbuffer1.endindex
			
			if node[2].defbuffer1.endindex < n1 then
				n1 = node[2].defbuffer1.endindex
			end
			if node[3].defbuffer1.endindex < n1 then
				n1 = node[3].defbuffer1.endindex
			end
			if node[4].defbuffer1.endindex < n1 then
				n1 = node[4].defbuffer1.endindex
			end
			if node[5].defbuffer1.endindex < n1 then
				n1 = node[5].defbuffer1.endindex
			end
			if node[6].defbuffer1.endindex < n1 then
				n1 = nnode[6].defbuffer1.endindex6
			end
			if node[7].defbuffer1.endindex < n1 then 
				n1 = node[7].defbuffer1.endindex
			end
			if node[8].defbuffer1.endindex < n1 then
				n1 = node[8].defbuffer1.endindex
			end
			
			-- Change over to the user swipe screen to indicate write progress...
			display.clear()
			display.changescreen(display.SCREEN_USER_SWIPE)
			line_1_txt = string.format("Saving data...")
			local savepct = 0.0
			line_2_txt = string.format("Write Progress: %0.2f %s", savepct, string.char(37))
			display.settext(display.TEXT1, line_1_txt)
			display.settext(display.TEXT2, line_2_txt)
			
			for i = 1, n1 do
				--[[print(node[1].defbuffer1.relativetimestamps[i], node[1].defbuffer1.readings[i], 
				                                                   node[2].defbuffer1.readings[i],
				                                                   node[3].defbuffer1.readings[i],
				                                                   node[4].defbuffer1.readings[i],
				                                                   node[5].defbuffer1.readings[i],
				                                                   node[6].defbuffer1.readings[i],
				                                                   node[7].defbuffer1.readings[i],
				                                                   node[8].defbuffer1.readings[i])]]
				file.write(filenumber, string.format("%g,%g,%g,%g,%g,%g,%g,%g,%g\n", node[1].defbuffer1.relativetimestamps[i], node[1].defbuffer1.readings[i],
																															   node[2].defbuffer1.readings[i],
																															   node[3].defbuffer1.readings[i],
																															   node[4].defbuffer1.readings[i],
																															   node[5].defbuffer1.readings[i],
																															   node[6].defbuffer1.readings[i],
																															   node[7].defbuffer1.readings[i],
																															   node[8].defbuffer1.readings[i]
																															   ))
				-- Update every 1000 writes
				if math.mod(i, 1000) == 0 then
					savepct = i/n1 * 100
					line_2_txt = string.format("Write Progress: %0.2f %s", savepct, string.char(37))
					display.settext(display.TEXT2, line_2_txt)
				end
			end
			file.close(filenumber)
		else
			response = display.input.prompt(display.BUTTONS_OK,
			"No drive detected. Allow more time after inserting a drive.")
		end
	end
end

export_data_to_usb_drive()
waitcomplete()