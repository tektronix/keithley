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
	
	This function steps user-determined potential values for a user-determined length of time, measuring the
	current at a measurement interval specified by the user.

	Using this test script requires the Model 2450, 2460, or 2461 to have firmware 1.5.0 or greater.  
	The latest firmware can be found on the Keithley website, tek.com/keithley.

	]]
	
--[General variables]--
changelist = "$Change: 189427 $"
local MIN_EC_FRAMEWORK_VERSION = "1.5"
local lineperiod = 1/localnode.linefreq
stats = {numPts = {}, sum = {}, avg = {}, stdevSum = {}, stdev = {}, min = {}, max = {}, median = {}, time = {}}--Declare variables that must be called in many functions throughout the program
local eventNums = {1707, 2203, 5074, 5076, 5077, 5079, 5084}
SAVED_SETUP_BASE_FILENAME = "KI_"..localnode.model.."-EC_CA_Setup"
SCRIPT_TITLE = "Chronoamperometry"
X_UNIT = "s"
Y_UNIT = "A"

local step = {endreadingnum = {}}
local run = {totaltime = 0, timeafterstep = {}} --s


--[User variables]--


step.potential =    {min = -20, max = 20}    --V
step.duration =     {min = 0.01, max = 99999, val = 5} --s

timing = {}
timing.mindiff = 5e-3 --minimum difference between the measurement interval or step duration and the sample time
timing.measinterval =  {min = 0.01,  val = 1,   max = 100}   --s
timing.sampletime = {min = 0.01 * lineperiod, val = 0.01 * lineperiod, max = math.min(math.min(timing.measinterval.val - timing.mindiff, 10 * lineperiod), step.duration.val)}      --s
timing.graceperiod = 100e-6 --this variable determines the predetermined time between the end of the sampling and the end of the pulse to allow the measurement to settle.

---------------------------------------------------------------------------------------------------------------------------------
--All these functions are related to the USB drive and saving data to that drive

--Save data points with their relative timestamps from the buffer to a file that the user names
function saveData()
	local stringData = { }
	
	table.insert(stringData, "Sample Interval:,"..data.meas_interval..",s")
	table.insert(stringData, "Current Range:,"..I_RANGES.range[data.i_range])
	--Add the settings for each step to the file
	for j = 1, data.num_steps do
		table.insert(stringData, "\nStep #"..j.." Settings")
		table.insert(stringData, "Potential,"..tostring(data.potential[j])..",V")
		table.insert(stringData, "Duration,"..tostring(data.duration[j])..",s")
	end
	--Add the quick statistics for each step to the file
	for j = 1, data.num_steps do
		table.insert(stringData, "\nStep #"..j.." Quick Stats")
		table.insert(stringData, stats.numPts[j]..",points recorded,,"..stats.avg[j]..",A average")
		table.insert(stringData, stats.min[j]..",A minimum,,"..stats.stdev[j]..",A standard deviation")
		table.insert(stringData, stats.median[j]..",A median,,"..stats.time[j]..",s to run experiment")
		table.insert(stringData, stats.max[j]..",A maximum")
	end

	table.insert(stringData, "\nRaw Data")
	--Add the results for each step to the file
	for j = 1, data.num_steps do
		table.insert(stringData, "\nStep #"..j)
		table.insert(stringData, "Data Pt, Times (s), Potential (V), Current (A)")
		if j == 1 then startNumber = 1 else startNumber = step.endreadingnum[j-1]+1 end
		for i = startNumber, step.endreadingnum[j] do
			--Here the instrument reads the voltage and then adds it to the existing stringData string, along with the timestamp
			table.insert(stringData, string.format("%s,%g,%g,%s", i, defbuffer1.relativetimestamps[i], defbuffer1.sourcevalues[i], defbuffer1.readings[i]))
		end
	end
	
	save_data_to_usb_with_prompt(stringData)
end

-------------------------------------------------------------------------------------------------------------------------------------
--This function sets the basic source and measure settings. These will be applied regardless of any user settings.
function basicSettings()
	smu.source.func = smu.FUNC_DC_VOLTAGE
	smu.measure.func = smu.FUNC_DC_CURRENT
	smu.source.offmode = smu.OFFMODE_HIGHZ
	smu.measure.sense = smu.SENSE_4WIRE
	
	smu.source.autorange = smu.OFF
	smu.source.readback = smu.OFF
	smu.source.autodelay = smu.OFF
	smu.source.delay = 0
	smu.measure.autozero.enable = smu.OFF
	smu.measure.nplc = 0.01
	smu.measure.autozero.once()
	smu.measure.autorange = smu.OFF
