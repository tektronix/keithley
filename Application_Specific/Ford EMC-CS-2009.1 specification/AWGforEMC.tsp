-- Arbitrary Waveform Generator Script for Series 2600B and 2650A SourceMeter instruments
--[[
	This script is designed to output an arbitrary waveform using any
	Series 2600A/B SourceMeter instrument or a Series 265oA High Power
	SourceMeter instrument.  This script contains functions that
	configure the instrument to output an arbitrary waveform function
	with a fixed source update rate.  A user can specify an arbitrary
	waveform by providing the script with a table of output values.
	
	This script is designed to be simple and easy to follow.  Due to
	its simplicity it does not include much in the way of parameter and
	error checking.  Passing invalid values to any of the functions are
	very likely to create errors.  Note: that no error generated should
	cause damage to the SMU. However, inappropriate use could cause
	damage to any device under test.
	
	The user of this script uses it at their own risk!
--]]

-- Local variables used exclusively by this script
local _arbFunc -- Used by script to hold generated waveform tables
local _startV -- Used by script to track the starting voltage
local _srcRate = 8000 -- Source Update Rate used by the script
--[[ Sets the source update rate (pts/sec) used by the script. Do not
	set higher than 8,000 if your waveform will have polarity changes
	0V crossings) or you will experience overrun errors and thus
	incomplete output of your waveform. If your	waveform does not
	contain polarity changes (all points are positive or all points are
	negative) then you can go as high as 20,000.
--]]


--[[ Name: SetupAWG()
	
	Usage: err,msg = SetupAWG(startV, rangeV, limitI, wfrmTbl, remoteSense, trigLineIn)
	
	Description:
		This function will configure the instrument to output the
		waveform defined in the table wfrmTbl. After calling this
		function you can output the waveform by calling RunAWG().
	
	Parameters:
		startV:		The voltage the output will start from before
			outputing the wavform.
		rangeV:		The voltage range that will be used to source the
			waveform.
		limitI:		The maximum current that will be allowed to flow.
		remoteSense:	Set to true to enable 4-Wire (Kelvin)
			measurements or to false for 2-Wire measurements.
		trigLineIn:	Valid values are between 0 and 14 or nil.  0
			selects the front panel TRIG button.  1 to 14 selects a
			Digital I/O line. Pass nil for immeditate triggering.

	Returns:
		err: Returns true if error was detected else returns false
		msg: A string describing the error that occured.
--]]
function SetupAWG(startV, rangeV, limitI, wfrmTbl, remoteSense, trigLineIn)
	-- Do some parameter checks
	--=========================
	if startV == nil then startV = 0 end
	if remoteSense ~= true then remoteSense = false end
	if type(trigLineIn) == "number" then
		trigLineIn = math.floor(trigLineIn)
		if trigLineIn < 0 or trigLineIn > 14 then
			return true, "Error: Selected trigger line is not valid.  trigLineIn must be a number between 0 and 14 or nil."
		end
	elseif trigLineIn ~= nil then
		return true,"Error: Invalid parameter trigLineIn.  trigLineIn must be a number between 0 and 14 or nil."
	end
	_startV = startV

	-- Setup the SMU for arb waveform output
	--======================================
	reset()
	smua.reset()
	smua.source.func					= smua.OUTPUT_DCVOLTS
	if remoteSense == true then
		smua.sense						= smua.SENSE_REMOTE
	else
		smua.sense						= smua.SENSE_LOCAL
	end
	smua.source.autorangev			= smua.AUTORANGE_OFF
	smua.source.autorangei			= smua.AUTORANGE_OFF
	smua.source.rangev				= rangeV
	smua.source.levelv				= startV
	smua.source.limiti				= limitI
	smua.source.delay				= 0
	smua.source.settling			= smua.SETTLE_FAST_POLARITY

	-- Configure the Trigger Model
	--============================
	-- Timer 1 controls the time per point
	trigger.timer[1].delay			= 1 / _srcRate
	trigger.timer[1].count			= table.getn(wfrmTbl) > 1 and table.getn(wfrmTbl) - 1 or 1
	if trigLineIn == nil then
		-- Immediate
		trigger.timer[1].stimulus	= smua.trigger.ARMED_EVENT_ID
	elseif trigLineIn == 0 then
		-- Front panel TRIG button
		display.trigger.clear()
		trigger.timer[1].stimulus	= display.trigger.EVENT_ID
	else
		-- Digio Trigger
		digio.trigger[trigLineIn].clear()
		digio.trigger[trigLineIn].mode = digio.TRIG_EITHER
		trigger.timer[1].stimulus	= digio.trigger[trigLineIn].EVENT_ID
	end
	trigger.timer[1].passthrough	= true
	

	-- Configure SMU Trigger Model for arb waveform output
	smua.trigger.source.listv(wfrmTbl)
	smua.trigger.source.limiti		= limitI
	smua.trigger.measure.action		= smua.DISABLE
	smua.trigger.endpulse.action	= smua.SOURCE_HOLD
	smua.trigger.endsweep.action	= smua.SOURCE_HOLD
	smua.trigger.count				= table.getn(wfrmTbl)
	smua.trigger.arm.count			= 1
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= 0
	smua.trigger.endpulse.stimulus	= 0
	smua.trigger.source.action		= smua.ENABLE
	--==============================
	-- End Trigger Model Configuration

