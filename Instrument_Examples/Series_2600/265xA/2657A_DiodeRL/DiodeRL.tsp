--[[
	DiodeRL(vstart, vstop, vstep, irange, ilimit)
	
	Description: This function uses a 'for' loop to configure a reverse voltage sweep on a diode
		and collect leakage current measurements.  
		
	This demonstrates a very simple method of performing a linear voltage sweep on the Model 2657A. 
	
	Parameters:
		vstart: The starting voltage of the diode reverse voltage sweep
		vstop: The stopping voltage of the diode reverse voltage sweep.  
		vstep: The step voltage of the diode reverse voltage sweep (how much the voltage changes per step)
		irange: current measurement range, set to value or set to "auto" to enable autorange
		ilimit: The current limit of the voltage source. 		
		
	Additional Notes: 
		Source delay is automatically added to each point of this sweep because the smua.source.levelv command is used.
		Source delay varies by voltage range. 
		If the timing of the source is critical to your application, please use the DiodeRL_Swp function instead. 
	
	Example Usage:
	DiodeRL(0, 1000, 100, 100e-9, 0.01)
--]]

function DiodeRL(vstart,vstop,vstep,irange,ilimit)

	--Reset and initialize instrument
	reset()
	status.reset()
	errorqueue.clear()
	
	--Configure source function as 2W DCVOLTS
	smua.source.func = smua.OUTPUT_DCVOLTS
	smua.sense = smua.SENSE_LOCAL
		
	--Define local variable to store the number of points in the sweep
	local l_numPoints 
	
	--Calculate the number of points based on the start and stop values of the sweep
	l_numPoints = math.abs((vstop - vstart) / vstep) + 1
	
	--Set up source range
	if math.abs(vstart) > math.abs(vstop) then 
		smua.source.rangev = vstart
	else
		smua.source.rangev = vstop
	end 
	
	--Set up current compliance
	smua.source.limiti = ilimit
	
	--Set up current range
	if irange == "auto" then
		smua.measure.autorangei = smua.AUTORANGE_ON
	else
		smua.measure.autorangei = smua.AUTORANGE_OFF
		smua.measure.rangei = irange
	end 
	
	--Set the measurement integration time
	smua.measure.nplc = 1
	smua.measure.delay = 0.05
	
	--Configure the reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode = 1
	smua.nvbuffer1.collecttimestamps = 1
	smua.nvbuffer1.collectsourcevalues = 0
	smua.nvbuffer1.fillmode = smua.FILL_ONCE
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode = 1
	smua.nvbuffer2.collecttimestamps = 1
	smua.nvbuffer2.collectsourcevalues = 0
	smua.nvbuffer2.fillmode = smua.FILL_ONCE
		
	--Turn on the output
	smua.source.output = 1    
	
	--Use a "for" loop to run the linear voltage sweep and make current and voltage measurements
	for l_i  = 0, (l_numPoints - 1) do 
		--Update the source level
		if vstop > vstart then
			smua.source.levelv = vstart + (l_i * math.abs(vstep))
		else
			smua.source.levelv = vstart - (l_i * math.abs(vstep))
		end
		
		--Make simultaneous voltage and current measurements
		smua.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	end
	
	--Set the voltage level back to 0V
	smua.source.levelv = 0 		
	
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