--[[Last Updated: $Date: 2020/03/06 $ $Change: 189427 $ 
	
	Copyright © Keithley Instruments, LLC.  All rights reserved.

	Part of the Keithley Instruments Potentiostat System.
	Users are permitted to modify but not distribute the software without prior written permission from Keithley.
	
	THIS SOFTWARE IS PROVIDED “AS-IS,” WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES OF ANY KIND, INCLUDING 
	BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
	NON-INFRINGEMENT OF INTELLECTUAL PROPERTY. IN NO EVENT SHALL KEITHLEY INSTRUMENTS, ITS AFFILIATES, 
	OFFICERS, EMPLOYEES, DIRECTORS, AGENTS, SUPPLIERS, OR OTHER THIRD PARTIES BE LIABLE FOR ANY DIRECT, 
	INDIRECT, INCIDENTAL, PUNITIVE, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT 
	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
	
	This program produces a current pulse or set of current pulses using user input parameters.

	Using this test script requires the Model 2450, 2460, or 2461 to have firmware 1.5.0 or greater.  
	The latest firmware can be found on the Keithley website, tek.com/keithley.

	]]

--[General variables]--
changelist = "$Change: 189427 $"
local MIN_EC_FRAMEWORK_VERSION = "1.5"
local modelNumber  = localnode.model
local lineperiod = 1/localnode.linefreq
stats = {} --stores quick statistics after test is finished
local eventNums = {2203, 5076, 5077, 1707,5084}
SAVED_SETUP_BASE_FILENAME = "KI_"..localnode.model.."-EC_CPSW_Setup"
SCRIPT_TITLE = "Current Pulse and Square Wave"
X_UNIT = "s"
Y_UNIT = "V"

--[User variables]--

--These 4 tables of variables contain all the user-defined parameters for the pulse wave program.
local current = {}
local VRange = {}
 timing = {}
--[[local]] ec = {} --End Conditions

--define the minimum, default, and maximum parameters specific to the 2450
if modelNumber == "2450" then
	current.peak = {min = -1.05,            val = 0.01, max = 1.05}             --A
	current.base = {min = current.peak.min, val = 0,    max = current.peak.max} --A
	VRange.choices = {0.02, 0.2, 2, 20}                                         --V
	VRange.select = 3
	timing.lowcurrent =  {period = {min = 0.2}, pulsewidth = {min = 0.1}}       --s
	timing.cutoffcurrent = 1.05e-6                                              --A
	timing.highcurrent = {period = {min = 0.004}, pulsewidth = {min = 0.002}}   --s
	timing.period =     {min = timing.highcurrent.period.min,       val = 0.02,      max = 3600} --s
	timing.pulsewidth = {min = timing.highcurrent.pulsewidth.min,   val = timing.period.val / 2, max = 0.99 * timing.period.val} --s
	timing.sampletime = {min = 0.01 * lineperiod, val = 0.01 * lineperiod, 	max = timing.pulsewidth.val - 0.001}      --s
--define the minimum, default, and maximum parameters specific to the 2460
elseif modelNumber == "2460" or modelNumber == "2461" then
	current.peak = {min = -7.35,            val = 0.01, max = 7.35}             --A
	current.base = {min = current.peak.min, val = 0,    max = current.peak.max} --A
	VRange.choices = {0.2, 2, 7, 10, 20}                                        --V
	VRange.select = 2
	timing.lowcurrent =  {period = {min = 0.08},  pulsewidth = {min = 0.04}}    --s
	timing.cutoffcurrent = 105e-6                                               --A
	timing.highcurrent = {period = {min = 0.01}, pulsewidth = {min = 0.005}}    --s
	timing.period =     {min = timing.highcurrent.period.min,       val = 0.02,      max = 3600} --s
	timing.pulsewidth = {min = timing.highcurrent.pulsewidth.min,   val = timing.period.val / 2, max = 0.99 * timing.period.val} --s
	timing.sampletime = {min = 0.01 * lineperiod, val = 0.01 * lineperiod, 	max = timing.pulsewidth.val - 0.001}      --s
end

timing.graceperiod = 100e-6 --this variable determines the predetermined time between the end of the sampling and the end of the pulse to allow the measurement to settle.

--The following variables are defined the same way for all instruments
VRange.fchoices = {}
VRange.limit = {}

ec.numcycles =  {min = 1,                   val = 1,    max = 100000,
				enabled = true,     actual = 0}
ec.exectime =   {min = timing.period.val,   val = ec.numcycles.val * timing.period.val,   max = timing.period.val * ec.numcycles.max,
				 enabled = false,    actual = 0} --s
ec.sourcelimit = {enabled = false}
ec.cause = "Error"

