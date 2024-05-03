--[[
	CheckForOverRun(pNode)
	
	This script contains a function that scans the 26XXA status model to
	detect an overrun condition in the trigger model.  If no overrun is
	detected, the function returns false.  If overrun is detected, the
	function returns true along with a message describing the overrun.

	The Overrun attribute is not available on the Models 2604B/2614B/2634B.

	Parameters:
		pNode:		The node whose status model to scan.  For the SMU
		executing the script use localnode for pNode.
]]

function CheckForOverRun(pNode)
	-- Check SMUA Trigger Overruns
	if (bit.bitand(pNode.status.operation.instrument.smua.trigger_overrun.condition, 2) == 2) then
		return true, "smua arm trigger is overrun"
	end
	if (bit.bitand(pNode.status.operation.instrument.smua.trigger_overrun.condition, 4) == 4) then
		return true, "smua source trigger is overrun"
	end
	if (bit.bitand(pNode.status.operation.instrument.smua.trigger_overrun.condition, 8) == 8) then
		return true, "smua measure trigger is overrun"
	end
	if (bit.bitand(pNode.status.operation.instrument.smua.trigger_overrun.condition, 16) == 16) then
		return true, "smua endpulse trigger is overrun"
	end

--[[
	-- Check SMUB Trigger Overruns
	if (bit.bitand(status.operation.instrument.smub.trigger_overrun.condition, 2) == 2) then
		return true, "smub arm trigger is overrun"
	end	
	if (bit.bitand(status.operation.instrument.smub.trigger_overrun.condition, 4) == 4) then
		return true, "smub source trigger is overrun"
	end
	if (bit.bitand(status.operation.instrument.smub.trigger_overrun.condition, 8) == 8) then
		return true, "smub measure trigger is overrun"
	end
	if (bit.bitand(status.operation.instrument.smub.trigger_overrun.condition, 16) == 16) then
		return true, "smub endpulse trigger is overrun"
	end
--]]

	local CFORi = 0
	-- Check Timers for Overrun
	if (pNode.status.operation.instrument.trigger_timer.trigger_overrun.condition > 0) then
		return true, string.format("Timer trigger is overrun: 0x%x", CFORi)
	end
	
	-- Check Blenders for Overrun
	if (pNode.status.operation.instrument.trigger_blender.trigger_overrun.condition > 0) then
		return true, string.format("blender trigger is overrun: 0x%x", CFORi)
	end

	-- Check TSP-Link Triggers for Overrun
	if (pNode.status.operation.instrument.tsplink.trigger_overrun.condition > 0) then
		return true, string.format("TSP-Link trigger is overrun: 0x%x", CFORi)
	end

	-- Check DIGIO Triggers for Overrun
	if (pNode.status.operation.instrument.digio.trigger_overrun.condition > 0) then
		return true, string.format("digio trigger is overrun: 0x%x", CFORi)
	end

	-- Check LAN Triggers for Overrun
	if (pNode.status.operation.instrument.lan.trigger_overrun.condition > 0) then
		return true, string.format("LAN trigger is overrun: 0x%x", CFORi)
	end

	return false, "no overrun detected"
end