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
	
	This test script enables select Keithley SourceMeter ® Instrument to perform cyclic voltammetry.  
	When the test script is executed, the user is prompted to enter the test parameters on the display of 
	the instrument.   As the test is executed, a voltammogram is plotted in real time on the home screen.

	Using this test script requires the Model 2450, 2460, or 2461 to have firmware 1.5.0 or greater.  
	The latest firmware can be found on the Keithley website, tek.com/keithley.

]]

--The variables to be used throughout the entirety of this code are as follows:
changelist = "$Change: 189427 $"
local MIN_EC_FRAMEWORK_VERSION = "1.5"
local terminalOption = smu.TERMINALS_FRONT
local gracePeriod = 2.85e-3
SAVED_SETUP_BASE_FILENAME = "KI_"..localnode.model.."-EC_CV_Setup"
SCRIPT_TITLE = "Cyclic Voltammetry"
X_UNIT = "V"
Y_UNIT = "A"
local MAX_SOURCE_STEPS, MAX_SOURCE_STEPS_MSG = 1e6, "Too many internal source steps.  Increase scan rate or reduce number of cycles."
local MAX_MEAS_POINTS, MAX_MEAS_POINTS_MSG = 100e3, "Too many measure points.  Adjust settings to reduce number of points."

--first appears in function measureEOC()
local EOCpotential	
local cycleRange
local samplingInterval = {}
local measureVoltageDifference

--first appears in function experimentSetup()
local stepSize
local sourceDelay
local measureIntervalComparison
local actualMeasureDelays
local sourceList
local sourceListLength
local measureIntervals
local voltageLimit

--=========================================================================================
-- (Private) Script Utility Functions  (Intended for use by this script only.  DO NOT CALL)
--=========================================================================================

function experimentInitialize(fpMode, rpTerminals)
	smu.source.offmode = smu.OFFMODE_HIGHZ
	eventlog.clear()
	eventlog.suppress(eventlog.SEV_ALL)
	
	-- If the rpTerminals parameter is true then the rear panel terminals will be used.
	if rpTerminals then
		terminalOption = smu.TERMINALS_REAR
	else
		terminalOption = smu.TERMINALS_FRONT
	end
	smu.terminals = terminalOption
	
	if eocBuffer == nil then
		eocBuffer = buffer.make(10000)
	end
	
	eocBuffer.clear()
	eocBuffer.fillmode = buffer.FILL_CONTINUOUS
	
	collectgarbage()

end


--[[function measureEOC()
	-checks with the user that the chemical set up is ready for the measurement
	-sets all of the SMU parameters necessary for making the Eoc measurement
	-makes the measurement
	-prompts the user to approve of it
--]]
function measureEOC()
	--[[The system must be set up and wired before measuring the Eoc, so the user is prompted to confirm that the set up is
		ready to take the Eoc measurement. The Eoc will automatically be measured after this question is answered.]]
	local button
	button = display.input.prompt(display.BUTTONS_YESNO, "Ready to measure Eoc?")
	if button == display.BUTTON_NO then test_cleanup() exit() end

	--Setup the SMU source and measure settings for Eoc measurement
	smu.source.func = smu.FUNC_DC_CURRENT
	smu.measure.func = smu.FUNC_DC_VOLTAGE
	smu.source.offmode = smu.OFFMODE_HIGHZ
	smu.measure.sense = smu.SENSE_4WIRE
	smu.source.range = 1e-6
	smu.source.level = 0
	smu.source.autodelay = smu.ON
	smu.source.vlimit.level = 2
	smu.measure.range = 2
	smu.measure.nplc = 10
	smu.measure.autozero.enable = smu.ON

	smu.source.output = smu.ON
	delay(0.5)
	EOCpotential = smu.measure.read(eocBuffer) --This is the actual measurement of the Eoc
	if EOCpotential > 1.95 then
		smu.measure.range = 20
		smu.source.vlimit.level = 20
		delay(1)
		EOCpotential = smu.measure.read(eocBuffer)
	end

	smu.source.output = smu.OFF
	button = display.input.prompt(display.BUTTONS_YESNO, string.format("Eoc is %gV. Do you want to continue?", EOCpotential))
	if button == display.BUTTON_NO then test_cleanup() exit() end
end


--[[function experimentSetup()
	This function does the following:
	-collects the "numberOfVertices" from the user
	-collects the magnitude of the vertices using the references from the user, stored in "vertexPotential"
	-collects the "sourceRate" from the user
	-collects the "numberOfCycles" from the user
	-collects the "currentLimit" from the user based on the model number
	-calculates the "cycleRange" for use in collecting more user inputs
	-collects the "data.samplingUnits" from the user
	-collects the corresponding magnitude for the data.samplingUnits
	-uses the magnitude, the cycle range, and other values to calculate the value for measureVoltage/CurrentDifference

	]]
