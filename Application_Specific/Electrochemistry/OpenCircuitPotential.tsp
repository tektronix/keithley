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
	
	This program measures the open circuit potential of a battery over time.
	
	All recordings must be 4-wire measurements.

	Using this test script requires the Model 2450, 2460, or 2461 to have firmware 1.5.0 or greater.  
	The latest firmware can be found on the Keithley website, tek.com/keithley.

	]]
	
--[General variables]--
changelist = "$Change: 189427 $"
local MIN_EC_FRAMEWORK_VERSION = "1.5"
stats = {}
local eventNums = {2203, 2728, 5076, 5084}
SAVED_SETUP_BASE_FILENAME = "KI_"..localnode.model.."-EC_OP_Setup"
SCRIPT_TITLE = "Open Circuit Potential"
X_UNIT = "s"
Y_UNIT = "V"

local measperiod = {min = 0.75, val = 1, max = 100} --s/pt
local numsamples = {min = 1,    val = 1, max = 100000}

---------------------------------------------------------------------------------------------------------------------------------
--All these functions are related to the USB drive and saving data to that drive

--Save data points with their relative timestamps from the buffer to a file that the user names
function saveData()
	local stringData = { }
		
	table.insert(stringData, "\nSampling Period,"..data.meas_interval..",s/pt")
	table.insert(stringData, "Potential Range,"..V_RANGES.range[data.v_range]..",V")
	table.insert(stringData, "\nQuick Stats")
	table.insert(stringData, stats.numPts..",points recorded,,"..stats.avg..",V average")
	table.insert(stringData, stats.min..",V minimum,,"..stats.stdev..",V standard deviation")
	table.insert(stringData, stats.median..",V median,,"..stats.time..",seconds to run experiment")
	table.insert(stringData, stats.max..",V maximum")
	table.insert(stringData, "\nRaw Data")
	table.insert(stringData, "Time(s),Current(A),Potential(V)")
	for i = 1, defbuffer1.n do
		table.insert(stringData, defbuffer1.relativetimestamps[i]..","..defbuffer1.sourcevalues[i]..","..defbuffer1.readings[i])
	end
	
	save_data_to_usb_with_prompt(stringData)
end

--------------------------------------------------------------------------------------------------------------------------
function basicSettings()
	--Setup the instrument source and measure settings for Eoc measurement
	smu.source.func = smu.FUNC_DC_CURRENT
	smu.measure.func = smu.FUNC_DC_VOLTAGE
	smu.source.offmode = smu.OFFMODE_HIGHZ
	smu.measure.sense = smu.SENSE_4WIRE
	smu.source.range = 1e-6
	smu.source.level = 0
	smu.source.autodelay = smu.ON
	smu.measure.range = V_RANGES.range[data.v_range]
	smu.source.vlimit.level = V_RANGES.range[data.v_range]
	smu.measure.nplc = 10
	smu.measure.autozero.enable = smu.ON
end
------------------------------------------------------------------------------------------------------------------------------
--This function measures the open circuit potential, providing the user with information about the battery potential directly from the Main Menu.
function runTest()
	defbuffer1.clear()
	defbuffer1.capacity = 100000
	
	display.graph.removeall(ui.home.graph)
	display.graph.add(ui.home.graph, defbuffer1, display.ELEMENT_DATA, defbuffer1, display.ELEMENT_TIME)
	display.graph.drawstyle(ui.home.graph, display.STYLE_BOTH)
	display.graph.scalex(ui.home.graph, display.XSCALE_SMART)
	display.graph.scaley(ui.home.graph, display.YSCALE_SMART)

	--[[Initialize the trigger timer that creates events which cause the instrument to take a measurement.
		The max amount of events that will be created is 100,000, which matches the max capacity of the buffer]]
	trigger.timer[1].reset()
	trigger.timer[1].start.generate = trigger.ON
	trigger.timer[1].delaylist = {data.meas_interval, data.meas_interval}
	trigger.timer[1].count = 100000
	
	--Initialize the trigger timer that creates events which cause the animation to change.
	trigger.timer[2].reset()
	trigger.timer[2].start.generate = trigger.OFF
	trigger.timer[2].delaylist = {0.5, 0.5} --s
	trigger.timer[2].count = 500000
	
	--[Experiment]--
	trigger.model.setblock(1, trigger.BLOCK_BUFFER_CLEAR)
	trigger.model.setblock(2, trigger.BLOCK_SOURCE_OUTPUT, smu.ON)
	trigger.model.setblock(3, trigger.BLOCK_WAIT, trigger.EVENT_TIMER1)
	trigger.model.setblock(4, trigger.BLOCK_MEASURE, defbuffer1)
	trigger.model.setblock(5, trigger.BLOCK_BRANCH_LIMIT_CONSTANT, trigger.LIMIT_ABOVE, 0, V_RANGES.range[data.v_range], 7, 4)
	trigger.model.setblock(6, trigger.BLOCK_BRANCH_COUNTER, data.num_samples, 3)
	trigger.model.setblock(7, trigger.BLOCK_SOURCE_OUTPUT, smu.OFF) --Done, turn the source output off.
	
	display.setstate(ui.home.start_stop, display.STATE_ENABLE)
	display.waitevent(0.001)	--Consume any previous events
	
	--start the trigger model and timers
	trigger.timer[1].enable = trigger.ON
	timer.cleartime()
	trigger.model.initiate()
	
	while trigger.model.state() == trigger.STATE_RUNNING or trigger.model.state() == trigger.STATE_WAITING do
		update_progress_bar(defbuffer1.n / data.num_samples * 100)
		delay(0.5)
		if display.waitevent(0.001) == ui.home.start_stop then
			trigger.model.abort()
			stats.time = timer.gettime()
			test_cleanup()
			return 
		end
	end
		
	waitcomplete()
	--Determine how long the test lasted
	stats.time = timer.gettime()
	if defbuffer1.n < data.num_samples then
		display.input.prompt(display.BUTTONS_OK, "Experiment terminated because compliance was reached.")
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
		
		if prompt ~= nil then display.delete(prompt) end
	else
		stats = { }
	end