---------------------------------------------------------------------------------------------------------------------------------
--All these functions are related to the USB drive and saving data to that drive

--Save data points with their relative timestamps from the buffer to a file that the user names
function saveData()
	local stringData = { }
	
	--Variable that will hold the string data
	--these three tables contain the three things that will be written to the cells in the for loop below
	local textCells
	local valueCells
	local unitsCells
	--Calls the function getCycles to determine the cause of termination and number of cycles
	getCyclesAndTermination()
	
	textCells = 	{	"Waveform Parameters", 	"Peak Intensity", 	"Base Intensity", 	"Period", 			"Pulse Width", 			"Sampling Time",			"# of Cycles",			"Duration of Experiment", 	"Cause of termination: "..ec.cause,		"", 	"Other Parameters", 	"Range", 						""}
	valueCells = 	{	"n/a", 					data.pulse_peak,	data.pulse_base,	data.pulse_period,	data.pulse_width, 		data.sample_time,			ec.numcycles.actual,	ec.exectime.actual,			"n/a",									"n/a", 	"n/a",					V_RANGES.range[data.v_range],	"n/a"}
	unitsCells = 	{	"n/a", 					"A", 				"A",				"s", 				"s", 					"s",						"n/a", 					"s",						"n/a",									"n/a", 	"n/a", 					"V", 							"n/a"}
	for i = 1, 23 do
		if valueCells[i] ~= nil then
			if valueCells[i] ~= "n/a" and unitsCells[i] ~= "n/a" then
				table.insert(stringData, string.format("%s, %g, %s", textCells[i], valueCells[i], unitsCells[i]))
			else
				if valueCells[i] ~= "n/a" then
					table.insert(stringData, string.format("%s, %g", textCells[i], valueCells[i]))
				else
					if unitsCells[i] ~= "n/a" then
						table.insert(stringData, string.format("%s, %s", textCells[i], unitsCells[i]))
					else
						table.insert(stringData, string.format("%s", textCells[i]))
					end
				end
			end
		end
	end
	
	--Add the quick statistics to the file
	table.insert(stringData, "\nQuick Stats")
	table.insert(stringData, stats.numPts..",points recorded,,"..stats.avg..",V average")
	table.insert(stringData, stats.min..",V minimum,,"..stats.stdev..",V standard deviation")
	table.insert(stringData, stats.median..",V median,,"..stats.time..",seconds to run experiment")
	table.insert(stringData, stats.max..",V maximum")
	
	table.insert(stringData, "\nRaw Data")
	table.insert(stringData, "Wave #, Potential")

	for i=1, defbuffer1.n do
		--Here the instrument reads the potential and then adds it to the existing stringData string, along with the timestamp
		table.insert(stringData, string.format("%s, %g, V", i, defbuffer1.readings[i]))
	end
	
	save_data_to_usb_with_prompt(stringData)
end

---------------------------------------------------------------------------------------------------------------------------------
--Misc. function, used for finding the cause of termination and the actual number of cycles executed
function getCyclesAndTermination()
	if ec.sourcelimit.actual then
		ec.cause = "Hit source limit"
		ec.numcycles.actual = ec.exectime.actual / data.pulse_period
	elseif data.num_cycles_enabled == get_index_from_value_enum(ONOFF_TYPE, "On") then
		ec.cause = "Completed specified number of cycles"
		ec.numcycles.actual = data.num_cycles_value
	elseif data.prog_time_enabled == get_index_from_value_enum(ONOFF_TYPE, "On") then
		ec.cause = "Specified time reached"
		ec.numcycles.actual = data.prog_time_value / data.pulse_period
	end
end
--------------------------------------------------------------------------------------------------------------------------
--This function sets the basic source and measure settings. These will be applied regardless of any user settings.
function basicSettings()
	--The instrument is set to measure potential and source current
	smu.source.func = smu.FUNC_DC_CURRENT
	smu.measure.func = smu.FUNC_DC_VOLTAGE
	smu.source.offmode = smu.OFFMODE_HIGHZ
	smu.measure.sense = smu.SENSE_4WIRE
		
	--Set initial settings
	smu.measure.range = 2
	
	--Settings for the SourceMeter
	smu.source.readback = smu.OFF
	smu.source.delay = 0
	smu.measure.nplc = 0.01
	smu.measure.autozero.once()
end

