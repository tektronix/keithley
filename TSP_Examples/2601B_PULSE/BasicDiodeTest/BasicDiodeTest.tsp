--[[
################################################################################

Script File: BasicDiodeTest.tsp

    ************************************************************************
    *** Copyright Tektronix, Inc.                                        ***
    *** See www.tek.com/sample-license for licensing terms.              ***
    ************************************************************************

Description:
    This script is example code, which creates (and subsequently calls) several
    functions that can be used with the Model 2601B-PULSE to perform a basic 
    diode test. The purpose is show that you can use the current pulser and the 
    SMU within the same application. As written, the functions use the current 
    pulser to perform a 4-point forward bias IV sweep, and the SMU to perform a 
    reverse bias leakage current measurement. Upon completion of each test, the 
    data is printed to the Test Script Builder Instrument Console in a format 
    that is suitable for copying and pasting into Microsoft Excel for graphing 
    and analysis.

Required Equipment:  1 Model 2601B-PULSE System SourceMeter instrument

Note:  The functions do not perform any error checking.  It is the user's 
       responsibility to specify settings that are compatible with the 
       instrument model being used, and with its power envelope.
       
Note:  It is the user's responsibility to follow all safety guidelines given in 
       the instrument's Reference Manual.  This is especially critical if 
       voltages in excess of 42VDC will be present in the test circuits.  Such 
       voltage levels are hazardous. 
       
Functions created by this script:
    * diode_iv(curr_level_list,pulse_period,pulse_width,meas_delay,meas_aperture,rangev,rangei,source_protectv,sense_protectv,bias_current)
    * diode_ir(src_rangev,src_levelv,src_limiti,meas_rangei,nplc,apply_time )
    * test_diode()

Example Usage:
    * diode_iv({1,2,3},10e-3,20e-6,15e-6,5e-6,10,10,40,20,0)
    * diode_ir(6,-5,1e-6,100e-9,1,20e-3)
    * test_diode()
    
See additional detailed information in the individual functions.

################################################################################
--]]

function diode_iv(curr_level_list,pulse_period,pulse_width,meas_delay,meas_aperture,rangev,rangei,source_protectv,sense_protectv,bias_current )
--[[
    This function configures and initiates a current pulse list sweep for the 
    2601B-PULSE pulser. It is used to perform a forward bias IV sweep on a 
    diode. The pulse is generated using the instrument's Synchronous Trigger 
    Model. The Pulse Period is controlled using a standard Trigger Timer. The 
    Pulse Width and Measure Delay (settling time) are determined by new 
    pulser commands for the pulse width and measure delay, which provide more 
    precise timing than a Trigger Timer. Using the dual 1MS/s digitizers built 
    into the current pulser, the voltage and current are measured 
    simultaneously at the top of each pulse. Upon completion of the sweep, the 
    data is printed to the Test Script Builder Instrument Console in a format 
    that is suitable for copying and pasting into Microsoft Excel for graphing 
    and analysis.
    
    Prerequisites:  None
    
    Pass Parameters:
        * curr_level_list  : Table of pulse levels to sweep thru; values in amps
        * pulse_period     : Time between start of consecutive pulses in seconds
        * pulse_width      : Width of current pulses in seconds
        * meas_delay       : Time from pulse start to measure start in seconds
        * meas_aperture    : Effective integration time in seconds
        * rangev           : Voltage measure range in volts
        * rangei           : Current source and measure range in amps
        * source_protectv  : Voltage protection level at source terminals
        * sense_protectv   : Voltage protection level at sense terminals
        * bias_current     : Idle current level in amps (base level for pulses)

    Returned values:  None
--]]

    -- Reset the pulser and SMU to default conditions
	smua.reset()
	
    -- Enable the fast current pulser
    smua.pulser.enable                  = smua.ENABLE
    
    -- Configure the reading buffers   
    smua.nvbuffer1.clear()
    smua.nvbuffer2.clear()
    smua.nvbuffer1.collecttimestamps    = 1
    smua.nvbuffer2.collecttimestamps    = 1

	-- Set ranges
    smua.pulser.rangei = rangei
    smua.pulser.rangev = rangev

	-- Set the idle current level
    smua.source.leveli 				= bias_current

	-- Set voltage protection levels
    smua.pulser.protect.sourcev 	= source_protectv
    smua.pulser.protect.sensev 		= sense_protectv
	
	-- Determine the number of current levels in the list
    local npulse					= table.getn(curr_level_list)
	
	-- Use Trigger Timer 1 to control pulse period
    trigger.timer[1].reset()
    trigger.timer[1].count			= npulse   
    trigger.timer[1].delay			= pulse_period 
    trigger.timer[1].passthrough	= false
    trigger.timer[1].stimulus		= smua.trigger.ARMED_EVENT_ID  

	-- Set measure delay and aperture
    smua.pulser.measure.delay 		= meas_delay
    smua.pulser.measure.aperture 	= meas_aperture

    -- Configure Trigger Model to perform a current pulse list sweep
    smua.trigger.count 				= npulse 	
    smua.trigger.source.listi(curr_level_list)    
    smua.trigger.source.pulsewidth 	= pulse_width 
    smua.trigger.source.action 		= smua.ENABLE
    smua.trigger.source.stimulus 	= trigger.timer[1].EVENT_ID
    smua.trigger.measure.action		= smua.ENABLE
    smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)  -- I in nvbuffer1
                                                             -- V in nvbuffer2
	
	-- Turn on the output
    smua.source.output              = smua.OUTPUT_ON
		
    -- Initiate the Trigger Model and wait for the sweep to complete
    smua.trigger.initiate()
    waitcomplete()

    -- Turn off the output and disable the current pulser
    smua.source.output 				= smua.OUTPUT_OFF
    smua.pulser.enable 				= smua.DISABLE
    
	-- Output the data in tab-separated format
    print("Time (s)\tCurrent (A)\tVoltage (V)")
    for i = 1, smua.nvbuffer1.n do
        print(smua.nvbuffer1.timestamps[i],smua.nvbuffer1[i],smua.nvbuffer2[i])
    end --for

