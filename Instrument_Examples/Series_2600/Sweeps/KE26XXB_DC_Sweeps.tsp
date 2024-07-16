--[[
	Title:			KE26XXB DC Sweeps

	Description:	This script demonstrates how to output simple auto-
		ranged DC sweeps with the Series 2600B System SourceMeter
		instruments.  This script contains functions to perform linear,
		log and list sweeps.
		For each sweep type there are two functions.  One function
		performs the sweep sourcing voltage while the other performs the
		sweep sourcing current.
		At the conclusion of the sweeps the data is returned to the
		instrument console in a format that is compatible for copy and
		paste into Microsoft Excel.

	Equipment Needed:
		1x Series 2600B SourceMeter instrument

	Script Functions:
		DCSweepVLinear(start, stop, numPoints, limitI, nplc)
		DCSweepILinear(start, stop, numPoints, limitV, nplc)
		DCSweepVLog(start, stop, numPoints, limitI, nplc)
		DCSweepILog(start, stop, numPoints, limitV, nplc)
		DCSweepVList(sweepList, numPoints, limitI, nplc)
		DCSweepIList(sweepList, numPoints, limitV, nplc)
--]]

--[[
	Name:	DCSweepVLinear(start, stop, numPoints, limitI, nplc)
	
	Description:
		This function performs an autoranged DC linear voltage sweep.  It
		demonstrates the simplest trigger model configuration to perform
		this sweep.

	Parameters:
		start:			The voltage level of the first step in the sweep in volts
		stop:			The voltage level of the last step in the sweep in volts
		numPoints:		The number of points in the sweep
		limitI:			The current limit of the source in amps
		nplc:			The measurment aperture setting in PLCs where 1 PLC = 1/60 s for 60Hz power

	Example Usage:
		DCSweepVLinear(0, 10, 11, 0.1, 1)
--]]
function DCSweepVLinear(start, stop, numPoints, limitI, nplc)
	reset()
	
	-- Configure the SMU
	smua.reset()
	smua.source.func					= smua.OUTPUT_DCVOLTS
	smua.source.limiti					= limitI
	smua.measure.nplc					= nplc
	smua.measure.delay					= smua.DELAY_AUTO

	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps	= 1

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.linearv(start, stop, numPoints)
	smua.trigger.source.limiti			= limitI
	smua.trigger.measure.action			= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action		= smua.SOURCE_HOLD
	-- By setting the endsweep action to SOURCE_IDLE, the output will return
	-- to the bias level at the end of the sweep.
	smua.trigger.endsweep.action		= smua.SOURCE_IDLE
	smua.trigger.count					= numPoints
	smua.trigger.source.action			= smua.ENABLE
	-- Ready to begin the test

	smua.source.output					= smua.OUTPUT_ON
	-- Start the trigger model execution
	smua.trigger.initiate()
	-- Wait until the sweep has completed
	waitcomplete()
	smua.source.output					= smua.OUTPUT_OFF
	
	-- Print the data back to the Console in tabular format
	print("Time\tVoltage\tCurrent")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x])
	end
end

--[[
	Name:	DCSweepILinear(start, stop, numPoints, limitV, nplc)
	
	Description:
		This function performs an autoranged DC linear current sweep.  It
		demonstrates the simplest trigger model configuration to perform
		this sweep.

	Parameters:
		start:			The current level of the first step in the sweep in amps
		stop:			The current level of the last step in the sweep in amps
		numPoints:		The number of points in the sweep
		limitV:			The voltage limit of the source in volts
		nplc:			The measurment aperture setting in PLCs where 1 PLC = 1/60 s for 60Hz power

	Example Usage:
		DCSweepILinear(0, 10e-3, 11, 10, 1)
--]]
function DCSweepILinear(start, stop, numPoints, limitV, nplc)
	reset()
	
	-- Configure the SMU
	smua.reset()
	smua.source.func					= smua.OUTPUT_DCAMPS
	smua.source.limitv					= limitV
	smua.measure.nplc					= nplc
	smua.measure.delay					= smua.DELAY_AUTO

	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps	= 1

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.lineari(start, stop, numPoints)
	smua.trigger.source.limitv			= limitV
	smua.trigger.measure.action			= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action		= smua.SOURCE_HOLD
	-- By setting the endsweep action to SOURCE_IDLE, the output will return
	-- to the bias level at the end of the sweep.
	smua.trigger.endsweep.action		= smua.SOURCE_IDLE
	smua.trigger.count					= numPoints
	smua.trigger.source.action			= smua.ENABLE
	-- Ready to begin the test

	smua.source.output					= smua.OUTPUT_ON
	-- Start the trigger model execution
	smua.trigger.initiate()
	-- Wait until the sweep has completed
	waitcomplete()
	smua.source.output					= smua.OUTPUT_OFF
	
	-- Print the data back to the Console in tabular format
	print("Time\tVoltage\tCurrent")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x])
	end