--[[ Uncomment this code to output a trigger on line 14 that you can
		use to synchronize other instruments with the ARB output.
	-- Digio Output Trigger
	--=================
	digio.trigger[14].clear()
	digio.trigger[14].mode = digio.TRIG_FALLING
	digio.trigger[14].stimulus = smua.trigger.ARMED_EVENT_ID
	--=================
--]]	
if errorqueue.count > 0 then
		return true,"Error occured during setup.  Please check that your parameters are valid."
	else
		return false,"No error."
	end
end

--[[ Name: SetupSineFunction()
	
	Usage: err,msg = SetupSineFunction(frequency, amplitude, offset, limitI, remoteSense, trigLineIn)
	
	Description:
		This function will configure the instrument to output the sine
		wave function.  After calling this function call RunAWG() to
		start the output.
	
	Parameters:
		frequency:	The frequency of the sine wave.  Recommended values
			are between 0.1 and 1000.
		amplitude:	The amplitude of the sine wave from peak to peak.
		offset:		The offset from 0 for the sine wave output.
		limitI:		The current limit setting.
		remoteSense:Set to true for 4-wire sensing, false for 2-wire
		trigLineIn:	Valid values are between 0 and 14 or nil.  0
			selects the front panel TRIG button.  1 to 14 selects a
			Digital I/O line. Pass nil for immediate triggering.

	Returns:
		err: Returns true if error was detected else returns false
		msg: A string describing the error that occured.
--]]
function SetupSineFunction(frequency, amplitude, offset, limitI, remoteSense, trigLineIn)
	_arbFunc = nil
	collectgarbage()
	_arbFunc = {}
	err,msg = GenerateSineWaveform(frequency, amplitude, offset, _arbFunc)
	if err then return err,msg end
	return SetupAWG(offset, math.abs(amplitude)/2 + math.abs(offset), limitI, _arbFunc, remoteSense, trigLineIn)
end

--[[ Name: SetupSquareFunction()
	
	Usage: err,msg = SetupSquareFunction(frequency, amplitude, offset, dutyCycle, limitI, remoteSense, trigLineIn)

	Description:
		This function will configure the instrument to output the
		square wave function.  After calling this function call
		RunAWG() to start the output.
		Note: This function is only provided for completeness. Series
		2600B and 2650A instruments provide pulse functions that are
		better suited for square wave output than this script.  These
		factory pulse functions allow for pulse width resolution of
		1us.
	
	Parameters:
		frequency:	The frequency of the output.  Recommended values
			are between 0.1 and 1000.
		amplitude:	The amplitude of the square wave from peak to peak.
		offset:		The offset from 0 for the square wave output.
		dutyCycle:	Sets the duty cycle of the square wave.  Valid
			values are a ratio of high to low time and between 0 and 1.
		limitI:		The current limit setting.
		remoteSense:Set to true for 4-wire sensing, false for 2-wire
		trigLineIn:	Valid values are between 0 and 14 or nil.  0
			selects the front panel TRIG button.  1 to 14 selects a
			Digital I/O line. Pass nil for immediate triggering.

	Returns:
		err: Returns true if error was detected else returns false
		msg: A string describing the error that occured.
--]]
function SetupSquareFunction(frequency, amplitude, offset, dutyCycle, limitI, remoteSense, trigLineIn)
	_arbFunc = nil
	collectgarbage()
	_arbFunc = {}
	err,msg = GenerateSquareWaveform(frequency, amplitude, offset, dutyCycle, _arbFunc)
	if err == true then return err,msg end
	return SetupAWG(offset - amplitude/2, math.abs(amplitude)/2 + math.abs(offset), limitI, _arbFunc, remoteSense, trigLineIn)
