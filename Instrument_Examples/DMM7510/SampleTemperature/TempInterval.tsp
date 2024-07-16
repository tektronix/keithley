--[[

Description:  This is example shows you how to do RTD temperature measurements at a fixed interval
on the Model DMM7510 Graphical Sampling Multimeter.

A temperature reading will be taken every minute (60seconds) over a 24hour period.
This is equivalent to 1440 readings.  The bottom half of the instrument display will change to a
graphical view of the temperature profile.  If you swipe to USER swipe screen, the displayed message
shows the status of the test.
The temperature readings and the corresponding timestamps can be
printed on the TSB console at the end of the test.
This example configures the DMM to perform 4 wire RTD temperature measurement using a PT100.  The
measurement is done at 1 NPLC with offsetcompensation enabled.

To Run:
1) Load TSP file to DMM7510 Memory
	- Select the .tsp file of interest
	- Press the run arrow in Test Script Builder Main Menu
	
2) Run Program
	- At the TSP> prompt in the Instrument Control Panel, type ConfigureTemperature()
	and then SetupTimer() and then press the TRIGGER key on the front panel.
	Type PrintResults() at the TSP> prompt to print the temperature readings and timestamps.
	
]] --

function ConfigureTemperature()
	--Reset the instrument to default settings
	reset()

	--Establish variables to take a measurement every 60 seconds for 1440 times (24 hours)
	MeasCount = 1440 --24 hours
	MeasInterval = 60 --60 seconds
	--Set the measure function to temperature
	dmm.measure.func = dmm.FUNC_TEMPERATURE
	--Configure to measure 4-wire RTD
	dmm.measure.transducer = dmm.TRANS_FOURRTD
	--Enable the detection of open leads
	dmm.measure.opendetector = dmm.ON
	--Select four-wire RTD type to be a Pt100 sensor
	dmm.measure.fourrtd = dmm.RTD_PT100
	--Set the number of power line cycles to 1
	dmm.measure.nplc = 1
	--Enable offset compensation for more accurate reading
	dmm.measure.offsetcompensation.enable = dmm.ON
	--Change to graph swipe screen
	display.changescreen(display.SCREEN_GRAPH_SWIPE)
end

function SetupTimer()
	--Set up timer 1
	trigger.timer[1].reset()
	--Timer delays each time the timer is triggered
	trigger.timer[1].delay = MeasInterval
	--Set EVENT_NOTIFY to trigger the start of timer
	trigger.timer[1].start.stimulus = trigger.EVENT_NOTIFY1
	--Generate timer event once when the timer delay elapses
	trigger.timer[1].start.generate = trigger.OFF
	--Enables timer
	trigger.timer[1].enable = trigger.ON

	--Wait for TRIGGER key from front panel to start trigger model
	trigger.model.setblock(1, trigger.BLOCK_WAIT, trigger.EVENT_DISPLAY)
	--Send notify to start the timer
	trigger.model.setblock(2, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1)
	--Make a measurement and store reading in default buffer
	trigger.model.setblock(3, trigger.BLOCK_MEASURE_DIGITIZE, defbuffer1)
	--Wait for timer delay to elapse
	trigger.model.setblock(4, trigger.BLOCK_WAIT, trigger.EVENT_TIMER1)
	--Go to block 2 for set number of times
	trigger.model.setblock(5, trigger.BLOCK_BRANCH_COUNTER, MeasCount, 2)

	--Initiate trigger model and wait until finished
	trigger.model.initiate()
	--The USER swipe screen will show the status of the test
	display.clear()
	--Prints a message on the user swipe screen to indicate test in progress
	display.settext(display.TEXT1, "Test in progress...")
	waitcomplete()
	--Prints a message on the user swipe screen to indicate test completion
	display.clear()
	display.settext(display.TEXT1, "Test complete.")
end

function PrintResults()
	--Print the temperature readings and the corresponding timestamps
	print("Temperature:")
	printbuffer(1, defbuffer1.n, defbuffer1)
	print("Timestamps:")
	printbuffer(1, defbuffer1.n, defbuffer1.relativetimestamps)
end

--Function
ConfigureTemperature()
SetupTimer()
--Press the TRIGGER key to start the measurement
--Upon completion
PrintResults()
