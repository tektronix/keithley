

--  *************************  Main Program Here **********************
reset()

local Current_Amplitude = 10e-3
local Current_DC_offset = 0
local Max_Voltage = 20
local Desired_Freq = 10  -- Hz of the sine wave
local NumPointsPerCycle = 36
local NumberOfCycles = 1
local smu_iRange = (Current_DC_offset + Current_Amplitude)/2  -- divide by 2?
local build_list = true
local build_list_name = "SINE_SOURCE_LIST"


--config_smu(src_level, voltage_limit)
config_smu_fimv(smu_iRange, Max_Voltage)  

if build_list then
     --build_sine_config_list(Arms, DCOffset, PtsPerCycle)
     build_sine_config_list(Current_Amplitude, Current_DC_offset, NumPointsPerCycle, build_list_name)
end -- if

-- update number of points for actual size of source config list
number_of_pts = smu.source.configlist.size("SINE_SOURCE_LIST")


--config_sine_wave_timer(frequency, PtsPerCycle, numCycles)
config_sine_wave_timer(Desired_Freq, NumPointsPerCycle, NumberOfCycles)

--config_trigger_model(number_src_pts, ListName)
config_trigger_model(number_of_pts * NumberOfCycles, build_list_name)

display.changescreen(display.SCREEN_GRAPH_SWIPE)


trigger.model.initiate()

waitcomplete()
-- assert SRQ ??

printData = true

if printData == true then
--Print Results
if defbuffer1.n == 0 then
	print("Buffer is empty\n")
else
	print("TimeStamp\tCurrent\tVoltage")
	for i=1,defbuffer1.n do
		print(string.format("%g\t%g\t%g", defbuffer1.relativetimestamps[i], defbuffer1.sourcevalues[i], defbuffer1.readings[i]))
	end
end
end  -- if