end

--[[ Name: SetupRampFunction()
	
	Usage: err,msg = SetupRampFunction(frequency, amplitude, offset, symmetry, limitI, remoteSense, trigLineIn)
	
	Description:
		This function will configure the instrument to output the ramp
		function.  After calling this function call RunAWG() to start
		the output.
	
	Parameters:
		frequency:	The frequency of the output.  Recommended values
			are between 0.1 and 1000.
		amplitude:	The amplitude of the ramp function from peak to peak
		offset:		The offset from 0 for the ramp function output
		symmetry:	Sets the symmetry of the square wave.  Valid values
			are a ratio of ramp up to ramp down time, between 0 and 1.
		limitI:		The current limit setting.
		remoteSense:Set to true for 4-wire sensing, false for 2-wire
		trigLineIn:	Valid values are between 0 and 14 or nil.  0
			selects the front panel TRIG button.  1 to 14 selects a
			Digital I/O line. Pass nil for immediate triggering.

	Returns:
		err: Returns true if error was detected else returns false
		msg: A string describing the error that occured.
--]]
function SetupRampFunction(frequency, amplitude, offset, symmetry, limitI, remoteSense, trigLineIn)
	_arbFunc = nil
	collectgarbage()
	_arbFunc = {}
	err,msg = GenerateRampWaveform(frequency, amplitude, offset, symmetry, _arbFunc)
	if err then return err,msg end
	return SetupAWG(offset - amplitude/2, math.abs(amplitude)/2 + math.abs(offset), limitI, _arbFunc, remoteSense, trigLineIn)
end

--[[ Name: SetupPulseFunction()

	Usage: err,msg = SetupPulseFunction(period, high, low, pulseWidth, limitI, remoteSense, trigLineIn)
	
	Description:
		This function will configure the instrument to output the
		pulse function.  After calling this function call RunAWG()
		to start the output.
		Note: This function is only provided for completeness. Series
		2600B and 2650A instruments provide pulse functions that are
		better suited for pulse output than this script.  The pulse
		functions allow for pulse width resolution of 1us.
	
	Parameters:
		period:	The length in time of one pulse cycle in seconds.
			Value must be greater than pulseWidth.
		high:	The peak value of the pulse.
		low:	The base level of the pulse.
		pulseWidth: The width of the pulse in seconds.
		limitI:		The current limit setting.
		remoteSense:Set to true for 4-wire sensing, false for 2-wire
		trigLineIn:	Valid values are between 0 and 14 or nil.  0
			selects the front panel TRIG button.  1 to 14 selects a
			Digital I/O line. Pass nil for immediate triggering.

	Returns:
		err: Returns true if error was detected else returns false
		msg: A string describing the error that occured.
--]]
function SetupPulseFunction(period, high, low, pulseWidth, limitI, remoteSense, trigLineIn)
	_arbFunc = nil
	collectgarbage()
	_arbFunc = {}
	err,msg = GeneratePulseWaveform(period, high, low, pulseWidth, _arbFunc)
	if err then return err,msg end
	return SetupAWG(low, math.abs(high), limitI, _arbFunc, remoteSense, trigLineIn)
end