end --function diode_iv()

function diode_ir(src_rangev,src_levelv,src_limiti,meas_rangei,nplc,apply_time )
--[[
    This function uses the 2601B-PULSE SMU to force a DC voltage and measure 
    the resulting current.  It is used to measure the reverse bias leakage 
    current (Ir) of a diode. Using the dual integrating analog-to-digital 
    converters built the SMU, the voltage and current are measured 
    simultaneously for the spot test. Upon completion of the sweep, the 
    data is printed to the Test Script Builder Instrument Console in a format 
    that is suitable for copying and pasting into Microsoft Excel for analysis.
    
    Prerequisites:  None
    
    Pass Parameters:
        * src_rangev    : Voltage source range in volts
        * src_levelv    : Voltage source level in volts
        * meas_rangei   : Current measure range in amps
        * nplc          : Measure integration time; number of power line cycles
        * apply_time    : Time in seconds for which voltage is applied before 
                          the current is measured

    Returned values:  None
--]]

    -- Reset the pulser and SMU to default conditions
    smua.reset()

	-- Disable the current pulser, which enables the SMU.  This is the default 
	--   condition, but show explicitly for clarity
    smua.pulser.enable          = smua.DISABLE	

	-- Use 4-wire voltage sensing
    smua.sense                  = smua.SENSE_REMOTE
	
	-- Configure source settings
    smua.source.func            = smua.OUTPUT_DCVOLTS
    smua.source.autorangei      = smua.AUTORANGE_OFF
    smua.source.autorangev      = smua.AUTORANGE_OFF
    smua.source.rangev          = src_rangev
    smua.source.limiti          = src_limiti
    smua.source.levelv          = src_levelv
    -- See 2600B Series Ref Manual for cautions about using following command
    smua.source.settling        = smua.SETTLE_FAST_RANGE
	
	-- Configure measure settings; perform autozero once after setting NPLC val
    smua.measure.autorangei     =   smua.AUTORANGE_OFF
    smua.measure.autorangev     = smua.AUTORANGE_OFF
    smua.measure.rangei         = meas_rangei
    smua.measure.nplc           = nplc
    smua.measure.autozero       = smua.AUTOZERO_ONCE
    display.smua.measure.func   = display.MEASURE_DCAMPS

	-- Turn on the output
    smua.source.output          = smua.OUTPUT_ON
	
	-- Delay the specified apply_time and then measure V and I
    delay(apply_time)
    local ir, vbias = smua.measure.iv()
	
	-- Turn off the output
    smua.source.output          = smua.OUTPUT_OFF
	
	-- Output the data in tab-separated format
    print("\nBias Voltage (V)\tIr (A)")
    print(vbias, ir)
	
end --function diode_ir()

function test_diode()
--[[
    This function simply calls the diode_iv() and diode_ir functions after 
    assigning values to their pass parameters.
    
    Prerequisites:  Functions diode_iv() and diode_ir() must exist before 
                    calling this function.
    
    Pass Parameters:  None
        
    Returned values:  None
--]]

    local curr_level_list   = {0.1,1,2,3}
    local pulse_period      = 10e-3
    local pulse_width 		= 20e-6
    local meas_delay 		= 15e-6
    local meas_aperture     = 5e-6
    local rangev			= 10
    local rangei			= 10
    local source_protectv 	= 40
    local sense_protectv	= 20
    local bias_current		= 0.001
    diode_iv(curr_level_list,pulse_period,pulse_width,meas_delay,meas_aperture,rangev,rangei,source_protectv,sense_protectv,bias_current )
	
    local src_rangev 		= 6
    local src_levelv 		= -5   --was 5
    local src_limiti		= 1e-3
    local meas_rangei		= 100e-9
    local nplc              = 1
    local apply_time		= 20e-3
    diode_ir(src_rangev,src_levelv, src_limiti,meas_rangei,nplc,apply_time )

end --function test_diode()

-- Call the diode test function
test_diode()
