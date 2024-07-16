--[[

Description: This example shows you how to do a 4W resistance measurement with offset compensation
on the Model DMM7510 Graphical Sampling Multimeter.

The example takes either a single reading or 10 readings.  Both setups will be doing a 4W Res at 1 NPLC
and with autorange enabled.

Single_Measure()
Single DMM7510 reading

Multi_Measure()
10 DMM7510 readings

Further information on making accurate 4W resistance measurement, please
refer to the DMM7510 Reference Manual and the Keithley Low Level Measurements Handbook.


To Run:
1) Load TSP file to DMM7510 Memory
	- Select the .tsp file of interest
	- Press the run arrow in Test Script Builder Main Menu
	
2) Run Program
	- At the TSP> prompt in the Instrument Control Panel, type Single_Measure()
	or Multi_Measure()
]]

function Resistance_Setup()
	--Reset the instrument to the default settings.
	reset()
	--Set the measurement function to four-wire resistance
	dmm.measure.func = dmm.FUNC_4W_RESISTANCE
	--Enable autozero (set to dmm.OFF to disable)
	dmm.measure.autozero.enable = dmm.ON
	--Enable offset compensation (set to dmm.OFF to disable)
	dmm.measure.offsetcompensation.enable = dmm.ON
	--Set the number of power line cycles to 1
	dmm.measure.nplc = 1
end

function Single_Measure()
	Resistance_Setup()
	--Read the resistance value
	print(dmm.measure.read())
end

function Multi_Measure()
	Resistance_Setup()
	--Set measure count to 10 for 10 readings
	dmm.measure.count = 10
	--start taking measurements
	dmm.measure.read()
	--print the 10 readings
	printbuffer(1, defbuffer1.n, defbuffer1)
end

--Function Copy and Paste
Single_Measure()
--Multi_Measure()
