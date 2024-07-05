--[[
	Title:			KE26XXB Pulsed Sweep Quad

	Description:	This example demonstrates how to synchronize pulsed
		sweeps between multiple SMU channels on multiple Series 2600B
		SourceMeter instruments.  It is written to control four SMU
		channels within two dual channels Series 2600B SourceMeter
		instruments and can easily be expanded to support additional
		Series 2600B SourceMeter instruments.  This example script
		performs linear sweeps but can easily be modified to perform log
		or list sweeps.  It also programs all SMUs to source the same
		levels however, this can also easily be modified for each SMU to
		output different levels.
		There are two functions contained in this script.  One function
		performs pulsed voltage sweeps while the other performs pulsed
		current sweeps.
		At the conclusion of the sweeps the data is returned to the
		instrument console in a format that is compatible for copy and
		paste into Microsoft Excel.

	Equipment Needed:
		2x Dual Channel Series 2600B SourceMeter instruments

	TSP-Link Configuration:
		26XXB #1: Node 1 (Master Node)
		26XXB #2: Node 2

	Script Functions:
		PulsedSweepVQuad(start, stop, numPoints, pulseWidth, pulsePeriod, limitI, nplc, remoteSense)
		PulsedSweepIQuad(start, stop, numPoints, pulseWidth, pulsePeriod, limitV, nplc, remoteSense)
]]

---# Description:
---This function performs synchronized pulsed linear voltage sweeps
---on four SMU channels across two dual channel Series 2600B
---SourceMeter instruments.
---
---# Parameters:
---@param start number The voltage level of the first step in the sweep in volts
---@param stop number The voltage level of the last step in the sweep in volts
---@param numPoints integer The number of points in the sweep
---@param pulseWidth number The width of the pulse in seconds
---@param pulsePeriod number The time from the start of one pulse to the start of the next pulse
---@param limitI number The current limit of the pulse in amps
---@param nplc number The measurment aperture setting in PLCs where 1 PLC = 1/60 s for 60Hz power
---@param remoteSense boolean Set to true to enable 4-Wire (Kelvin) measurements or to false for 2-Wire measurements
---
---# Notes:
---After calling this function you will need to press the TRIG button
---on the instrument's front panel to trigger the sweep to start.
---The code can easily be modified to trigger off other sources as
---well.
---
---# Example Usage:
---```lua
---PulsedSweepVQuad(0, 10, 11, 1e-3, 5e-3, 0.1, 0.001, false)
---```
function PulsedSweepVQuad(start, stop, numPoints, pulseWidth, pulsePeriod, limitI, nplc, remoteSense)
	-- Reset the TSP-Link if it is offline
	if tsplink.state == "offline" then
		local nodesFound = tsplink.reset()
		if nodesFound ~= 2 then
			print(string.format("Error: Found %d Nodes. Expecting 2.", nodesFound))
			exit()
		end
	end

	reset()

	-- Configure SMUs
	ConfigVSMU(node[1], node[1].smua, start, stop, numPoints, limitI, nplc, remoteSense)
	ConfigVSMU(node[1], node[1].smub, start, stop, numPoints, limitI, nplc, remoteSense)
	ConfigVSMU(node[2], node[2].smua, start, stop, numPoints, limitI, nplc, remoteSense)
	ConfigVSMU(node[2], node[2].smub, start, stop, numPoints, limitI, nplc, remoteSense)

	-- Configure the Trigger Model
	--============================
	-- Pressing the TRIG button on the front panel will trigger the sweep to start
	display.trigger.clear()

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numPoints > 1 and numPoints - 1 or 1
	trigger.timer[1].delay			= pulsePeriod
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= display.trigger.EVENT_ID

	-- Timer 2 controls the measure delay
	trigger.timer[2].count			= 1
	-- Set the measure delay long enough so that measurements start after the pulse
	-- has settled, but short enough that it fits within the width of the pulse.
	trigger.timer[2].delay			= pulseWidth - (1/localnode.linefreq)*nplc - 60e-6
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= trigger.timer[1].EVENT_ID

	-- Timer 3 controls the pulse width
	trigger.timer[3].count			= 1
	trigger.timer[3].delay			= pulseWidth
	trigger.timer[3].passthrough	= false
	trigger.timer[3].stimulus		= trigger.timer[1].EVENT_ID

	-- The TSP-Link triggers are used to synchronize the two instruments
	ConfigTSPLinkTriggers(node[1])
	ConfigTSPLinkTriggers(node[2])

	-- The Master Node sends out the TSP-Link triggers so its TSP-Link
	-- triggers need a stimulus.
	tsplink.trigger[1].stimulus	= trigger.timer[1].EVENT_ID
	tsplink.trigger[2].stimulus	= trigger.timer[2].EVENT_ID
	tsplink.trigger[3].stimulus	= trigger.timer[3].EVENT_ID

	-- SMU trigger models were configured in ConfigVSMU()

	--==============================
	-- End Trigger Model Configuration

	-- Turn the outputs on
	smua.source.output					= smua.OUTPUT_ON
	smub.source.output					= smub.OUTPUT_ON
	node[2].smua.source.output			= node[2].smua.OUTPUT_ON
	node[2].smub.source.output			= node[2].smub.OUTPUT_ON

	-- Start the trigger model execution
	smua.trigger.initiate()
	smub.trigger.initiate()
	node[2].smua.trigger.initiate()
	node[2].smub.trigger.initiate()
	-- Sweep will not start until the TRIG button is pressed

	-- Wait until the sweep has completed
	waitcomplete()

	-- Turn the output off
	smua.source.output					= smua.OUTPUT_OFF
	smub.source.output					= smub.OUTPUT_OFF
	node[2].smua.source.output			= node[2].smua.OUTPUT_OFF
	node[2].smub.source.output			= node[2].smub.OUTPUT_OFF

	-- Print the data back to the Console in tabular format
	print("Node 1 SMUA Voltage\tNode 1 SMUA Current\tNode 1 SMUB Voltage\tNode 1 SMUB Current\tNode 2 SMUA Voltage\tNode 2 SMUA Current\tNode 2 SMUB Voltage\tNode 2 SMUB Current")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer2[x], smua.nvbuffer1[x], smub.nvbuffer2[x], smub.nvbuffer1[x], node[2].smua.nvbuffer2[x], node[2].smua.nvbuffer1[x], node[2].smub.nvbuffer2[x], node[2].smub.nvbuffer1[x])
	end