--[[ Name: SetupNoiseFunction()

	Usage: err,msg = SetupNoiseFunction(amplitude, offset, lengthSeconds, limitI, remoteSense, trigLineIn)
	
	Description:
		This function will configure the instrument to output the
		noise function.  After calling this function call RunAWG()
		to start the output.
	
	Parameters:
		amplitude:	The amplitude of the noise from peak to peak
		offset:		The offset from 0 for the noise output
		lengthSeconds: Sets the amount of time the noise outputs before
			it repeats.
		limitI:		The current limit setting.
		remoteSense:Set to true for 4-wire sensing, false for 2-wire
		trigLineIn:	Valid values are between 0 and 14 or nil.  0
			selects the front panel TRIG button.  1 to 14 selects a
			Digital I/O line. Pass nil for immediate triggering.

	Returns:
		err: Returns true if error was detected else returns false
		msg: A string describing the error that occured.
--]]
function SetupNoiseFunction(amplitude, offset, lengthSeconds, limitI, remoteSense, trigLineIn)
	_arbFunc = nil
	collectgarbage()
	_arbFunc = {}
	err,msg = GenerateNoiseWaveform(amplitude, offset, lengthSeconds, _arbFunc)
	if err then return err,msg end
	return SetupAWG(offset, math.abs(amplitude)/2 + math.abs(offset), limitI, _arbFunc, remoteSense, trigLineIn)
end

--[[ Name: RunAWG()
	
	Usage: err,msg = RunAWG(numCycles)
	
	Description:
		This function turns the SMU output on and starts waveform
		output.  Use StopAWG() to stop the waveform output and turn the
		SMU output off.
	
	Parameters:
		numCycles: The number of cycles of the waveform that the SMU
			will output. Setting this value to 0 will cause the SMU to
			output the waveform indefinitely.  If this parameter is
			omitted then only one cycle will be output.

	Returns:
		err: Returns true if error was detected else returns false
		msg: A string describing the error that occured.
--]]
function RunAWG(numCycles)
	if numCycles == nil or numCycles < 0 then
		numCycles = 1
	end
	
	-- Set the number of cycles to output
	smua.trigger.arm.count = numCycles

	-- Turn output on
	smua.source.output = smua.OUTPUT_ON

	-- Start the trigger model execution
	smua.trigger.initiate()

	if errorqueue.count > 0 then
		return true,"Error occurred.  See error queue for details."
	else
		return false,"No error."
	end
end

--[[ Name: StopAWG()

	Usage: err,msg = StopAWG()

	Description:
		This function stops the waveform output and turns the SMU
		output off.
--]]
function StopAWG()
	smua.abort()
	smua.source.output = 0
	smua.source.levelv = _startV

	if errorqueue.count > 0 then
		return true,"Error occured.  See error queue for details."
	else
		return false,"No error."
	end
end

--[[ Name: ReadWaveformFromFile()

	Usage: err,msg = ReadWaveformFromFile(filepath, wfrmTbl)
	
	Description:	This function reads the contents of a .csv file and
		loads it into a table that can be used with the SetupAWG()
		function.  The .csv file must be loacated on a USB thumbdrive
		inseted into the front panel of the instrument. This function
		expects the .csv file to be in a format where each point in the
		waveform is on its own line. This function makes it possible to
		generate a list of points in a program such as Excel and load
		them into the instrument.
	
	Parameters:
		filepath: A string containing the path to the .csv file located
			on the USB drive
		wfrmTbl: The table where the contents of the .csv file
			will be loaded to.

	Returns:
		err: Returns true if error was detected else returns false
		msg: A string describing the error that occurred.
--]]
function ReadWaveformFromFile(filepath, wfrmTbl)
	local file
	local err
	file, err = io.open(filepath, "r")
	if err ~= nil then
		return true, "Error: Could not open file."
	end
	local line = file:read()
	local i = 1
	while line ~= nil do
		wfrmTbl[i] = tonumber(line)
		i = i + 1
		line = file:read()
	end
	io.close(file)
	return false, "No error."
end

--[[ Name: GenerateCI230WaveformX()

	Usage: GenerateCI230WaveformX(wfrmTbl)

	Description:
		The functions below generate waveform tables for the CI 230
		waveforms as specified in the Ford EMC-CS-2009.1 specification.
		Replace the X in GenerateCI230WaveformX with the desired
		waveform to generate (A, B, C, or D).
	Parameters:
		wfrmTbl:	A table to store the generated waveform in.
--]]
function GenerateCI230WaveformA(wfrmTbl)
	-- 100msec of 12.5V then back to 0V for 11 seconds then end at 13.5 V

	-- # of points in a segment = 
	-- length of the segment in seconds X source update rate
	
	-- 1) 100ms of 12.5V
	local seg1 = 0.100 * _srcRate
	for i=1, seg1 do
		wfrmTbl[i] = 12.5
	end
	
	-- 2) 11 seconds of 0V
	local seg2 = seg1 + 11 * _srcRate
	for i=seg1+1, seg2 do
		wfrmTbl[i] = 0
	end
	
	-- 3) Add an extra point so output goes to 13.5 at the end
	wfrmTbl[seg2 + 1] = 13.5
