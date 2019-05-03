--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

DisplayMenu.tsp

Adds menus to the front panel display that forces the user to enter values from the front panel. The example also
prompts the use for specific values where necessary.


Commands used in this example:

display.menu(name, items)
Where:
		name    	Menu name to display on the top line.
		items    	Menu items to display on the bottom line.
		
display.prompt(format, units, help[,default, min, max])
Where:
		format   	Define format string for the input field using 0s, the decimal point (.), 
					polarity sign (+) and E for exponent. 
		units   	Set units text string for top line (8 characters maximum).
		help   		Text string to display on the bottom line (32 characters maximum).
		default     Set the default value for the parameter. 
		min   		Set the minimum input value that can be set.
		max   		Set the maximum input value that can be set.
				

		
Rev1: JLT 7.16.2005
]]--

-- Let's create a voltage or current sweep function that forces the use to respond to menus on the front panel.
--
-- Parameters:  
--		channel - Sets the SourceMeter channel. Accepts 'smua' for SourceMeter
--			  	  Channel A and 'smub' for SourceMeter Channel B.
--		func - Sets the sourcing function. Accepts "amps" or "volts".
--		start - Starting value of the sweep
--		stop - Ending value of the sweep
--		step - Sets the step value in the sweep.
--
function linearSweep(channel,func,start,stop,step)
	reset()
	-- Check to see if a channel parameter is available. Prompt from display if not sent.
	-- This is the first section where we put up a user menu display.

	if (channel==nil) then
		channel=display.menu("Select Channel: ","smua smub")
		if (channel=="smua") then
			channel=smua
		else
		channel=smub
		end
	end	
	
	-- Check to see if a function parameter is available. Prompt from display if not sent.

	if (func==nil) then
		func = display.menu("Select Source: ","amps volts")
	end
	
	-- Check to see if a start value is available. Prompt from display if not sent. 
	-- Start value is dependent on the function. 

    if (start==nil) then
    	if (func=="amps") then
        	start = display.prompt("+0.0000E+0", " I", "Enter the start value", 1e-3, -3, 3)
        else
           	start = display.prompt("+0.0000E+0", " V", "Enter the start value", 1, -40, 40)	
        end
    end

	-- Check to see if a stop value is available. Prompt from display if not sent. 
	-- Stop value is dependent on the function. 

    if (stop==nil) then
    	if (func=="amps") then
        	stop = display.prompt("+0.0000E+0", " I", "Enter the stop value", 1, -3, 3)
        else
           	stop = display.prompt("+0.0000E+0", " V", "Enter the stop value", 10, -40, 40)            	
        end
    end

	-- Check to see if step value is available. Prompt from display if not sent. 

	if (step==nil) then
		if (func=="amps") then
			step = display.prompt("+0.0000E+0", " I", "Enter the step size", 1e-3, -3, 3)
		else
			step = display.prompt("+0.0000E+0", " V", "Enter the step size", 0.1, -40, 40)
		end
 	end

	-- Setup source parameters here depending on the selection of Current or Voltage and the Channel.
	-- To set the appropriate range, determine the maximum value between either the 'start' or 'stop
	-- value. Perform an absolute value function to use the correct value in the command.

	fixedrange = math.max(math.abs(start),math.abs(stop))

	channel.source.autorangei = channel.AUTORANGE_OFF
	channel.source.autorangev = channel.AUTORANGE_OFF
	channel.measure.autorangei = channel.AUTORANGE_OFF
	channel.measure.autorangev = channel.AUTORANGE_OFF
	
	channel.source.output = channel.OUTPUT_OFF
	
	if (func=="amps") then
		channel.source.func = channel.OUTPUT_DCAMPS
		channel.source.leveli = 0
		channel.source.rangei = fixedrange
		channel.measure.autozero = channel.AUTOZERO_OFF
		if (channel=='smua') then
			display.smua.measure.func = display.MEASURE_DCVOLTS
		else
		display.smub.measure.func = display.MEASURE_DCVOLTS
		end	
		channel.measure.rangev = 40
		
	else
		channel.source.func = channel.OUTPUT_DCVOLTS
		channel.source.levelv = 0
		channel.source.rangev = fixedrange
		channel.measure.autozero = channel.AUTOZERO_OFF
		if (channel=='smua') then
			display.smua.measure.func = display.MEASURE_DCAMPS
		else
			display.smub.measure.func = display.MEASURE_DCAMPS
		end
		channel.measure.rangei = 3
		
	end

	-- Define and set specific variables 

	ireadings = {}
	vreadings = {}
	sweep_index = 1
	newlevel = start
	points = math.ceil(((stop-start)/step)+1)

	-- Set the output to the initial value 

	if (func=="amps") then
		channel.source.leveli = start
	else
		channel.source.levelv = start
	end

	-- Set Display to front Panel

	display.screen = 2

	-- Turn output ON depending on channel selected

	channel.source.output = channel.OUTPUT_ON

	-- Execute sweep. Measure both I and V. Index the new level by the step value in order to 
	-- provide the 'channel.measureivandstep' command with the next value.
	
	while (sweep_index < points+1) do
		newlevel = newlevel + step	
		ireadings[sweep_index], vreadings[sweep_index] = channel.measureivandstep(newlevel)
		sweep_index = sweep_index + 1
	end		 
		
	-- Turn output OFF depending on channel selected

	channel.source.output = channel.OUTPUT_OFF   

	-- Return Readings
	
	for index = 1, points do
		print(ireadings[index], vreadings[index])
	end  
	
       
end

linearSweep()				-- This forces the function to execute and forces user input since none of the 
							-- parameters are included in the function.
							
											