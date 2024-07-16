--[[
	latchingCurr(gateBiasCurr, gateVoltLimit, gateOnTime, anodeStartCurr, anodeMaxCurr, anodeStepCurr, anodeVoltLimit, numNPLC)
	
	Description: This function can be used to determine Ilatch of a thyristor.  Two SMUs
	are required for this function.  One SMU (node[2].smua) is connected to the gate terminal and is used to 
	trigger the device.  The Model 2657A (smua) is connected to the anode and is used to source the current.  
	The gate is triggered while a current bias is applied to the anode.  The gate current is removed and 
	measurements are made to verify that the device is on.  If the device is off, the current at the anode is increased 
	and the gate is re-triggered.  This continues until the device remains on even after the gate signal is removed. 
	The current at which the device remains on is the latching current.
	
	In order to complete this task, custom list sweeps are configured on the gate and anode SMUs. 

	Parameters:
		gateBiasCurr = Current to apply to the gate to trigger the device on. Should be greater than or equal to the gate trigger current.
		gateVoltLimit = Voltage limit for the gate SMU. Should be greater than or equal to the gate trigger voltage.  
		gateOnTime = Number of seconds to apply the gate trigger (single pulse event)
		anodeStartCurr = Start value for the anode current sweep. Typically slightly less than or equal to the holding current value. 
		anodeMaxCurr = Stop value for the anode current sweep.  May not reach this value, but this is the maximum value to source
		anodeStepCurr = Step value for the anode current sweep
		anodeVoltLimit = Voltage limit for the anode SMU.  Should be equal to Vdrm.
		numNPLC = Integration time in the number of power line cycles
					
	Example Usage:
	
	latchingCurr(0.060, 10, 1e-3, 0.020, 0.120, 0.005, 600, 0.01)
	
--]]

function latchingCurr(gateBiasCurr, gateVoltLimit, gateOnTime, anodeStartCurr, anodeMaxCurr, anodeStepCurr, anodeVoltLimit, numNPLC)

	--Initialize instruments and clear errors and status registers
	tsplink.reset()
	reset()
	errorqueue.clear()
	status.reset()
	
	--Configure gate SMU
	node[2].smua.source.func = node[2].smua.OUTPUT_DCAMPS
	node[2].smua.source.rangei = gateBiasCurr
	node[2].smua.source.leveli = 0
	node[2].smua.source.limitv = gateVoltLimit
	node[2].smua.source.delay = gateOnTime
	
	--Configure anode SMU source parameters
	smua.source.func = smua.OUTPUT_DCAMPS
	smua.sense = smua.SENSE_LOCAL
	smua.source.rangei = anodeMaxCurr
	smua.source.leveli = 0
	smua.source.limitv = anodeVoltLimit
	
	--Configure anode SMU measurement parameters
	smua.measure.delay = 0.005 
	--Must have delay if you want reasonable anode measurements
	
	smua.measure.rangev = anodeVoltLimit
	smua.measure.nplc = numNPLC
	smua.measure.autozero = smua.AUTOZERO_ONCE
	
	smua.nvbuffer1.clear()
	smua.nvbuffer2.clear()
	smua.nvbuffer1.appendmode = 1
	smua.nvbuffer2.appendmode = 1
	smua.nvbuffer1.collecttimestamps = 1
	smua.nvbuffer2.collecttimestamps = 1
	
	--Create custom sweeps for anode and gate SMUs
	numSwpPts = 2*((anodeMaxCurr - anodeStartCurr)/(anodeStepCurr)) + 1
	
	gateSwp = {}
	anodeSwp = {}
	
	for i = 1, numSwpPts do
		if math.mod(i,2) == 0 then
			gateSwp[i] = 0
		else
			gateSwp[i] = gateBiasCurr
		end
	end
	
	for j = 1, numSwpPts, 2 do
		anodeSwp [j] = anodeStartCurr + ((j-1)/2)*anodeStepCurr
		anodeSwp[j+1] = anodeStartCurr + ((j-1)/2)*anodeStepCurr
	end
		
	smua.source.output = 1
	node[2].smua.source.output = 1
	
	for k = 1, numSwpPts, 2 do
		smua.source.leveli = anodeSwp[k]
		node[2].smua.source.leveli = gateSwp[k]
		node[2].smua.source.leveli = gateSwp[k+1]
		smua.measure.iv(smua.nvbuffer1,smua.nvbuffer2)
		checkCmpl = smua.source.compliance
		--If in compliance, then device is off.  If out of compliance, then device is on and we've reached latching current. 
		
		if checkCmpl == false then 
			finalIL = anodeSwp[k]
			break
		end
	end
	
	node[2].smua.source.output = 0
	smua.source.output = 0
	print("Latching Current(Amps): ", finalIL)
	print("Raw Data follows:")
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