end
function GenerateCI230WaveformB(wfrmTbl)
	-- 0V for 5ms, 12.5V for 200ms, ramp from 12.5 down to 5V over 5ms, 5V for 15ms, ramp from 5V to 9V over 50ms,
	-- 4HZ sine wave centered at 9V with 2V pk-pk for 10s, ramp from 9V to 13.5V over 500ms, 13.5V for 325 ms, end at 13.5V
	local stepsize = 0
	
	-- 1) 0V for 5ms
	local seg1 = 0.005 * _srcRate
	for i=1, seg1 do
		wfrmTbl[i] = 0
	end
	
	-- 2) 12.5V for 200ms
	local seg2 = seg1 + 0.200 * _srcRate
	for i=seg1+1, seg2 do
		wfrmTbl[i] = 12.5
	end
	
	-- 3) Ramp 12.5V -> 5V over 5ms
	local seg3 = seg2 + 0.005 * _srcRate
	stepsize = (5 - 12.5)/(0.005 * _srcRate)
	for i=seg2+1, seg3 do
		wfrmTbl[i] = wfrmTbl[i-1] + stepsize
	end
	
	-- 4) 5V for 15ms
	local seg4 = seg3 + 0.015 * _srcRate
	for i=seg3+1, seg4 do
		wfrmTbl[i] = 5
	end
	
	-- 5) Ramp 5V -> 9V over 50ms
	local seg5 = seg4 + 0.050 * _srcRate
	stepsize = (9-5)/(0.050 * _srcRate)
	for i=seg4+1, seg5 do
		wfrmTbl[i] = wfrmTbl[i-1] + stepsize
	end
	
	-- 6) 4Hz Sine centered at 9V with 2V pk-pk for 10s
	local seg6 = seg5 + 10 * _srcRate
	for i=seg5+1, seg6 do
		wfrmTbl[i] = 2/2*math.sin(4 * 2*math.pi*(i-seg5)/_srcRate) + 9
	end
	
	-- 7) Ramp from 9V to 13.5V over 500ms
	local seg7 = seg6 + 0.500 * _srcRate
	stepsize = (13.5 - 9)/(0.500 * _srcRate)
	for i=seg6+1, seg7 do
		wfrmTbl[i] = wfrmTbl[i-1] + stepsize
	end
	
	-- 8) 13.5V for 325ms
	local seg8 = seg7 + 0.325 * _srcRate
	for i=seg7+1, seg8 do
		wfrmTbl[i] = 13.5
	end
