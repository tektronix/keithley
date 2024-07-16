--[[
	
	Description:	This Model 2450 example shows you how to measure the 
	leakage current of a device such as a capacitor.  The Model 2450 
	voltage source outputs 20V as the Model 2450 ammeter measures the
	resulting leakage current as a function of time.  This application
	is set up to take current measurements at 200 ms intervals for 60 s.  
	Once the measurements are made, the capacitor is discharged to 0V and 
	the output is turned off.  The current and time measurements are printed
	to the Instrument Console.  You can copy and paste these readings into a 
	spreadsheet for further analysis and graphing.  The program is set up
	to use the rear panel terminals so that low noise triax cables can
	be used to connect to the device.
	
	If you are measuring small current values, the device should be 
	electrostatically shielded. If the capacitor is greater than 20nF, 
	the high capacitance mode may need to be enabled for best results.  
	For sourcing voltages greater than 37V, the interlock on the rear panel 
	of the Model 2450 must be enabled.
	
	Further information on making optimal capacitor leakage measurements
	can be found in the Keithley Low Level Measurements Handbook.

	]]
	
--reset
reset()
defbuffer1.clear()

--set up source function
smu.source.func = smu.FUNC_DC_VOLTAGE
smu.source.ilimit.level = 10e-3
smu.source.level = 20
smu.source.delay = 0.2

--set up measure function
smu.measure.func = smu.FUNC_DC_CURRENT
smu.measure.terminals = smu.TERMINALS_REAR
smu.measure.autorange = smu.ON
smu.measure.nplc = 1
smu.source.highc = smu.OFF

--turn on output and initiate readings
smu.source.output = smu.ON
trigger.model.load("DurationLoop", 60)

trigger.model.initiate()

--wait for complete
waitcomplete()

--parse index and data into three columns
print("Rdg #", "Time (s)", "Current (A)")
for i=1, defbuffer1.n do
	print(i, defbuffer1.relativetimestamps[i], defbuffer1[i])
end

--Discharge the capacitor to 0V and turn off the output
smu.source.level = 0
delay(2)
smu.source.output = smu.OFF