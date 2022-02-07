loadandrunscript
--[[
################################################################################

Script File: measurementLIV_CaseI_2601B_PULSE_DMMs.tsp

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
	simultaneously at the top of each pulse and PD current measured from the DMM.
	Upon completion of the sweep, the data is printed to the Test Script Builder 
	Instrument Console in a format that is suitable for copying and pasting into 
	Microsoft Excel for graphing and analysis.

Required Equipment: 1 Model 2601B-PULSE System SourceMeter instrument
					1 DMM 7510 or DMM6500 Multimeter instrument

Note:  The function does not perform any error checking.  It is the user's 
       responsibility to specify settings that are compatible with the 
       instrument model being used, and with its power envelope.
       
Note:  It is the user's responsibility to follow all safety guidelines given in 
       the instrument's Reference Manual.  This is especially critical if 
       voltages in excess of 42VDC will be present in the test circuits.  Such 
       voltage levels are hazardous. 
       
Function created by this script:
    * measurementLIV_CaseI_2601B_PULSE_DMMs(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,measDelay,rangeV,rangeI,protectVsrc,protectVsns,biasCurrent,rangeDMM,optoFactor)
    
Example Usage:
    * measurementLIV_CaseI_2601B_PULSE_DMM(0.0,0.2,21,50e-3,50e-6,20e-6,10e-6,5,1,10,10,0.1e-3,1e-3,2700,1) 

################################################################################
--]]

function measurementLIV_CaseI_2601B_PULSE_DMM(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,measDelay,rangeV,rangeI,protectVsrc,protectVsns,biasCurrent,rangeDMM,optoFactor,printData)

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
	    * rangeDMM	    : Range of DMM
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

    node[1].tsplink.trigger[1].reset()
    node[1].tsplink.trigger[1].mode = node[1].tsplink.TRIG_FALLING
    node[1].tsplink.trigger[1].stimulus = measSyncTimer.EVENT_ID 
	node[1].tsplink.trigger[1].pulsewidth = 3e-6
	
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
	local meaDelayDMM = 0   -- DMM delay after TSPLINK trigger, but not necessary in most case
	node[2].tsplink.group = 1
	node[2].execute("DMM_setup("..nPulse..","..meaDelayDMM..","..measAperture..","..rangeDMM..")")
	waitcomplete(1)
	
    -- Turn on the output
	smua.source.output = smua.OUTPUT_ON
	
	-- Initiate the Trigger Model and wait for the sweep to complete
	if measAperture < 20e-6 then
		node[2].trigger.model.initiate()
	end
	smua.trigger.initiate()
	waitcomplete()
	
    -- Turn off the output and disable the current pulser
    smua.source.output = smua.OUTPUT_OFF
    smua.pulser.enable = smua.DISABLE
    
	-- Output the data in tab-separated format
	if printData > 0 then
		print("\n Time (s)\tCurrent (A)\tVoltage(V) \t DMM1(A)\t DMM1(W)")
		for i = 1, smua.nvbuffer1.n do
			print(smua.nvbuffer1.timestamps[i],smua.nvbuffer1[i],smua.nvbuffer2[i],math.abs(node[2].defbuffer1[i]),math.abs(node[2].defbuffer1[i] * optoFactor))
		end 
	end
end 


function configPulserShorter500us(startI,stopI,nPulse,rangeI,rangeV,protectVsrc,protectVsns,biasCurrent,measAperture,nPulse,pulseWidth)
    -- Enable the fast current pulser
    smua.pulser.enable = smua.ENABLE
	smua.pulser.rangei 				= rangeI
	smua.pulser.rangev 				= rangeV

    smua.pulser.protect.sourcev         = protectVsrc
    smua.pulser.protect.sensev          = protectVsns
	smua.source.leveli 				= biasCurrent

--	smua.pulser.measure.delay 		= measDelay
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
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)  
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
	smua.source.limitv				= rangeV 

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