end

---# Description
---
---This function performs synchronized pulsed linear current sweeps
---on four SMU channels across two dual channel Series 2600B
---SourceMeter instruments.
---
---# Parameters
---
---@param start number	The current level of the first step in the sweep in amps
---@param stop	number The current level of the last step in the sweep in amps
---@param numPoints integer The number of points in the sweep
---@param pulseWidth number The width of the pulse in seconds
---@param pulsePeriod number The time from the start of one pulse to the start of the next pulse
---@param limitV number The voltage limit of the pulse in volts
---@param nplc	 number	The measurment aperture setting in PLCs where 1 PLC = 1/60 s for 60Hz power
---@param remoteSense boolean Set to true to enable 4-Wire (Kelvin) measurements or to false for 2-Wire measurements
---
---# Notes
---
---After calling this function you will need to press the TRIG button
---on the instrument's front panel to trigger the sweep to start.
---The code can easily be modified to trigger off other sources as
---well.
---
---# Usage
---
---```lua
---PulsedSweepIQuad(0, 10e-3, 11, 1e-3, 5e-3, 10, 0.001, false)
---```
---
function PulsedSweepIQuad(start, stop, numPoints, pulseWidth, pulsePeriod, limitV, nplc, remoteSense)
	-- Reset the TSP-Link if it is offline
	if tsplink.state == "offline" then
		NodesFound = tsplink.reset()
		if NodesFound ~= 2 then
			print(string.format("Error: Found %d Nodes. Expecting 2.", NodesFound))
			exit()
		end
	end

	reset()

	-- Configure SMUs
	ConfigISMU(node[1], node[1].smua, start, stop, numPoints, limitV, nplc, remoteSense)
	ConfigISMU(node[1], node[1].smub, start, stop, numPoints, limitV, nplc, remoteSense)
	ConfigISMU(node[2], node[2].smua, start, stop, numPoints, limitV, nplc, remoteSense)
	ConfigISMU(node[2], node[2].smub, start, stop, numPoints, limitV, nplc, remoteSense)

	-- Configure the Trigger Model
	--============================
	-- Pressing the TRIG button on the front panel will trigger the sweep to start
	display.trigger.clear()

	-- Timer 1 controls the pulse period
	trigger.timer[1].count			= numPoints > 1 and numPoints - 1 or 1
	trigger.timer[1].delay			= pulsePeriod
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= display.trigger.EVENT_ID

	-- Timer 2 controls the measure delay
	trigger.timer[2].count			= 1
	-- Set the measure delay long enough so that measurements start after the pulse
	-- has settled, but short enough that it fits within the width of the pulse.
	trigger.timer[2].delay			= pulseWidth - (1/localnode.linefreq)*nplc - 60e-6
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= trigger.timer[1].EVENT_ID

	-- Timer 3 controls the pulse width
	trigger.timer[3].count			= 1
	trigger.timer[3].delay			= pulseWidth
	trigger.timer[3].passthrough	= false
	trigger.timer[3].stimulus		= trigger.timer[1].EVENT_ID

	-- The TSP-Link triggers are used to synchronize the two instruments
	ConfigTSPLinkTriggers(node[1])
	ConfigTSPLinkTriggers(node[2])

	-- The Master Node sends out the TSP-Link triggers so its TSP-Link
	-- triggers need a stimulus.
	tsplink.trigger[1].stimulus	= trigger.timer[1].EVENT_ID
	tsplink.trigger[2].stimulus	= trigger.timer[2].EVENT_ID
	tsplink.trigger[3].stimulus	= trigger.timer[3].EVENT_ID

	-- SMU trigger models were configured in ConfigVSMU()

	--==============================
	-- End Trigger Model Configuration

	-- Turn the outputs on
	smua.source.output					= smua.OUTPUT_ON
	smub.source.output					= smub.OUTPUT_ON
	node[2].smua.source.output			= node[2].smua.OUTPUT_ON
	node[2].smub.source.output			= node[2].smub.OUTPUT_ON

	-- Start the trigger model execution
	smua.trigger.initiate()
	smub.trigger.initiate()
	node[2].smua.trigger.initiate()
	node[2].smub.trigger.initiate()
	-- Sweep will not start until the TRIG button is pressed

	-- Wait until the sweep has completed
	waitcomplete()

	-- Turn the output off
	smua.source.output					= smua.OUTPUT_OFF
	smub.source.output					= smub.OUTPUT_OFF
	node[2].smua.source.output			= node[2].smua.OUTPUT_OFF
	node[2].smub.source.output			= node[2].smub.OUTPUT_OFF

	-- Print the data back to the Console in tabular format
	print("Node 1 SMUA Voltage\tNode 1 SMUA Current\tNode 1 SMUB Voltage\tNode 1 SMUB Current\tNode 2 SMUA Voltage\tNode 2 SMUA Current\tNode 2 SMUB Voltage\tNode 2 SMUB Current")
	for x=1,smua.nvbuffer1.n do
		-- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		print(smua.nvbuffer2[x], smua.nvbuffer1[x], smub.nvbuffer2[x], smub.nvbuffer1[x], node[2].smua.nvbuffer2[x], node[2].smua.nvbuffer1[x], node[2].smub.nvbuffer2[x], node[2].smub.nvbuffer1[x])
	end
