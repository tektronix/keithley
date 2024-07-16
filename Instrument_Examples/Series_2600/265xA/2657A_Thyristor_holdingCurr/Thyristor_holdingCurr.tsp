--[[
	holdingCurr(gateBiasCurr, gateVoltLimit, gateOnTime, anodeBiasVolt, anodeLatchingCurr, anodeCurrStep, numNPLC)
	
	Description: This function can be used to determine Ih of a thyristor.  Two SMUs
	are required for this function.  One SMU (node[2].smua) is connected to the gate terminal and is used to 
	trigger the device.  The Model 2657A (smua) is connected to the anode and is applying a voltage bias.
	After the device is turned on, the gate signal is removed and the current limit of 
	the Model 2657A is varied until the device turns off.  The current at which the device turns
	off is the holding current.  

	Parameters:
		gateBiasCurr = Current to apply to the gate to trigger the device on. Should be greater than or equal to the gate trigger current.
		gateVoltLimit = Voltage limit for the gate SMU. Should be greater than or equal to the gate trigger voltage.  
		gateOnTime = Number of seconds to apply the gate trigger (single pulse event)
		anodeBiasVolt = Model 2657A applies this voltage to the anode terminal
		anodeLatchingCurr = Specified latching current of the device.  This will be the initial current limit of the Model 2657A
		anodeCurrStep = How much to vary the anode current in order to arrive at the gate current. 
		numNPLC = Integration time in number of power line cycles
					
	Example Usage:
	
	holdingCurr(0.05, 10e-3, 2, 12, 0.06, 0.005, 1)
	
--]]

function holdingCurr(gateBiasCurr, gateOnTime, gateVoltLimit, anodeBiasVolt, anodeLatchingCurr, anodeCurrStep, numNPLC)

	--Initialize instruments and clear errors and status registers
	tsplink.reset()
	reset()
	errorqueue.clear()
	status.reset()
	
	--Configure gate SMU
	node[2].smua.source.func = node[2].smua.OUTPUT_DCAMPS
	node[2].smua.source.rangei = gateBiasCurr
	node[2].smua.source.leveli = gateBiasCurr
	node[2].smua.source.limitv = gateVoltLimit
	node[2].smua.source.delay = 0
	
	--Configure anode SMU source parameters
	smua.source.func = smua.OUTPUT_DCVOLTS
	smua.sense = smua.SENSE_LOCAL
	smua.source.rangev = anodeBiasVolt
	smua.source.levelv = anodeBiasVolt
	smua.source.limiti = anodeLatchingCurr --This is the initial current limit to ensure that the device stays on after the gate 
	
	--Configure anode SMU measure parameters
	smua.measure.rangei = anodeLatchingCurr
	smua.measure.nplc = numNPLC
	smua.measure.autozero = smua.AUTOZERO_ONCE
	
	numSteps = (anodeLatchingCurr / anodeCurrStep) + 1
		
	if anodeCurrStep >= anodeLatchingCurr then
		print("Wrong value: The current step cannot be greater than or equal to the expected latching current.")
	else
		smua.source.output = 1
		node[2].smua.source.output = 1
		delay(gateOnTime)
		node[2].smua.source.output = 0
			
		for i = 1, numSteps do
			smua.measure.i()
			cmplCheck = smua.source.compliance
			
			if cmplCheck == false then
				break
			else
				smua.source.limiti = anodeLatchingCurr - (i*anodeCurrStep)
			end
							
		end
		
		--Complete the test and output the result
		smua.source.output = 0	
		finalIh = smua.source.limiti
		print("Holding Current (Amps): ", finalIh)
	end
	
end