----------------------------------------------------------------------------------------------------------------------------------
--Execution function: this function uses the previously input data to run the current pulse program
function runIPulse()
	if not verify_power_limits(data.pulse_base, instr.FUNC_DC_CURRENT, V_RANGES.range[data.v_range]) then
		display.input.prompt(display.BUTTONS_OK, "Pulse bias exceeds power limits. Reduce pulse bias current to less than "..V_RANGES.i_limit[data.v_range].."\21A or reduce potential range.")
		test_cleanup()
		exit()
	elseif not verify_power_limits(data.pulse_peak, instr.FUNC_DC_CURRENT, V_RANGES.range[data.v_range]) then
		display.input.prompt(display.BUTTONS_OK, "Pulse peak exceeds power limits. Reduce pulse peak current to less than "..V_RANGES.i_limit[data.v_range].."\21A or reduce potential range.")
		test_cleanup()
		exit()
	end

	display.setstate(ui.home.start_stop, display.STATE_ENABLE)
	eventlog.clear()
	
	--Ensure that the settings are up-to-date.
	if math.abs(data.pulse_peak) >= math.abs(data.pulse_base) then
		smu.source.range = math.abs(data.pulse_peak)
	else
		smu.source.range = math.abs(data.pulse_base)
	end
	for i = 1,table.getn(eventNums) do eventlog.suppress(eventNums[i]) end
	smu.measure.range = V_RANGES.range[data.v_range]
	smu.source.vlimit.level = V_RANGES.range[data.v_range] * 1.05
	smu.measure.nplc = data.sample_time/lineperiod
	
	--[[numcycles is a value used to determine how many cycles should be used in the loop.
		Unlike data.num_cycles_value, it will be 100,000 if the Program Time end condition is enabled.]]
	local numcycles
	if data.prog_time_enabled == get_index_from_value_enum(ONOFF_TYPE, "On") then numcycles = 1e5 else numcycles = data.num_cycles_value end
	
	--Initialize variables used to keep track of timing and end conditions
	local endCycleTime = 0
	ec.exectime.actual = 0
	ec.sourcelimit.actual = false --true or false depending on whether compliance (hitting the source limit) caused the execution loop to break
	timing.beginmeasure = data.pulse_width - data.sample_time - timing.graceperiod --determines at what time in the pulse the measurement should begin
	
	--turn the source on (starting at 0) and start the timer
	defbuffer1.clear()
	defbuffer1.capacity = 100000
	display.graph.removeall(ui.home.graph)
	display.graph.add(ui.home.graph, defbuffer1, display.ELEMENT_DATA, defbuffer1, display.ELEMENT_TIME)
	display.graph.drawstyle(ui.home.graph, display.STYLE_BOTH)
	display.graph.scalex(ui.home.graph, display.XSCALE_ALL)
	display.graph.scaley(ui.home.graph, display.YSCALE_ALL)
	
	display.waitevent(0.001)	--Consume any previous events
	smu.source.level = 0
	smu.source.output = smu.ON
	timer.cleartime()
	
	--[Experiment]--
	--[[(Step 1) The peak current value will be sourced until timing.beginmeasure, then (Step 2) make a measurement. Then, (Step 3) 
		end conditions will be checked (if enabled) to determine whether to break out of the program. At the end of the pulse width,
		(Step 4) the base current value will then be sourced. (Step 5) The timing end condition will be checked again.
		At the end of the period, the cycle will repeat.]]
	for i = 1, numcycles do
		--Step 1: source peak current value
		smu.source.level = data.pulse_peak
		
		repeat until timer.gettime() - endCycleTime >= timing.beginmeasure
		--Step 2: take measurement
		smu.measure.read(defbuffer1)
		if display.waitevent(0.001) == ui.home.start_stop then
			test_cleanup()
			return 
		end
		
		--Step 3: check timing and source limit end conditions
		if data.prog_time_enabled == get_index_from_value_enum(ONOFF_TYPE, "On") and timer.gettime() > data.prog_time_value then break end
		if data.src_limit_enabled == get_index_from_value_enum(ONOFF_TYPE, "On") and (defbuffer1.readings[i] >= V_RANGES.range[data.v_range] or defbuffer1.readings[i] <= -V_RANGES.range[data.v_range]) then
			ec.sourcelimit.actual = true
			break
		end
		
		repeat until timer.gettime() - endCycleTime >= data.pulse_width
		--Step 4: source base current value
		smu.source.level = data.pulse_base
		
		--Step 5: check timing end condition again
		if data.prog_time_enabled == get_index_from_value_enum(ONOFF_TYPE, "On") and timer.gettime() > data.prog_time_value then break end
		repeat until timer.gettime() - endCycleTime >= data.pulse_period
		
		endCycleTime = timer.gettime()
		update_progress_bar(i / numcycles * 100)
	end
	smu.source.output = smu.OFF
	--varible later used to determine cause of termination, number of cycles, and experiment duration
	ec.exectime.actual = timer.gettime()
	if ec.sourcelimit.actual then
		display.input.prompt(display.BUTTONS_OK, "Experiment terminated because source limit was reached.")
	end
	
	calculateStats()
	update_stats(stats_table, stats)
