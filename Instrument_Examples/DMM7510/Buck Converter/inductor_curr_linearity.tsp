--[[

***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This example is from the DMM7510's User's Manual. Check there for more details on running this example.

This sequence of TSP commands analyzes in the current linearity of a DC buck converter inductor 
    by digitizing current for ~ 100us.

After the code executes, the data is displayed in the Instrument Console of Test Script Builder.

]]

-- Reset the instrument to default settings
reset()
-- Create a local variable to store the number of samples
numofsamples=50
-- Set DMM function to digitize current to capture the inductor current
dmm.digitize.func = dmm.FUNC_DIGITIZE_CURRENT
-- Current range must be fixed when using digitize current
dmm.digitize.range = 1
-- Set the sample rate to 500 ksamples per second to sample a 50 kHz current waveform
dmm.digitize.samplerate = 500e3
-- Set the aperture to auto to get the highest accuracy measurement for the sampling rate configured
dmm.digitize.aperture = dmm.APERTURE_AUTO
-- Set the sample count to the number of samples to capture about 5 ripples
dmm.digitize.count = numofsamples
-- Clear buffer
defbuffer1.clear()
-- Make sure your signal is connected to the DMM. Digitize now...
dmm.digitize.read()
if defbuffer1.n > 0 then
    print("Digitize Current:")
    print("Total Number of readings:", defbuffer1.n)
    printbuffer(1, defbuffer1.n, defbuffer1)
    print("Timestamps:")
    printbuffer(1, defbuffer1.n, defbuffer1.relativetimestamps)
else
    print("No data collected")
end
print("Test Ended")