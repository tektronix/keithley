--[[
	offVoltLeakI(startV, stopV, numSteps, measDelay, measRange, iLimit, numNPLC)
	
	Description: This function can be used to determine Vdrm and Idrm or
	Vrrm and Irrm of a thyristor. In this function, the Model 2657A will
	perform a voltage sweep on the anode and measure the corresponding
	leakage current at each step. As no voltage or current bias is required	
	on the gate terminal of the thyristor, this function can be used with
	gated and non-gated devices.

	To determine Vdrm and Idrm, connect the Model 2657A from anode to
	cathode of the device, and program positive start and stop voltages
	for the sweep.

	To determine Vrrm and Irrm, connect the Model 2657A from the anode to
	the cathode of the device, and program negative start and stop voltages
	for the sweep.

	Parameters:
		startV: Starting drain voltage (Vds).
		stopV: Final drain voltage (Vds).
		numSteps: Number of points in the drain voltage sweep.
		measDelay: Measurement delay.
		measRange: Current measurement range for the drain current measurements.
		iLimit: Current limit (compliance) for the drain current.
		numNPLC: Integration time in number of power line cycles.

	Example usage:
	
	for Vdrm and Idrm:
	offVoltLeakI(0, 800, 501, 0.010, 100e-6, 1e-3, 1)
	
	for Vrrm and Irrm:
	offVoltLeakI(0, -800, 501, 0.010, 100e-6, 1e-3, 1)
--]]

function offVoltLeakI(startV, stopV, numSteps, measDelay, measRange, iLimit, numNPLC)

	--Initialize SMU
	reset()
	errorqueue.clear()
	status.reset()

	--Configure reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.appendmode = 1
	smua.nvbuffer1.collecttimestamps = 1
	
	smua.nvbuffer2.clear()
	smua.nvbuffer2.appendmode = 1
	smua.nvbuffer2.collecttimestamps = 1
		
	--Configure source parameters for the drain SMU
	smua.source.func = smua.OUTPUT_DCVOLTS
	smua.source.levelv = 0
	smua.source.limiti = iLimit
	if math.abs(startV) > math.abs(stopV) then
		smua.source.rangev = startV
	else 
		smua.source.rangev = stopV
	end

	--Calculate the step voltage
	stepV = (stopV - startV)/(numSteps - 1)

	--Configure measurement parameters for the drain SMU
	smua.measure.rangei = measRange
	smua.measure.nplc = numNPLC
	smua.measure.delay = measDelay
	smua.measure.autozero = smua.AUTOZERO_ONCE
	
	--Run the test
	smua.source.output = 1

	for i = 0, (numSteps - 1) do
		smua.source.levelv = startV + (i * stepV)
		smua.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	end

	--Turn off the SMU to complete the test
	smua.source.levelv = 0
	smua.source.output = 0

	printData()
	
end


function printData()

	if  smua.nvbuffer1.n == 0 then
		print("No reading in buffer")
	else
		print("Timestamps\tVoltage\tCurrent")
		for i = 1, smua.nvbuffer1.n do
			print(string.format("%g\t%g\t%g", smua.nvbuffer1.timestamps[i], smua.nvbuffer2.readings[i], smua.nvbuffer1.readings[i]))
		end
	end
end