end
-----------------------------------------------------------------------------------------------------------------
--The following functions are related to statistics of the results

--This function calculates the number of points, the minimum potential, the maximum potential, the median potential, the average potential, and the standard deviation of the potential
function calculateStats()
	local prompt
	if defbuffer1.n >= 10000 then prompt = display.prompt(display.BUTTONS_NONE, "Calculating Statistics...") end
	bufferCopy = {}
	local bufStats = buffer.getstats(defbuffer1)
	if bufStats.n > 0 then
	
		--copy the buffer
		for i=1, defbuffer1.n do
			bufferCopy[i] = defbuffer1.readings[i]
		end
		
		--number of data points
		stats.numPts = defbuffer1.n
		
		--find average
		stats.avg = bufStats.mean
		
		--find standard deviation
		stats.stdev = bufStats.stddev or 0
		
		table.sort(bufferCopy)
		--find minimum
		stats.min = bufStats.min.reading
		--find maximum
		stats.max = bufStats.max.reading
		--find median
		if math.mod(table.getn(bufferCopy), 2) == 1 then
			stats.median = bufferCopy[math.ceil(table.getn(bufferCopy)/2)]
		elseif table.getn(bufferCopy) > 0 then
			stats.median = (bufferCopy[table.getn(bufferCopy)/2] + bufferCopy[table.getn(bufferCopy)/2 + 1])/2
		else
			stats.median = 0
		end
		
		stats.time = ec.exectime.actual
		
		if prompt ~= nil then display.delete(prompt) end
	else
		stats = { }
	end
end

function end_conditions_event_handler(eventID, value, no_validate)
	sync_ui_to_data(ui_data_event_table, eventID)
	
	if eventID == ui.end_conditions.prog_time_enabled then
		if value == get_index_from_value_enum(ONOFF_TYPE, "On") and 
				display.getvalue(ui.end_conditions.num_cycles_enabled) ~= get_index_from_value_enum(ONOFF_TYPE, "Off") and 
				not no_validate then
			display.setvalue(ui.end_conditions.num_cycles_enabled, get_index_from_value_enum(ONOFF_TYPE, "Off"))
			end_conditions_event_handler(ui.end_conditions.num_cycles_enabled, get_index_from_value_enum(ONOFF_TYPE, "Off"))
			
		elseif display.getvalue(ui.end_conditions.num_cycles_enabled) ~= get_index_from_value_enum(ONOFF_TYPE, "On") and 
				not no_validate then
			display.setvalue(ui.end_conditions.num_cycles_enabled, get_index_from_value_enum(ONOFF_TYPE, "On"))
			end_conditions_event_handler(ui.end_conditions.num_cycles_enabled, get_index_from_value_enum(ONOFF_TYPE, "On"))
			
		end
	elseif eventID == ui.end_conditions.num_cycles_enabled then
		if value == get_index_from_value_enum(ONOFF_TYPE, "On") and 
				display.getvalue(ui.end_conditions.prog_time_enabled) ~= get_index_from_value_enum(ONOFF_TYPE, "Off") and 
				not no_validate then
			display.setvalue(ui.end_conditions.prog_time_enabled, get_index_from_value_enum(ONOFF_TYPE, "Off"))
			end_conditions_event_handler(ui.end_conditions.prog_time_enabled, get_index_from_value_enum(ONOFF_TYPE, "Off"))
		elseif display.getvalue(ui.end_conditions.prog_time_enabled) ~= get_index_from_value_enum(ONOFF_TYPE, "On") and 
				not no_validate then 
			display.setvalue(ui.end_conditions.prog_time_enabled, get_index_from_value_enum(ONOFF_TYPE, "On"))
			end_conditions_event_handler(ui.end_conditions.prog_time_enabled, get_index_from_value_enum(ONOFF_TYPE, "On"))
		end
	end
end