function experimentSetup()
	local function verifyListSize(size, prompt, max_size, message)
		if size > max_size then
			display.delete(prompt)
			display.input.prompt(display.BUTTONS_OK, message)
			test_cleanup()
			exit()
		end
	end
	
	--[[This variable, "data.numberOfVertices," tells the total number of fixed points that will be swept to and from in the 
		CV.]]
	
	--numberOfVertices = tonumber(string.sub(tostring(display.input.option("Enter number of vertices:", "Two", "Three", "Four")), -1))
	if data.numberOfVertices == nil then return false, "Number of vertices not supplied." end


	--[[In this for loop, the magnitude and reference type of each vertex is obtained from the user. From 1 up to the 
		total number of vertices, the loop first obtains a voltage for the vertex, then asks if it is to be measured 
		vs. Eref or vs. Eoc. Eoc is the open circuit potential measured earlier, and Eref is using the value of the 
		physical reference electrode as the zero potential. This is built into the set up of the system, so it does not 
		need to be accounted for in code.
		If the point is to be measured vs. Eref, then nothing needs to be done to the vertex magnitude because the
		reference potential is physically built into the system by the user's choice of reference electrode.
		If the point is to be measured vs. Eoc, then the previously measured variable "EOCpotential" must be added to 
		the vertex's magnitude in order to set the point so that the Eoc is the zero-voltage reference state. ]]
	local numericWordsForVertices
	numericWordsForVertices = {"first", "second", "third", "fourth"}
	
	local max_potential = math.abs(data.vertexPotential[1])
	for i = 1, data.numberOfVertices do
		--vertexPotential[i] = display.input.number(string.format("Enter %s potential, -5 to 5V", numericWordsForVertices[i]), display.NFORMAT_PREFIX, 0, -5, 5)
		if data.vertexPotential[i] == nil then data.vertexPotential[i] = nil return false, "Vertex "..i.." not supplied" end

		if data.referenceType == 2 then
			data.vertexPotential[i] = data.vertexPotential[i] + EOCpotential
		end
		if math.abs(data.vertexPotential[i]) > max_potential then
			max_potential = math.abs(data.vertexPotential[i])
		end
	end
	
	if not verify_power_limits(max_potential, instr.FUNC_DC_VOLTAGE, I_RANGES.range[data.currentLimit]) then
		display.input.prompt(display.BUTTONS_OK, "Vertex potential exceeds power limits. Reduce vertex potential to less than "..I_RANGES.v_limit[data.currentLimit].."\21V or reduce current range.")
		test_cleanup()
		exit()
	end
	
	--[[The variable "sourceRate" dictates the speed at which the scan will sweep from vertex to vertex. The scan is 
		done at the same speed across the entire experiment.]]
	--sourceRate = display.input.number("Enter scan rate (mV/sec)", display.NFORMAT_DECIMAL, 25, 1, 3500)
	if data.sourceRate == nil then return false, "Source rate not supplied" end

	--[[The variable "numberOfCycles" is the number of times that the experiment will sweep between all the specified 
		vertices.]]
	--numberOfCycles = display.input.number("Enter number of cycles", display.NFORMAT_INTEGER, 1, 1, 100)
	if data.numberOfCycles == nil then return false, "Number of cycles not supplied" end

	--[[Here, the "modelNumber" collected at the very beginning of the code is used to determine the possible current 
		ranges that will be presented to the user. The variable "currentLimit" is the maximum current allowed to be 
		measured. If the user selects "Not known" then the code will default to the largest current range available for 
		the instrument. This value is only used later in the code when setting the smu.measure.range() command.]]
	if data.currentLimit == nil then return false, "Current limit not supplied" end
	
	--[[The variable "highCapacitance" is to toggle the High Capacitance Mode.
	   This value is only used later in the code when setting the smu.source.highc command.]]
	if data.highCapacitance == nil then return false, "High Capacitance Mode not supplied" end

	--[[Because all the vertices have been specified, the total scalar voltage to be swept in a single cycle, 
		"cycleRange" can be calculated for use in further calculations.]]
	cycleRange = 0
	for i = 1, (data.numberOfVertices-1) do
		if data.vertexPotential[i + 1] ~= nil then
			cycleRange = cycleRange + math.abs(data.vertexPotential[i + 1] - data.vertexPotential[i])
		end
	end

	--[[The variable "data.samplingUnits" has 4 possible values: "points/test", "points/cycle", "sec/pt", "pts/sec",
		Depending on which units the user selects, data will be sorted into the data sheet in different ways, and they 
		will be allowed to enter the magnitude of their sampling method in a different range of values.]]
	--samplingInterval.Units = tonumber(string.sub(tostring(display.input.option("Enter sampling interval units:", "points/test", "points/cycle", "sec/pt", "pts/sec")), -1))
	if data.samplingUnits == nil then return false, "Sampling units not supplied" end

	--[[After selecting the units for their sampling interval, the user is prompted for a magnitude of the interval, and
		the further variable "measureVoltageDifference" is calculated.]]
	if data.samplingUnits == 2 then -- "points/test"
		--ptsPerTest = display.input.number("Enter number of pts/test:", display.NFORMAT_DECIMAL, 101, 10, 10000)
		if data.samplerate == nil then return false, "Samplerate not supplied" end
		samplingInterval.Scalar = data.samplerate
		local totalVoltageScalar
		totalVoltageScalar = data.numberOfCycles * cycleRange
		measureVoltageDifference = totalVoltageScalar / (data.samplerate - 1)

	elseif data.samplingUnits == 1 then -- "points/cycle"
		--ptsPerCycle = display.input.number("Enter number of pts/cycle:", display.NFORMAT_DECIMAL, 101, 10, 10000)
		if data.samplerate == nil then return false, "Samplerate not supplied" end
		samplingInterval.Scalar = data.samplerate
		measureVoltageDifference = cycleRange / (data.samplerate - 1)

	elseif data.samplingUnits == 4 then -- "sec/pt"
		--secPerPt = display.input.number("Enter number of seconds/pt:", display.NFORMAT_DECIMAL, 1, .01, 100)
		if data.samplerate == nil then return false, "Samplerate not supplied" end
		samplingInterval.Scalar = data.samplerate
		measureVoltageDifference = (data.sourceRate/1000) * data.samplerate

	elseif data.samplingUnits == 3 then -- "pts/sec"
		--ptsPerSec = display.input.number("Enter number of pts/second:", display.NFORMAT_DECIMAL, 1, .01, 100)
		if data.samplerate == nil then return false, "Samplerate not supplied" end
		samplingInterval.Scalar = data.samplerate
		measureVoltageDifference = (data.sourceRate/1000) / data.samplerate
		
	else
		return false, "Invalid sampling interval units"
	end
	
	--[[The variable "stepSize" is a constant voltage value of .1mV or .0001V, and it is the voltage step size used in 
		the digitized voltage sweep. To sweep from vertex to vertex, the instrument puts out very small pulses at 
		varying time intervals in order to step from one voltage to another.
		The variable "sourceDelay" is the time that each of the small sourced steps remains. It is calculated by using 
		the "sourceRate" variable, converting it to V/sec, and dividing with the stepSize (V) to get a time value in 
		seconds that the pulses will last for.]]
	if data.sourceRate >= 350 then
		stepSize = .01
	elseif data.sourceRate >= 35 then
		stepSize = .001
	else
		stepSize = .0001
	end
	sourceDelay = (stepSize * 1000) / data.sourceRate

	--[[Now that we know all the information necessary to source the CV, we will create a comprehensive list that 
		contains every small step to be sourced by the instrument. This list will be used with any sampling interval 
		method, as it is only relevant to the sourcing of voltage, not the collection of data.
		The variable "listSize" is initiated to be 1, but it increments itself each time that a value is added to the 
		list titled "sourceList" within the for loop.
		The variable "sourceList" is a table initiated with no values in it, and within the for loop, the values of the 
		voltages to be stepped are added to it one by one. The final list contains every voltage to be sourced.]]
	sourceList = {}
	local listSize
	listSize = 1
	local nextSourceValue
	local prompt = display.prompt(display.BUTTONS_NONE, "Preparing to run test...")
	local tolerance = 1e-9
	for k = 1, data.numberOfCycles do
		for i  = 1, (data.numberOfVertices - 1) do
			sourceList[listSize] = data.vertexPotential[i]
			listSize = listSize + 1
			verifyListSize(listSize, prompt, MAX_SOURCE_STEPS, MAX_SOURCE_STEPS_MSG)
			if data.vertexPotential[i] < data.vertexPotential[i + 1] then
				nextSourceValue = data.vertexPotential[i] + stepSize
				while nextSourceValue < (data.vertexPotential[i + 1] + tolerance) do
					sourceList[listSize] = nextSourceValue
					nextSourceValue = nextSourceValue + stepSize
					listSize = listSize + 1
					verifyListSize(listSize, prompt, MAX_SOURCE_STEPS, MAX_SOURCE_STEPS_MSG)
				end
				listSize = listSize - 1
			elseif data.vertexPotential[i] > data.vertexPotential[i + 1] then
				nextSourceValue = data.vertexPotential[i] - stepSize
				while nextSourceValue > (data.vertexPotential[i + 1] - tolerance) do
					sourceList[listSize] = nextSourceValue
					nextSourceValue = nextSourceValue - stepSize
					listSize = listSize + 1
					verifyListSize(listSize, prompt, MAX_SOURCE_STEPS, MAX_SOURCE_STEPS_MSG)
				end
				listSize = listSize - 1
			end
			verifyListSize(listSize, prompt, MAX_SOURCE_STEPS, MAX_SOURCE_STEPS_MSG)
		end
		update_progress_bar(k / data.numberOfCycles * 100)
	end
	sourceListLength = table.getn(sourceList)
	
--Now, the unit will calculate the intervals of steps needed between measurements
	actualMeasureStepDelay = measureVoltageDifference / stepSize
	actualMeasureDelays = {}
	local j = 1
	measureIntervals = {1}
	update_progress_bar(0)
	local NUM_OF_MEAS_POINTS = ((sourceListLength - actualMeasureStepDelay) / actualMeasureStepDelay) + 1
	verifyListSize(NUM_OF_MEAS_POINTS, prompt, MAX_MEAS_POINTS, MAX_MEAS_POINTS_MSG)
	
	for i = actualMeasureStepDelay, sourceListLength, actualMeasureStepDelay do
		actualMeasureDelays[j] = math.floor(i)
		j = j + 1
		update_progress_bar(i / NUM_OF_MEAS_POINTS * 100)
	end
	actualMeasureDelays[j] = 10000000
	
	display.delete(prompt)
	update_progress_bar(0)
	--[[This "measureIntervalComparison" section of the code deals with a potential downfall of the code attempting
		to measure at a faster rate than it is sourcing. To deal with this, the code compares the measureVoltageDifference
		to the step size in the form of a ratio, and if it proves that the measureVoltageDifference is smaller than the step
		size, the ratio will be less than 1 and will round down to 0. When this happens, an error prompt appears stating
		"ERROR: measure rate too fast" and it prompts the user to enter a new source rate, thus a new step size, and a new 
		sampling interval unit with a new magnitude, thus a new measure voltage difference.]]
	measureIntervalComparison = math.floor(measureVoltageDifference / stepSize)
	if measureIntervalComparison == 0 then
		return false, "Sampling rate too fast"
	end -- if measureIntervalComparison == 0

	--[[Similar to the source_range value specified by the user, the command "smu.source.range" needs to be set. To do
		this, this loop uses the two, three, or four vertices in order to obtain a value for the largest voltage to be
		sourced. This value is called "voltageLimit."]]
	if data.numberOfVertices == 4 then
		voltageLimit =  math.max(math.abs(data.vertexPotential[1]), math.abs(data.vertexPotential[2]), math.abs(data.vertexPotential[3]), math.abs(data.vertexPotential[4]))
	elseif data.numberOfVertices == 3 then
		voltageLimit =  math.max(math.abs(data.vertexPotential[1]), math.abs(data.vertexPotential[2]), math.abs(data.vertexPotential[3]))
	else
		voltageLimit =  math.max(math.abs(data.vertexPotential[1]), math.abs(data.vertexPotential[2]))
	end
	
	return true, "experimentSetup completed successfully"
end -- function experimentSetup()


--[[function experimentExecution()
	This function executes the test based on the test parameters store in the local script variables.
--]]
function experimentExecution(fpMode)
	--[[The variable "saveOption" equals display.BUTTON_YES when the user wants to save, and equals display.BUTTON_YES
	    when the user does not.
		It is used here to prompt for a filename when they want to save, and it is used later as a condition before
		writing the data to a file after the experiment is complete.
		Similarly, the variable "fileName" is a string which is used in the format ___.csv when saving the file at the 
		end]]
	


	--display.changescreen(display.SCREEN_GRAPH)
	
	--Set up the source and measure commands
	--[[The source.range is set using if statements to procure the absolute values of each vertex and locating the maximum 
	value]]
	smu.source.func = smu.FUNC_DC_VOLTAGE
	smu.measure.func = smu.FUNC_DC_CURRENT
	smu.source.offmode = smu.OFFMODE_HIGHZ
	smu.measure.sense = smu.SENSE_4WIRE
	smu.source.range = voltageLimit
	smu.source.autorange = smu.OFF
	smu.source.readback = smu.OFF
	smu.source.ilimit.level = I_RANGES.range[data.currentLimit]
	smu.source.autodelay = smu.OFF
	smu.source.delay = 0
	
	if data.highCapacitance == get_index_from_value_enum(OFF_ON_HC, "On") then
		smu.source.highc = smu.ON
	else
		smu.source.highc = smu.OFF
	end
	
	smu.terminals = terminalOption
	smu.measure.range = I_RANGES.range[data.currentLimit]
	local nplc = (sourceDelay - gracePeriod) * localnode.linefreq
	if nplc < 0.01 then
		smu.measure.nplc = 0.01
	elseif nplc < 10 then
		smu.measure.nplc = nplc
	else
		smu.measure.nplc = 10
	end
	smu.measure.autozero.once()
	
	--[[Now, all information has been collected, calculated, or specified, and the instrument has had its source and 
		measure functions set up properly. The experiment is now, finally, executed.
		
		The experiment begins by clearing the timer and assigning the internal timer to the variable t. Using the value 
		for sourceDelay, it calculates the next time that a point will need to be sourced, called nextSourceTime. 
		
	    If enough voltage has been sourced since the previous kept measurement, a measurement is made to "cvBuffer," and
		previousKeptMeasure is incremented in order to index the cvBuffer buffer.
		
		Before entering the loop, the output is turned on, the first value is sourced, and the first measurement is made
		into "cvBuffer." This initiates the relative time stamps of the kept values in such a way that when this
		measurement is made, it is considered to be the "zero" time in reference to all source and measure values.
		
		Then, a large for loop is initiated. This loop will repeat going through the sourceList for however many cycles 
		were specified by the value "numberOfCycles." Within each cycle, timer.gettime() controls the time difference 
		between each sourced point. Another loop exists, which bounds the experiment until the local variable i has been
		iterated to the point where it is larger than the sourceListLength. 
		
		For each of these iterations, the code waits until the internal timer, timer.gettime(), exceeds the value for 
		nextSourceTime. When this is the case, the next value in the sourceList is sourced, and a measurement is taken 
		to cvBuffer.
		
		This loop is repeated until the entire source list has been sourced, for each cycle.]]

	local stepCount
	stepCount = 0
	
	-- cvBuffer will hold readings collected at the user set sample interval
	if cvBuffer == nil then
		cvBuffer = buffer.make(100000)
	end
	cvBuffer.clear()
	cvBuffer.capacity = 100000
	cvBuffer.fillmode = buffer.FILL_CONTINUOUS
	display.graph.removeall(ui.home.graph)
	display.graph.add(ui.home.graph, cvBuffer)
	display.graph.drawstyle(ui.home.graph, display.STYLE_BOTH)
	display.graph.scalex(ui.home.graph, display.XSCALE_SMART)
	display.graph.scaley(ui.home.graph, display.YSCALE_SMART)
	
	eventlog.clear()
	collectgarbage()
	
	local i = 1
	local j = 2
	local nextSourceTime
	local k = 1
	local reading
	display.setstate(ui.home.start_stop, display.STATE_ENABLE)
	display.waitevent(0.001)	--Consume any previous events

	smu.source.output = smu.ON
	smu.source.level = sourceList[1]
	delay(0.5)
	reading = smu.measure.read(cvBuffer)

	nextSourceTime = timer.gettime() + sourceDelay
	while j <= sourceListLength do
      	if timer.gettime() >= nextSourceTime then
      		if sourceList[j] == sourceList[j-1] then j = j + 1 end
	        smu.source.level = sourceList[j]
	        stepCount = stepCount + 1
	        if cvBuffer.n >= 0 then
       			if stepCount >= actualMeasureDelays[k] then
       				k = k + 1
			        smu.source.level = sourceList[j]
		        	reading = smu.measure.read(cvBuffer)
		        	update_progress_bar(j / sourceListLength * 100)
		        	if display.waitevent(0.001) == ui.home.start_stop then
						test_cleanup()
						return 
					end
       			end
            end
            nextSourceTime = nextSourceTime + sourceDelay
            i = i + 1
            j = j + 1
 		end
	end
	if cvBuffer.sourcevalues[cvBuffer.n] ~= data.vertexPotential[data.numberOfVertices] then
		if cvBuffer.sourcevalues[cvBuffer.n] <= data.vertexPotential[data.numberOfVertices] - .0005 or cvBuffer.sourcevalues[cvBuffer.n] >= data.vertexPotential[data.numberOfVertices] + .0005 then
			reading = smu.measure.read(cvBuffer)
		end
	end
	
	test_cleanup()
	return true,"CV test complete successfully"
end --function experimentExecution()


--[[function experimentSave()
	This function saves the test parameters and the collected data to the USB thumb drive.
--]]
function experimentSave()
	--these three tables contain the three things that will be written to the cells in the for loop below
	local textCells, valueCells, unitsCells
	local stringData = { }
	textCells = 	{"General Parameters", 	"EOC potential", 	"\nSource Parameters", 	"Source Range", 	"# of Vertices", 		"Vertex 1", 				"Vertex 2", 				"Vertex 3", 				"Vertex 4", 				"Source Rate", 			"# of Cycles", 			"\nMeasure Parameters", 	"Current Range", 						"Sampling Interval", 								"nplc",				"\nCalculated Parameters", 	"stepSize", 	"sourceDelay", 		"listSize", 	"voltageLimit"}
	valueCells = 	{"n/a", 				EOCpotential, 		"n/a", 					smu.source.range, 	data.numberOfVertices, 	data.vertexPotential[1],	data.vertexPotential[2],	data.vertexPotential[3],	data.vertexPotential[4],	data.sourceRate, 		data.numberOfCycles, 	"n/a", 						I_RANGES.range[data.currentLimit], 		samplingInterval.Scalar,							smu.measure.nplc,	"n/a", 						stepSize, 		sourceDelay, 		listSize, 		voltageLimit}
	unitsCells = 	{"n/a",					"V", 				"n/a", 					"n/a", 				"", 					"V", 						"V", 						"V", 						"V", 						"mV/sec", 				"n/a", 					"n/a", 						"A", 									SAMPLE_UNITS.value[data.samplingUnits], 			"n/a",				"n/a", 						"V", 			"seconds", 			"n/a", 			"V"}
	for i = 1, 20 do
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
	table.insert(stringData, "")
	
	--[[This part of the file-writing code writes all of the data in a large loop into columns Current, Voltage, and 
	Seconds]]
	table.insert(stringData, "\nRaw Data")
	table.insert(stringData, "Voltage,Current,Seconds\n")
	for i = 1, cvBuffer.n do
		table.insert(stringData, string.format("%g,%g, %g", cvBuffer.sourcevalues[i], cvBuffer.readings[i], cvBuffer.relativetimestamps[i]))
	end
	
	save_data_to_usb_with_prompt(stringData)
end --function experimentSave()

--===============================================
-- (Public) KICV Front Panel Operation Functions
--===============================================
-- Call these functions to perform the CV test from the front panel.

--[[function KICV_RunFrontPanel()
	Starts the front panel operation of the script.  In front panel operation, the script will prompt the user to enter
	test parameters on the front panel of the instrument.
--]]
function KICV_RunFrontPanel()

	-- Initialize the instrument and script to test
	experimentInitialize(true)

	--[[Before accepting any sorts of commands or inputs regarding the experiment, the code must measure the Eoc for the 
		user to potentially reference throughout the experiment.
	
		The Eoc is the open circuit potential of the system, or the natural voltage response to 0A of current being drawn.
		This value is the voltaic center of the reactions occurring in the system.
	
		The function "measureEOC" is defined above, and only returns the value of the Eoc.]]
------------------------------------------------------------------------------------------------------------------------
	
	--Only measure open circuit potential if we're actually referencing to Eoc
	if REFERENCE_TYPES.value[display.getvalue(ui.scan.reference)] == "Eoc" then
		measureEOC(true)
	end

------------------------------------------------------------------------------------------------------------------------
	--[[Now that the Eoc has been measured, you can collect the user inputs necessary to calculate the things needed for
		the experiment.
	
		The function experimentSetup() collects the user input, uses this input to calculate the remaining parameters
		for executing the experiment, then copies these results to the matrix "parameters".
	]]
------------------------------------------------------------------------------------------------------------------------	
	local success, message = experimentSetup(true)
	if message == nil then message = "" end
	if not success then
		display.input.prompt(display.BUTTONS_OK, "Error: "..message)
		test_cleanup()
		return
	end

	----------------------------------------------------------------------------------------------------------------------

	experimentExecution(true)

end

function scan_event_handler(eventID, value)
	if eventID == ui.scan.number_vertices then
		for i = 1, table.getn(ui.scan.vertex) do
			if i > value then
				display.setstate(ui.scan.vertex[i], display.STATE_INVISIBLE)
			else
				display.setstate(ui.scan.vertex[i], display.STATE_ENABLE)
			end
		end
	end
	
	sync_ui_to_data(ui_data_event_table, eventID)
end

function measure_event_handler(eventID, value)
	if eventID == ui.measure.sample_units then
		if ui.measure.samplerate ~= nil then display.delete(ui.measure.samplerate) ui.measure.samplerate = nil end
		if value == get_index_from_value_enum(SAMPLE_UNITS, "points/cycle") then
			ui.measure.samplerate = display.create(ui.measure.root, display.OBJ_EDIT_NUMBER, 200, option_height*0 + 20, "Sampling Rate", "10\21pts/cycle to 10000\21pts/cycle", display.NFORMAT_INTEGER, 101, 10, 10000)--, "points/cycle")
		elseif value == get_index_from_value_enum(SAMPLE_UNITS, "points/test") then
			ui.measure.samplerate = display.create(ui.measure.root, display.OBJ_EDIT_NUMBER, 200, option_height*0 + 20, "Sampling Rate", "10\21pts/test to 10000\21pts/test", display.NFORMAT_INTEGER, 101, 10, 10000)--, "points/test")
		elseif value == get_index_from_value_enum(SAMPLE_UNITS, "points/s") then
			ui.measure.samplerate = display.create(ui.measure.root, display.OBJ_EDIT_NUMBER, 200, option_height*0 + 20, "Sampling Rate", "0.01\21pt/s to 100\21pts/s", display.NFORMAT_DECIMAL, 1, 0.01, 100)--, "points/s")
		else	--if value == get_index_from_value_enum(SAMPLE_UNITS, "s/point") then
			ui.measure.samplerate = display.create(ui.measure.root, display.OBJ_EDIT_NUMBER, 200, option_height*0 + 20, "Sampling Rate", "0.01\21s/pt to 100\21s/pt", display.NFORMAT_DECIMAL, 1, 0.01, 100)--, "s/point")
		end
		display.setevent(ui.measure.samplerate, display.EVENT_PRESS, "measure_event_handler(%id, %value)")
		measure_event_handler(ui.measure.samplerate, display.getvalue(ui.measure.samplerate))
	end
	
	sync_ui_to_data(ui_data_event_table, eventID)
