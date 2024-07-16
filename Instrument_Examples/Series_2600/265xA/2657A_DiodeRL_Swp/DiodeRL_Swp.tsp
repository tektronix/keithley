--[[
	DiodeRL_Swp(vstart, vstop, vstep, irange, ilimit, sourceDelay)
	
	Description: This function uses the trigger model and built-in sweeping function to create a linear
	voltage sweep to measure the reverse leakage of a diode.  
	
	Using this method is useful when there is a need to send or receive external triggers from another instrument
	or device handler.  
				
	Parameters:
		vstart: The starting voltage of the diode reverse voltage sweep.
		vstop: The stopping voltage of the diode reverse voltage sweep.  
		vstep: The step voltage of the diode reverse voltage sweep (how much the voltage changes per step).
		irange: current measurement range, set to value or set to "auto" to enable autorange.
		ilimit: The current limit of the voltage source. 		
		sourceDelay: The delay between the start of source and the source complete event.
		
	Example Usage:
	DiodeRL_Swp(0, 1000, 10, 100e-9, 0.01, 0.05)
--]]

function DiodeRL_Swp(vstart,vstop,vstep,irange,ilimit,sourceDelay)

	--Reset and initialize instrument
	reset()
	status.reset()
	errorqueue.clear()
	
	--Configure source function as 2W DCVOLTS
	smua.source.func = smua.OUTPUT_DCVOLTS
	smua.sense = smua.SENSE_LOCAL
	
	--Define a local variable to store the number of points in the sweep
	local l_numPoints 
	
	--Calculate the number of points in the sweep based on the start and stop values
	l_numPoints = math.abs((vstop - vstart) / vstep) + 1
	
	--Set up source range
	if math.abs(vstart) > math.abs(vstop) then 
		smua.source.rangev = vstart
	else
		smua.source.rangev = vstop
	end 
	
	--Set up source delay
	smua.source.delay = sourceDelay
	
	--Set up current compliance
	smua.source.limiti = ilimit
	
	--Set up current measurement range
	if irange == "auto" then
		smua.measure.autorangei = smua.AUTORANGE_ON
	else
		smua.measure.autorangei = smua.AUTORANGE_OFF
		smua.measure.rangei = irange
	end 
	
	--Set the integration time
	smua.measure.nplc = 1
		
	--Configure the reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode = 0
	smua.nvbuffer1.collecttimestamps = 1
	smua.nvbuffer1.collectsourcevalues = 0
	smua.nvbuffer1.fillmode = smua.FILL_ONCE
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode = 0
	smua.nvbuffer2.collecttimestamps = 1
	smua.nvbuffer2.collectsourcevalues = 0
	smua.nvbuffer2.fillmode = smua.FILL_ONCE

	--Configure the source lsweep
	smua.trigger.source.linearv(vstart, vstop, l_numPoints)
	smua.trigger.source.action = smua.ENABLE
	smua.trigger.source.stimulus = 0
	
	--Configure measurements during the sweep
	smua.trigger.measure.action = smua.ENABLE
	smua.trigger.measure.stimulus = 0
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	
	--Configure trigger model parameters
	smua.trigger.count = l_numPoints
	smua.trigger.arm.count = 1
	
	--Turn on the output
	smua.source.output = 1
	
	--Initiate the sweep and wait until sweep is complete before proceeding to next command
	smua.trigger.initiate()
	waitcomplete()
	
	--Turn off the output
	smua.source.output = 0		
end


--This function prints the data from the smua.nvbuffer1 and smua.nvbuffer2 reading buffers into three separate columns.
function printData()
	if smua.nvbuffer1.n == 0 then 
		print("No readings in buffer")
	else	
		print("Timestamps\tCurrent\tVoltage")
		for i = 1, smua.nvbuffer1.n do 
			print(string.format("%g\t%g\t%g", smua.nvbuffer1.timestamps[i], smua.nvbuffer1.readings[i], smua.nvbuffer2.readings[i]))
		end
	end
end	