end

------------------------------------------------------------------------------------------------------------------------------------
--Functions involved with the execution of the program based on user inputs.

--This function sets the user-defined settings and sets the configuration lists for the user's inputted step settings
function prepareTest()
	for i = 1,table.getn(eventNums) do eventlog.suppress(eventNums[i]) end
	
	--ensure that the maximum step potential is set as the source range
	step.max = math.abs(data.potential[1])
	for i = 2, data.num_steps do
		if math.abs(data.potential[i]) > math.abs(data.potential[1]) then step.max = math.abs(data.potential[i]) end
	end
	
	if not verify_power_limits(step.max, instr.FUNC_DC_VOLTAGE, I_RANGES.range[data.i_range]) then
		display.input.prompt(display.BUTTONS_OK, "Step potential exceeds power limits. Reduce step potential to less than "..I_RANGES.v_limit[data.i_range].."\21V or reduce current range.")
		test_cleanup()
		exit()
	end
	smu.source.range = step.max
	smu.measure.range = I_RANGES.range[data.i_range]
	smu.source.ilimit.level = I_RANGES.range[data.i_range]
	
	--Configuration list is created using the user input parameters
	smu.source.configlist.create("TestLevels")
	
	--This source and measurement configuration lists will start will be listed backwards from the numbering of step settings
	for i = 0,data.num_steps-1 do
		smu.source.level = data.potential[data.num_steps - i]
		smu.source.configlist.store("TestLevels",i+1)
	end
	--NPLC is based on the user-defined sample time
	smu.measure.nplc = data.sampletime/lineperiod
end

--This function runs the experiment, using the configuration lists already declared.
function runTest()
	local numPoints = 0
	for i = 1, data.num_steps do
		numPoints = numPoints + data.duration[i] / data.meas_interval
	end
	if numPoints > 100e3 then
		display.input.prompt(display.BUTTONS_OK, "Settings have generated too many points. Increase measurement interval.")
		test_cleanup()
		exit()
	end
		
	display.setstate(ui.home.start_stop, display.STATE_ENABLE)
	for i = 1,table.getn(eventNums) do eventlog.suppress(eventNums[i]) end
	--declare local variables used for running the experiment
	run.timeafterstep[0] = 0
	run.totaltime = 0
	
	defbuffer1.clear()
	defbuffer1.capacity = 100000
	display.graph.removeall(ui.home.graph)
	display.graph.add(ui.home.graph, defbuffer1, display.ELEMENT_DATA, defbuffer1, display.ELEMENT_TIME)
	display.graph.drawstyle(ui.home.graph, display.STYLE_BOTH)
	display.graph.scalex(ui.home.graph, display.XSCALE_ALL)
	display.graph.scaley(ui.home.graph, display.YSCALE_ALL)
	
	--create a delay list array using the user's duration settings, and determine how long the program is expected to take.
	delayListSteps = {}
	table.setn(delayListSteps, data.num_steps)
	for i = 1, data.num_steps do
		delayListSteps[i] = data.duration[i]
		run.totaltime = run.totaltime + data.duration[i]
	end
	totalTimeString = tostring(math.floor(run.totaltime))
	
	--turn the source on and start the timer
	timer.cleartime()
	smu.source.output = smu.ON
	y = timer.gettime()
	
	--[Experiment]--
	--[[There are 2 variables of importance here: x and y. y is the time recorded as soon as possible after
		switching steps, and x is the time that has elapsed since y. This ensures that the measurement interval is
		constant after the first measurement is ABLE to be made, while the total time that has elapsed since the
		instrument started switching to the present step, x + y, is used to determine when to start switching to the next
		step.]]
	local elasped_duration = 0
	local total_duration = 0
	for i = 1, data.num_steps do
		total_duration = total_duration + data.duration[i]
	end
	display.waitevent(0.001)	--Consume any previous events
	for i = 1, data.num_steps do
		step.endreadingnum[i] = 0
		nextReading = timer.gettime() + data.meas_interval + 4e-5 - y
		smu.measure.read(defbuffer1) --Reading at the beginning of every step
		while true do
			x = timer.gettime() - y
			if x + y > data.duration[i] and i > 1 or x > data.duration[i] and i == 1 then break end --Break out of the while loop if it's time to move to the next step
			if x > nextReading then --If it's time to make the next measurement, do so.
				--The measurement will not be made if it would cause the step to last longer than it's defined duration.
				if data.duration[i] - timer.gettime() - y > data.sampletime + timing.graceperiod then
					nextReading = timer.gettime() - y + data.meas_interval + 4e-5
					update_progress_bar((elasped_duration + x)/(total_duration) * 100)
					if display.waitevent(0.001) == ui.home.start_stop then
						test_cleanup()
						return 
					end
					smu.measure.read(defbuffer1)
				end
			end
		end
		step.endreadingnum[i] = defbuffer1.n
		if i ~= data.num_steps then
			--[[If there are more steps to call, move to the PREVIOUS space in the configuration list
				(Remember: the configuration list was made to be indexed backwards compared to the step indices)]]
			run.timeafterstep[i] = run.timeafterstep[i-1] + timer.gettime()
			if i == 1 then
				run.timeafterstep[i] = run.timeafterstep[i] - y
			end
			timer.cleartime()
			smu.source.configlist.recall("TestLevels",data.num_steps-i)
			y = timer.gettime()
		else
			--If there are no more steps to call, stop the timers.
			run.timeafterstep[i] = run.timeafterstep[i-1] + timer.gettime()
			smu.source.output = smu.OFF
		end
		elasped_duration = elasped_duration + data.duration[i]
	end
	
	calculateStats()
	update_stats(stats_table, stats)
	test_cleanup()