end

-- =================
-- Utility functions
-- =================

---@param trig_smu model2636B | nodeArr
---@param smu smua | smub
---@param start number
---@param stop number
---@param numPoints integer
---@param limitI number
---@param nplc number
---@param remoteSense boolean
---
---#Usage
---```lua
---ConfigVSMU(node[1], node[1].smua, 1.0, 10.0, 100, 0.005, 0.6, true)
---```
function ConfigVSMU(trig_smu, smu, start, stop, numPoints, limitI, nplc, remoteSense)
	smu.reset()
	smu.source.func					= smu.OUTPUT_DCVOLTS
	if (remoteSense == true) then
		smu.sense					= smu.SENSE_REMOTE
	else
		smu.sense					= smu.SENSE_LOCAL
	end
	smu.source.autorangev			= smu.AUTORANGE_OFF
	smu.source.rangev				= math.max(math.abs(start), math.abs(stop))
	smu.source.levelv				= 0
	-- Set the DC bias limit.  This is not the limit used during the pulses.
	smu.source.limiti				= 0.1

	-- Disabling Auto-Ranging and Auto-Zero ensures accurate and consistent timing
	smu.measure.autozero			= smu.AUTOZERO_ONCE
	smu.measure.autorangei			= smu.AUTORANGE_OFF
	smu.measure.rangei				= limitI
	smu.measure.nplc				= nplc
	-- A timer will be used to set the measure delay and synchronize the measurement
	-- between the SMUs so set the built in delay to 0.
	smu.measure.delay				= 0
	
	-- Prepare the Reading Buffers
	smu.nvbuffer1.clear()
	smu.nvbuffer1.appendmode		= 1
	smu.nvbuffer1.collecttimestamps	= 1
	smu.nvbuffer2.clear()
	smu.nvbuffer2.appendmode		= 1
	smu.nvbuffer2.collecttimestamps	= 1

	-- Configure SMU Trigger Model for Sweep
	smu.trigger.source.linearv(start, stop, numPoints)
	smu.trigger.source.limiti		= limitI
	smu.trigger.measure.action		= smu.ENABLE
	smu.trigger.measure.iv(smu.nvbuffer1, smu.nvbuffer2)
	smu.trigger.endpulse.action		= smu.SOURCE_IDLE
	smu.trigger.endsweep.action		= smu.SOURCE_IDLE
	smu.trigger.count				= numPoints
	smu.trigger.arm.stimulus		= 0
	smu.trigger.source.stimulus		= trig_smu.tsplink.trigger[1].EVENT_ID
	smu.trigger.measure.stimulus	= trig_smu.tsplink.trigger[2].EVENT_ID
	smu.trigger.endpulse.stimulus	= trig_smu.tsplink.trigger[3].EVENT_ID
	smu.trigger.source.action		= smu.ENABLE
