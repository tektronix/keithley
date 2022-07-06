--[[
	This script provides an example of how the 7707 might be configured as a multi-channel totalizer for 8 
	digital input lines. 
	
	Note: Tested up to 100Hz with repeatable results. It is likely that if more channels are added that this
	repeatable frequency will be lower. 
]]
-- Configure Channel 111 of the 7707 to be 1 bank wide (for 8 lines) set to be inputs
-- Loop for a duration n seconds while continually polling the input lines for state
-- If a rising/fall/either edge is detected update a counter specific to the input 
--    line number. 

dio_0 = 0
dio_0_previous_state = 0
dio_1 = 0
dio_1_previous_state = 0
dio_2 = 0
dio_2_previous_state = 0
dio_3 = 0
dio_3_previous_state = 0
dio_4 = 0
dio_4_previous_state = 0
dio_5 = 0
dio_5_previous_state = 0
dio_6 = 0
dio_6_previous_state = 0
dio_7 = 0
dio_7_previous_state = 0

trans_expected = 0  -- 0 for high to low, 1 for low to high, 2 for either


function Setup_Digital_Inputs(channels)
	channel.setmode(channels, channel.MODE_INPUT)
	channel.setwidth(channels, 1)  -- 1 register wide will give 8 inputs; 2 will give 16; up to 4 for 32 inputs
end

function Get_Initial_Digital_Input_States(channels)
	my_bank = channel.read(channels)
	
	-- set dio_0...
	tmpval = (my_bank[1] & 1)
	if tmpval == 1 then
		dio_0_previous_state = 1
	else
		dio_0_previous_state = 0
	end
	
	-- set dio_1...
	tmpval = (my_bank[1] & 2)
	if tmpval == 1 then
		dio_1_previous_state = 1
	else
		dio_1_previous_state = 0
	end
	
	-- set dio_2...
	tmpval = (my_bank[1] & 4)
	if tmpval == 1 then
		dio_2_previous_state = 1
	else
		dio_2_previous_state = 0
	end
	
	-- set dio_3...
	tmpval = (my_bank[1] & 8)
	if tmpval == 1 then
		dio_3_previous_state = 1
	else
		dio_3_previous_state = 0
	end
	
	-- set dio_4...
	tmpval = (my_bank[1] & 16)
	if tmpval == 1 then
		dio_4_previous_state = 1
	else
		dio_4_previous_state = 0
	end
	
	-- set dio_5...
	tmpval = (my_bank[1] & 32)
	if tmpval == 1 then
		dio_5_previous_state = 1
	else
		dio_5_previous_state = 0
	end
	
	-- set dio_6...
	tmpval = (my_bank[1] & 64)
	if tmpval == 1 then
		dio_6_previous_state = 1
	else
		dio_6_previous_state = 0
	end
	
	-- set dio_7...
	tmpval = (my_bank[1] & 128)
	if tmpval == 1 then
		dio_7_previous_state = 1
	else
		dio_7_previous_state = 0
	end
end

function Totalize_Digital_Inputs(channels, duration)
	timer.cleartime()
	t1 = timer.gettime()
	for j = 0, 1000 do
		my_bank = channel.read(channels)
		
		-- check dio_0...
		tmpval = (my_bank[1] & 1)
		if tmpval == 1 then
			if (trans_expected == 1) and (dio_0_previous_state == 0) then
				dio_0 = dio_0 + 1
			end 
			dio_0_previous_state = 1
		else
			if (trans_expected == 0) and (dio_0_previous_state == 1) then
				dio_0 = dio_0 + 1
			end 
			dio_0_previous_state = 0
		end
		
		-- check dio_1...
		tmpval = (my_bank[1] & 2)
		if tmpval == 2 then
			if (trans_expected == 1) and (dio_1_previous_state == 0) then
				dio_1 = dio_1 + 1
			end 
			dio_1_previous_state = 1
		else
			if (trans_expected == 0) and (dio_1_previous_state == 1) then
				dio_1 = dio_1 + 1
			end 
			dio_1_previous_state = 0
		end
		
		-- check dio_2...
		tmpval = (my_bank[1] & 4)
		if tmpval == 4 then
			if (trans_expected == 1) and (dio_2_previous_state == 0) then
				dio_2 = dio_2 + 1
			end 
			dio_2_previous_state = 1
		else
			if (trans_expected == 0) and (dio_2_previous_state == 1) then
				dio_2 = dio_2 + 1
			end 
			dio_2_previous_state = 0
		end
		
		-- check dio_3...
		tmpval = (my_bank[1] & 8)
		if tmpval == 8 then
			if (trans_expected == 1) and (dio_3_previous_state == 0) then
				dio_3 = dio_3 + 1
			end 
			dio_3_previous_state = 1
		else
			if (trans_expected == 0) and (dio_3_previous_state == 1) then
				dio_3 = dio_3 + 1
			end 
			dio_3_previous_state = 0
		end
		
		-- check dio_4...
		tmpval = (my_bank[1] & 16)
		if tmpval == 16 then
			if (trans_expected == 1) and (dio_4_previous_state == 0) then
				dio_4 = dio_4 + 1
			end 
			dio_4_previous_state = 1
		else
			if (trans_expected == 0) and (dio_4_previous_state == 1) then
				dio_4 = dio_4 + 1
			end 
			dio_4_previous_state = 0
		end
		
		-- check dio_5...
		tmpval = (my_bank[1] & 32)
		if tmpval == 32 then
			if (trans_expected == 1) and (dio_5_previous_state == 0) then
				dio_5 = dio_5 + 1
			end 
			dio_5_previous_state = 1
		else
			if (trans_expected == 0) and (dio_5_previous_state == 1) then
				dio_5 = dio_5 + 1
			end 
			dio_5_previous_state = 0
		end
		
		-- check dio_6...
		tmpval = (my_bank[1] & 64)
		if tmpval == 64 then
			if (trans_expected == 1) and (dio_6_previous_state == 0) then
				dio_6 = dio_6 + 1
			end 
			dio_6_previous_state = 1
		else
			if (trans_expected == 0) and (dio_6_previous_state == 1) then
				dio_6 = dio_6 + 1
			end 
			dio_6_previous_state = 0
		end
		
		-- check dio_7...
		tmpval = (my_bank[1] & 128)
		if tmpval == 128 then
			if (trans_expected == 1) and (dio_7_previous_state == 0) then
				dio_7 = dio_7 + 1
			end 
			dio_7_previous_state = 1
		else
			if (trans_expected == 0) and (dio_7_previous_state == 1) then
				dio_7 = dio_7 + 1
			end 
			dio_7_previous_state = 0
		end
		
		t2 = timer.gettime()
		if ((t2-t1) > duration) then 
			print(t2-t1)
			break
		end
		--print(string.format("\nRun time: %.3f s\n", t2-t1))
	end
end

function Get_Totalizer_Counts()
	return tostring(dio_0) .. "," .. tostring(dio_1) .. "," .. tostring(dio_2) .. "," .. tostring(dio_3) .. "," .. 
			tostring(dio_4) .. "," .. tostring(dio_5) .. "," .. tostring(dio_6) .. "," .. tostring(dio_7)
end

chans = "111"
run_time = 1.0
Setup_Digital_Inputs(chans)
Get_Initial_Digital_Input_States(chans)
Totalize_Digital_Inputs(chans, run_time)
print(Get_Totalizer_Counts())
