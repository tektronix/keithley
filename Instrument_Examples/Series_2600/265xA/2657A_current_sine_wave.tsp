--[[

   model:  Keithley Instruments Inc.,Model 2657A,4098545,1.1.8
   
   Purpose:  generate a current sinewave with DC offset
   


]]


-- Helper functions

function compute_waveform_cycle(Arms, DCOffset, PtsPerCycle)

	-- Generate the source values
	--local Vpp				= Vrms * math.sqrt(2) / 2

	for i=1, PtsPerCycle do  --numDataPoints do
		sourceValues[i]		= (Arms/2 * math.sin(i * 2 * math.pi / PtsPerCycle)) + DCOffset
	end
	
end  -- function


function config_timer(smu, frequency, PtsPerCycle, numCycles)

       trigger.timer[1].delay = (1/frequency) / PtsPerCycle
       trigger.timer[1].stimulus = smu.trigger.ARMED_EVENT_ID
       trigger.timer[1].count = PtsPerCycle * numCycles
       trigger.timer[1].passthrough = false
       trigger.timer[1].clear()

end -- function


function config_smu(smu, IRange, limitV, numCycles, remoteSense)


-- config a fixed range list sweep
	smu.source.func					= smu.OUTPUT_DCAMPS
		
	if (remoteSense == true) then
		smu.sense					= smu.SENSE_REMOTE
	else
		smu.sense					= smu.SENSE_LOCAL
	end
	smu.source.autorangei			= smu.AUTORANGE_OFF
	smu.source.rangei				= IRange  
	smu.source.leveli				= 0
	smu.source.limitv				= limitV

	-- allow limited auto ranging
	smu.measure.autozero			= smu.AUTOZERO_ONCE
	smu.measure.autorangei			= smu.AUTORANGE_OFF
	smu.measure.rangei				= smu.source.rangei
	smu.measure.autorangev          = smu.AUTORANGE_OFF
	smu.measure.rangev				= smu.source.limitv   -- measure range to follow source limit
	smu.measure.nplc				= 0.001  --nplc
	smu.measure.delay				= 0
	
	-- Configure SMU Trigger Model for Sweep
	smu.trigger.source.listi(sourceValues)   -- sourceValues is global table
	smu.trigger.source.limitv		= limitV
	smu.trigger.measure.action		= smu.ENABLE
	smu.trigger.measure.iv(smu.nvbuffer1, smu.nvbuffer2)
	smu.trigger.endpulse.action		= smu.SOURCE_HOLD
	smu.trigger.endsweep.action		= smu.SOURCE_IDLE
	smu.trigger.count				= table.getn(sourceValues) * numCycles
	smu.trigger.arm.stimulus		= 0
	smu.trigger.source.stimulus		= trigger.timer[1].EVENT_ID
	smu.trigger.measure.stimulus	= 0  
	smu.trigger.endpulse.stimulus	= 0  
	smu.trigger.source.action		= smu.ENABLE

end  -- function



function reset_buffers(smu)
    	-- Prepare the Reading Buffers
	smu.nvbuffer1.clear()
	smu.nvbuffer1.appendmode		= 1
	smu.nvbuffer1.collecttimestamps	= 1
	smu.nvbuffer2.clear()
	smu.nvbuffer2.appendmode		= 1
	smu.nvbuffer2.collecttimestamps	= 1

end



--  ******************  Main Program  *****************

reset()
errorqueue.clear()


local numberCyclesToPlay = 2
local sineWaveFreq = 100
local numberPtsPerCycle = 60
local AC_waveform_height = 0.5
local DC_offset = 0
local VoltageLimit = 40

local smu_iRange = DC_offset + AC_waveform_height  -- divide by 2?

sourceValues = {}  -- empty table, global var

--compute_waveform_cycle(Vrms, DCOffset, PtsPerCycle)
compute_waveform_cycle(AC_waveform_height, DC_offset, numberPtsPerCycle)

--[[
for i = 1, table.getn(sourceValues) do
   print(sourceValues[i])
end  -- for loop
]]

--config_timer(smu, frequency, PtsPerCycle, numCycles)
config_timer(smua, sineWaveFreq, numberPtsPerCycle, numberCyclesToPlay)

--config_smu(smu, IRange, limitV, numCycles, remoteSense)
config_smu(smua, smu_iRange, VoltageLimit, numberCyclesToPlay, false)


   -- clear the reading buffers
   reset_buffers(smua)

 

	-- Turn the outputs on
	smua.source.output					= smua.OUTPUT_ON


	-- Start the trigger model execution
	smua.trigger.initiate()  
	
	-- Wait until the sweep has completed
	waitcomplete()
	
	delay(0.1) 
	
	smua.source.output					= smua.OUTPUT_OFF
	
	  show_data = true
	  if show_data == true then
		   -- Print the data back to the Console in tabular format
	   print("Time\tVoltage\tCurrent")
	   for x=1,smua.nvbuffer1.n do
		  -- Voltage readings are in nvbuffer2.  Current readings are in nvbuffer1.
		  print(smua.nvbuffer1.timestamps[x], smua.nvbuffer2[x], smua.nvbuffer1[x])
	   end
     end  -- if
     
-- on exit, free the memory used by table
sourceValues = nil