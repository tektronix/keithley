function runCapLeak(testV, iLimit, measRange, numReadings, soakTime, numNPLC)
	
	--Initialize SMU
	reset()
	errorqueue.clear()
	status.reset()
	
	--Configure reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode = 0
	smua.nvbuffer1.collecttimestamps = 1
	smua.nvbuffer1.collectsourcevalues = 0
	
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode = 0
	smua.nvbuffer2.collecttimestamps = 1
	smua.nvbuffer2.collectsourcevalues = 0
	
	--Configure source function
	smua.source.func = smua.OUTPUT_DCVOLTS
	smua.source.levelv = testV
	smua.source.limiti = iLimit
	
	--[[
	Configure measurement parameters.  Each call of the measurement function 
	will result in the number of readings specified by smua.measure.count.  
	The time specified by smua.measure.delay is enforced before any 
	measurements are made. 
	--]]
	smua.measure.autozero = smua.AUTOZERO_ONCE
	smua.measure.rangei = measRange
	smua.measure.count = numReadings
	smua.measure.nplc = numNPLC
	smua.measure.delay = soakTime
	
	--Run the test
	--Turn on the output. The programmed voltage is output immediately.
	smua.source.output = 1
	--Perform a set of current and voltage measurements. Measure delay is enforced before measurements are made.
	smua.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	--After measurements are complete, return the voltage to 0V. Rate of discharge is limited by programmed current limit. 
	smua.source.levelv = 0
	--Wait until the capacitor is fully discharged before turning off the output. 
	delay(soakTime)
	smua.source.output = 0
	
end


--This function prints the raw voltage and current measurements that are stored in reading buffers smua.nvbuffer1 and smua.nvbuffer2
function printData()
	--Retrieve average values of measured current and voltage
	current_stats = smua.buffer.getstats(smua.nvbuffer1)
	voltage_stats = smua.buffer.getstats(smua.nvbuffer2)
	current_mean = current_stats.mean
	voltage_mean = voltage_stats.mean

	--Calculate the insulation resistance of the capacitor
	resistance = voltage_mean/current_mean

	--Print the summary of the results to the communication interface
	print(string.format("Average current: %g", current_mean))
	print(string.format("Average voltage: %g", voltage_mean))
	print(string.format("Insulator Resistance: %g", resistance))
	
	if  smua.nvbuffer1.n == 0 then
		print("No reading in buffer")
	else
		print("Timestamps\tCurrent\tVoltage")
		for i = 1, smua.nvbuffer1.n do
			print(string.format("%g\t%g\t%g", smua.nvbuffer1.timestamps[i], smua.nvbuffer1.readings[i], smua.nvbuffer2.readings[i]))
		end
	end
end