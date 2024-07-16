--[[
	Title: FET Drain-Source Breakdown Voltage
	Description: This script measures the drain-source breakdown voltage (BVdss) of a FET.  
]]

--[[
	BVdss(gateV, drainI, measDelay, igLimit, vdLimit, numNPLC)
	
	Description: This function uses the Model 2657A to force a current from drain to source. The SMU
	also measures the resulting voltage (Vds) with the FET channel turned off. A second System SourceMeter Instrument
	applies the gate to source voltage (Vgs) to ensure that the gate is turned off. 
	
	Parameters:
		gateV: Applied gate voltage (Vgs)
		drainI: Test current applied by the Model 2657A from drain to source (Id)
		measDelay: Measurement delay before making the drain voltage measurement (Vgs)
		igLimit: Current limit (compliance) for the SMU connected to the FET gate terminal
		vdLimit: Voltage limit (compliance) for the SMU connected to the FET drain terminal
		numNPlC: Integration time for the drain voltage measurement (in number of power line cycles)
					
	Example Usage:
	BVdss(0, 0.001, 0.01, 0.01, 2000, 1)
--]]

function BVdss(gateV, drainI, measDelay, igLimit, vdLimit, numNPLC)

	--Initialize SMU
	reset()
	errorqueue.clear()
	status.reset()
	tsplink.reset()

	--Configure source function
	node[2].smua.source.func = node[2].smua.OUTPUT_DCVOLTS
	node[2].smua.source.levelv = gateV
	node[2].smua.source.limiti = igLimit
	
	smua.source.func = smua.OUTPUT_DCAMPS
	smua.source.rangei = drainI
	smua.source.leveli = drainI
	smua.source.limitv = vdLimit

	--Configure measurement parameters
	smua.measure.rangev = vdLimit
	smua.measure.nplc = numNPLC
	smua.measure.delay = measDelay
	
	--Run the test
	node[2].smua.source.output = 1
	smua.source.output = 1
	
	I,V = smua.measure.iv()

	smua.source.output = 0
	node[2].smua.source.output = 0
	
	print("Test current:", I)
	print("Measured voltage:", V)

end