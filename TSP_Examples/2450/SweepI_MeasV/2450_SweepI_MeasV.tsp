--[[
	
	Description:	This Model 2450 example shows you how to sweep the 
	test current and measure the resulting voltage drop on a low 
	resistance device. The Model 2450 current source outputs a sweep 
	from -100 mA to 100 mA in 101 steps as the Model 2450 voltmeter 
	measures the resulting voltage drop across the resistor.  This 
	application is set up to take 101 readings with a 100 ms interval 
	time.  Once the measurements are made, the output is turned off.  
	The current and voltage readings are printed to the Instrument 
	Console.  You can copy and paste these readings into a spreadsheet 
	for further analysis and graphing.
	
	--]]	

--Reset the instrument
reset()
defbuffer1.clear()

--Measure Settings
smu.measure.func = smu.FUNC_DC_VOLTAGE
smu.measure.autorange = smu.ON
smu.measure.nplc = 1
smu.measure.sense=smu.SENSE_4WIRE

--Source Settings
smu.source.func = smu.FUNC_DC_CURRENT
smu.source.vlimit.level = 1
smu.source.delay = 0.1
smu.source.sweeplinear('LowR', -100e-3, 100e-3, 101)

--Run trigger model and wait for it to complete
trigger.model.initiate()
waitcomplete()

--Print Results
if defbuffer1.n == 0 then
	print("Buffer is empty\n")
else
	print("Current\tVoltage")
	for i=1,defbuffer1.n do
		print(string.format("%g\t%g", defbuffer1.sourcevalues[i], defbuffer1.readings[i]))
	end
end
