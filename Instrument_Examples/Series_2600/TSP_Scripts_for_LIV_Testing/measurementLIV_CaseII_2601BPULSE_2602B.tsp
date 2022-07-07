loadandrunscript
--[[
################################################################################

Script File: measurementLIV_CaseII_2601BPULSE_2602B.tsp

    ************************************************************************
    *** Copyright Tektronix, Inc.                                        ***
    *** See www.tek.com/sample-license for licensing terms.              ***
    ************************************************************************

Description:
	This script is example code, which creates (and subsequently calls) a 
	single function that can be used with the Model 2601B-PULSE current pulser 
	to output a current pulse sweep. The sweep is generated using the 
	instrument's Asynchronous Trigger Model. Using the dual 1MS/s digitizers 
	built into the current pulser, the voltage and current are measured 
	simultaneously at the top of each pulse and PD current measured from the 2602B.
	Upon completion of the sweep, the data is printed to the Test Script Builder 
	Instrument Console in a format that is suitable for copying and pasting into 
	Microsoft Excel for graphing and analysis.


Required Equipment:  1 Model 2601B-PULSE System SourceMeter instrument
                     1 2602B System SourceMeter intrument

Note:  The function does not perform any error checking.  It is the user's 
       responsibility to specify settings that are compatible with the 
       instrument model being used, and with its power envelope.
       
Note:  It is the user's responsibility to follow all safety guidelines given in 
       the instrument's Reference Manual.  This is especially critical if 
       voltages in excess of 42VDC will be present in the test circuits.  Such 
       voltage levels are hazardous. 
       
Function created by this script:
    * measurementLIV_CaseII_2601BPULSE_2602B(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,measDelay,rangeV,rangeI,protectVsrc,protectVsns,biasCurrent, biasPD1,measRngPD1,nplcPD1,optoFactor,printData)
    
Example Usage:
    * measurementLIV_CaseII_2601BPULSE_2602B(0,0.2,21,50e-3,50e-6,10e-6,10e-6,10,1,10,10,0.1e-3,0,1e-3,0.001,7200,1)
    
See additional detailed information in the individual functions.

################################################################################
--]]

function measurementLIV_CaseII_2601BPULSE_2602B(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,measDelay,rangeV,rangeI,protectVsrc,protectVsns,biasCurrent, biasPD1,measRngPD1,nplcPD1,optoFactor,printData)


--[[
    
    Prerequisites:  None
    
	Pass Parameters:
	    * startI        : Current level of the first pulse in amps
	    * stopI         : Current level of the last pulse in amps
	    * nPulse        : Number of pulses in the sweep 
	    * pulsePeriod   : Time between start of consecutive pulses in seconds
	    * pulseWidth    : Width of current pulses in seconds
	    * measAperture  : Effective integration time in seconds
	    * measDelay     : Time from pulse start to measure start in seconds
	    * rangeV        : Voltage measure range in volts
	    * rangeI        : Current source and measure range in amps
	    * protectVsrc   : Protection Voltage on Source side
	    * protectVsns   : Protection Voltage on Sense side
	    * biasCurrent   : Idle current level in amps (base level for pulses)
		* biasPD1 		: Bias voltage for PD with 2602B 
		* measRngPD1	: Measure Range for PD 
		* nplcPD1		: NPLC for PD measurement  
	    * optoFactor    : Proportaional Constant to calculate optical power based on the PD current 

     Returned values:  None
--]]

	-- Reset the pulser to default conditions
	smua.reset()
	-- Configure the reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer2.clear()
	smua.nvbuffer1.collecttimestamps= 1
	smua.nvbuffer2.collecttimestamps= 1

	-- Use Trigger Timer 1 to control pulse period
	pulsePeriodTimer = trigger.timer[1]
	pulsePeriodTimer.reset()
	pulsePeriodTimer.delay 			= pulsePeriod
	pulsePeriodTimer.count 			= nPulse
	pulsePeriodTimer.passthrough 	= true
	pulsePeriodTimer.stimulus 		= smua.trigger.ARMED_EVENT_ID

	-- Use Trigger Timer 2 to control measurement synchronization
	measSyncTimer = trigger.timer[2]
	measSyncTimer.reset()
	measSyncTimer.delay 			= measDelay
	measSyncTimer.count 			= 1
	measSyncTimer.passthrough 		= false
	measSyncTimer.stimulus 			= pulsePeriodTimer.EVENT_ID

    node[1].tsplink.trigger[1].clear()
    node[1].tsplink.trigger[1].mode = tsplink.TRIG_FALLING
    node[1].tsplink.trigger[1].pulsewidth = 3e-6
	node[2].tsplink.trigger[1].clear()
	node[2].tsplink.trigger[1].mode		= tsplink.TRIG_FALLING
	node[2].tsplink.trigger[1].pulsewidth = 3e-6
    node[1].tsplink.trigger[1].stimulus = measSyncTimer.EVENT_ID 
	
	if pulseWidth > 500e-6 then
		if measAperture < 20e-6 then
			measAperture = 20e-6
		end
		if measDelay < 100e-6 then
			measDelay  = 100e-6
		end
		configDcLonger500us(startI,stopI,nPulse,rangeI,rangeV,biasCurrent,measAperture,nPulse,pulseWidth)
	else
		configPulserShorter500us(startI,stopI,nPulse,rangeI,rangeV,protectVsrc,protectVsns,biasCurrent,measAperture,nPulse,pulseWidth)	
	end 
	setupPhotoDiode2602B(biasPD1, measRngPD1, nplcPD1, nPulse, pulsePeriod, false)
	
    -- Turn on the output
    node[2].smua.source.output = node[2].smua.OUTPUT_ON
	smua.source.output = smua.OUTPUT_ON
	
	-- Initiate the Trigger Model and wait for the sweep to complete
	node[2].smua.trigger.initiate()
	node[2].trigger.generator[1].assert()	
	smua.trigger.initiate()
	waitcomplete()
	
    -- Turn off the output and disable the current pulser
    node[2].smua.source.output = node[2].smua.OUTPUT_OFF
    smua.source.output = smua.OUTPUT_OFF
    smua.pulser.enable = smua.DISABLE
    
	-- Output the data in tab-separated format
	if printData > 0 then
		print("\nTime (s)\t Current(A)\t Voltage(V)\t PD1_I(A)\t PD1_P(W)")
		for i = 1, smua.nvbuffer1.n do
			print( smua.nvbuffer1.timestamps[i],smua.nvbuffer1[i],smua.nvbuffer2[i],node[2].smua.nvbuffer1[i],math.abs(node[2].smua.nvbuffer1[i]*optoFactor))
		end 	
	end
