--[[
	Title: Combining SMUs for 100A Example
	Description: This script is designed to perform an Rds(on)sweep on a power
	MOSFET device. It combines two 2651A SMUs in parallel to perform a current
	sweep up to 100A. Data collected from the sweep is then returned in a
	Microsoft Excel compatible format for plotting and analysis.
	Equipment needed:
	2x 2651A
	1x 26xxA
	2x TSP-Link Cable
	TSP-Link Configuration:
	-----------------------
	Unit | Node #
	2651A #1 | 1
	2651A #2 | 2
	26xxA | 3
	Master Node (PC Interface): Node 1

	If you are not familiar with high current, consult Keithley Applications Engineering before attempting this test. It could damage you or your equipment.
	
	Written By: Keithley Applications Engineering
]]
--[[
	Name:			DualSmuRdson(gateLevel, dstart, dstop, dsteps, pulseWidth, pulsePeriod, pulseLimit)
	Description:	This function uses two 2651A SMUs to perform a pulsed Rds(on)
	sweep with currents up to 100A.
	Parameters:
		gateLevel:	The gate level to be used during the sweep
		dstart:		The starting current level of the drain sweep
		dstop:		The ending current level of the drain sweep
		dsteps:		The number of steps in the drain sweep
		pulseWidth:	The width of the drain pulse in seconds
		pulsePeriod:The time from the start of one drain pulse to
			the next in seconds
		pulseLimit:	The voltage limit of the drain pulse in volts
			Note: Actual pulse limit will be 10% lower than setting
			to protect SMUs in a compliance condition
	
	Example Usage:
		DualSmuRdson(10, 1, 100, 100, 500e-6, 50e-3, 10)
]]
function DualSmuRdson(gateLevel, dstart, dstop, dsteps, pulseWidth, pulsePeriod, pulseLimit)
	tsplink.reset(3) -- Verify that at least three nodes are present
	reset()
	-- Configure 2651A #1 (Drain SMU 1)
	-----------------------------------
	smua.reset()
	smua.source.func		= smua.OUTPUT_DCAMPS
	smua.sense				= smua.SENSE_REMOTE
	smua.source.offmode		= smua.OUTPUT_NORMAL
	smua.source.offfunc		= smua.OUTPUT_DCVOLTS
	smua.source.offlimiti	= 1e-3 -- Set off limit
	-- SMU #1 will be a 0V voltage source with 1mA limit when its
	-- output is turned off. SMU #2 will be a 0A current source with
	-- a 10V limit when the output is turned off. These settings keep
	-- the parallel combination safe in case one SMU is turned off.
	smua.source.rangei		= math.max(math.abs(dstart / 2), math.abs(dstop / 2))
	smua.source.leveli		= 0 -- Sets the DC bias level
	smua.source.limitv		= 9 -- Sets the DC bias limit
	-- SMU #2 will have a voltage limit of 10V. By setting the voltage
	-- limit 10% lower than that of SMU #2, we can ensure that only
	-- one of the two SMUs will ever go into compliance and become a
	-- voltage source. This is desirable, because if both SMUs went
	-- into compliance, there would be two voltage sources in parallel,
	-- which is an unsafe condition.
	smua.measure.nplc		= 0.005
	smua.measure.rangev		= pulseLimit

	smua.measure.autozero	= smua.AUTOZERO_ONCE
	smua.measure.delay		= pulseWidth - ((1 / localnode.linefreq) * smua.measure.nplc) - 20e-6
	-- Set the delay so that the measurement is near the end of the pulse

	-- Prepare the reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer1.collecttimestamps	= 1
	smua.nvbuffer1.collectsourcevalues	= 1
	smua.nvbuffer1.fillmode				= smua.FILL_ONCE
	smua.nvbuffer2.clear()
	smua.nvbuffer2.collecttimestamps	= 1
	smua.nvbuffer2.collectsourcevalues	= 1
	smua.nvbuffer2.fillmode				= smua.FILL_ONCE

	-- Configure TSP-Link Trigger 1
	tsplink.trigger[1].clear()
	tsplink.trigger[1].mode				= tsplink.TRIG_FALLING
	tsplink.trigger[1].stimulus			= trigger.timer[1].EVENT_ID
	-- TSP-Link Trigger 1 signals 2651A #2 to pulse

	-- Timer 1 controls the pulse period by triggering the pulse to begin
	trigger.timer[1].count			= dsteps - 1
	trigger.timer[1].delay			= pulsePeriod
	trigger.timer[1].passthrough	= true
	trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID
	trigger.timer[1].clear()

	-- Timer 2 controls the pulse width
	trigger.timer[2].count			= 1
	trigger.timer[2].delay			= pulseWidth - 3e-6
	trigger.timer[2].passthrough	= false
	trigger.timer[2].stimulus		= smua.trigger.SOURCE_COMPLETE_EVENT_ID
	trigger.timer[2].clear()

	-- Configure SMU Trigger Model for Sweep
	-- Each unit will source half the current, so divide the start
	-- and stop values by 2
	smua.trigger.source.lineari(dstart / 2, dstop / 2, dsteps)
	smua.trigger.source.limitv		= pulseLimit - (pulseLimit * 0.1)
	-- Again, keep the limit SMU #1 lower than the limit of SMU #2
	-- to prevent parallel V-sources
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.measure.action		= smua.ENABLE
	-- Return to the bias level at the end of the pulse/sweep
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= dsteps
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= 0
	smua.trigger.endpulse.stimulus	= trigger.timer[2].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE

	-- Configure 2651A #2 (Drain SMU 2)
	-----------------------------------
	node[2].smua.reset()
	node[2].smua.source.func		= node[2].smua.OUTPUT_DCAMPS
	node[2].smua.sense				= node[2].smua.SENSE_REMOTE
	node[2].smua.source.offmode		= node[2].smua.OUTPUT_NORMAL
	node[2].smua.source.offfunc		= node[2].smua.OUTPUT_DCAMPS
	node[2].smua.source.offlimitv	= 10 -- Set off limit
	-- SMU will be a 0A current source with 10V limit when output is turned off
	node[2].smua.source.rangei		= math.max(math.abs(dstart / 2), math.abs(dstop / 2))
	node[2].smua.source.leveli		= 0 -- Sets the DC bias level
	node[2].smua.source.limitv		= 10 -- Sets the DC bias limit
	node[2].smua.measure.nplc		= 0.005
	node[2].smua.measure.rangev		= pulseLimit
	node[2].smua.measure.autozero	= node[2].smua.AUTOZERO_ONCE
	node[2].smua.measure.delay		= (pulseWidth -	((1 / node[2].linefreq) * node[2].smua.measure.nplc)) - 20e-6

	-- Set the delay so that the measurement is near the end of the pulse
	-- Prepare the reading buffers
	node[2].smua.nvbuffer1.clear()
	node[2].smua.nvbuffer1.collecttimestamps	= 1
	node[2].smua.nvbuffer1.collectsourcevalues	= 1
	node[2].smua.nvbuffer1.fillmode				= node[2].smua.FILL_ONCE
	node[2].smua.nvbuffer2.clear()
	node[2].smua.nvbuffer2.collecttimestamps	= 1
	node[2].smua.nvbuffer2.collectsourcevalues	= 1
	node[2]. smua.nvbuffer2.fillmode			= node[2].smua.FILL_ONCE

	-- Configure TSP-Link Trigger 1
	node[2].tsplink.trigger[1].clear()
	node[2].tsplink.trigger[1].mode				= node[2].tsplink.TRIG_FALLING

	-- Timer 1 controls the pulse width
	node[2].trigger.timer[1].count				= 1
	node[2].trigger.timer[1].delay				= pulseWidth - 3e-6
	node[2].trigger.timer[1].passthrough		= false
	node[2].trigger.timer[1].stimulus			= node[2].smua.trigger.SOURCE_COMPLETE_EVENT_ID
	node[2].trigger.timer[1].clear()

	-- Configure SMU Trigger Model for Sweep
	node[2].smua.trigger.source.lineari(dstart / 2, dstop / 2, dsteps)
	node[2].smua.trigger.source.limitv			= pulseLimit
	node[2].smua.trigger.measure.iv(node[2].smua.nvbuffer1, node[2].smua.nvbuffer2)
	node[2].smua.trigger.measure.action			= node[2].smua.ENABLE

	-- Return the output to the bias level at the end of the pulse/sweep
	node[2].smua.trigger.endpulse.action		= node[2].smua.SOURCE_IDLE
	node[2].smua.trigger.endsweep.action		= node[2].smua.SOURCE_IDLE
	node[2].smua.trigger.count					= dsteps
	node[2].smua.trigger.arm.stimulus			= 0
	node[2].smua.trigger.source.stimulus		= node[2].tsplink.trigger[1].EVENT_ID
	node[2].smua.trigger.measure.stimulus		= 0
	node[2].smua.trigger.endpulse.stimulus		= node[2].trigger.timer[1].EVENT_ID
	node[2].smua.trigger.source.action			= node[2].smua.ENABLE

	-- Configure the 26xxA (Gate SMU)
	---------------------------------
	node[3].smua.reset()
	node[3].smua.source.func			= node[3].smua.OUTPUT_DCVOLTS
	node[3].smua.sense					= node[3].smua.SENSE_REMOTE
	node[3].smua.source.levelv			= gateLevel
	node[3].smua.source.highc			= node[3].smua.ENABLE
	-- If you find your gate oscillating even with a dampening resistor
	-- in place, try enabling high-C mode to help stabilize the gate.

	-- Prepare the reading buffers
	node[3].smua.nvbuffer1.clear()
	node[3].smua.nvbuffer1.collectsourcevalues	= 1
	if node[3].smua.nvbuffer1.fillmode ~= nil then
		node[3].smua.nvbuffer1.fillmode = node[3].smua.FILL_ONCE
	end
	node[3].smua.nvbuffer2.clear()
	node[3].smua.nvbuffer2.collectsourcevalues	= 1
	if node[3].smua.nvbuffer2.fillmode ~= nil then
		node[3].smua.nvbuffer2.fillmode = node[3].smua.FILL_ONCE
	end
	--------------------------
	-- Ready to begin the test
	--------------------------
	-- Outputs on
	node[3].smua.source.output		= node[3].smua.OUTPUT_ON
	node[2].smua.source.output		= node[2].smua.OUTPUT_ON
	smua.source.output				= smua.OUTPUT_ON
	if errorqueue.count > 0 then
		print(�Errors were encountered�)
		reset()
		return
	end

	-- Give the gate some time to settle before starting the sweep
	delay(0.001)
	node[3].smua.measure.iv(node[3].smua.nvbuffer1, node[3].smua.nvbuffer2)
	-- Start the 2651A #2 trigger model
	node[2].smua.trigger.initiate()
	-- Start the 2651A #1 trigger model
	smua.trigger.initiate()
	-- Wait until test is complete
	waitcomplete()
	-- Outputs off
	node[3].smua.source.output = node[3].smua.OUTPUT_OFF
	smua.source.output = smua.OUTPUT_OFF
	node[2].smua.source.output = node[2].smua.OUTPUT_OFF
	-- Print back data
	PrintDualSmuRdsonData()