end

-----------------------------------------------------------------------------------------------------------------
--The following functions are related to statistics of the results

--This function calculates the number of points, the minimum potential, the maximum potential, the median potential, the average potential, and the standard deviation of the potential
function calculateStats()
	local prompt
	if defbuffer1.n >= 10000 then prompt = display.prompt(display.BUTTONS_NONE, "Calculating Statistics...") end
	local bufferCopy = {}
	local startNumber
	
	for j = 1, data.num_steps do
		if j == 1 then startNumber = 1 else startNumber = step.endreadingnum[j-1]+1 end
		
		--number of data points
		stats.numPts[j] = step.endreadingnum[j] - startNumber + 1
		
		--find average
		stats.sum[j] = 0
		count = 1
		for i = startNumber, step.endreadingnum[j] do
			bufferCopy[i - startNumber + 1] = defbuffer1.readings[i] --copy defbuffer1.readings to a table that can be manipulated
			stats.sum[j] = stats.sum[j] + defbuffer1.readings[i]
		end
		stats.avg[j] = stats.sum[j] / table.getn(bufferCopy)
		
		--find standard deviation
		stats.stdevSum[j] = 0
		for i = 1, table.getn(bufferCopy) do
			stats.stdevSum[j] = stats.stdevSum[j] + math.pow((bufferCopy[i] - stats.avg[j]), 2)
		end
		stats.stdev[j] = math.sqrt(stats.stdevSum[j]/table.getn(bufferCopy))
		
		table.sort(bufferCopy)
		--find minimum
		stats.min[j] = bufferCopy[1]
		--find maximum
		stats.max[j] = bufferCopy[table.getn(bufferCopy)]
		--find median
		if math.mod(table.getn(bufferCopy), 2) == 1 then
			stats.median[j] = bufferCopy[math.ceil(table.getn(bufferCopy)/2)]
		elseif table.getn(bufferCopy) > 0 then
			stats.median[j] = (bufferCopy[table.getn(bufferCopy)/2] + bufferCopy[table.getn(bufferCopy)/2 + 1])/2
		else
			stats.median[j] = 0
		end
		
		--display "0" if there are no points in this step (only for CC)
		if stats.min[j] == nil then
			stats.min[j] = 0
		end
		if stats.max[j] == nil then
			stats.max[j] = 0
		end
		
		--find time
		stats.time[j] = run.timeafterstep[j] - run.timeafterstep[j-1]
		
		bufferCopy = {}
	end
	
	if defbuffer1.n >= 10000 then display.delete(prompt) end
	
end
------------------------------------------------------
function measure_event_handler(eventID, value, no_validate)
	sync_ui_to_data(ui_data_event_table, eventID)
	
	if eventID == ui.measure.meas_interval then
		adjust_sampletime_max()
	end