function pulse_event_handler(eventID, value, no_validate)
	sync_ui_to_data(ui_data_event_table, eventID)
	
	if eventID == ui.pulse.pulse_period then
		timing.pulsewidth.max = 0.99 * value
		update_min_max(ui.pulse.pulse_width, display.NFORMAT_USER, timing.pulsewidth.min, timing.pulsewidth.max)
		
		if data.pulse_width > timing.pulsewidth.max and not no_validate then
			display.input.prompt(display.BUTTONS_OK, "Pulse Width has been changed to accommodate the maximum Pulse Period.")
			display.setvalue(ui.pulse.pulse_width, timing.pulsewidth.max)
			pulse_event_handler(ui.pulse.pulse_width, timing.pulsewidth.max)
		elseif data.pulse_width < timing.pulsewidth.min and not no_validate then
			display.input.prompt(display.BUTTONS_OK, "Pulse Width has been changed to accommodate the minimum Pulse Period.")
			display.setvalue(ui.pulse.pulse_width, timing.pulsewidth.min)
			pulse_event_handler(ui.pulse.pulse_width, timing.pulsewidth.min)
		end
		
		ec.exectime.min = value
		ec.exectime.max = ec.numcycles.max * value
		update_min_max(ui.end_conditions.prog_time_value, display.NFORMAT_USER, ec.exectime.min, ec.exectime.max)
		if display.getvalue(ui.end_conditions.prog_time_value) < ec.exectime.min and not no_validate then
			display.setvalue(ui.end_conditions.prog_time_value, ec.exectime.min)
			pulse_event_handler(ui.end_conditions.prog_time_value, ec.exectime.min)
			if display.getvalue(ui.end_conditions.prog_time_enabled) == get_index_from_value_enum(ONOFF_TYPE, "On") then
				display.input.prompt(display.BUTTONS_OK, "Program Time has been changed to accommodate the Pulse Period.")
			end
		elseif display.getvalue(ui.end_conditions.prog_time_value) > ec.exectime.max and not no_validate then
			display.setvalue(ui.end_conditions.prog_time_value, ec.exectime.max)
			pulse_event_handler(ui.end_conditions.prog_time_value, ec.exectime.max)
			if display.getvalue(ui.end_conditions.prog_time_enabled) == get_index_from_value_enum(ONOFF_TYPE, "On") then
				display.input.prompt(display.BUTTONS_OK, "Program Time has been changed to accommodate the Pulse Period.")
			end
		end
		
	elseif eventID == ui.pulse.pulse_width then
		timing.sampletime.max = math.min(value - 0.001, lineperiod * 10)
		update_min_max(ui.pulse.sample_time, display.NFORMAT_USER, timing.sampletime.min, timing.sampletime.max)
		
		if display.getvalue(ui.pulse.sample_time) > timing.sampletime.max and not no_validate then
			display.input.prompt(display.BUTTONS_OK, "Sample Time has been changed to accommodate the maximum Pulse Width")
			display.setvalue(ui.pulse.sample_time, timing.sampletime.max)
			pulse_event_handler(ui.pulse.sample_time, timing.sampletime.max)
		elseif display.getvalue(ui.pulse.sample_time) < timing.sampletime.min and not no_validate then
			display.input.prompt(display.BUTTONS_OK, "Sample Time has been changed to accommodate the minimum Pulse Width")
			display.setvalue(ui.pulse.sample_time, timing.sampletime.min)
			pulse_event_handler(ui.pulse.sample_time, timing.sampletime.min)
		end
		
	elseif eventID == ui.pulse.sample_time then
		--Do nothing
		
	elseif eventID == ui.pulse.pulse_peak or eventID == ui.pulse.pulse_base then
		adjust_pulse_timing()

	end
end

function adjust_pulse_timing()
	if math.max(math.abs(display.getvalue(ui.pulse.pulse_peak)), math.abs(display.getvalue(ui.pulse.pulse_base))) <= timing.cutoffcurrent then --make the proper timing adjustments
		timing.period.min = timing.lowcurrent.period.min
		update_min_max(ui.pulse.pulse_period, display.NFORMAT_USER, timing.period.min, timing.period.max)
		timing.pulsewidth.min = timing.lowcurrent.pulsewidth.min
		update_min_max(ui.pulse.pulse_width, display.NFORMAT_USER, timing.pulsewidth.min, timing.pulsewidth.max)
		
		if display.getvalue(ui.pulse.pulse_period) < timing.period.min then
			display.input.prompt(display.BUTTONS_OK, "Period has been changed due to low curent range.")
			display.setvalue(ui.pulse.pulse_period, timing.period.min)
			pulse_event_handler(ui.pulse.pulse_period, timing.period.min)
		end

	else
		--If a limited current range is not selected, return to the default period and pulse width limits
		timing.period.min = timing.highcurrent.period.min
		update_min_max(ui.pulse.pulse_period, display.NFORMAT_USER, timing.period.min, timing.period.max)
		timing.pulsewidth.min = timing.highcurrent.pulsewidth.min
		update_min_max(ui.pulse.pulse_width, display.NFORMAT_USER, timing.pulsewidth.min, timing.pulsewidth.max)
	end
end

