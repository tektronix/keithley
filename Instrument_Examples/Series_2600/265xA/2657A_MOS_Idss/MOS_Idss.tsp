--[[
	Title: FET Drain-to-Source Leakage Current Measurement Sweep
	Description: This script measures the drain current while the drain voltage is sweeping linearly and 
	under a 0 V gate bias.  
]]

--[[
	Idss(gateV, startV, stopV, numSteps, measDelay, measRange, iLimit, intNPLC)
	
	Description: This function uses the Model 2657A to sweep the voltage across the drain
	up to the drain-source breakdown voltage and measure the drain current.  A second SourceMeter
	instrument is used to bias the gate. For enhancement-mode power MOSFETs, a typical gate bias
	is 0 V.  
	
	Parameters:
		gateV: Applied gate voltage bias (Vgs)
		startV: Starting drain voltage (Vds)
		stopV: Final drain voltage (Vds)
		numSteps: Number of points in the drain voltage sweep
		measDelay: Measurement delay
		measRange: Current measurement range for the drain current measurements
		iLimit: Current limit (compliance) for the drain current
		numNPLC: Integration time in the number of power line cycles
					
	Example Usage:
	Idss(0, 10, 1760, 500, 0.05, 100e-9, 500e-6, 1)
--]]


function Idss(gateV, startV, stopV, numSteps, measDelay, measRange, iLimit, numNPLC)

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
	
	--Configure source parameters for the gate SMU
	node[2].smua.source.func = node[2].smua.OUTPUT_DCVOLTS
	node[2].smua.source.levelv = gateV
	node[2].smua.source.limiti = 0.001
	
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

	--Run the test
	node[2].smua.source.output = 1
	smua.source.output = 1
	delay(1)

	for i = 0, (numSteps - 1) do
		smua.source.levelv = startV + (i * stepV)
		smua.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
		--Remove the following 4 lines if you do not want to monitor for compliance
		testCmpl = smua.source.compliance
		if testCmpl == true then 
			break 
		end
	end

	--Turn off the SMUs to complete the test
	smua.source.levelv = 0
	node[2].smua.source.levelv = 0	
	node[2].smua.source.output = 0
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