end

---@param trig_smu model2636B | nodeArr
---@param smu smua | smub
---@param start number
---@param stop number
---@param numPoints integer
---@param limitV number
---@param nplc number
---@param remoteSense boolean
---
---#Usage
---```lua
---ConfigVSMU(node[1], node[1].smua, 1.0, 10.0, 100, 0.005, 0.6, true)
---```
function ConfigISMU(trig_smu, smu, start, stop, numPoints, limitV, nplc, remoteSense)
	smu.reset()
	smu.source.func					= smu.OUTPUT_DCAMPS
	if (remoteSense == true) then
		smu.sense					= smu.SENSE_REMOTE
	else
		smu.sense					= smu.SENSE_LOCAL
	end
	smu.source.autorangei			= smu.AUTORANGE_OFF
	smu.source.rangei				= math.max(math.abs(start), math.abs(stop))
	smu.source.leveli				= 0
	-- Set the DC bias limit.  This is not the limit used during the pulses.
	smu.source.limitv				= 1

	-- Disabling Auto-Ranging and Auto-Zero ensures accurate and consistent timing
	smu.measure.autozero			= smu.AUTOZERO_ONCE
	smu.measure.autorangev			= smu.AUTORANGE_OFF
	smu.measure.rangev				= limitV
	smu.measure.nplc				= nplc
	-- A timer will be used to set the measure delay and synchronize the measurement
	-- between the SMUs so set the built in delay to 0.
	smu.measure.delay				= 0
	
	-- Prepare the Reading Buffers
	smu.nvbuffer1.clear()
	smu.nvbuffer1.appendmode		= 1
	smu.nvbuffer1.collecttimestamps	= 1
	smu.nvbuffer2.clear()
	smu.nvbuffer2.appendmode		= 1
	smu.nvbuffer2.collecttimestamps	= 1

	-- Configure SMU Trigger Model for Sweep
	smu.trigger.source.lineari(start, stop, numPoints)
	smu.trigger.source.limitv		= limitV
	smu.trigger.measure.action		= smu.ENABLE
	smu.trigger.measure.iv(smu.nvbuffer1, smu.nvbuffer2)
	smu.trigger.endpulse.action		= smu.SOURCE_IDLE
	smu.trigger.endsweep.action		= smu.SOURCE_IDLE
	smu.trigger.count				= numPoints
	smu.trigger.arm.stimulus		= 0
	smu.trigger.source.stimulus		= trig_smu.tsplink.trigger[1].EVENT_ID
	smu.trigger.measure.stimulus	= trig_smu.tsplink.trigger[2].EVENT_ID
	smu.trigger.endpulse.stimulus	= trig_smu.tsplink.trigger[3].EVENT_ID
	smu.trigger.source.action		= smu.ENABLE
end

---Configure the TSP-Link triggers for the given node index. 
---@param triggerNode model2636B | nodeArr
---
---*Example*
---```lua
---ConfigTSPLinkTriggers(node[1])
---```
function ConfigTSPLinkTriggers(triggerNode)
	assert(triggerNode ~= nil, "attempt to reference a node that is a nil value")
	assert(triggerNode.tsplink ~= nil, "attempt to set a tsplink trigger on a node that doesn't have tsplink triggering support")

	triggerNode.tsplink.trigger[1].clear()
	triggerNode.tsplink.trigger[1].mode		= tsplink.TRIG_FALLING
	triggerNode.tsplink.trigger[2].clear()
	triggerNode.tsplink.trigger[2].mode		= tsplink.TRIG_FALLING
	triggerNode.tsplink.trigger[3].clear()
	triggerNode.tsplink.trigger[3].mode		= tsplink.TRIG_FALLING

end