function start_stop_event_handler(eventID)
	test_start()
	basicSettings()
	runIPulse()
	test_cleanup()
end

local function create_screens()
	ui.pulse = { }
	ui.pulse.root = display.create(display.ROOT, display.OBJ_SCREEN, "Pulse Settings")
	ui.end_conditions = { }
	ui.end_conditions.root = display.create(display.ROOT, display.OBJ_SCREEN, "End Conditions")
	
end

local function create_controls()
	--Setup ui.home controls
	display.settext(ui.home.version, "Version "..get_version_number(changelist))
	display.settext(ui.home.root, SCRIPT_TITLE)
	display.setevent(ui.home.start_stop, display.EVENT_PRESS, "start_stop_event_handler(%id)")
	hide_home_stats()	--We're not using stats here, so hide them
	display.setevent(ui.home.save, display.EVENT_PRESS, "saveData()")

	--Create ui.menu controls
	local offset = 0 -- button offset
	if display.EVENT_ENDAPP then offset = 1 end
	--ui.menu.root = display.create(display.ROOT, display.OBJ_SCREEN_MENU, "Settings", "Views", "Save/Load", "System")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 0 + offset, 0 + offset, ui.pulse.root, "Pulse Settings", "pulse_settings")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 0 + offset, 1 + offset, ui.end_conditions.root, "End Conditions", "PSW_end_conditions")
	
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 1 + offset, 0 + offset, ui.home.root, "Run/Graph", "graph")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 1 + offset, 1 + offset, display.SCREEN_READING_TABLE, "Reading Table")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 1 + offset, 2 + offset, ui.stats.root, "Statistics", "stats")
	
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 2 + offset, 0 + offset, ui.save.root, "Save Settings", "save")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 2 + offset, 1 + offset, ui.load.root, "Load Settings", "load")
	
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 3 + offset, 0 + offset, display.SCREEN_SYS_EVENT_LOG, "Event Log")
	
	--Create ui.end_conditions controls
	ui.end_conditions.num_cycles_text = display.create(ui.end_conditions.root, display.OBJ_TEXT, 10, 40, "Number of Cycles", CID.LIGHT_CYAN, display.FONT_LARGE, display.JUST_LEFT)
	ui.end_conditions.num_cycles_line = display.create(ui.end_conditions.root, display.OBJ_LINE, 270, 30, 789, 30)
	display.setcolor(ui.end_conditions.num_cycles_line, CID.DARK_GREY)
	
	ui.end_conditions.num_cycles_enabled = create_edit_option(ui.end_conditions.root, 200, 50, "Enabled", "Off or On", ONOFF_TYPE)
	display.setevent(ui.end_conditions.num_cycles_enabled, display.EVENT_PRESS, "end_conditions_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.end_conditions.num_cycles_enabled", data = "data.num_cycles_enabled", event = "end_conditions_event_handler"})
	
	ui.end_conditions.num_cycles_value = display.create(ui.end_conditions.root, display.OBJ_EDIT_NUMBER, 600, 50, "Value", ec.numcycles.min.." to "..ec.numcycles.max, display.NFORMAT_INTEGER, ec.numcycles.val, ec.numcycles.min, ec.numcycles.max)
	display.setevent(ui.end_conditions.num_cycles_value, display.EVENT_PRESS, "end_conditions_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.end_conditions.num_cycles_value", data = "data.num_cycles_value", event = "end_conditions_event_handler"})
	
	ui.end_conditions.prog_time_text = display.create(ui.end_conditions.root, display.OBJ_TEXT, 10, (option_height + 15) * 1 + 40, "Program Time", CID.LIGHT_CYAN, display.FONT_LARGE, display.JUST_LEFT)
	ui.end_conditions.prog_time_line = display.create(ui.end_conditions.root, display.OBJ_LINE, 220, (option_height + 15) * 1 + 30, 789, (option_height + 15) * 1 + 30)
	display.setcolor(ui.end_conditions.prog_time_line, CID.DARK_GREY)
	
	ui.end_conditions.prog_time_enabled = create_edit_option(ui.end_conditions.root, 200, (option_height + 15) * 1 + 50, "Enabled", "Off or On", ONOFF_TYPE)
	display.setevent(ui.end_conditions.prog_time_enabled, display.EVENT_PRESS, "end_conditions_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.end_conditions.prog_time_enabled", data = "data.prog_time_enabled", event = "end_conditions_event_handler"})
	
	ui.end_conditions.src_limit_text = display.create(ui.end_conditions.root, display.OBJ_TEXT, 10, (option_height + 15) * 2 + 40, "Source Limit", CID.LIGHT_CYAN, display.FONT_LARGE, display.JUST_LEFT)
	ui.end_conditions.src_limit_line = display.create(ui.end_conditions.root, display.OBJ_LINE, 200, (option_height + 15) * 2 + 30, 789, (option_height + 15) * 2 + 30)
	display.setcolor(ui.end_conditions.src_limit_line, CID.DARK_GREY)
	
	ui.end_conditions.src_limit_enabled = create_edit_option(ui.end_conditions.root, 200, (option_height + 15) * 2 + 50, "Enabled", "Off or On", ONOFF_TYPE)
	display.setevent(ui.end_conditions.src_limit_enabled, display.EVENT_PRESS, "end_conditions_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.end_conditions.src_limit_enabled", data = "data.src_limit_enabled", event = "end_conditions_event_handler"})

	--Create ui.pulse controls
	ui.pulse.potential_range = create_edit_option(ui.pulse.root, 200, option_height*0 + 20, "Potential Range", V_RANGES.value[1].."..."..V_RANGES.value[table.getn(V_RANGES.value)], V_RANGES)
	table.insert(ui_data_event_table, {ui = "ui.pulse.potential_range", data = "data.v_range", event = "pulse_event_handler"})
	display.setevent(ui.pulse.potential_range, display.EVENT_PRESS, "pulse_event_handler(%id, %value)")
	
	ui.pulse.pulse_period = display.create(ui.pulse.root, display.OBJ_EDIT_NUMBER, 600, option_height*0 + 20, "Pulse Period", display.format(timing.period.min, "s", display.NFORMAT_USER, 4).." to "..display.format(timing.period.max, "s", display.NFORMAT_USER, 4), display.NFORMAT_USER, timing.period.val, timing.period.min, timing.period.max, "s")
	table.insert(ui_data_event_table, {ui = "ui.pulse.pulse_period", data = "data.pulse_period", event = "pulse_event_handler"})
	display.setevent(ui.pulse.pulse_period, display.EVENT_PRESS, "pulse_event_handler(%id, %value)")
	
	ui.pulse.sample_time = display.create(ui.pulse.root, display.OBJ_EDIT_NUMBER, 600, option_height*1 + 20, "Sample Time", display.format(timing.sampletime.min, "s", display.NFORMAT_USER, 4).." to "..display.format(timing.sampletime.max, "s", display.NFORMAT_USER, 4), display.NFORMAT_USER, timing.sampletime.val, timing.sampletime.min, timing.sampletime.max, "s")
	display.setevent(ui.pulse.sample_time, display.EVENT_PRESS, "pulse_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.pulse.sample_time", data = "data.sample_time", event = "pulse_event_handler"})
	
	table.insert(ui_data_event_table, {ui = "ui.pulse.pulse_width", data = "data.pulse_width", event = "pulse_event_handler"})
	table.insert(ui_data_event_table, {ui = "ui.end_conditions.prog_time_value", data = "data.prog_time_value", event = "end_conditions_event_handler"})
	ui.pulse.pulse_width = display.create(ui.pulse.root, display.OBJ_EDIT_NUMBER, 200, option_height*1 + 20, "Pulse Width", display.format(timing.pulsewidth.min, "s", display.NFORMAT_USER, 4).." to "..display.format(timing.pulsewidth.max, "s", display.NFORMAT_USER, 4), display.NFORMAT_USER, timing.pulsewidth.val, timing.pulsewidth.min, timing.pulsewidth.max, "s")
	display.setevent(ui.pulse.pulse_width, display.EVENT_PRESS, "pulse_event_handler(%id, %value)")
	ui.end_conditions.prog_time_value = display.create(ui.end_conditions.root, display.OBJ_EDIT_NUMBER, 600, (option_height + 15) * 1 + 50, "Value", display.format(ec.exectime.min, "s", display.NFORMAT_USER, 4).." to "..display.format(ec.exectime.max, "s", display.NFORMAT_USER, 4), display.NFORMAT_USER, ec.exectime.val, ec.exectime.min, ec.exectime.max, "s")
	display.setevent(ui.end_conditions.prog_time_value, display.EVENT_PRESS, "end_conditions_event_handler(%id, %value)")
	
	ui.pulse.pulse_peak = display.create(ui.pulse.root, display.OBJ_EDIT_NUMBER, 200, option_height*2 + 20, "Peak Current", current.peak.min.."\21A to "..current.peak.max.."\21A", display.NFORMAT_USER, current.peak.val, current.peak.min, current.peak.max, "A")
	table.insert(ui_data_event_table, {ui = "ui.pulse.pulse_peak", data = "data.pulse_peak", event = "pulse_event_handler"})
	display.setevent(ui.pulse.pulse_peak, display.EVENT_PRESS, "pulse_event_handler(%id, %value)")
	
	ui.pulse.pulse_base = display.create(ui.pulse.root, display.OBJ_EDIT_NUMBER, 600, option_height*2 + 20, "Base Current", current.base.min.."\21A to "..current.base.max.."\21A", display.NFORMAT_USER, current.base.val, current.base.min, current.base.max, "A")
	table.insert(ui_data_event_table, {ui = "ui.pulse.pulse_base", data = "data.pulse_base", event = "pulse_event_handler"})
	display.setevent(ui.pulse.pulse_base, display.EVENT_PRESS, "pulse_event_handler(%id, %value)")
	
	--Create ui.stats controls
	tbl_settings = { }
	tbl_settings.screen_id = ui.stats.root
	tbl_settings.rows = {"-Time", "Points", "-Minimum", "Maximum", "Median", "Average", "Stddev-"}
	tbl_settings.cols = {"-", "-"}
	tbl_settings.table = {x = 200-14*2, y = 75}
	tbl_settings.cell = { width = 200 }
	tbl_settings.font = display.FONT_MEDIUM
	
	--Create ui.stats controls
	stats_table = tbl.make(tbl_settings)
	
	--Set defaults
	display.setvalue(ui.pulse.potential_range, get_index_from_range(V_RANGES, 2)) --Default to 2V range
	pulse_event_handler(ui.pulse.potential_range, get_index_from_range(V_RANGES, 2))	--Default to 2V range
	display.setvalue(ui.end_conditions.prog_time_enabled, get_index_from_value_enum(ONOFF_TYPE, "Off"))
	display.setvalue(ui.end_conditions.src_limit_enabled, get_index_from_value_enum(ONOFF_TYPE, "Off"))
	sync_ui_to_data(ui_data_event_table)