local setDMM7510 =[[
function DMM_setup(nReading,measDelayDMM,measAperture,rangeDMM)
	
	-- Configure DMM 1 reading buffer defbuffer1
    node[2].defbuffer1.clear()
    node[2].defbuffer1.capacity = 100000
    node[2].defbuffer1.fillmode = node[2].buffer.FILL_ONCE

	if measAperture >= 20e-6 then
    	node[2].dmm.measure.func = node[2].dmm.FUNC_DC_CURRENT
    	node[2].dmm.measure.range = rangeDMM  
		node[2].dmm.measure.aperture = measAperture
		node[2].dmm.measure.autozero.once()
		node[2].dmm.measure.autozero.enable = 0
		node[2].dmm.measure.count 			= 1
		node[2].dmm.measure.autodelay 		= 0	
		node[2].dmm.trigger.measure.stimulus = node[2].trigger.EVENT_TSPLINK1
		
    else
    	node[2].dmm.digitize.func =   node[2].dmm.FUNC_DIGITIZE_CURRENT
    	node[2].dmm.digitize.range =  rangeDMM                
    	node[2].dmm.digitize.samplerate = math.floor(1 / measAperture)	
    	node[2].dmm.digitize.count = 1              

    	-- Create DMM Trigger Model
   		node[2].trigger.model.load("EMPTY") --If the configuration name is set to "EMPTY", any existing trigger model settings are reset.
    	node[2].trigger.model.setblock(1, node[2].trigger.BLOCK_BUFFER_CLEAR, defbuffer1)
    	node[2].trigger.model.setblock(2, node[2].trigger.BLOCK_WAIT, node[2].trigger.EVENT_TSPLINK1, node[2].trigger.CLEAR_NEVER)
    	node[2].trigger.model.setblock(3, node[2].trigger.BLOCK_DELAY_CONSTANT, measDelayDMM) -- meas Delay
    	node[2].trigger.model.setblock(4, node[2].trigger.BLOCK_MEASURE_DIGITIZE, defbuffer1, node[2].trigger.COUNT_AUTO)
    	node[2].trigger.model.setblock(5, node[2].trigger.BLOCK_NOTIFY, node[2].trigger.EVENT_NOTIFY1)
    	node[2].trigger.model.setblock(6, node[2].trigger.BLOCK_BRANCH_COUNTER, nReading, 2)    
    	node[2].trigger.model.setblock(7, node[2].trigger.BLOCK_BRANCH_ALWAYS, 0)        
    end  
    -- Configure TSP-Link Trigger Line 1 to detect trigger from 2601B-PULSE
    node[2].tsplink.line[1].reset()
    node[2].tsplink.line[1].mode = node[2].tsplink.MODE_TRIGGER_OPEN_DRAIN  -- For compatibilty with 2600A/B series
    node[2].trigger.tsplinkin[1].edge = node[2].trigger.EDGE_FALLING
end
]]

function measurementLIV()
	local startI        = 0
	local stopI         = 0.2
	local nPulse        = 21
	local pulsePeriod  	= 50e-3
	local pulseWidth   	= 50e-6
	local measAperture 	= 10e-6
	local measDelay    	= 10e-6
	local rangeV        = 5
	local rangeI        = 1
	local protectVsrc	= 10
	local protectVsns	= 10
	local biasCurrent  	= 0.5e-3
	local rangeDMM 		= 1e-3
	local optoFactor	= 27000  	
	measurementLIV_CaseI_2601B_PULSE_DMM(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,measDelay,rangeV,rangeI,protectVsrc,protectVsns,biasCurrent,rangeDMM,optoFactor, 1)
end

function initializeTSPLINK()
	local nodesFound = tsplink.reset()
	if nodesFound ~= 2 then
		print(string.format("TSPLINK Error: not Found 2nd Node."))
		exit()
	end
	local DMM_group = 1
	local DMM_node = node[2]
	DMM_node.tsplink.group = DMM_group
	DMM_node.execute(setDMM7510)
	waitcomplete(1)
	print("TSPLINK is successfully linked")
end
	
endscript	
print("the script is loaded")

