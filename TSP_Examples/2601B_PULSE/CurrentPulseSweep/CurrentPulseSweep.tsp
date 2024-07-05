--[[
################################################################################

Script File: CurrentPulseSweep.tsp

    ************************************************************************
    *** Copyright Tektronix, Inc.                                        ***
    *** See www.tek.com/sample-license for licensing terms.              ***
    ************************************************************************

Description:
	This script is example code, which creates (and subsequently calls) a 
	single function that can be used with the Model 2601B-PULSE current pulser 
	to output a current pulse sweep. The sweep is generated using the 
	instrument's Synchronous Trigger Model. Using the dual 1MS/s digitizers 
	built into the current pulser, the voltage and current are measured 
	simultaneously at the top of each pulse. Upon completion of the sweep, the 
	data is printed to the Test Script Builder Instrument Console in a format 
	that is suitable for copying and pasting into Microsoft Excel for graphing 
	and analysis.

Required Equipment:  1 Model 2601B-PULSE System SourceMeter instrument

Note:  The function does not perform any error checking.  It is the user's 
       responsibility to specify settings that are compatible with the 
       instrument model being used, and with its power envelope.
       
Note:  It is the user's responsibility to follow all safety guidelines given in 
       the instrument's Reference Manual.  This is especially critical if 
       voltages in excess of 42VDC will be present in the test circuits.  Such 
       voltage levels are hazardous. 
       
Function created by this script:
    * sweep_current_level(starti,stopi,npulse,pulse_period,pulse_width,meas_aperture,meas_delay,rangev,rangei,bias_current)
    
Example Usage:
    * sweep_current_level(1,10,10,10e-3,10e-6,1e-6,9e-6,10,10,0 ) 
 
See additional detailed information in the individual functions.

################################################################################
--]]

function sweep_current_level(starti,stopi,npulse,pulse_period,pulse_width,meas_aperture,meas_delay,rangev,rangei,bias_current )

--[[
    This function configures and initiates a current pulse sweep for the 
    2601B-PULSE pulser. The sweep is generated using the instrument's 
    Synchronous Trigger Model. The Pulse Period is controlled using a standard 
    Trigger Timer. The Pulse Width and Measure Delay (settling time) are 
    determined by new pulser commands for the pulse width and measure delay, 
    which provide more precise timing than a Trigger Timer. The voltage and 
    current are measured simultaneously at the top of each pulse. Upon 
    completion of the sweep, the data is printed to the Test Script Builder 
    Instrument Console in a format that is suitable for copying and pasting 
    into Microsoft Excel for graphing and analysis.
    
    Prerequisites:  None
    
	Pass Parameters:
	    * starti        : Current level of the first pulse in amps
	    * stopi         : Current level of the last pulse in amps
	    * npulse        : Number of pulses in the sweep 
	    * pulse_period  : Time between start of consecutive pulses in seconds
	    * pulse_width   : Width of current pulses in seconds
	    * meas_aperture : Effective integration time in seconds
	    * meas_delay    : Time from pulse start to measure start in seconds
	    * rangev        : Voltage measure range in volts
	    * rangei        : Current source and measure range in amps
	    * bias_current  : Idle current level in amps (base level for pulses)
            
    Returned values:  None
--]]

	-- Reset the pulser and SMU to default conditions
	smua.reset()
	
    -- Enable the fast current pulser
    smua.pulser.enable = smua.ENABLE
    		
	-- Configure the reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer2.clear()
	smua.nvbuffer1.collecttimestamps= 1
	smua.nvbuffer2.collecttimestamps= 1
	
	-- Set ranges
	smua.pulser.rangei 				= rangei
	smua.pulser.rangev 				= rangev

	-- Set the idle current level
	smua.source.leveli 				= bias_current
	
	-- Use Trigger Timer 1 to control pulse period
	trigger.timer[1].reset()
	trigger.timer[1].delay 			= pulse_period
	trigger.timer[1].count 			= npulse
	trigger.timer[1].passthrough 	= false
	trigger.timer[1].stimulus 		= smua.trigger.ARMED_EVENT_ID

	-- Set measure delay and aperture
	smua.pulser.measure.delay 		= meas_delay
	smua.pulser.measure.aperture 	= meas_aperture
	
	-- Configure Trigger Model to perform a linear staircase current pulse sweep
	smua.trigger.count 				= npulse
	smua.trigger.source.lineari(starti, stopi, npulse)
	smua.trigger.source.action 		= smua.ENABLE
	smua.trigger.source.pulsewidth 	= pulse_width
	smua.trigger.source.stimulus 	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.action 	= smua.ENABLE
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)  -- I in nvbuffer1
	                                                         -- V in nvbuffer2
    -- Turn on the output
	smua.source.output = smua.OUTPUT_ON
	
	-- Initiate the Trigger Model and wait for the sweep to complete
	smua.trigger.initiate()
	waitcomplete()
	
    -- Turn off the output and disable the current pulser
    smua.source.output = smua.OUTPUT_OFF
    smua.pulser.enable = smua.DISABLE
    
	-- Output the data in tab-separated format
	print("\nTime (s)\tCurrent (A)\tVoltage (V)")
	for i = 1, smua.nvbuffer1.n do
		print(smua.nvbuffer1.timestamps[i],smua.nvbuffer1[i],smua.nvbuffer2[i])
	end --for

end --function sweep_current_level()

-- Call the function.
local starti        = 1
local stopi         = 10
local npulse        = 10
local pulse_period  = 10e-3
local pulse_width   = 10e-6
local meas_aperture = 1e-6
local meas_delay    = 9e-6
local rangev        = 10
local rangei        = 10
local bias_current  = 0

sweep_current_level(starti,stopi,npulse,pulse_period,pulse_width,meas_aperture,meas_delay,rangev,rangei,bias_current)