end

local function create_global_tables()
	--NOTE: Use find and replace when changing *.value strings to avoid breaking lookups

	if localnode.model == "2450" then
		I_RANGES = {
			value = {"1\21\20A", "10\21\20A", "100\21\20A", "1\21mA", "10\21mA", "100\21mA", "1\21A"},
			range = {1e-6, 10e-6, 100e-6, 1e-3, 10e-3, 100e-3, 1},
			v_limit = {210, 210, 210, 210, 210, 210, 21}
		}
		V_RANGES = {
			value = {"20\21mV", "200\21mV", "2\21V", "20\21V"},
			range = {20e-3, 200e-3, 2, 20},
			i_limit = {1.05, 1.05, 1.05, 1.05}
		}
	elseif localnode.model == "2460" or localnode.model == "2461" then
		I_RANGES = {
			value = {"1\21\20A", "10\21\20A", "100\21\20A", "1\21mA", "10\21mA", "100\21mA", "1\21A", "4\21A", "5\21A", "7\21A"},
			range = {1e-6, 10e-6, 100e-6, 1e-3, 10e-3, 100e-3, 1, 4, 5, 7},
			v_limit = {105, 105, 105, 105, 105, 105, 105, 21, 10.5, 7.35}
		}
		V_RANGES = {
			value = {"200\21mV", "2\21V", "7\21V", "10\21V", "20\21V"},
			range = {200e-3, 2, 7, 10, 20},
			i_limit = {7.35, 7.35, 7.35, 5.25, 4.2}
		}
	end
