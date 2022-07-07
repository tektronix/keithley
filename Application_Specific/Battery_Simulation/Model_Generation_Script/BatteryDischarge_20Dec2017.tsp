--[[
	
Script: BatteryDischarge_20Dec2017
Written by: Keithley Applications Engineering (Al Ivons)
`
***********************************************************
*** Copyright 2017 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Revision History:
	* Originally released on 07/31/2017 as BatteryDischargeScript_31Jul2017.
		- Name was shortened to BatteryDischarge_31Jul2017 on 08/03/2017 because length 
		  of original name caused errors when trying to manage or run the script from 
		  the front panel of the instrument.
	* Revised on 12/20/2017 and name changed to BatteryDischarge_20Dec2017.
		- Added front panel entry of a general purpose comment.  Comment is saved in  
		  the "..._SetupAndRawData.csv" file.
		- Added conditional to check the polarity of the initial Voc reading.  Positive 
		  polarity is expected.  Script is aborted and an error is generated if the 
		  polarity is negative.
		- Fixed a couple of debug print statements.  One caused an error under some 
		  conditions and one was formatted incorrectly.

This script is example code designed to discharge a battery and create a battery model for use
in a Keithley Model 2281S-20-6 Battery Simulator and Precision DC Power Supply.  It will run 
on any of the following Keithley instruments:
	* Model 2450 SourceMeter
	* Model 2460 SourceMeter
	* Model 2461 SourceMeter

WARNING:	This script presently does not include any safeguards to prevent the user from 
			discharging a LITHIUM ION battery beyond safe limits.  It is the user's responsibility 
			to follow all manufacturer's guidelines when setting the discharge current and cut-off 
			voltage for a LITHIUM ION battery to ensure safe operation of the test setup and program.

Functions:
	* Dround()
	* SigDig()
	* MeasESR()
	* ConfigSystem()
	* ConfigTest()
	* DoConstantCurrDischarge()
	* DoCurrListDischarge()
	* ExtractModel()
	* SaveModel()
	* SaveSetupAndRawData()
	* RunTest()

--]]

-- ********** Declare global tables **********

TEST_PARAM = {}				-- Global table to hold various test parameters and share them among different functions

BATT_MODEL_RAW = {}			-- Global table to hold "raw" measured and calculated data for battery model
BATT_MODEL_RAW.voc = {}		-- Global table to hold all measured open-circuit voltage values
BATT_MODEL_RAW.vload = {}	-- Global table to hold all voltage values measured at load (i.e. discharge) current
BATT_MODEL_RAW.esr = {}		-- Global table to hold all measured/calculated internal resistance values
BATT_MODEL_RAW.tstamp = {}	-- Global table to hold all timestamp values

BATT_MODEL = {}			-- Global table to hold final model values extracted from BATT_MODEL_RAW
BATT_MODEL.voc = {}		-- Global table to hold final open-circuit voltage values extracted from BATT_MODEL_RAW.voc
BATT_MODEL.vload = {}	-- Global table to hold final voltage-at-load values extracted from BATT_MODEL_RAW.vload
BATT_MODEL.esr = {}		-- Global table to hold final internal resistance values extracted from BATT_MODEL_RAW.esr
BATT_MODEL.tstamp = {}	-- Global table to hold final timestamp values extracted from BATT_MODEL_RAW.tstamp
BATT_MODEL.soc = {}		-- Global table to hold state-of-charge values (0 to 100%, in 1% increments)

-- ********** Define Utility Functions **********

function Dround(number, n_decimal_places)		-- Round to n_decimal_places
	local mult = 10 ^ (n_decimal_places or 0)	-- Will use n_decimal_places, unless n_decimal_places = nil, then will use 0
	return math.floor(number * mult + 0.5) / mult
end --function Dround()

function SigDig(number, ndigits)	-- Round to ndigits significant digits
	return tonumber(string.format("%."..(ndigits or 0).."g", number))
end --function SigDig()

function MeasESR(test_curr, settle_time)	-- Ivons modified on 07/25/2017

	-- load_curr and test_curr are load currents, which are drawn from the battery.
	--   To draw current FROM the battery, the programmed current level must be negative (or zero).
	
	test_curr = -math.abs(test_curr)				-- Ensure test_curr has proper sense
	local load_curr = smu.source.level				-- Will be negative
	local vload = smu.measure.read(defbuffer1)		-- Battery voltage at load_curr
	smu.source.level = -math.abs(test_curr)			-- test_curr equal to zero corresponds to an open circuit
	if settle_time > 0 then delay(settle_time) end
	local vtest = smu.measure.read(defbuffer2)		-- Battery voltage at test_curr; vtest is Voc if test_curr = 0
	smu.source.level = load_curr
	local esr = math.abs((vtest - vload) / (test_curr - load_curr))	-- (V2-V1)/(I2-I1); ensure positive resistance
	return vload, vtest, esr
	
end

-- ********** Define Primary Test Functions **********

function ConfigSystem(do_beeps, debug)

	reset()
	
	display.changescreen(display.SCREEN_HOME)
	
	eventlog.clear()

	--[[
	display.BUTTON_OPTIONn = display.input.option(dialogTitle, buttonTitle1, buttonTitle2, ... buttonTitleN)
	
		* n is the number of the button that is selected from the front-panel display; value returned is nil 
		  if Cancel is pressed on the keypad
		  	- Buttons are numbered top to bottom, left to right
		* dialogTitle is a string that contains the text to be displayed as the title of the dialog box on the
		  front-panel display; up to 32 characters
		* buttonTitle1 is a string that contains the name of the first button; up to 15 characters
		* buttonTitle2 is a string that contains the name of the second button; up to 15 characters
		* buttonTitleN is a string that contains the names of subsequent buttons, where N is a number from 3
		  to 10
		  	- You can define up to 10 buttons; each button title can be up to 15 characters
	--]]
	
	-- Configure terminals
    if do_beeps then beeper.beep(0.08, 2400) end
    local terminals = display.input.option("Select TERMINALS you want to use:", "Front", "Rear")
    
    if terminals == display.BUTTON_OPTION1 then		-- If Front Terminals selected
		terminals = "FRONT TERMINALS"
		smu.terminals = smu.TERMINALS_FRONT			-- "smu.terminals" command replaces "smu.measure.terminals" command, which is deprecated
	elseif terminals == display.BUTTON_OPTION2 then	-- If Rear Terminals selected
		terminals = "REAR TERMINALS"
		smu.terminals = smu.TERMINALS_REAR
	else											-- If Cancel selected
		return -1010, "ConfigSystem aborted by user"
	end --if	
	
	TEST_PARAM.terminals = terminals
	
	-- Configure source settings
	smu.source.func = smu.FUNC_DC_CURRENT
	smu.source.offmode = smu.OFFMODE_HIGHZ	-- SMU is disconnected from output terminals when SMU output is OFF
											--   Moved this command after function command on 05/29/2017 because
											--   because I observed that off-state was being set back to Normal.
	smu.source.readback = smu.OFF
	smu.source.level = 0.0		-- Amps; zero is default value
	smu.source.range = 0.001	-- Amps; automatically disables source autorange.  Was 0.1; Ivons changed to 1mA on 07/25/2017
	smu.source.delay = 0.0		-- Seconds; automatically disables source autodelay
	
	-- Configure measure settings
	smu.measure.func = smu.FUNC_DC_VOLTAGE
	
    smu.measure.sense = smu.SENSE_4WIRE
    
	if localnode.model == "2450" then
		smu.measure.range = 200			-- Volts
		smu.source.vlimit.level = 210	-- Volts
	elseif localnode.model == "2460" then
		smu.measure.range = 100			-- Volts
		smu.source.vlimit.level = 105	-- Volts
	elseif localnode.model == "2461" then
		smu.measure.range = 100			-- Volts
		smu.source.vlimit.level = 105	-- Volts
	else
		return -1011, "Unexpected SMU model detected; ConfigSystem aborted"
	end --if
	
	smu.measure.autorange = smu.ON
	smu.measure.nplc = 1.0	-- Bob Green wants 1PLC, but may want to reduce to 0.1PLC like in original Valentine program
	
	--[[
	buttonReturn = display.input.prompt(buttonSet, dialogTitle)
	
		* buttonReturn indicates which button was pressed:
			- OK: display.BUTTON_OK
			- Cancel: display.BUTTON_CANCEL
			- Yes: display.BUTTON_YES
			- No: display.BUTTON_NO
		* buttonSet is the set of buttons to display:
			- OK button only: display.BUTTONS_OK
			- Cancel button only: display.BUTTONS_CANCEL
			- OK and Cancel buttons: display.BUTTONS_OKCANCEL
			- Yes and No buttons: display.BUTTONS_YESNO
			- Yes, No, and Cancel buttons: display.BUTTONS_YESNOCANCEL
		* dialogTitle is a string that contains the text to be displayed as the title 
			of the dialog box on the front-panel display; up to 63 characters (appears to allow more than 63)
	--]]

	local dialog_text = "Make 4-wire connections to your battery at the SMU "..terminals.." and then press OK."
	if do_beeps then beeper.beep(0.08, 2400) end
	display.input.prompt(display.BUTTONS_OK, dialog_text)

	smu.source.output = smu.ON
	
	defbuffer2.clear()
	
	local scrap_reading = smu.measure.read(defbuffer2)	-- Measure voltage to set range; using defbuffer2 to collect voc values
														-- Expected autorange to do this automatically, but different range 
														--   boundaries in 2460/61 affect my plans.  Use scrap_reading to set 
														--   the range.

	if debug then
		print("\nIn ConfigSystem()...")
		print("\nterminals = "..terminals)
		print("smu.terminals = "..smu.terminals)
		print("\nlocalnode.model = "..localnode.model)
		print("smu.measure.range (before ranging)= "..smu.measure.range)
		print("smu.source.vlimit.level (before ranging)= "..smu.source.vlimit.level)
		print("\nscrap_reading= "..scrap_reading)
	end --if
									
	smu.measure.range = scrap_reading	-- Automatically disables measure autoranging
	smu.source.vlimit.level = 1.05 * smu.measure.range	-- When forcing current, the source voltage limit MUST ALWAYS be kept greater than the DUT voltage
														-- Both real and range compliance should be avoided
	
	TEST_PARAM.initial_voc = smu.measure.read()	-- Capture an initial voltage measurement for system check
	
	smu.source.output = smu.OFF

	if debug then
		print("\nsmu.measure.range (after ranging)= "..smu.measure.range)
		print("smu.source.vlimit.level (after ranging)= "..smu.source.vlimit.level)
		print("\nTEST_PARAM.initial_voc = "..TEST_PARAM.initial_voc)
	end --if
	
	-- Ivons added following conditional on 12/20/2017 because negative value 
	--   subsequently causes instrument Error 1131 in ConfigTest()
	if TEST_PARAM.initial_voc <= 0 then
		return -1012, "Negative or zero Initial Voc detected; ConfigSystem aborted"
	end --if
	
	dialog_text = "Measured battery voltage = "..string.format("%.3f",TEST_PARAM.initial_voc).."V.\nPress OK to continue or Cancel to quit."
	if do_beeps then beeper.beep(0.08, 2400) end
	local button_selection = display.input.prompt(display.BUTTONS_OKCANCEL, dialog_text)
	if button_selection == display.BUTTON_CANCEL then
		return -1010, "ConfigSystem aborted by user"
	end --if
	
	local error_count = eventlog.getcount(eventlog.SEV_ERROR)
	if error_count == 0 then
		return error_count, "No errors"
	else
		return error_count, "Instrument errors occurred in ConfigSystem"
	end --if
	
end --function ConfigSystem()

function ConfigTest(do_beeps, debug)

	eventlog.clear()

	--[[
	numberEntered = display.input.number(dialogTitle, numberFormat, defaultValue, minimumValue, maximumValue)
		* Dialog title up to 32 characters
		* Available number formats:  display.NFORMAT_INTEGER, display.NFORMAT_DECIMAL, 
									 display.NFORMAT_EXPONENT, display.NFORMAT_PREFIX
		* numberEntered is value entered or nil (if Cancel selected)
	--]]

	--	32characters: --------------------------------

	-- Gather test parameters
	
	local max_allowed_current
	-- On 05/29/2017 Ivons recognized that he was mistakenly inspecting value of source range
	--   instead of measure range.  It is voltage measure range that determines voltage compliance 
	--   setting and the corresponding max current.  Changed it to inspection of voltage measure range.
	if localnode.model == "2450" then
		if smu.measure.range == 200 then	-- Volts
			max_allowed_current = 0.105		-- Amps
		else
			max_allowed_current = 1.05		-- Amps
		end --if
	elseif localnode.model == "2460" then
		if smu.measure.range == 100 then	-- Volts
			max_allowed_current = 1.05		-- Amps
		elseif smu.measure.range == 20 then	-- Volts
			max_allowed_current = 4.2		-- Amps
		elseif smu.measure.range == 10 then	-- Volts
			max_allowed_current = 5.25		-- Amps
		else
			max_allowed_current = 7.35		-- Amps
		end --if
	elseif localnode.model == "2461" then
		if smu.measure.range == 100 then	-- Volts
			max_allowed_current = 1.05		-- Amps
		elseif smu.measure.range == 20 then	-- Volts
			max_allowed_current = 4.2		-- Amps
		elseif smu.measure.range == 10 then	-- Volts
			max_allowed_current = 5.25		-- Amps
		else
			max_allowed_current = 7.35		-- Amps
		end --if
	else
		return -1021, "Unexpected SMU model detected; ConfigTest aborted"
	end --if

	--[[
	optionID = display.input.option(dialogTitle, buttonTitle1, buttonTitle2, ... buttonTitleN)
		* Up to 10 options
		* Dialog title up to 32 characters
		* Button titles up to 15 characters
		* optionID will be display.BUTTON_OPTIONN or nil (if Cancel selected)
	--]]
	
	-- Ivons added code below to enter a descriptive comment on 12/20/2017
	if do_beeps then beeper.beep(0.08, 2400) end
	local comment = display.input.string("Enter Comment (64 char max):", display.SFORMAT_ANY)
	if comment == "" or comment == nil then comment = "NO COMMENT" end
	TEST_PARAM.comment = comment

	if do_beeps then beeper.beep(0.08, 2400) end
	local button_selection = display.input.option("Select Discharge Type:", "Constant Curr", "Current List")
	
	if debug then
		print("\nIn ConfigTest()...")
		print("\nlocalnode.model = "..localnode.model)
		print("smu.measure.range = "..smu.measure.range)
		print("max_allowed_current = "..max_allowed_current)
		print("\ncomment = "..comment)	-- Ivons added on 12/20/2017
		print("\nbutton_selection = "..tostring(button_selection))	-- Ivons added "tostring()" on 12/20/2017 because button_selection can be nil
	end --if
	
	if button_selection == display.BUTTON_OPTION1 then	-- If Constant Current selected
	
		TEST_PARAM.discharge_type = "CONSTANT"
		
		local dialog_text = "Discharge Curr (1E-6 to "..max_allowed_current.."A)"	-- Ivons changed to local variable on 07/26/2017
		
		TEST_PARAM.discharge_current = display.input.number(dialog_text, display.NFORMAT_PREFIX, 0.1, 1e-6, max_allowed_current)
		if TEST_PARAM.discharge_current == nil then
			return -1020, "ConfigTest aborted by user"
		end
		
		TEST_PARAM.discharge_curr_list = nil							-- If discharge_type is CONSTANT, then there is no current list, 
		TEST_PARAM.max_discharge_current = TEST_PARAM.discharge_current	--   and discharge_current is the max_discharge_current
		
		if debug then
			print("TEST_PARAM.discharge_type = "..TEST_PARAM.discharge_type)
			print("TEST_PARAM.discharge_current = "..tostring(TEST_PARAM.discharge_current))
			print("TEST_PARAM.discharge_curr_list = "..tostring(TEST_PARAM.discharge_curr_list))
			print("TEST_PARAM.max_discharge_current = "..TEST_PARAM.max_discharge_current)
		end --if
	
	elseif button_selection == display.BUTTON_OPTION2 then	-- If Current List selected
	
		TEST_PARAM.discharge_type = "LIST"
		
		TEST_PARAM.discharge_curr_list = {}	-- Create table to hold current list values
		TEST_PARAM.discharge_current = nil	-- If discharge_type is LIST, then there is no constant discharge_current

		local npoints = display.input.number("Number of Pts in List (2 to 10)", display.NFORMAT_INTEGER, 2, 2, 10)
		if npoints == nil then
			return -1020, "ConfigTest aborted by user"
		end

		if debug then
			print("TEST_PARAM.discharge_type = "..TEST_PARAM.discharge_type)
			print("TEST_PARAM.discharge_current = "..tostring(TEST_PARAM.discharge_current))
			print("TEST_PARAM.discharge_curr_list = "..tostring(TEST_PARAM.discharge_curr_list))
			print("npoints = "..npoints)
		end --if
		
		local average_curr = 0
		local list_duration = 0
		for i = 1, npoints do
			
			TEST_PARAM.discharge_curr_list[i] = {}	-- Create table to hold current level and duration for list point i
			
			dialog_text = "Dischrg Curr #"..i.." (1E-6 to "..max_allowed_current.."A)"
			TEST_PARAM.discharge_curr_list[i].current = display.input.number(dialog_text, display.NFORMAT_PREFIX, 0.1, 1e-6, max_allowed_current)
			if TEST_PARAM.discharge_curr_list[i].current == nil
				then return -1020, "ConfigTest aborted by user"
			end
			
			TEST_PARAM.discharge_curr_list[i].duration = display.input.number("Curr #"..i.." Duration (s, 500us min)", display.NFORMAT_PREFIX, 1, 500E-6)	-- Still need min/max
			if TEST_PARAM.discharge_curr_list[i].duration == nil then
				return -1020, "ConfigTest aborted by user"
			end
			
			average_curr = average_curr + TEST_PARAM.discharge_curr_list[i].current * TEST_PARAM.discharge_curr_list[i].duration
			list_duration = list_duration + TEST_PARAM.discharge_curr_list[i].duration
			
			if debug then
				print("\nTEST_PARAM.discharge_curr_list["..i.."].current = "..TEST_PARAM.discharge_curr_list[i].current)
				print("TEST_PARAM.discharge_curr_list["..i.."].duration = "..TEST_PARAM.discharge_curr_list[i].duration)
			end --if
			
		end --for
		
		average_curr = average_curr / list_duration
		TEST_PARAM.discharge_curr_list.average_curr = average_curr
		TEST_PARAM.discharge_curr_list.duration = list_duration
		
		local max_specified_current = TEST_PARAM.discharge_curr_list[1].current
		for i = 2, npoints do
			if TEST_PARAM.discharge_curr_list[i].current > max_specified_current then max_specified_current = TEST_PARAM.discharge_curr_list[i].current end
		end --for
		TEST_PARAM.max_discharge_current = max_specified_current
		
		local maxdur = TEST_PARAM.discharge_curr_list[1].duration
		for i = 2, npoints do
			if TEST_PARAM.discharge_curr_list[i].duration > maxdur then maxdur = TEST_PARAM.discharge_curr_list[i].duration end
		end --for
		
		-- Create table of list points with duration equal to maxdur
		local maxdur_indices = {}
		for i = 1, npoints do
			if TEST_PARAM.discharge_curr_list[i].duration == maxdur then table.insert(maxdur_indices, i) end
		end --for
		
		-- Determine the primary step in the sweep where ESR will be measured
		local max_dur_index
		if table.getn(maxdur_indices) == 1 then
			max_dur_index = maxdur_indices[1]
		else
			local maxcurr = TEST_PARAM.discharge_curr_list[maxdur_indices[1]].current
			max_dur_index = maxdur_indices[1]
			for i = 2, table.getn(maxdur_indices) do
				if TEST_PARAM.discharge_curr_list[maxdur_indices[i]].current > maxcurr then
					maxcurr = TEST_PARAM.discharge_curr_list[maxdur_indices[i]].current
					max_dur_index = maxdur_indices[i]
				end
			end --for
		end --if
		TEST_PARAM.discharge_curr_list.max_dur_index = max_dur_index
		
		if debug then
			print("\nTEST_PARAM.discharge_curr_list.average_curr = "..TEST_PARAM.discharge_curr_list.average_curr)
			print("TEST_PARAM.discharge_curr_list.duration = "..TEST_PARAM.discharge_curr_list.duration)
			print("TEST_PARAM.max_discharge_current = "..TEST_PARAM.max_discharge_current)
			print("maxdur = "..maxdur)
			print("maxdur_indices.n = "..table.getn(maxdur_indices))
			print("TEST_PARAM.discharge_curr_list.max_dur_index = "..tostring(TEST_PARAM.discharge_curr_list.max_dur_index))
		end --if
		
	else	-- If Cancel selected
	
		return -1020, "ConfigTest aborted by user"
		
	end --if	

	-- Set maximum cut-off voltage to 98% of TEST_PARAM.initial_voltage
	local cov_max = Dround(0.98 * TEST_PARAM.initial_voc, 2)	-- Was 3 decimal places; Ivons changed to 2 on 07/26/2017
	
	-- Set default cut-off voltage to 50% of TEST_PARAM.initial_voltage.  Was 75%; Ivons changed on 07/26/2017.
	local cov_default = Dround(0.5 * TEST_PARAM.initial_voc, 2)	-- Was 1 decimal place; Ivons changed to 2 on 07/26/2017
	
	local dialog_text = "Cut-off Voltage (0.1 to "..cov_max.."V)"	-- 100mV is arbitrary minimum
	TEST_PARAM.vcutoff = display.input.number(dialog_text, display.NFORMAT_PREFIX, cov_default, 0.1, cov_max)
	if TEST_PARAM.vcutoff == nil then
		return -1020, "ConfigTest aborted by user"
	end
	
	if debug then
		print("\ncov_max = "..cov_max)
		print("cov_default = "..cov_default)
		print("TEST_PARAM.vcutoff = "..TEST_PARAM.vcutoff)
	end --if

	-- Ivons changed minimum measure interval from 10ms to 80ms on 07/26/2017.  80ms is more appropriate for 4 x 1PLC measurements.
	TEST_PARAM.measure_interval = display.input.number("ESR Meas Interval (0.08 to 600s)", display.NFORMAT_PREFIX, 2, 0.01, 600) 
	if TEST_PARAM.measure_interval == nil then
		return -1020, "ConfigTest aborted by user"
	end
	
	if debug then print("\nTEST_PARAM.measure_interval = "..TEST_PARAM.measure_interval) end
	
	local error_count = eventlog.getcount(eventlog.SEV_ERROR)
	if error_count == 0 then
		return error_count, "No errors"
	else
		return error_count, "Instrument errors occurred in ConfigTest"
	end --if

end --function ConfigTest()

function DoConstantCurrDischarge(debug)

	eventlog.clear()
	
	-- Create local aliases for global tables
	local voc_tbl = BATT_MODEL_RAW.voc
	local vload_tbl = BATT_MODEL_RAW.vload
	local esr_tbl = BATT_MODEL_RAW.esr
	local tstamp_tbl = BATT_MODEL_RAW.tstamp
	
	-- Declare other local variables
	local dialog_text	-- Ivons made a local variable on 07/30/2017
		
	local azero_overhead = 0.00133	-- Execution overhead associated with autozero; appears to vary slightly with NPLC value.  
									--   Includes execution overhead for timer.cleartime() y=timer.gettime(), which is approx 10us.
									--   Values determined using 2461 with Rev 1.6.1a FW

	local azero_duration = 2 * smu.measure.nplc / localnode.linefreq + azero_overhead	-- Approximate execution time of autozero
	
	local meas_intrvl = TEST_PARAM.measure_interval			-- Ivons renamed time_intvl to meas_intrvl on 07/26/2017
	local loop_delay = math.max(meas_intrvl / 10000, 0.001)	-- Ivons added on 07/26/2017
	local tstart_meas_intrvl	-- Ivons replaced tstart and tstart_cycle with tstart_meas_intrvl on 07/26/2017

	local counter = 0
	local quit = false
	
	-- Set up display
	display.clear()
	display.changescreen(display.SCREEN_USER_SWIPE)
	
	-- Initialize SMU output
	smu.source.range = TEST_PARAM.max_discharge_current		-- Use fixed source range
	smu.source.level = -1*TEST_PARAM.discharge_current		-- Negative current because drawing current from battery

	TEST_PARAM.discharge_start_time = os.date('%x %X', localnode.gettime())
	smu.source.output = smu.ON
	
	delay(0.1)	-- Allow some settling time; required time is TBD

	timer.cleartime()	-- Reset timer to zero	

	if debug then
		print("\nIn DoConstantCurrDischarge()...")
		print("\nazero_overhead = "..azero_overhead) 
		print("azero_duration = "..azero_duration)
		print("\nmeas_intrvl = "..meas_intrvl)
		print("loop_delay = "..loop_delay)
		print("\nTEST_PARAM.discharge_start_time = "..TEST_PARAM.discharge_start_time)
		print("\ncounter, tstamp, voc, vload, esr")
	end --if
	
	while(quit == false) do
	
		counter = counter + 1
	
		smu.measure.autozero.once()
		
		tstart_meas_intrvl = timer.gettime()

		-- MeasESR(test_curr, settle_time); Ivons changed function name on 07/26/2017
		vload_tbl[counter], voc_tbl[counter], esr_tbl[counter] = MeasESR(0, 0.01)	-- Proper settle_time is still TBD

		tstamp_tbl[counter] = tstart_meas_intrvl

		if debug then print(counter, tstamp_tbl[counter], voc_tbl[counter], vload_tbl[counter], esr_tbl[counter]) end

		display.clear()
		display.settext(display.TEXT1, "Total time="..Dround(timer.gettime(),0).." s")
		-- dialog_text = "Voc="..Dround(voc_tbl[counter],2).." Vload="..Dround(vload_tbl[counter],2).." ESR="..Dround(esr_tbl[counter],4)
		-- Ivons replaced line above with line below on 07/26/2015.  Had to change to string.format because concatenate alone did not preserve trailing zeroes.
		dialog_text = "Voc="..string.format("%0.2f", voc_tbl[counter]).." Vload="..string.format("%0.2f", vload_tbl[counter]).." ESR="..string.format("%0.4f", esr_tbl[counter])
		display.settext(display.TEXT2, dialog_text)
		
		if (vload_tbl[counter] <= TEST_PARAM.vcutoff) then
			quit = true
			break
		end
		
		while (timer.gettime() - tstart_meas_intrvl) < (meas_intrvl - azero_duration) do
			delay(loop_delay)	-- Was delay(meas_intrvl / 101); Ivons changed on 07/26/2017
		end --while
		
	end --while
		
	smu.source.level = 0
	smu.source.output = smu.OFF
	
	TEST_PARAM.discharge_stop_time = os.date('%x %X', localnode.gettime())
	
	BATT_MODEL_RAW.capacity = TEST_PARAM.discharge_current * tstamp_tbl[counter] / 3600
	
	if debug then
		print("\nTEST_PARAM.discharge_stop_time = "..TEST_PARAM.discharge_stop_time)
		print("\nBATT_MODEL_RAW.capacity = "..BATT_MODEL_RAW.capacity)
	end --if
	
	local error_count = eventlog.getcount(eventlog.SEV_ERROR)
	if error_count == 0 then
		return error_count, "No errors"
	else
		return error_count, "Instrument errors occurred in DoConstantCurrDischarge"
	end --if

end --DoConstantCurrDischarge()

function DoCurrListDischarge(settle_delay, debug)

	eventlog.clear()
	
	-- Create local aliases for global tables
	local voc_tbl = BATT_MODEL_RAW.voc
	local vload_tbl = BATT_MODEL_RAW.vload
	local esr_tbl = BATT_MODEL_RAW.esr
	local tstamp_tbl = BATT_MODEL_RAW.tstamp
	local curr_list_tbl = TEST_PARAM.discharge_curr_list	-- Ivons renamed TPDCL to curr_list_tbl on 07/26/2017
		
	-- Declare other local variables
	local dialog_text	-- Ivons made a local variable on 07/30/2017
	local azero_overhead = 0.00133	-- Execution overhead associated with autozero; appears to vary slightly with NPLC value.  
									--   Includes execution overhead for timer.cleartime() y=timer.gettime(), which is approx 10us.
									--   Values determined using 2461 with Rev 1.6.1a FW

	local azero_duration = 2 * smu.measure.nplc / localnode.linefreq + azero_overhead	-- Approximate execution time of autozero
	
	local npoints = table.getn(curr_list_tbl)
	local max_dur_index = curr_list_tbl.max_dur_index
	
	local meas_intrvl = TEST_PARAM.measure_interval	-- Ivons renamed time_intvl to meas_intrvl on 07/26/2017
	local loop_delay2	-- Ivons added on 07/30/2017
	local tstart_step	-- Ivons renamed tstart to tstart_step on 07/26/2017
	local tmeas
	
	local do_measure
	local counter
	local quit = false

	if debug then
		print("\nIn DoCurrListDischarge()...")
		print("\nsettle_delay = "..settle_delay)
		print("\nazero_overhead = "..azero_overhead) 
		print("azero_duration = "..azero_duration)
		print("\nnpoints = "..npoints) 
		print("max_dur_index = "..max_dur_index)
		print("\nmeas_intrvl = "..meas_intrvl)
	end --if

	-- Configure DIO Trigger Line 1; use to trigger Trigger Timer 1
	digio.line[1].reset()
	digio.line[1].mode = digio.MODE_TRIGGER_OPEN_DRAIN
	trigger.digin[1].edge = trigger.EDGE_FALLING
	trigger.digout[1].logic = trigger.LOGIC_NEGATIVE
	
	-- Configure Trigger Timer 1; use to pace measurements; triggered by DIO Trigger Line 1
	trigger.timer[1].reset()
	trigger.timer[1].delay = meas_intrvl	-- Was (meas_intrvl - azero_duration); Ivons changed on 07/31/2017
	trigger.timer[1].count = 0						-- Zero sets count to infinite
	trigger.timer[1].start.generate = trigger.OFF	-- Don't need first event for this application
	trigger.timer[1].start.stimulus = trigger.EVENT_DIGIO1
	trigger.timer[1].enable = trigger.ON
	
	-- Configure Trigger Blender 1; use blender to latch Trigger Timer 1 events
	trigger.blender[1].reset()
	trigger.blender[1].orenable = false						-- Set as AND blender
	trigger.blender[1].stimulus[1] = trigger.EVENT_TIMER1	-- Believe I need 2 events for blender to work
	trigger.blender[1].stimulus[2] = trigger.EVENT_TIMER1

	-- Set up display
	display.clear()
	display.changescreen(display.SCREEN_USER_SWIPE)
	
	-- Initialize SMU output
	smu.source.range = TEST_PARAM.max_discharge_current		-- Considering changing to autorange depending on required dynamic range
	smu.source.level = 0

	trigger.timer[1].clear()
	trigger.blender[1].clear()
	trigger.digin[1].clear()

	TEST_PARAM.discharge_start_time = os.date('%x %X', localnode.gettime())
	
	smu.source.output = smu.ON
	
	if debug then
		print("\nTEST_PARAM.discharge_start_time = "..TEST_PARAM.discharge_start_time)
		print("\ncounter, tstamp, voc, iload, vload, esr")
	end --if

	timer.cleartime()
			
	if max_dur_index == 1 then	-- Ivons rearranged this conditional on 07/27/2017
	
		counter = 0

	else
	
		counter = 1
		
		smu.source.level = -curr_list_tbl[max_dur_index].current	-- Negative current because drawing current from battery
		
		-- Allow some settling time; required time is TBD
		if (settle_delay - azero_duration) > 0 then delay(settle_delay - azero_duration) end -- Ivons added delay conditional on 07/30/2017
		
		smu.measure.autozero.once()

		trigger.digout[1].assert()	-- Assert DIO Trigger Line 1 to start Trigger Timer 1
		
		tmeas = timer.gettime()
		
		-- MeasESR(test_curr, settle_time); Ivons changed function name on 07/26/2017
		vload_tbl[counter], voc_tbl[counter], esr_tbl[counter] = MeasESR(0, 0.01)	-- Proper settle_time is still TBD

		tstamp_tbl[counter] = tmeas

		if debug then print(counter, tstamp_tbl[counter], voc_tbl[counter], -smu.source.level, vload_tbl[counter], esr_tbl[counter]) end	-- Ivons added -smu.source.level on 07/25/2017

		if vload_tbl[counter] <= TEST_PARAM.vcutoff then quit = true end	-- Ivons changed on 07/20/2017; was incorrectly voc_tbl[counter]
		
	end --if

	while not(quit) do
	
		for i = 1, npoints do
			
			smu.source.level = -curr_list_tbl[i].current	-- Negative current because drawing current from battery
			
			tstart_step = timer.gettime()
			
			-- if i == max_dur_index or curr_list_tbl[i].current == curr_list_tbl[max_dur_index].current then
			if curr_list_tbl[i].current == curr_list_tbl[max_dur_index].current then	-- Ivons simplified conditional on 07/30/2017
			
				-- Allow some settling time; required time is TBD.  Ivons moved delay here on 07/30/2017.
				if (settle_delay - azero_duration) > 0 then delay(settle_delay - azero_duration) end -- Ivons added delay conditional on 07/30/2017
			
				if counter == 0 then
					
					counter = counter + 1
					
					-- delay(math.max(settle_delay - azero_duration, 0))	-- Ivons moved delay earlier in sequence on 07/30/2017.
		
					smu.measure.autozero.once()
		
					trigger.digout[1].assert()	-- Assert DIO Trigger Line 1 to start Trigger Timer 1
				
					tmeas = timer.gettime()
					
					vload_tbl[counter], voc_tbl[counter], esr_tbl[counter] = MeasESR(0, 0.01)	-- Proper settle_time is still TBD

					tstamp_tbl[counter] = tmeas
					
					if vload_tbl[counter] <= TEST_PARAM.vcutoff then quit = true end	-- Ivons changed on 07/20/2017; was incorrectly voc_tbl[counter]
					
					if debug then print(counter, tstamp_tbl[counter], voc_tbl[counter], -smu.source.level, vload_tbl[counter], esr_tbl[counter]) end	-- Ivons added -smu.source.level on 07/25/2017  
					
				end --if

				-- delay(settle_time)	-- Ivons moved delay earlier in sequence on 07/30/2017.
				
				-- loop_delay2 = math.max(curr_list_tbl[i].duration / 10000, 0.001)	-- Ivons added on 07/30/2017 and then comment out on 07/31/2017
				while not(quit) and (timer.gettime() - tstart_step) < curr_list_tbl[i].duration do
				
					--[[ -- Ivons commented out this code on 07/31/2017; simplified by going to single wait statement below
					do_meas = trigger.blender[1].wait(0)
					while not(do_meas) do
						do_meas = trigger.blender[1].wait(loop_delay2)	-- Was .wait(curr_list_tbl[i].duration / 101); Ivons changed on 07/30/2017
					end --while
					--]]

					-- Ivons added the following 6 lines on 07/31/2017
					do_meas = trigger.blender[1].wait(meas_intrvl)	-- Believe measurement time provides sufficient margin for wait time
					if not(do_meas) then
						smu.source.level = 0
						smu.source.output = smu.OFF
						return -1060, "Blender wait statement timed out; DoCurrListDischarge aborted"
					end --if
					
					counter = counter + 1
					
					smu.measure.autozero.once()
		
					tmeas = timer.gettime()
					
					-- MeasESR(test_curr, settle_time); Ivons changed function name on 07/26/2017
					vload_tbl[counter], voc_tbl[counter], esr_tbl[counter] = MeasESR(0, 0.01)	-- Proper settle_time is still TBD

					tstamp_tbl[counter] = tmeas

					if debug then print(counter, tstamp_tbl[counter], voc_tbl[counter], -smu.source.level, vload_tbl[counter], esr_tbl[counter]) end	-- Ivons added -smu.source.level on 07/25/2017  

					display.clear()
					display.settext(display.TEXT1, "Total time="..Dround(tmeas,0).." s")
					-- dialog_text = "Voc="..Dround(voc_tbl[counter],2).." Vload="..Dround(vload_tbl[counter],2).." ESR="..Dround(esr_tbl[counter],4)
					-- Ivons replaced line above with line below on 07/30/2015.  Had to change to string.format because concatenate alone did not preserve trailing zeroes.
					dialog_text = "Voc="..string.format("%0.2f", voc_tbl[counter]).." Vload="..string.format("%0.2f", vload_tbl[counter]).." ESR="..string.format("%0.4f", esr_tbl[counter])
					display.settext(display.TEXT2, dialog_text)
				
					if vload_tbl[counter] <= TEST_PARAM.vcutoff then quit = true end	-- Ivons changed on 07/20/2017; was incorrectly voc_tbl[counter]
					
				end --while
				
			else	-- if not measuring then...
			
				if debug then print("\nDischarging at "..curr_list_tbl[i].current.."A for "..curr_list_tbl[i].duration.."s\n") end	-- Ivons added on 07/31/2017
				
				display.clear()
				display.settext(display.TEXT2, "Discharging at "..curr_list_tbl[i].current.."A")
				delay(curr_list_tbl[i].duration)
				
			end --if
			
			if quit then break end
			
		end --for
	end --while
	
	smu.source.level = 0
	smu.source.output = smu.OFF
	
	TEST_PARAM.discharge_stop_time = os.date('%x %X', localnode.gettime())
	
	trigger.timer[1].enable = trigger.OFF	-- Disable timer; not sure this is really necessary
	
	-- Calculate battery capacity in amp-hours
	-- For list discharge, use average current calculated for discharge profile
	BATT_MODEL_RAW.capacity = curr_list_tbl.average_curr * tstamp_tbl[counter] / 3600	-- Current in amps; timestamp in seconds; 3600 s/hr
	if debug then
		print("\nloop_delay2 = "..loop_delay2)
		print("\nBATT_MODEL_RAW.capacity = "..BATT_MODEL_RAW.capacity)
		print("\nTEST_PARAM.discharge_stop_time = "..TEST_PARAM.discharge_stop_time)
	end --if

	local error_count = eventlog.getcount(eventlog.SEV_ERROR)
	if error_count == 0 then
		return error_count, "No errors"
	else
		return error_count, "Instrument errors occurred in DoCurrListDischarge"
	end --if
	
end --DoCurrListDischarge()

function ExtractModel(debug)

	eventlog.clear()

	-- Create local aliases for global tables
	local voc_tbl = BATT_MODEL_RAW.voc
	local vload_tbl = BATT_MODEL_RAW.vload
	local esr_tbl = BATT_MODEL_RAW.esr
	local tstamp_tbl = BATT_MODEL_RAW.tstamp
	
	-- Declare other local variables
	local max_index = table.getn(tstamp_tbl)

	local model_interval = tstamp_tbl[max_index] / 100
	
	BATT_MODEL.soc[101] = 100	-- 100% state-of-charge
	BATT_MODEL.voc[101] = voc_tbl[1]
	BATT_MODEL.vload[101] = vload_tbl[1]
	BATT_MODEL.esr[101] = esr_tbl[1]
	BATT_MODEL.tstamp[101] = tstamp_tbl[1] - tstamp_tbl[1]	-- Calculate model timestamps relative to timestamp of first raw timestamp
	
	if debug then
		print("\nIn ExtractModel()...")
		print("\nsoc_index, soc, target_time, i, tstamp, voc, vload, esr")
		print(101, BATT_MODEL.soc[101], 0, 1, BATT_MODEL.tstamp[101], BATT_MODEL.voc[101], BATT_MODEL.vload[101], BATT_MODEL.esr[101])
	end --if
	 
	local start_index = 1
	local soc_index
	local target_time
	local i
	
	for soc = 99, 1, -1 do	-- 99% to 1% state_of_charge
	
		soc_index = soc + 1
		BATT_MODEL.soc[soc_index] = soc		-- soc% state-of-charge
		target_time = (100 - soc) * model_interval
		i = start_index
		
		while (tstamp_tbl[i] - tstamp_tbl[1]) < target_time do
			i = i + 1	-- Need to make sure this does not exceed max_index
		end --while
		
		if (tstamp_tbl[i] - tstamp_tbl[1]) > target_time then
		
			if ((tstamp_tbl[i] - tstamp_tbl[1]) - target_time) < (target_time - (tstamp_tbl[i-1] - tstamp_tbl[1])) then
				
				BATT_MODEL.voc[soc_index] = voc_tbl[i]
				BATT_MODEL.vload[soc_index] = vload_tbl[i]
				BATT_MODEL.esr[soc_index] = esr_tbl[i]
				BATT_MODEL.tstamp[soc_index] = tstamp_tbl[i] - tstamp_tbl[1]	-- Calculate model timestamps relative to timestamp of first raw timestamp
				start_index = i
				
			else
			
				BATT_MODEL.voc[soc_index] = voc_tbl[i-1]
				BATT_MODEL.vload[soc_index] = vload_tbl[i-1]
				BATT_MODEL.esr[soc_index] = esr_tbl[i-1]
				BATT_MODEL.tstamp[soc_index] = tstamp_tbl[i-1] - tstamp_tbl[1]	-- Calculate model timestamps relative to timestamp of first raw timestamp
				start_index = i - 1
				
			end --if
			
		else	-- if (tstamp_tbl[i] - tstamp_tbl[1]) == target_time then...
			
			BATT_MODEL.voc[soc_index] = voc_tbl[i]
			BATT_MODEL.vload[soc_index] = vload_tbl[i]
			BATT_MODEL.esr[soc_index] = esr_tbl[i]
			BATT_MODEL.tstamp[soc_index] = tstamp_tbl[i] - tstamp_tbl[1]	-- Calculate model timestamps relative to timestamp of first raw timestamp
			start_index = i
			
		end --if
		
		if debug then
			print(soc_index, BATT_MODEL.soc[soc_index], target_time, i, BATT_MODEL.tstamp[soc_index], BATT_MODEL.voc[soc_index], BATT_MODEL.vload[soc_index], BATT_MODEL.esr[soc_index])
		end --if
			
	end --for
	
	BATT_MODEL.soc[1] = 0	-- 0% state-of-charge
	BATT_MODEL.voc[1] = voc_tbl[max_index]
	BATT_MODEL.vload[1] = vload_tbl[max_index]
	BATT_MODEL.esr[1] = esr_tbl[max_index]
	BATT_MODEL.tstamp[1] = tstamp_tbl[max_index] - tstamp_tbl[1]	-- Calculate model timestamps relative to timestamp of first raw timestamp
	
	BATT_MODEL.capacity = Dround(BATT_MODEL_RAW.capacity, 4)
	
	if debug then
		print(1, BATT_MODEL.soc[1], 100*model_interval, max_index, BATT_MODEL.tstamp[1], BATT_MODEL.voc[1], BATT_MODEL.vload[1], BATT_MODEL.esr[1])
		print("\nBATT_MODEL.capacity = "..BATT_MODEL.capacity)	-- Ivons added " = " on 12/20/2017
	end --if
	
	if table.getn(tstamp_tbl) < 101 then
	
		local dialog_text = "Fewer than 101 measurements were made.  As a result, your battery model will have some duplicate values.  Press OK to continue."
		if do_beeps then beeper.beep(0.08, 2400) end
		display.input.prompt(display.BUTTONS_OK, dialog_text)
	
	end --if
	
	local error_count = eventlog.getcount(eventlog.SEV_ERROR)
	if error_count == 0 then
		return error_count, "No errors"
	else
		return error_count, "Instrument errors occurred in ExtractModel"
	end --if
	
end --ExtractModel()

function SaveModel(do_beeps, debug)

	eventlog.clear()
	
	if debug then
		print("\nIn SaveModel()...")
	end --if
	
	local button_selection = display.input.prompt(display.BUTTONS_YESNO, "Do you want to save model to a USB drive?")
	
	if button_selection == display.BUTTON_YES then
		
		local count = 1
		
		while (file.usbdriveexists() ~= 1) and count <= 3 do
		
			if do_beeps then beeper.beep(0.08, 2400) end
			button_selection = display.input.prompt(display.BUTTONS_OKCANCEL, "No drive found. Insert USB drive and press OK.")
			if button_selection == display.BUTTON_CANCEL then
				return -1030, "No USB drive found; SaveModel aborted by user"
			end --if
			count = count + 1
			
		end --while
		
		if(file.usbdriveexists() == 1) then
		
			--[[
			textEntered = display.input.string(dialogTitle, textFormat)
				* textEntered is the text that is entered from the front-panel display; nil if Cancel is pressed on the keypad
				* dialogTitle is a string that contains the text to be displayed as the title of the dialog box on the
				  front-panel display; up to 32 characters
				* textFormat is the format of the entered text:
					- Allow any characters: display.SFORMAT_ANY (default)
					- Allow both upper and lower case letters (no special characters): display.SFORMAT_UPPER_LOWER
					- Allow only upper case letters: display.SFORMAT_UPPER
					- Allow both upper and lower case letters, no special characters, no spaces,
					  and limited to 32 characters: display.SFORMAT_BUFFER_NAME
			--]]
			
			local filename
			repeat
				filename = display.input.string("Enter file name (8 char max)", display.SFORMAT_UPPER_LOWER)	-- Hopefully format won't allow period; still need to 
																												-- determine if 2281S imposes limitations on file name
			until string.len(filename) <= 8
			
			filename = filename..".csv"
			
			local outputfile = file.open("/usb1/"..filename, file.MODE_WRITE)
			file.write(outputfile, "PW_MODEL_PW2281S_20_6 \n")
			
			file.write(outputfile, "Capacity="..BATT_MODEL.capacity.."AH\n")
			file.write(outputfile, "SOC(%), Open Voltage(V), ESR(ohm)\n")
			
			for i = 1, 101 do
				file.write(outputfile, "" .. BATT_MODEL.soc[i] .. ", " ..  BATT_MODEL.voc[i] .. ", " ..  BATT_MODEL.esr[i] .. " \n")
			end --for
			
			file.close(outputfile)
			
			TEST_PARAM.batt_model_filename = filename
		
		else -- Never found USB drive
		
			-- ###### Need to do something here, but not sure what just yet	
	
			return -1031, "No USB drive found; SaveModel aborted"
	
		end --if
		
	else	-- button_selection == display.BUTTON_NO
	
		return 0, "User did not save model"		-- Not sure if should use zero here
		
	end --if
	
	display.clear()
	
	local error_count = eventlog.getcount(eventlog.SEV_ERROR)
	if error_count == 0 then
		return error_count, "No errors"
	else
		return error_count, "Instrument errors occurred in SaveModel"
	end --if

end --function SaveModel()

function SaveSetupAndRawData(do_beeps, debug)

	eventlog.clear()
	
	if debug then
		print("\nIn SaveSetupAndRawData()...")
	end --if
	
	local button_selection = display.input.prompt(display.BUTTONS_YESNO, "Do you want to save setup info and raw data to a USB drive?")
	
	if button_selection == display.BUTTON_YES then
		
		local count = 1
		
		while (file.usbdriveexists() ~= 1) and count <= 3 do
		
			if do_beeps then beeper.beep(0.08, 2400) end
			button_selection = display.input.prompt(display.BUTTONS_OKCANCEL, "No drive found. Insert drive and press OK.")
			if button_selection == display.BUTTON_CANCEL then
				return -1040, "No USB drive found; SaveSetupAndRawData aborted by user"
			end --if
			count = count + 1
			
		end --while
		
		if(file.usbdriveexists() == 1) then
		
			--[[
			textEntered = display.input.string(dialogTitle, textFormat)
				* textEntered is the text that is entered from the front-panel display; nil if Cancel is pressed on the keypad
					- As of Rev 1.6.4c FW, the maximum number of characters that can be entered is 64
				* dialogTitle is a string that contains the text to be displayed as the title of the dialog box on the
				  front-panel display; up to 32 characters
				* textFormat is the format of the entered text:
					- Allow any characters: display.SFORMAT_ANY (default)
					- Allow both upper and lower case letters (no special characters): display.SFORMAT_UPPER_LOWER
					- Allow only upper case letters: display.SFORMAT_UPPER
					- Allow both upper and lower case letters, no special characters, no spaces,
					  and limited to 32 characters: display.SFORMAT_BUFFER_NAME
			--]]
			
			local j, k = string.find(TEST_PARAM.batt_model_filename, ".csv")
			local filename = string.sub(TEST_PARAM.batt_model_filename, 1, j-1)
			filename = filename.."_SetupAndRawData.csv"
			
			local outputfile = file.open("/usb1/"..filename, file.MODE_WRITE)
			file.write(outputfile, "TEST_PARAM.comment:,"..TEST_PARAM.comment.."\n")	-- Ivons added on 12/20/2017
			file.write(outputfile, "\n")												-- Ivons added on 12/20/2017
			file.write(outputfile, "SourceMeter Model:,"..localnode.model.."\n")
			file.write(outputfile, "SourceMeter S/N:,"..localnode.serialno.."\n")
			file.write(outputfile, "SourceMeter Firmware:,"..localnode.version.."\n")
			file.write(outputfile, "\n")
			file.write(outputfile, "TEST_PARAM.terminals:,"..TEST_PARAM.terminals.."\n")
			file.write(outputfile, "\n")
			file.write(outputfile, "TEST_PARAM.initial_voc:,"..TEST_PARAM.initial_voc.."\n")
			file.write(outputfile, "TEST_PARAM.vcutoff:,"..TEST_PARAM.vcutoff.."\n")
			file.write(outputfile, "\n")
			file.write(outputfile, "TEST_PARAM.discharge_type:,"..TEST_PARAM.discharge_type.."\n")
			if TEST_PARAM.discharge_current ~= nil then
				file.write(outputfile, "TEST_PARAM.discharge_current:,"..TEST_PARAM.discharge_current.."\n")
				file.write(outputfile, "TEST_PARAM.max_discharge_current:,"..TEST_PARAM.max_discharge_current.."\n")
			end --if
			if TEST_PARAM.discharge_curr_list ~= nil then
				file.write(outputfile, "TEST_PARAM.discharge_curr_list:,Index,Current (A),Duration (s)\n")
				for i = 1, table.getn(TEST_PARAM.discharge_curr_list) do
					file.write(outputfile, ","..i..","..TEST_PARAM.discharge_curr_list[i].current..","..TEST_PARAM.discharge_curr_list[i].duration.."\n")
				end --for
				file.write(outputfile, "TEST_PARAM.discharge_curr_list.average_curr:,,"..TEST_PARAM.discharge_curr_list.average_curr.."\n")
				file.write(outputfile, "TEST_PARAM.discharge_curr_list.duration:,,,"..TEST_PARAM.discharge_curr_list.duration.."\n")
				file.write(outputfile, "TEST_PARAM.discharge_curr_list.max_dur_index:,"..TEST_PARAM.discharge_curr_list.max_dur_index.."\n")
				file.write(outputfile, "TEST_PARAM.max_discharge_current:,,"..TEST_PARAM.max_discharge_current.."\n")
			end --if
			file.write(outputfile, "\n")
			file.write(outputfile, "TEST_PARAM.measure_interval:,"..TEST_PARAM.measure_interval.."\n")
			file.write(outputfile, "\n")
			file.write(outputfile, "TEST_PARAM.discharge_start_time:,"..TEST_PARAM.discharge_start_time.."\n")
			file.write(outputfile, "TEST_PARAM.discharge_stop_time:,"..TEST_PARAM.discharge_stop_time.."\n")
			file.write(outputfile, "\n")
			file.write(outputfile, "BATT_MODEL_RAW:,Index,Timestamp,Voc,Vload,ESR\n")
			for i = 1, table.getn(BATT_MODEL_RAW.tstamp) do
				file.write(outputfile, "BATT_MODEL_RAW:,"..i..","..BATT_MODEL_RAW.tstamp[i]..","..
						   BATT_MODEL_RAW.voc[i]..","..BATT_MODEL_RAW.vload[i]..","..BATT_MODEL_RAW.esr[i].."\n")
			end --for
			file.write(outputfile, "BATT_MODEL_RAW.capacity:,"..BATT_MODEL_RAW.capacity.."\n")
			file.write(outputfile, "\n")
			file.write(outputfile, "BATT_MODEL:,Index,Timestamp,Voc,Vload,ESR\n")
			for i = 1, table.getn(BATT_MODEL.tstamp) do
				file.write(outputfile, "BATT_MODEL:,"..i..","..BATT_MODEL.tstamp[i]..","..
						   BATT_MODEL.voc[i]..","..BATT_MODEL.vload[i]..","..BATT_MODEL.esr[i].."\n")
			end --for
			file.write(outputfile, "BATT_MODEL.capacity:,"..BATT_MODEL.capacity.."\n")
			
			file.close(outputfile)
		
		else -- Never found USB drive
	
			-- ###### Need to do something here, but not sure what just yet	
	
			return -1041, "No USB drive found; SaveSetupAndRawData aborted"
	
		end
		
	else	-- button_selection == display.BUTTON_NO
	
		return 0, "User did not save setup and raw data"	-- Not sure if should use zero here
	
	end --if
	
	display.clear()
	
	local error_count = eventlog.getcount(eventlog.SEV_ERROR)
	if error_count == 0 then
		return error_count, "No errors"
	else
		return error_count, "Instrument errors occurred in SaveSetupAndRawData"
	end --if

end --function SaveSetupAndRawData()

function RunTest(do_beeps, debug)
	
	local status_num, status_msg
	
	if debug then print("\nCall ConfigSystem()...") end
	
	status_num, status_msg = ConfigSystem(do_beeps, debug)
	
	if debug then print("status_num = "..tostring(status_num).."; status_msg = "..status_msg) end
	
	if status_num ~= 0 then
		return status_num, status_msg
	end --if
	
	if debug then print("\nCall ConfigTest()...") end
	
	status_num, status_msg = ConfigTest(do_beeps, debug)
	
	if debug then print("status_num = "..tostring(status_num).."; status_msg = "..status_msg) end
	
	if status_num ~= 0 then
		return status_num, status_msg
	end --if
	
	local dialog_text = "Select OK to START TEST, or Cancel to ABORT and EXIT."
	if do_beeps then beeper.beep(0.08, 2400) end
	local button_selection = display.input.prompt(display.BUTTONS_OKCANCEL, dialog_text)
	if button_selection == display.BUTTON_CANCEL then
		return -1050, "RunTest aborted by user"
	end --if
	
	-- Configure buffers; TBD if this would be better located elsewhere.
	defbuffer1.clear()
    defbuffer1.fillmode=buffer.FILL_ONCE
    defbuffer1.capacity = 1000000		-- Just how many points should we allow?  Have never aproached a million.
    defbuffer2.clear()
    defbuffer2.fillmode=buffer.FILL_ONCE
    defbuffer2.capacity = 1000000
	
	if TEST_PARAM.discharge_type == "CONSTANT" then
	
		if debug then print("\nCall DoConstantCurrDischarge()...") end
		
		status_num, status_msg = DoConstantCurrDischarge(debug)
	
	elseif TEST_PARAM.discharge_type == "LIST" then
	
		if debug then print("\nCall DoCurrListDischarge()...") end
		
		-- DoCurrListDischarge(settle_delay, debug); need to empirically determine an appropriate settling delay
		--   Start with 50us, which is the practical minimum you can use with the delay() function
		status_num, status_msg = DoCurrListDischarge(50e-6, debug)
		
	else
	
		return -1051, "Unexpected discharge_type detected; RunTest aborted"
		
	end --if
		
	if debug then print("status_num = "..tostring(status_num).."; status_msg = "..status_msg) end
	
	if status_num ~= 0 then
		return status_num, status_msg
	end --if
	
	if debug then print("\nCall ExtractModel()...") end
	
	status_num, status_msg = ExtractModel(debug)
	
	if debug then print("status_num = "..tostring(status_num).."; status_msg = "..status_msg) end
	
	if status_num ~= 0 then
		return status_num, status_msg
	end --if
	
	if debug then print("\nCall SaveModel()...") end
	
	status_num, status_msg = SaveModel(do_beeps, debug)
	
	if debug then print("status_num = "..tostring(status_num).."; status_msg = "..status_msg) end
	
	if status_num ~= 0 then
		return status_num, status_msg
	end --if
	
	if debug then print("\nCall SaveSetupAndRawData()...") end
	
	status_num, status_msg = SaveSetupAndRawData(do_beeps, debug)
	
	if debug then print("status_num = "..tostring(status_num).."; status_msg = "..status_msg) end
	
	if status_num ~= 0 then
		return status_num, status_msg
	end --if

	return 0, "No errors"

end --function RunTest()

-- Declare script level local variables
local status_num, status_msg
local dialog_text

local debug = false		-- Options are true or false; true only applies when running this script from Test Script Builder
local do_beeps = true	-- Options are true or false; true causes certain audible cues to be generated when user interaction is required

beeper.beep(0.08, 2400)	-- Ivons added on 02Aug2017

-- Ivons added the following 7 lines of code on 07/31/2017
dialog_text = "Follow all manufacturer's guidelines to ensure safe operation when discharging a battery (especially a LITHIUM ION battery)!"
local button_selection = display.input.prompt(display.BUTTONS_OKCANCEL, dialog_text)
if button_selection == display.BUTTON_CANCEL then
	dialog_text = "Test aborted by user.\nPress OK to finish."
	display.input.prompt(display.BUTTONS_OK, dialog_text)
	exit()
end --if

status_num, status_msg = RunTest(do_beeps, debug)

beeper.beep(0.08, 2400)	-- Ivons added on 02Aug2017

if status_num == 0 then
	dialog_text = "Test complete.\nPress OK to finish."
else
	smu.source.output = smu.OFF
	dialog_text = "Test aborted: "..status_num..", "..status_msg..". Press OK to finish."
end --if

display.input.prompt(display.BUTTONS_OK, dialog_text)

--[[	-- Eventually need to clean up variables, functions and possibly script

	-- Delete global variables
	TEST_PARAM = nil
	BATT_MODEL_RAW = nil
	BATT_MODEL = nil
	
	-- Delete functions...
	
	collectgarbage()
--]]