end 


function configPulserShorter500us(startI,stopI,nPulse,rangeI,rangeV,protectVsrc,protectVsns,biasCurrent,measAperture,nPulse,pulseWidth)
    -- Enable the fast current pulser
    smua.pulser.enable = smua.ENABLE
	-- Set ranges
	smua.pulser.rangei 				= rangeI
	smua.pulser.rangev 				= rangeV

    smua.pulser.protect.sourcev         = protectVsrc
    smua.pulser.protect.sensev          = protectVsns
	smua.source.leveli 				= biasCurrent
 
	smua.pulser.measure.aperture 	= measAperture
	smua.measure.count              = 1
	-- Configure Trigger Model to perform a linear staircase current pulse sweep
	smua.trigger.count 				= nPulse
	smua.trigger.source.lineari(startI, stopI, nPulse)
	smua.trigger.source.action 		= smua.ENABLE
	smua.trigger.source.pulsewidth 	= pulseWidth
	smua.trigger.source.stimulus 	= pulsePeriodTimer.EVENT_ID
	smua.trigger.measure.stimulus 	= tsplink.trigger[1].EVENT_ID
	smua.trigger.measure.action 	= smua.ASYNC
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)  -- I in nvbuffer1
end

function configDcLonger500us(startI,stopI,nPulse,rangeI,rangeV,biasCurrent,measAperture,nPulse,pulseWidth)
	rangeV = 6
    -- Enable the fast current pulser
    smua.pulser.enable = smua.DISABLE

	smua.source.func				= smua.OUTPUT_DCAMPS
	smua.sense						= smua.SENSE_REMOTE	
	smua.source.autorangei			= smua.AUTORANGE_OFF
	smua.source.rangei				= rangeI
	smua.source.leveli				= biasCurrent
	smua.source.limitv				= 6 

	-- Disabling Auto-Ranging and Auto-Zero ensures accurate and consistent timing
	smua.measure.autozero			= smua.AUTOZERO_ONCE
	smua.measure.autorangev			= smua.AUTORANGE_OFF
	smua.measure.rangev				= rangeV
	smua.measure.nplc				= measAperture * localnode.linefreq
	
	-- A timer will be used to control the measure delay so set the built-in delay to 0
	smua.measure.delay				= 0
	pulseWidthTimer = trigger.timer[4]
	pulseWidthTimer.reset()
	pulseWidthTimer.delay 			= pulseWidth
	pulseWidthTimer.count 			= 1
	pulseWidthTimer.passthrough 	= false
	pulseWidthTimer.stimulus 		= trigger.timer[2].EVENT_ID
	
	-- Configure SMU Trigger Model for Sweep
	smua.trigger.source.lineari(startI, stopI, nPulse)
	smua.trigger.source.limitv		= rangeV
	smua.trigger.measure.action		= smua.ASYNC
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= nPulse
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= pulsePeriodTimer.EVENT_ID
	smua.trigger.measure.stimulus	= tsplink.trigger[1].EVENT_ID
	smua.trigger.endpulse.stimulus	= pulseWidthTimer.EVENT_ID
	smua.trigger.source.action		= smua.ENABLE