end

function main()
	if not EC_FRAMEWORK_VERSION then
		if EC_Framework then
			EC_Framework.run()
		elseif file.usbdriveexists() == 1 then
			EC_Framework = script.load("/usb1/EC_Framework.tsp")
			if EC_Framework then
				EC_Framework.run()
			end
		end
		
		if not EC_Framework then
			print("Unable to load EC_Framework.tsp!")
			display.input.prompt(display.BUTTONS_OK, "Unable to load EC_Framework.tsp!")
			exit()
		end
	end
	
	if EC_FRAMEWORK_VERSION < MIN_EC_FRAMEWORK_VERSION then
		print("EC_Framework version "..MIN_EC_FRAMEWORK_VERSION.." or greater required, please update.")
		display.input.prompt(display.BUTTONS_OK, "EC_Framework version "..MIN_EC_FRAMEWORK_VERSION.." or greater required, please update.")
		exit()
	end
	
	reset()
	for i = 1,table.getn(eventNums) do eventlog.suppress(eventNums[i]) end
	basicSettings()
	
	stats_table = { }
	init_toplevel()
	data.potential = { }
	data.duration = { }
	create_global_tables()
	
	create_top_screens()
	create_screens()
	create_loading_screen()
	
	create_top_controls()
	create_controls()
	
	destroy_loading_screen()
end

main()