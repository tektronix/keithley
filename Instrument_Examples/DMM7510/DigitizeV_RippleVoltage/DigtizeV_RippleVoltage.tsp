--[[

Description:  This example shows you how capture a repetitive voltage waveform using
the Model DMM7510 Graphical Sampling Multimeter.

This example configures the Model DMM7510 to acquire a mV 50kHz ripple at 5V DC offset
using the Digitize Voltage function.

This is a one-shot measurement that captures about 5 ripples at 1MSample/sec sampling rate.
The signal coupling remains at default DC coupling.  The count is set to 100.  The digitize
voltage range is at 10V.  The waveform captured can be viewed on the instrument touch screen
display.  You can also copy and paste the data from the TSB instrument console to a spreadsheet.

To Run:
1) Load TSP file to DMM7510 Memory
	- Select the .tsp file of interest
	- Press the run arrow in Test Script Builder Main Menu
	
2) Run Program
	- Make sure the ripple voltage is presented on the input terminals of the DMM
	- At the TSP> prompt in the Instrument Control Panel, type Single_Digitize()
	
]] --

function Single_Digitize()
	--Reset the instrument to default settings.
	reset()
	--Create a local variable to store the number of samples desired
	local numofsamples = 100
	--Set the measurement function to Digitize Voltage to capture the ripple waveform
	dmm.digitize.func = dmm.FUNC_DIGITIZE_VOLTAGE
	--Voltage range must be fixed when using Digitizing Voltage
	dmm.digitize.range = 10
	--Set the sample rate to 1MS/s to sample a 50kHz voltage ripple
	dmm.digitize.samplerate = 1e6
	--Set the aperture to auto to get the highest accuracy measurement for the sampling rate configured
	dmm.digitize.aperture = dmm.APERTURE_AUTO
	--Set the sample count to the number of samples to capture about 5 ripples
	dmm.digitize.count = numofsamples
	--Set the input impedance to auto so it select 10G for the 10V range
	dmm.digitize.inputimpedance = dmm.IMPEDANCE_AUTO
	--Set the buffer to align with the number of samples.  This is optional
	defbuffer1.capacity = numofsamples
	--Clear buffer
	defbuffer1.clear()
	--Make sure your signal is connected to the DMM.  Digitize now...
	dmm.digitize.read()

	--Print the measurement
	if defbuffer1.n > 0 then
		print("Ripple Voltage:")
		print("Total number of readings:", defbuffer1.n)
		printbuffer(1, defbuffer1.n, defbuffer1)
		print("Timestamps:")
		printbuffer(1, defbuffer1.n, defbuffer1.relativetimestamps)
	else
		print("No data collected")
	end
	print("Test Ended")
end

--Function Copy and Paste
Single_Digitize()