end
function GenerateCI230WaveformC(wfrmTbl)
	-- 0V for 190ms, 12.5V for 15ms, ramp from 12.5 down to 5V over 5ms, 5V for 15ms, ramp from 5V to 9V over 50ms,
	-- 4HZ sine wave centered at 9V with 2V pk-pk for 10s, ramp from 9V to 13.5V over 500ms, 13.5V for 100 ms, end at 0V
	local stepsize = 0
	
	-- 1) 0V for 190ms
	local seg1 = 0.190 * _srcRate
	for i=1, seg1 do
		wfrmTbl[i] = 0
	end
	
	-- 2) 12.5V for 15ms
	local seg2 = seg1 + 0.015 * _srcRate
	for i=seg1+1, seg2 do
		wfrmTbl[i] = 12.5
	end
	
	-- 3) Ramp 12.5V -> 5V over 5ms
	local seg3 = seg2 + 0.005 * _srcRate
	stepsize = (5 - 12.5)/(0.005 * _srcRate)
	for i=seg2+1, seg3 do
		wfrmTbl[i] = wfrmTbl[i-1] + stepsize
	end
	
	-- 4) 5V for 15ms
	local seg4 = seg3 + 0.015 * _srcRate
	for i=seg3+1, seg4 do
		wfrmTbl[i] = 5
	end
	
	-- 5) Ramp 5V -> 9V over 50ms
	local seg5 = seg4 + 0.050 * _srcRate
	stepsize = (9-5)/(0.050 * _srcRate)
	for i=seg4+1, seg5 do
		wfrmTbl[i] = wfrmTbl[i-1] + stepsize
	end
	
	-- 6) 4Hz Sine centered at 9V with 2V pk-pk for 10s
	local seg6 = seg5 + 10 * _srcRate
	for i=seg5+1, seg6 do
		wfrmTbl[i] = 2/2*math.sin(4 * 2*math.pi*(i-seg5)/_srcRate) + 9
	end
	
	-- 7) Ramp from 9V to 13.5V over 500ms
	local seg7 = seg6 + 0.500 * _srcRate
	stepsize = (13.5 - 9)/(0.500 * _srcRate)
	for i=seg6+1, seg7 do
		wfrmTbl[i] = wfrmTbl[i-1] + stepsize
	end
	
	-- 8) 13.5V for 100ms
	local seg8 = seg7 + 0.100 * _srcRate
	for i=seg7+1, seg8 do
		wfrmTbl[i] = 13.5
	end
	
	-- 9) End at 0V for 225ms
	local seg9 = seg8 + 0.225 * _srcRate
	for i=seg8+1, seg9 do
		wfrmTbl[i] = 0
	end
end
function GenerateCI230WaveformD(wfrmTbl)
	-- 12.5V for 205ms, ramp from 12.5V down to 5V over 5ms, 5V for 15ms, ramp from 5V to 9V over 50ms,
	-- 4HZ sine wave centered at 9V with 2V pk-pk for 10s, ramp from 9V to 13.5V over 500ms, end at 13.5V
	local stepsize = 0
	
	-- 1) 12.5V for 205ms
	local seg1 = 0.205 * _srcRate
	for i=1, seg1 do
		wfrmTbl[i] = 12.5
	end
	
	-- 2) Ramp 12.5V -> 5V over 5ms
	local seg2 = seg1 + 0.005 * _srcRate
	stepsize = (5 - 12.5)/(0.005 * _srcRate)
	for i=seg1+1, seg2 do
		wfrmTbl[i] = wfrmTbl[i-1] + stepsize
	end
	
	-- 3) 5V for 15ms
	local seg3 = seg2 + 0.015 * _srcRate
	for i=seg2+1, seg3 do
		wfrmTbl[i] = 5
	end
	
	-- 4) Ramp 5V -> 9V over 50ms
	local seg4 = seg3 + 0.050 * _srcRate
	stepsize = (9-5)/(0.050 * _srcRate)
	for i=seg3+1, seg4 do
		wfrmTbl[i] = wfrmTbl[i-1] + stepsize
	end
	
	-- 5) 4Hz Sine centered at 9V with 2V pk-pk for 10s
	local seg5 = seg4 + 10 * _srcRate
	for i=seg4+1, seg5 do
		wfrmTbl[i] = 2/2*math.sin(4 * 2*math.pi*(i-seg4)/_srcRate) + 9
	end
	
	-- 6) Ramp from 9V to 13.5V over 500ms
	local seg6 = seg5 + 0.500 * _srcRate
	stepsize = (13.5 - 9)/(0.500 * _srcRate)
	for i=seg5+1, seg6 do
		wfrmTbl[i] = wfrmTbl[i-1] + stepsize
	end
	
	-- 7) End at 13.5V for 325ms
	local seg7 = seg6 + 0.325 * _srcRate
	for i=seg6+1, seg7 do
		wfrmTbl[i] = 13.5
	end
end


--[[
	The functions below are utility functions used by the Setup
	functions to generate the waveform points.  You do not need to call
	these functions yourself unless you wish to generate your own copy
	of the waveform table for these Arb Functions.
	
	Note: These functions do only a minimal amount of error checking
--]]
function GenerateSineWaveform(frequency, amplitude, offset, wfrmTbl)
	if frequency > (_srcRate / 4) then
		return true, "Frequency must be less than 1/4 th source rate."
	elseif frequency <= 0 then
		return true, "Frequency must be greater than 0."
	end
	
	local pointsInCycle = math.floor(_srcRate / frequency)
	for i=1, pointsInCycle do
		wfrmTbl[i] = amplitude / 2 * math.sin(frequency * 2 * math.pi*(i)/_srcRate) + offset
	end
	return false, "No error."