end

function step_event_handler(eventID, value, init)
	if init or eventID == ui.step.num_steps then
		ui.stats.step_select_value = 1
		if ui.stats.step_select ~= nil then
			display.delete(ui.stats.step_select)
			ui.stats.step_select = nil 
		end
		if value ~= nil and value > 1 then
			ui.stats.step_select = display.create(ui.stats.root, display.OBJ_EDIT_SLIDER, 100, 50, 600, "Step Select", display.ORIENT_HORZ, 1, value, value, 1)
			display.setevent(ui.stats.step_select, display.EVENT_PRESS, "update_stats(stats_table, stats, %value)")
		end
		update_stats(stats_table, stats)
	
		for i=1,table.getn(ui.step.potential) do
			if i <= value then
				display.setstate(ui.step.potential[i], display.STATE_ENABLE)
				display.setstate(ui.step.duration[i], display.STATE_ENABLE)
			else
				display.setstate(ui.step.potential[i], display.STATE_INVISIBLE)
				display.setstate(ui.step.duration[i], display.STATE_INVISIBLE)
			end
		end
		adjust_sampletime_max()
		
	elseif eventID >= ui.step.duration[1] and eventID <= ui.step.duration[table.getn(ui.step.duration)] then
		adjust_sampletime_max()
	end
	
	sync_ui_to_data(ui_data_event_table, eventID)
end

function adjust_sampletime_max()
	timing.sampletime.max = math.min(display.getvalue(ui.measure.meas_interval) - timing.mindiff, lineperiod * 10)
	
	for i=1, display.getvalue(ui.step.num_steps) do
		timing.sampletime.max = math.min(timing.sampletime.max, display.getvalue(ui.step.duration[i]) - timing.mindiff)
	end
	
	update_min_max(ui.measure.sampletime, display.NFORMAT_USER, timing.sampletime.min, timing.sampletime.max)
	if display.getvalue(ui.measure.sampletime) > timing.sampletime.max and not no_validate then
		display.input.prompt(display.BUTTONS_OK, "Sample Time has been changed to accommodate the maximum Sample Interval and Step Duration")
		display.setvalue(ui.measure.sampletime, timing.sampletime.max)
		measure_event_handler(ui.measure.sampletime, timing.sampletime.max)
	end
end

function start_stop_event_handler(eventID)
	test_start()
	basicSettings()
	prepareTest()
	runTest()
end
------------------------------------------------------

local function create_screens()
	ui.measure = { }
	ui.measure.root = display.create(display.ROOT, display.OBJ_SCREEN, "Measure Settings")
	ui.step = { }
	ui.step.root = display.create(display.ROOT, display.OBJ_SCREEN, "Step Settings", option_height, option_height * (10) + 10)
	
end