end

--[[
	Function:	PrintDualSmuRdsonData()
	Description:
		This function processes the data stored in the SMU reading buffers by
	function DualSmuRdson() and prints back the individual SMU data and the
	combined SMU data and Rds(on) readings in a format that is copy and paste
	compatible with Microsoft Excel.
]]
function PrintDualSmuRdsonData()
	-- Print the gate SMU readings
	print("Gate SMU\r\nSource Value\tVoltage\tCurrent")
	print(string.format("%0.2f\t%g\t%g\r\n", node[3].smua.nvbuffer1.sourcevalues[1], node[3].smua.nvbuffer2[1], node[3].smua.nvbuffer1[1]))

	-- Print column headers
	print("Timestamp\tSource Value\tVoltage 1\tCurrent 1\tVoltage 2\tCurrent 2\tVoltage\tCurrent\tRds(on)")
	-- Loop through the reading buffer printing one row at a time
	for i = 1,smua.nvbuffer1.n do
		-- Combined Source Level = SMU1 source level + SMU2 source level
		sourceLevel = smua.nvbuffer1.sourcevalues[i] + node[2].smua.nvbuffer1.sourcevalues[i]
		-- Combined Voltage = Average(SMU1 Voltage reading, SMU2 Voltage reading)
		combinedVoltage = (smua.nvbuffer2[i] + node[2].smua.nvbuffer2[i]) / 2
		-- Combined Current = SMU1 Current reading + SMU2 Current reading
		combinedCurrent = smua.nvbuffer1[i] + node[2].smua.nvbuffer1[i]
		-- Rds(on) = Combined Voltage / Combined Current
		rdson = combinedVoltage / combinedCurrent
		-- Print a row of data
		print(string.format("%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g\t%g", smua.nvbuffer1.timestamps[i], sourceLevel, smua.nvbuffer2[i], smua.nvbuffer1[i], node[2].smua.nvbuffer2[i], node[2].smua.nvbuffer1[i], combinedVoltage, combinedCurrent, rdson))
	end
end