--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

If_Then_Branching.tsp

In general, the 260x and Test Script Language uses the 'if' keyword to do conditional branching. An 'if'
statement tests its condition and exeuctes its 'then' part of its 'else' part accordingly. The 'else'
part is optional.

When your write nested 'if's, you can use 'elseif'. It is similar to an 'else' followed by an 'if', but
it avoides the need for multiple 'end' statements.

This tutorial creates a linear sweep, using a number of 'if..then..else' statements for conditional
branching.

One interesting technique used in this example is the use of 'aliasing'. The use of aliasing 
attributes is used to improve execution speed.

	- 2602B
	- 2604B
	- 2606B
	- 2612B
	- 2614B
	- 2634B
	- 2636B

Rev1: JLT 09/11/05
Rev2: BCO 05/02/19
]]--

function linearSweep(channel,func,start,stop,step)
	reset()
	-- Check to see if a channel parameter is available. Prompt from display if not sent.
	-- This section uses nested 'if' statement. Also note how the variable 'channel' is used to alias
	-- the attribute 'smua' or 'smub'.
 
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
            end
            start = display.prompt("+0.0000E+0", " V", "Enter the start value", 1, -40, 40)
       	end

	-- Check to see if a stop value is available. Prompt from display if not sent. 
	-- Stop value is dependent on the function. 

       	if (stop==nil) then
        	if (func=="amps") then
            	stop = display.prompt("+0.0000E+0", " I", "Enter the stop value", 1, -3, 3)
            end
            stop = display.prompt("+0.0000E+0", " V", "Enter the stop value", 10, -40, 40)
       	end

	-- If the stop value

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
							
											