end

function start_stop_event_handler(eventID)
	test_start()
	KICV_RunFrontPanel()
	test_cleanup()
end

local function create_screens()
	ui.scan = { }
	ui.scan.root = display.create(display.ROOT, display.OBJ_SCREEN, "Scan Settings")
	ui.measure = { }
	ui.measure.root = display.create(display.ROOT, display.OBJ_SCREEN, "Measure Settings")
	
end

local function create_controls()
	--Setup ui.home controls
	display.settext(ui.home.version, "version "..get_version_number(changelist))
	display.settext(ui.home.root, SCRIPT_TITLE)
	display.setevent(ui.home.start_stop, display.EVENT_PRESS, "start_stop_event_handler(%id)")
	hide_home_stats()	--We're not using stats here, so hide them
	display.setevent(ui.home.save, display.EVENT_PRESS, "experimentSave()")

	--Create ui.menu controls
	local offset = 0 -- button offset
	if display.EVENT_ENDAPP then offset = 1 end
	--ui.menu.root = display.create(display.ROOT, display.OBJ_SCREEN_MENU, "Settings", "Views", "Save/Load", "System")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 0 + offset, 0 + offset, ui.measure.root, "Measure Settings", "meas_settings")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 0 + offset, 1 + offset, ui.scan.root, "Scan Settings", "CV_scan_settings")
	
	--Statistics are disabled for CV until reliable stats are defined
	--display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 1 + offset, 0 + offset, ui.stats.root, "Statistics")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 1 + offset, 0 + offset, ui.home.root, "Run/Graph", "graph")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 1 + offset, 1 + offset, display.SCREEN_READING_TABLE, "Reading Table")
	
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 2 + offset, 0 + offset, ui.save.root, "Save Settings", "save")
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 2 + offset, 1 + offset, ui.load.root, "Load Settings", "load")
	
	display.create(ui.menu.root, display.OBJ_BUTTON_MENU, 3 + offset, 0 + offset, display.SCREEN_SYS_EVENT_LOG, "Event Log")
	
	--Create ui.scan controls
	ui.scan.number_vertices = display.create(ui.scan.root, display.OBJ_EDIT_NUMBER, 200, 20, "Number of Vertices", "2 to 4", display.NFORMAT_INTEGER, 3, 2, 4)
	display.setevent(ui.scan.number_vertices, display.EVENT_PRESS, "scan_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.scan.number_vertices", data = "data.numberOfVertices", event = "scan_event_handler"})
	
	ui.scan.reference = create_edit_option(ui.scan.root, 200, option_height + 20, "Reference", "Eref or Eoc", REFERENCE_TYPES)
	display.setevent(ui.scan.reference, display.EVENT_PRESS, "scan_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.scan.reference", data = "data.referenceType", event = "scan_event_handler"})
	
	ui.scan.scan_rate = display.create(ui.scan.root, display.OBJ_EDIT_NUMBER, 200, option_height*2 + 20, "Scan Rate", "0.1\21mV/s to 3500\21mV/s", display.NFORMAT_DECIMAL, 25, 0.1, 3500, "")
	display.setevent(ui.scan.scan_rate, display.EVENT_PRESS, "scan_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.scan.scan_rate", data = "data.sourceRate", event = "scan_event_handler"})
	
	ui.scan.number_cycles = display.create(ui.scan.root, display.OBJ_EDIT_NUMBER, 200, option_height*3 + 20, "Number of Cycles", "1 to 100", display.NFORMAT_INTEGER, 3, 1, 100)
	display.setevent(ui.scan.number_cycles, display.EVENT_PRESS, "scan_event_handler(%id, %value)")
	table.insert(ui_data_event_table, {ui = "ui.scan.number_cycles", data = "data.numberOfCycles", event = "scan_event_handler"})
	
	ui.scan.vertex = { }
	for i = 1, 4 do
		ui.scan.vertex[i] = display.create(ui.scan.root, display.OBJ_EDIT_NUMBER, 600, option_height*(i-1) + 20, "Vertex "..i, "-20\21V to 20\21V", display.NFORMAT_USER, i, -20, 20, "V")
		table.insert(ui_data_event_table, {ui = "ui.scan.vertex["..i.."]", data = "data.vertexPotential["..i.."]", event = "scan_event_handler"})
		display.setevent(ui.scan.vertex[i], display.EVENT_PRESS, "scan_event_handler(%id, %value)")
		if i > display.getvalue(ui.scan.number_vertices) then
			display.setstate(ui.scan.vertex[i], display.STATE_INVISIBLE)
		end
	end
	
	--Create ui.measure controls
	ui.measure.sample_units = create_edit_option(ui.measure.root, 200, option_height*1 + 20, "Sampling Rate Units", "pts/cycle...s/pt", SAMPLE_UNITS)
	table.insert(ui_data_event_table, {ui = "ui.measure.sample_units", data = "data.samplingUnits", event = "measure_event_handler"})
	table.insert(ui_data_event_table, {ui = "ui.measure.samplerate", data = "data.samplerate", event = "measure_event_handler"})
	measure_event_handler(ui.measure.sample_units, get_index_from_value_enum(SAMPLE_UNITS, "points/cycle"))	--Set default to pts/cycle
	display.setevent(ui.measure.sample_units, display.EVENT_PRESS, "measure_event_handler(%id, %value)")
	
	ui.measure.current_range = create_edit_option(ui.measure.root, 600, option_height*0 + 20, "Current Range", I_RANGES.value[1].."..."..I_RANGES.value[table.getn(I_RANGES.value)], I_RANGES)
	table.insert(ui_data_event_table, {ui = "ui.measure.current_range", data = "data.currentLimit", event = "measure_event_handler"})
	display.setvalue(ui.measure.current_range, get_index_from_range(I_RANGES, 10e-3))	--Set default range to 10mA
	measure_event_handler(ui.measure.current_range, 10e-3)	--Set default range to 10mA
	display.setevent(ui.measure.current_range, display.EVENT_PRESS, "measure_event_handler(%id, %value)")
	
	ui.measure.high_capacitance = create_edit_option(ui.measure.root, 600, option_height*1 + 20, "High Capacitance", "Off or On", OFF_ON_HC)
	table.insert(ui_data_event_table, {ui = "ui.measure.high_capacitance", data = "data.highCapacitance", event = "measure_event_handler"})
	display.setvalue(ui.measure.high_capacitance, get_index_from_value_enum(OFF_ON_HC, "Off"))	--Set default range to Off
	measure_event_handler(ui.measure.high_capacitance, get_index_from_value_enum(OFF_ON_HC, "Off"))
	display.setevent(ui.measure.high_capacitance, display.EVENT_PRESS, "measure_event_handler(%id, %value)")
	
	sync_ui_to_data(ui_data_event_table)
