--[[

***********************************************************
*** Copyright 2022 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Written by: Keithley Applications Engineering 

This script outputs a linear current pulse sweep from 0A to 10A with a 100V limit on a 
    2461 Graphical SMU. It uses the built-in command smu.source.pulsesweeplinear()

This represents the upper edge of the 2461's power envelope.  

]]

reset()
eventlog.clear()
defbuffer1.clear()

-- Define pulse sweep characteristics
local pulseName = "Pulse10A"  -- Name of configuration list to be used. Meas will be prepended to this name for the measure config list. Should be <28 characters. 
local bias_level = 0          -- A level the instrument sources before the first pulse and returns to between pulses (delay and off time)
local start = 0               -- Starting pulse amplitude
local stop = 10               -- Ending pulse amplitude
local points = 20             -- Number of pulses
local pulseWidth = 0.00091    -- The time spend at amplitude for each pulse. At 10A/100V: 0.001 is the maximum pulse width, 0.00015 is the minimum (load dependent)
local measEnable = smu.ON     -- Do you want to measure at the top of each pulse? (yes) Other option is smu.OFF
local sDelay = 0              -- Time spent at bias level before each pulse, 0 to 10,000
local offTime = 0.1           -- Time spent at bias level after each pulse, 0 to 10,000
local count = 1               -- How many times to repeat the pulse, 1 to 268,435,455, or smu.INFINITE
local vLimit = 2              -- Voltage limit at bias level
local vPulseLimit = 100       -- Voltage limit at pulse level
local failAbort = smu.OFF     -- Should the sweep stop immediately if a limit is exceeded? (no), otherwise set to smu.ON
local dual = smu.OFF          -- Should the sweep go back from stop to start _after_ running start to stop? / dual sweep? (no), other option is smu.ON

-- Configure Sourcing
smu.source.func = smu.FUNC_DC_CURRENT
smu.source.autorange = smu.OFF
smu.source.range = 1
smu.source.level = 0
smu.source.readback = smu.OFF            -- Readback needs to be off when using smu.measure. Of you need to also measure current, use smu.digitize commands
smu.source.autodelay = smu.OFF
smu.source.vlimit.level = vPulseLimit

-- Configure Measurement
smu.measure.setattribute(smu.FUNC_DC_VOLTAGE, smu.ATTR_MEAS_RANGE, vPulseLimit) -- Using ...setattribute() to set the measure range prevents a warning from being thrown
smu.measure.func = smu.FUNC_DC_VOLTAGE
smu.measure.nplc = 0.01                       -- Number of Power Line Cycles. @ 60Hz 0.01 NPLC ~= 0.00016s ~= 160us, this must be less than pulseWidth
smu.measure.sense = smu.SENSE_4WIRE           -- Other option is smu.SENSE_2WIRE, 4WIRE is recommended because this is a high current test
smu.measure.autozero.enable = smu.OFF
smu.measure.autozero.once()                   -- It's good practice to force a ref measurement before testing when autozero is disabled

if eventlog.getcount(eventlog.SEV_WARN | eventlog.SEV_ERROR) > 0 then 
    print("Error with source/measure set up") 
    exit() 
end

-- Configure pulse sweep with built-in function smu.source.pulsesweeplinear()
-- Here we are using the most complete Usage from the 2461 Reference Manual:
-- smu.source.pulsesweeplinear(configListName, biasLevel, start, stop, points, pulseWidth, measEnable, bufferName, sDelay, offTime, count, xBiasLimit, 
--     xPulseLimit, failAbort, dual)
smu.source.pulsesweeplinear(pulseName, bias_level, start, stop, points, pulseWidth, measEnable, defbuffer1, sDelay, offTime, count, vLimit, vPulseLimit, failAbort, dual)
if eventlog.getcount(eventlog.SEV_WARN | eventlog.SEV_ERROR) > 0 then 
    print("Error configuring Pulse") 
    exit() 
end

-- Execute the pulse sweep
trigger.model.initiate()
waitcomplete()
smu.source.output = smu.OFF

if eventlog.getcount(eventlog.SEV_WARN | eventlog.SEV_ERROR) > 0 then 
    print("Error during trigger model execution") 
    exit() 
end

-- Print results to the terminal, they are of course located in defbuffer1
for i = 1, points do
    print("Pt ", i, "meas", defbuffer1.formattedreadings[i], ", source", defbuffer1.sourceformattedvalues[i])
end
--[[
Example Output from 10 Ohm resistor:
Pt 	1	meas	+000.000 V	, source	+00.00000 A
Pt 	2	meas	+004.939 V	, source	+00.50000 A
Pt 	3	meas	+009.881 V	, source	+01.00000 A
Pt 	4	meas	+014.822 V	, source	+01.50000 A
Pt 	5	meas	+019.758 V	, source	+02.00000 A
Pt 	6	meas	+024.695 V	, source	+02.50000 A
Pt 	7	meas	+029.630 V	, source	+03.00000 A
Pt 	8	meas	+034.556 V	, source	+03.50000 A
Pt 	9	meas	+039.478 V	, source	+04.00000 A
Pt 	10	meas	+044.379 V	, source	+04.50000 A
Pt 	11	meas	+049.284 V	, source	+05.00000 A
Pt 	12	meas	+054.171 V	, source	+05.50000 A
Pt 	13	meas	+059.056 V	, source	+06.00000 A
Pt 	14	meas	+063.960 V	, source	+06.50000 A
Pt 	15	meas	+068.837 V	, source	+07.00000 A
Pt 	16	meas	+073.745 V	, source	+07.50000 A
Pt 	17	meas	+078.628 V	, source	+08.00000 A
Pt 	18	meas	+083.524 V	, source	+08.50000 A
Pt 	19	meas	+088.408 V	, source	+09.00000 A
Pt 	20	meas	+093.304 V	, source	+09.50000 A
Pt 	21	meas	+098.156 V	, source	+10.00000 A
]]