end

function setupPhotoDiode2602B(biasPD1, measRngPD1, nplcPD1, nPulse, pulsePeriod, remoteSense)

	node[2].smua.reset()
	node[2].smua.source.func					= node[2].smua.OUTPUT_DCVOLTS
	if node[2].remoteSense == true then
		node[2].smua.sense						= node[2].smua.SENSE_REMOTE
	else
		node[2].smua.sense						= node[2].smua.SENSE_LOCAL
	end
	node[2].smua.source.autorangev			= node[2].smua.AUTORANGE_OFF
	node[2].smua.source.rangev				= biasPD1 
	node[2].smua.source.levelv				= biasPD1
	node[2].smua.source.limiti				= measRngPD1

	-- Disabling Auto-Ranging and Auto-Zero ensures accurate and consistent timing
	node[2].smua.measure.autozero			= node[2].smua.AUTOZERO_OFF
	node[2].smua.measure.autorangei			= node[2].smua.AUTORANGE_OFF
	node[2].smua.measure.rangei				= measRngPD1
	node[2].smua.measure.nplc				= nplcPD1
	node[2].smua.measure.delay				= 0

	-- Prepare the Reading Buffers
	node[2].smua.nvbuffer1.clear()
	node[2].smua.nvbuffer1.collecttimestamps= 1
	node[2].smua.nvbuffer2.clear()
	node[2].smua.nvbuffer2.collecttimestamps= 1
	
	node[2].trigger.timer[1].reset()
	node[2].trigger.timer[1].delay = 100e-3 + (nPulse * pulsePeriod)
	node[2].trigger.timer[1].count = 1      
    node[2].trigger.timer[1].passthrough = false 
    node[2].trigger.timer[1].stimulus 	 = node[2].trigger.generator[1].EVENT_ID
   
	-- Configure the Trigger Model
	node[2].smua.trigger.source.linearv(biasPD1,biasPD1,1)
	node[2].smua.trigger.source.action		= node[2].smua.ENABLE
	node[2].smua.trigger.source.limiti		= measRngPD1
	node[2].smua.trigger.measure.action		= node[2].smua.ASYNC
	node[2].smua.trigger.measure.iv(node[2].smua.nvbuffer1, node[2].smua.nvbuffer2)
	node[2].smua.trigger.endpulse.action	= node[2].smua.SOURCE_IDLE
	node[2].smua.trigger.endsweep.action	= node[2].smua.SOURCE_IDLE
	node[2].smua.trigger.count				= 1
	node[2].smua.trigger.arm.stimulus		= 0
	node[2].smua.trigger.source.stimulus	= node[2].trigger.generator[1].EVENT_ID
	node[2].smua.trigger.measure.stimulus	= node[2].tsplink.trigger[1].EVENT_ID 
	node[2].smua.trigger.endpulse.stimulus	= node[2].trigger.timer[1].EVENT_ID
end

function initializeTSPLINK()
	local nodesFound = tsplink.reset()
	if nodesFound ~= 2 then
		print(string.format("TSPLINK Error: not Found 2nd Node."))
		exit()
	end
	print("TSPLINK is sucessfully linked")
end

function measurementLIV()
	local startI        = 0
	local stopI         = 0.2
	local nPulse        = 21
	local pulsePeriod  = 50e-3
	local pulseWidth   = 50e-6
	local measAperture = 20e-6	
	local measDelay    = 10e-6
	local rangeV        = 10
	local rangeI        = 1
	local protectVsrc	= 10
	local protectVsns	= 10
	local biasCurrent   = 0.1e-3

	local biasPD1 		= 0
	local measRngPD1	= 0.001
	local nplcPD1		= 0.001 -- minimum nplc 0.001 = 0.001 x 16.67ms = 17us  
	local optoFactor	= 72000

	measurementLIV_CaseII_2601BPULSE_2602B(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,measDelay,rangeV,rangeI,protectVsrc,protectVsns,biasCurrent, biasPD1,measRngPD1,nplcPD1,optoFactor,1)
end 
endscript
print("the script is loaded")