end

local function create_global_tables()
	--NOTE: Use find and replace when changing *.value strings to avoid breaking lookups

	REFERENCE_TYPES = {
		value = {"Eref", "Eoc"}
	}
	
	SAMPLE_UNITS = {
		value = {"points/cycle", "points/test", "points/s", "s/point"},
		abbreviation = {"pts/cycle", "pts/test", "pts/s", "s/pt"}
	}
	
	OFF_ON_HC = {
		value = {"Off", "On"}
	}
	
	if localnode.model == "2450" then
		I_RANGES = {
			value = {"10\21\20A", "100\21\20A", "1\21mA", "10\21mA", "100\21mA", "1\21A"},
			range = {10e-6, 100e-6, 1e-3, 10e-3, 100e-3, 1},
			v_limit = {210, 210, 210, 210, 210, 21}
		}
		V_RANGES = {
			value = {"20\21mV", "200\21mV", "2\21V", "20\21V"},
			range = {20e-3, 200e-3, 2, 20},
			i_limit = {1.05, 1.05, 1.05, 1.05}
		}
	elseif localnode.model == "2460" or localnode.model == "2461" then
		I_RANGES = {
			value = {"1\21mA", "10\21mA", "100\21mA", "1\21A", "4\21A", "5\21A", "7\21A"},
			range = {1e-3, 10e-3, 100e-3, 1, 4, 5, 7},
			v_limit = {105, 105, 105, 105, 21, 10.5, 7.35}
		}
		V_RANGES = {
			value = {"200\21mV", "2\21V", "7\21V", "10\21V", "20\21V"},
			range = {200e-3, 2, 7, 10, 20},
			i_limit = {7.35, 7.35, 7.35, 5.25, 4.2}
		}
	end
end

--==============================
-- Script Execution Begins Here!
--==============================
-- When you run the script, all the functions and local variables above will be loaded into memory but, script execution
-- really begins here.

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