end
function GenerateSquareWaveform(frequency, amplitude, offset, dutyCycle, wfrmTbl)
	if frequency > (_srcRate / 4) then
		return true, "Frequency must be less than 1/4 th source rate."
	elseif frequency <= 0 then
		return true, "Frequency must be greater than 0."
	end
	if dutyCycle < 0 or dutyCycle > 1 then
		return true,"dutyCycle must be a number between 0 and 1."
	end

	local pointsInCycle = math.floor(_srcRate / frequency)
	local highPoints = math.floor(pointsInCycle * dutyCycle)
	if dutyCycle == 0 then
		for i=1, pointsInCycle do wfrmTbl[i] = offset - amplitude / 2 end
	elseif dutyCycle == 1 then
		for i=1, pointsInCycle do wfrmTbl[i] = offset + amplitude / 2 end
	else
		for i=1, highPoints do
			wfrmTbl[i] = offset + amplitude / 2
		end
		for i=highPoints + 1, pointsInCycle do
			wfrmTbl[i] = offset - amplitude / 2
		end
	end
	return false, "No error."
end
function GenerateRampWaveform(frequency, amplitude, offset, symmetry, wfrmTbl)
	if frequency > (_srcRate / 4) then
		return true, "Frequency must be less than 1/4 th source rate."
	elseif frequency <= 0 then
		return true, "Frequency must be greater than 0."
	end
	if symmetry < 0 or symmetry > 1 then
		return true,"symmetry must be a number between 0 and 1."
	end

	local pointsInCycle = math.floor(_srcRate / frequency)
	local risePoints = math.floor(pointsInCycle * symmetry)
	local fallPoints = pointsInCycle - risePoints
	if symmetry == 0 then
		for i=1, pointsInCycle do
			wfrmTbl[i] = offset + amplitude / 2 - amplitude * (i / pointsInCycle)
		end
	elseif symmetry == 1 then
		for i=1, pointsInCycle do
			wfrmTbl[i] = offset - amplitude / 2 + amplitude * (i / pointsInCycle)
		end
	else
		for i=1, risePoints do
			wfrmTbl[i] = offset - amplitude / 2 + amplitude * (i / risePoints)
		end
		for i=1, fallPoints do
			wfrmTbl[risePoints + i] = offset + amplitude / 2 - amplitude * (i / fallPoints)
		end
	end
	return false, "No error."
end
function GeneratePulseWaveform(period, high, low, pulseWidth, wfrmTbl)
	if pulseWidth < (1/_srcRate) then
		return true,string.format("pulseWidth must be greater than %0.6g seconds.", 1/_srcRate)
	end
	if pulseWidth > period then
		return true, "pulseWidth must be less than period."
	end

	local pointsInCycle = math.floor(period * _srcRate)
	local highPoints = math.floor(pulseWidth * _srcRate)
	
	for i=1, highPoints do
		wfrmTbl[i] = high
	end
	for i=highPoints + 1, pointsInCycle do
		wfrmTbl[i] = low
	end
	return false, "No error."
end
function GenerateNoiseWaveform(amplitude, offset, lengthSeconds, wfrmTbl)
	if lengthSeconds < (1/_srcRate) then
		return true,string.format("lengthSeconds must be greater than or equal to %0.6g seconds.", 1/_srcRate)
	end

	for i=1, math.floor(_srcRate * lengthSeconds) do
		wfrmTbl[i] = amplitude * math.random() - amplitude / 2 + offset
	end
	return false, "No error."
end

function test()
	wfrmA = {}
	wfrmB = {}
	wfrmC = {}
	wfrmD = {}
	GenerateCI230WaveformA(wfrmA)
	GenerateCI230WaveformB(wfrmB)
	GenerateCI230WaveformC(wfrmC)
	GenerateCI230WaveformD(wfrmD)
end