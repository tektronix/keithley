--[[

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This example is from the DMM7510's User's Manual. Check there for more details on running this example.

This sequence of TSP commands captures the ripple voltage on the output of a DC buck converter
    by digitizing voltage for ~ 100us.

After the code executes, the data is displayed in the Instrument Console of Test Script Builder.

]]

-- Reset the instrument to default settings.
reset()
-- Create a local variable to store the number of samples
numofsamples = 100
-- Set the measure function to digitize voltage to capture the ripple waveform
dmm.digitize.func = dmm.FUNC_DIGITIZE_VOLTAGE
-- Voltage range must be fixed when using digitize voltage
dmm.digitize.range = 10
-- Set sample rate to 1 Msample per second to sample a 50 kHz voltage ripple
dmm.digitize.samplerate = 1e6
-- Set aperture to auto to get the highest accuracy measurement for the configured sampling rate
dmm.digitize.aperture = dmm.APERTURE_AUTO
-- Set sample count to the number of samples to capture about 5 ripples
dmm.digitize.count = numofsamples
-- Set the input impedance to auto so it selects 10 G for the 10V range
dmm.digitize.inputimpedance = dmm.IMPEDANCE_AUTO
-- Set the buffer to align with the number of samples (optional)
defbuffer1.capacity = numofsamples
-- Clear buffer
defbuffer1.clear()
-- Make sure your signal is connected to the DMM. Digitize now.
dmm.digitize.read()
-- Print the digitized readings
if defbuffer1.n > 0 then
    print("Ripple Voltage:")
    print("Total Count:", defbuffer1.n)
    printbuffer(1, defbuffer1.n, defbuffer1)
    print("Timestamps:")
    printbuffer(1, defbuffer1.n, defbuffer1.relativetimestamps)
else
    print("No data collected")
end
print("Test Ended")