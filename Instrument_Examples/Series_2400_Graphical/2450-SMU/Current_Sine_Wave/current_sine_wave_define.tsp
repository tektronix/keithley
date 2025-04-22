--[[

KEITHLEY INSTRUMENTS,MODEL 2450,04407385,1.7.16a

Purpose:  custom version of smu.source.sweeplinear()
          for generation of current sine wave


]]



--[[

    config_smu_fimv():
       config SMU to force current and measure voltage (FIMV)
       Forcing current has corresponding Voltage Compliance Limit
]]

function config_smu_fimv(src_level, voltage_limit)

     -- set active source function and complaince limit
     smu.source.func = smu.FUNC_DC_CURRENT
     smu.measure.func = smu.FUNC_DC_VOLTAGE
     
     --set fixed ranges based on limits and source level
     smu.source.vlimit.level  = voltage_limit
     smu.measure.range = voltage_limit
     
     smu.source.range = src_level
     smu.source.readback = smu.OFF
     smu.source.autodelay = smu.OFF
     smu.source.delay = 0
     
     -- for sine wave generation, we want to go fast.
     -- set for minimum measure time, auto zero off
     smu.measure.nplc = 0.01
     smu.measure.autozero.enable = smu.OFF
     
     
    
     -- for debug only, we can strobe a digital bit on the DB9
     -- for monitoring with scope.
     --setup digital output line you want to monitor
     dig_line = 1
     digio.line[dig_line].mode = digio.MODE_TRIGGER_OUT
     trigger.digout[dig_line].pulsewidth = 100e-6
     trigger.digout[dig_line].stimulus   = trigger.EVENT_NOTIFY2
     -- end setup digital output
     

end  -- function

function build_sine_config_list(Arms, DCOffset, PtsPerCycle, ListName)

     -- when building list, turn the output off else the source values will occur at the output
  if smu.source.output == smu.ON then
     smu.source.output = smu.OFF
  end -- if
     

     --smu.source.configlist.delete(ListName)  -- if exists, delete it?
     smu.source.configlist.create(ListName)  
     
     for i = 1, PtsPerCycle do
		smu.source.level = (Arms/2 * math.sin(i * 2 * math.pi / PtsPerCycle)) + DCOffset
		smu.source.configlist.store(ListName)  
	 end

end  -- function




function config_sine_wave_timer(frequency, PtsPerCycle, numCycles)

     -- Timer to control source value writing rate
     local N = 1
     trigger.timer[N].enable = 0
     trigger.timer[N].reset()
     trigger.timer[N].clear()
     trigger.timer[N].delay = (1/frequency) / PtsPerCycle
     
     --print("*** Sine Wave Timer Delay: "..trigger.timer[N].delay)
     
     trigger.timer[N].count = PtsPerCycle * numCycles
     trigger.timer[N].start.stimulus = trigger.EVENT_NOTIFY1
     trigger.timer[N].start.generate = trigger.OFF  -- first timer event after timer delay elapses
     trigger.timer[N].enable = 1  -- enable the timer after all settings
     
end  -- function




function config_trigger_model(number_src_pts, ListName)

     trigger.model.setblock(1, trigger.BLOCK_BUFFER_CLEAR, defbuffer1)
     --trigger.model.setblock(1, trigger.BLOCK_NOP)

     trigger.model.setblock(2, trigger.BLOCK_SOURCE_OUTPUT, smu.ON)
          
     trigger.model.setblock(3, trigger.BLOCK_CONFIG_RECALL, ListName, 1)  -- source first value
     trigger.model.setblock(4, trigger.BLOCK_MEASURE)  -- measure first value

     trigger.model.setblock(5, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1)  -- start timer1

     trigger.model.setblock(6, trigger.BLOCK_WAIT, trigger.EVENT_TIMER1)

     trigger.model.setblock(7, trigger.BLOCK_CONFIG_NEXT, ListName)
     trigger.model.setblock(8, trigger.BLOCK_MEASURE)
     trigger.model.setblock(9, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY2)  -- digital output

     trigger.model.setblock(10, trigger.BLOCK_BRANCH_COUNTER, number_src_pts - 1, 6)  -- branch back to wait for timer
     
     trigger.model.setblock(11, trigger.BLOCK_SOURCE_OUTPUT, smu.OFF)

end  -- function