end

--[[
	Name:	DCSweepVLog(start, stop, numPoints, limitI, nplc)
	
	Description:
		This function performs an autoranged DC log voltage sweep.  It
		demonstrates the simplest trigger model configuration to perform
		this sweep.

	Parameters:
		start:			The voltage level of the first step in the sweep in volts
		stop:			The voltage level of the last step in the sweep in volts
		numPoints:		The number of points in the sweep
		limitI:			The current limit of the source in amps
		nplc:			The measurment aperture setting in PLCs where 1 PLC = 1/60 s for 60Hz power

	Example Usage:
		DCSweepVLog(1, 10, 11, 0.1, 1)
--]]
function DCSweepVLog(start, stop, numPoints, limitI, nplc)
	reset()
	
	-- Configure the SMU
	smua.reset()
	smua.source.func					= smua.OUTPUT_DCVOLTS
	smua.source.limiti					= limitI
	smua.measure.nplc					= nplc
	smua.measure.delay					= smua.DELAY_AUTO

	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps	= 1

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.logv(start, stop, numPoints, 0)
	smua.trigger.source.limiti			= limitI
	smua.trigger.measure.action			= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action		= smua.SOURCE_HOLD
	-- By setting the endsweep action to SOURCE_IDLE, the output will return
	-- to the bias level at the end of the sweep.
	smua.trigger.endsweep.action		= smua.SOURCE_IDLE
	smua.trigger.count					= numPoints
	smua.trigger.source.action			= smua.ENABLE
	-- Ready to begin the test

	smua.source.output					= smua.OUTPUT_ON
	-- Start the trigger model execution
	smua.trigger.initiate()
	-- Wait until the sweep has completed
	waitcomplete()
	smua.source.output					= smua.OUTPUT_OFF
	
	-- Print the data back to the Console in tabular format
	print("Time\tVoltage\tCurrent")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x])
	end
end

--[[
	Name:	DCSweepILog(start, stop, numPoints, limitV, nplc)
	
	Description:
		This function performs an autoranged DC log current sweep.  It
		demonstrates the simplest trigger model configuration to perform
		this sweep.

	Parameters:
		start:			The current level of the first step in the sweep in amps
		stop:			The current level of the last step in the sweep in amps
		numPoints:		The number of points in the sweep
		limitV:			The voltage limit of the source in volts
		nplc:			The measurment aperture setting in PLCs where 1 PLC = 1/60 s for 60Hz power

	Example Usage:
		DCSweepILog(1e-3, 10e-3, 11, 10, 1)
--]]
function DCSweepILog(start, stop, numPoints, limitV, nplc)
	reset()
	
	-- Configure the SMU
	smua.reset()
	smua.source.func					= smua.OUTPUT_DCAMPS
	smua.source.limitv					= limitV
	smua.measure.nplc					= nplc
	smua.measure.delay					= smua.DELAY_AUTO

	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps	= 1

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.logi(start, stop, numPoints, 0)
	smua.trigger.source.limitv			= limitV
	smua.trigger.measure.action			= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action		= smua.SOURCE_HOLD
	-- By setting the endsweep action to SOURCE_IDLE, the output will return
	-- to the bias level at the end of the sweep.
	smua.trigger.endsweep.action		= smua.SOURCE_IDLE
	smua.trigger.count					= numPoints
	smua.trigger.source.action			= smua.ENABLE
	-- Ready to begin the test

	smua.source.output					= smua.OUTPUT_ON
	-- Start the trigger model execution
	smua.trigger.initiate()
	-- Wait until the sweep has completed
	waitcomplete()
	smua.source.output					= smua.OUTPUT_OFF
	
	-- Print the data back to the Console in tabular format
	print("Time\tVoltage\tCurrent")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x])
	end
end