end

function measure_event_handler(eventID, value)
	sync_ui_to_data(ui_data_event_table, eventID)
end

function start_stop_event_handler(eventID)
	test_start()
	basicSettings()
	runTest()
	test_cleanup()
end

local function create_screens()
	ui.measure = { }
	ui.measure.root = display.create(display.ROOT, display.OBJ_SCREEN, "Measure Settings")
	
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
	
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 1 + offset, 0 + offset, ui.home.root, "Run/Graph", "graph")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 1 + offset, 1 + offset, display.SCREEN_READING_TABLE, "Reading Table")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 1 + offset, 2 + offset, ui.stats.root, "Statistics", "stats")
	
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 2 + offset, 0 + offset, ui.save.root, "Save Settings", "save")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 2 + offset, 1 + offset, ui.load.root, "Load Settings", "load")
	
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 3 + offset, 0 + offset, display.SCREEN_SYS_EVENT_LOG, "Event Log")
	
	--Create ui.measure controls
	ui.measure.potential_range = create_edit_option(ui.measure.root, 200, option_height*0 + 20, "Potential Range", V_RANGES.value[1].."..."..V_RANGES.value[table.getn(V_RANGES.value)], V_RANGES)
	table.insert(ui_data_event_table, {ui = "ui.measure.potential_range", data = "data.v_range", event = "measure_event_handler"})
	display.setvalue(ui.measure.potential_range, get_index_from_range(V_RANGES, 2))	--Set default range to 2V
	measure_event_handler(ui.measure.potential_range, 2)	--Set default range to 2V
	display.setevent(ui.measure.potential_range, display.EVENT_PRESS, "measure_event_handler(%id, %value)")
	
	ui.measure.num_samples = display.create(ui.measure.root, display.OBJ_EDIT_NUMBER, 600, option_height*0 + 20, "Sample Count", numsamples.min.." to "..numsamples.max, display.NFORMAT_INTEGER, numsamples.val, numsamples.min, numsamples.max)
	display.setevent(ui.measure.num_samples, display.EVENT_PRESS, "measure_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.measure.num_samples", data = "data.num_samples", event = "measure_event_handler"})
	
	ui.measure.meas_interval = display.create(ui.measure.root, display.OBJ_EDIT_NUMBER, 200, option_height*1 + 20, "Sample Interval (s/pt)", display.format(measperiod.min, "s", display.NFORMAT_USER, 4).." to "..display.format(measperiod.max, "s", display.NFORMAT_USER, 4), display.NFORMAT_USER, measperiod.val, measperiod.min, measperiod.max, "s")
	display.setevent(ui.measure.meas_interval, display.EVENT_PRESS, "measure_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.measure.meas_interval", data = "data.meas_interval", event = "measure_event_handler"})
	
	sync_ui_to_data(ui_data_event_table)
	
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
	
	sync_ui_to_data(ui_data_event_table)
end

local function create_global_tables()
	--NOTE: Use find and replace when changing *.value strings to avoid breaking lookups

	
end

--[[------------------------------------------------------------------------------------------------------------------------------
=============================
--Program is executed here		
=============================
]]

local function main()
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
	smu.source.offmode = smu.OFFMODE_HIGHZ
	smu.measure.sense = smu.SENSE_4WIRE
	
	init_toplevel()
	data.vertexPotential = { }
	create_global_tables()
	
	create_top_screens()
	create_screens()
	create_loading_screen()
	
	create_top_controls()
	create_controls()
	
	destroy_loading_screen()
end
main()