local function create_controls()
	--Setup ui.home controls
	display.settext(ui.home.version, "version "..get_version_number(changelist))
	display.settext(ui.home.root, SCRIPT_TITLE)
	display.setevent(ui.home.start_stop, display.EVENT_PRESS, "start_stop_event_handler(%id)")
	hide_home_stats()	--We're not using stats here, so hide them
	display.setevent(ui.home.save, display.EVENT_PRESS, "saveData()")

	--Create ui.menu controls
	local offset = 0 -- button offset
	if display.EVENT_ENDAPP then offset = 1 end
	--ui.menu.root = display.create(display.ROOT, display.OBJ_SCREEN_MENU, "Settings", "Views", "Save/Load", "System")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 0 + offset, 0 + offset, ui.measure.root, "Measure Settings", "meas_settings")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 0 + offset, 1 + offset, ui.step.root, "Step Settings", "CH_step_settings")
	
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 1 + offset, 0 + offset, ui.home.root, "Run/Graph", "graph")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 1 + offset, 1 + offset, display.SCREEN_READING_TABLE, "Reading Table")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 1 + offset, 2 + offset, ui.stats.root, "Statistics", "stats")
	
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 2 + offset, 0 + offset, ui.save.root, "Save Settings", "save")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 2 + offset, 1 + offset, ui.load.root, "Load Settings", "load")
	
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 3 + offset, 0 + offset, display.SCREEN_SYS_EVENT_LOG, "Event Log")
	
	--Create ui.step controls
	ui.step.num_steps = display.create(ui.step.root, display.OBJ_EDIT_NUMBER, 200, 20, "Number of Steps", "1 to 10", display.NFORMAT_INTEGER, 1, 1, 10)
	display.setevent(ui.step.num_steps, display.EVENT_PRESS, "step_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.step.num_steps", data = "data.num_steps", event = "step_event_handler"})
	
	ui.step.divider = display.create(ui.step.root, display.OBJ_LINE, 10, option_height - 5, 789, option_height - 5)
	display.setcolor(ui.step.divider, CID.DARK_GREY)
	
	ui.step.potential = { }
	ui.step.duration = { }
	for i=1,10 do
		ui.step.potential[i] = display.create(ui.step.root, display.OBJ_EDIT_NUMBER, 200, option_height * i + 20, "Potential "..i, step.potential.min.."\21V to "..step.potential.max.."\21V", display.NFORMAT_USER, 0, step.potential.min, step.potential.max, "V")
		display.setstate(ui.step.potential[i], display.STATE_INVISIBLE)
		display.setevent(ui.step.potential[i], display.EVENT_PRESS, "step_event_handler(%id, %value)")
		table.insert(ui_data_event_table, {ui = "ui.step.potential["..i.."]", data = "data.potential["..i.."]", event = "step_event_handler"})
		
		ui.step.duration[i] = display.create(ui.step.root, display.OBJ_EDIT_NUMBER, 600, option_height * i + 20, "Duration "..i, step.duration.min.."\21s to "..step.duration.max.."\21s", display.NFORMAT_USER, step.duration.val, step.duration.min, step.duration.max, "s")
		display.setstate(ui.step.duration[i], display.STATE_INVISIBLE)
		display.setevent(ui.step.duration[i], display.EVENT_PRESS, "step_event_handler(%id, %value)")
		table.insert(ui_data_event_table, {ui = "ui.step.duration["..i.."]", data = "data.duration["..i.."]", event = "step_event_handler"})
	end
	
	--Create ui.measure controls
	data.sampletime = timing.sampletime.min
	
	ui.measure.current_range = create_edit_option(ui.measure.root, 200, option_height*0 + 20, "Current Range", I_RANGES.value[1].."..."..I_RANGES.value[table.getn(I_RANGES.value)], I_RANGES)
	table.insert(ui_data_event_table, {ui = "ui.measure.current_range", data = "data.i_range", event = "measure_event_handler"})
	display.setvalue(ui.measure.current_range, get_index_from_range(I_RANGES, 10e-3))	--Default to 10mA range
	measure_event_handler(ui.measure.current_range, get_index_from_range(I_RANGES, 10e-3))	--Default to 10mA range
	display.setevent(ui.measure.current_range, display.EVENT_PRESS, "measure_event_handler(%id, %value)")
	
	ui.measure.meas_interval = display.create(ui.measure.root, display.OBJ_EDIT_NUMBER, 600, option_height*0 + 20, "Sample Interval", timing.measinterval.min.."\21s to "..timing.measinterval.max.."\21s", display.NFORMAT_USER, timing.measinterval.val, timing.measinterval.min, timing.measinterval.max, "s")
	table.insert(ui_data_event_table, {ui = "ui.measure.meas_interval", data = "data.meas_interval", event = "measure_event_handler"})
	display.setevent(ui.measure.meas_interval, display.EVENT_PRESS, "measure_event_handler(%id, %value)")
	sync_ui_to_data(ui_data_event_table)
	
	ui.measure.sampletime = display.create(ui.measure.root, display.OBJ_EDIT_NUMBER, 200, option_height*1 + 20, "Sample Time", display.format(timing.sampletime.min, "s", display.NFORMAT_USER, 4).." to "..display.format(timing.sampletime.max, "s", display.NFORMAT_USER, 4), display.NFORMAT_USER, timing.sampletime.val, timing.sampletime.min, timing.sampletime.max, "s")
	display.setevent(ui.measure.sampletime, display.EVENT_PRESS, "measure_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.measure.sampletime", data = "data.sampletime", event = "measure_event_handler"})
	
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
	
	--Initialization
	step_event_handler(nil, 1, true)	--Cause the step screen to be initialized
	sync_ui_to_data(ui_data_event_table)
end

local function create_global_tables()
	--NOTE: Use find and replace when changing *.value strings to avoid breaking lookups


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