--[[
	Name:	DCSweepVList(sweepList, numPoints, limitI, nplc)
	
	Description:
		This function performs an autoranged DC list voltage sweep.  It demonstrates
		the simplest trigger model configuration to perform this sweep.

	Parameters:
		sweeplist:		A table of values to source during the sweep
		numPoints:		The number of points to source in the sweep
		limitI:			The current limit of the source in amps
		nplc:			The measurment aperture setting in PLCs where 1 PLC = 1/60 s for 60Hz power

	Example Usage:
		DCSweepVList({3,1,4,5,2}, 5, 0.1, 1)
		DCSweepVList(nil, 12, 0.1, 1)
--]]
function DCSweepVList(sweepList, numPoints, limitI, nplc)
	-- If the user does not include a table of values then generate one.
	if sweepList == nil or type(sweepList) ~= "table" then
		sweepList = {1, 5, 2, 6, 3, 7, 4, 8, 5, 9, 6, 10}
	end
	
	reset()
	
	-- Configure the SMU
	smua.reset()
	smua.source.func					= smua.OUTPUT_DCVOLTS
	smua.source.limiti					= limitI
	smua.measure.nplc					= nplc
	smua.measure.delay					= smua.DELAY_AUTO

	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps	= 1

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.listv(sweepList)
	smua.trigger.source.limiti			= limitI
	smua.trigger.measure.action			= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action		= smua.SOURCE_HOLD
	-- By setting the endsweep action to SOURCE_IDLE, the output will return
	-- to the bias level at the end of the sweep.
	smua.trigger.endsweep.action		= smua.SOURCE_IDLE
	smua.trigger.count					= numPoints
	smua.trigger.source.action			= smua.ENABLE
	-- Ready to begin the test

	smua.source.output					= smua.OUTPUT_ON
	-- Start the trigger model execution
	smua.trigger.initiate()
	-- Wait until the sweep has completed
	waitcomplete()
	smua.source.output					= smua.OUTPUT_OFF
	
	-- Print the data back to the Console in tabular format
	print("Time\tVoltage\tCurrent")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x])
	end
end

--[[
	Name:	DCSweepIList(sweepList, numPoints, limitV, nplc)
	
	Description:
		This function performs an autoranged DC list current sweep.  It demonstrates
		the simplest trigger model configuration to perform this sweep.

	Parameters:
		sweeplist:		A table of values to source during the sweep
		numPoints:		The number of points to source in the sweep
		limitV:			The voltage limit of the source in volts
		nplc:			The measurment aperture setting in PLCs where 1 PLC = 1/60 s for 60Hz power

	Example Usage:
		DCSweepIList({3e-3,1e-3,4e-3,5e-3,2e-3}, 5, 10, 1)
		DCSweepIList(nil, 12, 10, 1)
--]]
function DCSweepIList(sweepList, numPoints, limitV, nplc)
	-- If the user does not include a table of values then generate one.
	if sweepList == nil or type(sweepList) ~= "table" then
		sweepList = {1e-3, 5e-3, 2e-3, 6e-3, 3e-3, 7e-3, 4e-3, 8e-3, 5e-3, 9e-3, 6e-3, 10e-3}
	end
	
	reset()
	
	-- Configure the SMU
	smua.reset()
	smua.source.func					= smua.OUTPUT_DCAMPS
	smua.source.limitv					= limitV
	smua.measure.nplc					= nplc
	smua.measure.delay					= smua.DELAY_AUTO

	-- Prepare the Reading Buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps	= 1
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps	= 1

	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.listi(sweepList)
	smua.trigger.source.limitv			= limitV
	smua.trigger.measure.action			= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action		= smua.SOURCE_HOLD
	-- By setting the endsweep action to SOURCE_IDLE, the output will return
	-- to the bias level at the end of the sweep.
	smua.trigger.endsweep.action		= smua.SOURCE_IDLE
	smua.trigger.count					= numPoints
	smua.trigger.source.action			= smua.ENABLE
	-- Ready to begin the test

	smua.source.output					= smua.OUTPUT_ON
	-- Start the trigger model execution
	smua.trigger.initiate()
	-- Wait until the sweep has completed
	waitcomplete()
	smua.source.output					= smua.OUTPUT_OFF
	
	-- Print the data back to the Console in tabular format
	print("Time\tVoltage\tCurrent")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x])
	end
end
