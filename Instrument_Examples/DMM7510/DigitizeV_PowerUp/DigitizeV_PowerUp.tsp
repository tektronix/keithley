--[[

Description:  This example shows you how to capture a power-up transient waveform
using the analog edge trigger feature on the Model DMM7510 Graphical Sampling Multimeter.

This example configures the Model DMM7510 to acquire the 0 to 5V power up behavior on a
buck converter.  The sampling rate is set to 1MHz.   The data buffer is sized to 10000
to cover about 10ms of the transient activity at 50% pretrigger and 50% posttrigger distribution.
The analog edge trigger level is set to 3V.   This is a single trigger measurement.
The captured waveform can be viewed on the instrument touch screen display.
You can also copy and paste the data from the TSB instrument console to a spreadsheet.

To Run:
1) Load TSP file to DMM7510 Memory
	- Select the .tsp file of interest
	- Press the run arrow in Test Script Builder Main Menu
	
2) Run Program
	- At the TSP> prompt in the Instrument Control Panel, type Single_EdgeTrigger()
	- Turn on the power supply to the buck converter to power up the DUT
	
]] --

function Single_EdgeTrigger()
	--Reset the instrument to default settings
	reset()
	--Create a local variable to store the number of samples desired
	local numofsamples = 10000
	--Set the measurement function to Digitize Voltage to capture the power-up behavior
	dmm.digitize.func = dmm.FUNC_DIGITIZE_VOLTAGE
	--Voltage range must be fixed when using Digitizing Voltage
	dmm.digitize.range = 10
	--Set the sample rate to 1MHz to capture any glitch
	dmm.digitize.samplerate = 1e6
	--Set aperture to auto to get the highest accuracy measurement for the sampling rate configured
	dmm.digitize.aperture = dmm.APERTURE_AUTO
	--Changing count is optional.  The reading buffer capacity is the determining factor
	dmm.digitize.count = 1
	--Set the input impedance to auto so it select 10G for the 10V range
	dmm.digitize.inputimpedance = dmm.IMPEDANCE_AUTO
	--Set the buffer size to number of samples to capture both pre and post triggerred data
	defbuffer1.capacity = numofsamples
	--Clear buffer
	defbuffer1.clear()

	--Select analog edge trigger to capture the power up behavior
	dmm.digitize.analogtrigger.mode = dmm.MODE_EDGE
	--Set edge slope to detect a rising edge
	dmm.digitize.analogtrigger.edge.slope = dmm.SLOPE_RISING
	--Set edge level trigger to 3V for the 5V steadystate output
	dmm.digitize.analogtrigger.edge.level = 3

	--Change to graph screen
	display.changescreen(display.SCREEN_GRAPH)

	--Define a trigger model that will capture 50% pre and 50% post triggered data
	trigger.model.setblock(1, trigger.BLOCK_MEASURE_DIGITIZE, defbuffer1, trigger.COUNT_INFINITE)
	trigger.model.setblock(2, trigger.BLOCK_WAIT, trigger.EVENT_ANALOGTRIGGER)
	trigger.model.setblock(3, trigger.BLOCK_MEASURE_DIGITIZE, defbuffer1, numofsamples / 2)

	trigger.model.initiate()
	--Waits for the trigger model to finish collecting data before proceeding
	waitcomplete()

	print("test ended")
end

--Function Copy and Paste
Single_EdgeTrigger()
