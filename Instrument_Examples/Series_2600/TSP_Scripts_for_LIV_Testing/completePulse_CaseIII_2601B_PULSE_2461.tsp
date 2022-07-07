loadandrunscript
--[[
################################################################################

Script File: completePulse_CaseIII_2601B_PULSE_2461.tsp

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
					 1 2461 SourceMeter instrument

Note:  The function does not perform any error checking.  It is the user's 
       responsibility to specify settings that are compatible with the 
       instrument model being used, and with its power envelope.
       
Note:  It is the user's responsibility to follow all safety guidelines given in 
       the instrument's Reference Manual.  This is especially critical if 
       voltages in excess of 42VDC will be present in the test circuits.  Such 
       voltage levels are hazardous. 
       
Function created by this script:
    * completePulse_CaseIII_2601B_PULSE_2461(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,rangeV,rangeI,protectVsrc,protectVsns,biasCurrent,rangeSMU2461,biasSMU2461,printData)
    
Example Usage:
    * completePulse_CaseIII_2601B_PULSE_2461(0.1,0.2,2,500e-3,500e-6,20e-6,5,1,10,10,0.1e-3,0.001,0,1 ) 
 
See additional detailed information in the individual functions.

################################################################################
--]]
noReadings = 0
function completePulse_CaseIII_2601B_PULSE_2461(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,rangeV,rangeI,protectVsrc,protectVsns,biasCurrent,rangeSMU2461,biasSMU2461,printData)

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
 	    * startI        : Current level of the first pulse in amps
	    * stopI         : Current level of the last pulse in amps
	    * nPulse        : Number of pulses in the sweep 
	    * pulsePeriod   : Time between start of consecutive pulses in seconds
	    * pulseWidth    : Width of current pulses in seconds
	    * measAperture  : Effective integration time in seconds
	    * rangeV        : Voltage measure range in volts
	    * rangeI        : Current source and measure range in amps
	    * protectVsrc   : Protection Voltage on Source side
	    * protectVsns   : Protection Voltage on Sense side
	    * biasCurrent   : Idle current level in amps (base level for pulses)
	    * rangeSMU2461	: Measure Range of 2461
	    * biasSMU2461   : Bias voltage for PD with 2461 
        
    Returned values:  None
--]]
	-- Reset the pulser and SMU to default conditions
	smua.reset()
	-- Configure the reading buffers
	smua.nvbuffer1.clear()
	smua.nvbuffer2.clear()
	smua.nvbuffer1.collecttimestamps= 1
	smua.nvbuffer2.collecttimestamps= 1
	
	-- Use Trigger Timer 1 to control pulse period
	trigger.timer[1].reset()
	if pulseWidth < 100e-6 then
		trigger.timer[1].delay 		=  10e-6
	else
		trigger.timer[1].delay 			= 0.1*pulseWidth
	end
	trigger.timer[1].count 			= 1
	trigger.timer[1].passthrough 	= false
	trigger.timer[1].stimulus 		= trigger.timer[2].EVENT_ID

	trigger.timer[2].reset()
	trigger.timer[2].delay 			= pulsePeriod
	trigger.timer[2].count 			= nPulse
	trigger.timer[2].passthrough 	= true
	trigger.timer[2].stimulus 		= smua.trigger.ARMED_EVENT_ID

    node[1].tsplink.trigger[1].reset()
    node[1].tsplink.trigger[1].mode = node[1].tsplink.TRIG_FALLING
    node[1].tsplink.trigger[1].pulsewidth = 3e-6     


	-- Set measure delay and aperture
	if pulseWidth > 500e-6 then	
		if pulseWidth <=500e-3 then
			measAperture = 5e-3  
			smua.measure.nplc = 0.1
		end
		if pulseWidth <20e-3 then
			measAperture = 500e-6  
			smua.measure.nplc = 0.01
		end
		if pulseWidth <=1e-3 then
			measAperture = 50e-6  
			smua.measure.nplc = 0.001
		end	
		noReadings = math.ceil((1.4*pulseWidth)/measAperture)
		smua.measure.count              = 1
		configDcLonger500us(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,rangeV,rangeI,biasCurrent,noReadings)
	else
	
		if pulseWidth < 100e-6 then
			measAperture = 1e-6
			noReadings = math.ceil( (20e-6 + pulseWidth)/measAperture)
		else
			noReadings = math.ceil((1.2*pulseWidth)/measAperture)
		end
		smua.measure.count              = noReadings		
		node[1].tsplink.trigger[1].stimulus = trigger.timer[2].EVENT_ID
		configPulserShorter500us(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,rangeV,rangeI,protectVsrc,protectVsns,biasCurrent)
	end

	node[2].smu.source.output = 1
	local mea_Delay = 0   
	node[2].tsplink.group = 1
	node[2].execute("SMU2461_setup("..nPulse..","..measAperture..","..noReadings..","..rangeSMU2461..","..biasSMU2461..","..pulseWidth..")")
	waitcomplete(1)
                                                    
    -- Turn on the output

	smua.source.output = smua.OUTPUT_ON

	-- Initiate the Trigger Model and wait for the sweep to complete
	node[2].trigger.model.initiate()
	smua.trigger.initiate()
	waitcomplete()
	
    -- Turn off the output and disable the current pulser
    waitcomplete(1)
    node[2].smu.source.output = 0
    smua.source.output = smua.OUTPUT_OFF
    smua.pulser.enable = smua.DISABLE


	-- Output the data in tab-separated format
	if printData > 0 then
		print("\nTime (s)\t Current (A)\t Voltage (V) \t CurrentPD(A)")
		for i = 1, (nPulse*noReadings)  do
			print(smua.nvbuffer1.timestamps[i],smua.nvbuffer1[i],smua.nvbuffer2[i],math.abs(node[2].defbuffer1[i]))
		end 
	end
end 

function configPulserShorter500us(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,rangeV,rangeI,protectVsrc,protectVsns,biasCurrent)

    -- Enable the fast current pulser
    smua.pulser.enable = smua.ENABLE
	-- Set ranges
	smua.pulser.rangei 				= rangeI
	smua.pulser.rangev 				= rangeV
	
    smua.pulser.protect.sourcev         = protectVsrc
    smua.pulser.protect.sensev          = protectVsns
	-- Set the idle current level
	smua.source.leveli 				= biasCurrent
	
	smua.pulser.measure.delay 		= 0 
	smua.pulser.measure.aperture 	= measAperture

	-- Configure Trigger Model to perform a linear staircase current pulse sweep
	smua.trigger.count 				= nPulse
	smua.trigger.source.lineari(startI, stopI, nPulse)
	smua.trigger.source.limitv		= rangeV
	smua.trigger.source.action 		= smua.ENABLE
	smua.trigger.source.pulsewidth 	= pulseWidth
	smua.trigger.source.stimulus 	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus 	= trigger.timer[2].EVENT_ID
	smua.trigger.measure.action 	= smua.ASYNC
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)  -- I in nvbuffer1
	 
end

function configDcLonger500us(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,rangeV,rangeI,biasCurrent,noPoints)
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
	smua.measure.delay				= 0

	trigger.timer[3].reset()
	trigger.timer[3].delay 			= measAperture
	trigger.timer[3].count 			= noPoints
	trigger.timer[3].passthrough 	= false
	trigger.timer[3].stimulus 		= trigger.timer[2].EVENT_ID
	
	trigger.timer[4].reset()
	trigger.timer[4].delay 			= pulseWidth
	trigger.timer[4].count 			= 1
	trigger.timer[4].passthrough 	= false
	trigger.timer[4].stimulus 		= trigger.timer[1].EVENT_ID

   	node[1].tsplink.trigger[1].stimulus = trigger.timer[3].EVENT_ID 

	smua.trigger.source.lineari(startI, stopI, nPulse)
	smua.trigger.source.limitv		= rangeV
	smua.trigger.measure.action		= smua.ASYNC
	smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
	smua.trigger.endpulse.action	= smua.SOURCE_IDLE
	smua.trigger.endsweep.action	= smua.SOURCE_IDLE
	smua.trigger.count				= nPulse+1
	smua.trigger.arm.stimulus		= 0
	smua.trigger.source.stimulus	= trigger.timer[1].EVENT_ID
	smua.trigger.measure.stimulus	= trigger.timer[3].EVENT_ID
	smua.trigger.endpulse.stimulus	= trigger.timer[4].EVENT_ID
	smua.trigger.source.action		= smua.ENABLE
end

local setSMU2461 =[[
function SMU2461_setup(nReading,measAperture,noReadings,rangeSMU2461,biasSMU2461,pulseWidth)
	
	-- Configure SMU 1 reading buffer defbuffer1
    node[2].defbuffer1.clear()
    node[2].defbuffer1.capacity = 100000
    node[2].defbuffer1.fillmode = node[2].buffer.FILL_ONCE
	node[2].smu.source.func = node[2].smu.FUNC_DC_VOLTAGE
	node[2].smu.source.autodelay = node[2].smu.OFF
	node[2].smu.source.range = biasSMU2461
	node[2].smu.source.level = biasSMU2461
	
	if pulseWidth > 500e-6 then

    	node[2].smu.digitize.func =   node[2].smu.FUNC_DIGITIZE_CURRENT
    	node[2].smu.digitize.range =  rangeSMU2461        
     	node[2].smu.digitize.samplerate =  50000	
    	node[2].smu.digitize.count = 1          

    	-- Create SMU Trigger Model
   		node[2].trigger.model.load("EMPTY") --If the configuration name is set to "EMPTY", any existing trigger model settings are reset.
    	node[2].trigger.model.setblock(1, node[2].trigger.BLOCK_BUFFER_CLEAR, defbuffer1)
    	node[2].trigger.model.setblock(2, node[2].trigger.BLOCK_WAIT, node[2].trigger.EVENT_TSPLINK1, node[2].trigger.CLEAR_NEVER)
    	node[2].trigger.model.setblock(3, node[2].trigger.BLOCK_DELAY_CONSTANT, 0) 
    	node[2].trigger.model.setblock(4, node[2].trigger.BLOCK_DIGITIZE, node[2].defbuffer1, 1)
    	node[2].trigger.model.setblock(5, node[2].trigger.BLOCK_NOTIFY, node[2].trigger.EVENT_NOTIFY1)
    	node[2].trigger.model.setblock(6, node[2].trigger.BLOCK_BRANCH_COUNTER, nReading*noReadings, 2)    
    	node[2].trigger.model.setblock(7, node[2].trigger.BLOCK_BRANCH_ALWAYS, 0)            	  
	else
    	node[2].smu.digitize.func =   node[2].smu.FUNC_DIGITIZE_CURRENT
    	node[2].smu.digitize.range =  rangeSMU2461        
     	node[2].smu.digitize.samplerate =  1/measAperture	
    	node[2].smu.digitize.count = noReadings              

    	-- Create SMU Trigger Model
   		node[2].trigger.model.load("EMPTY") --If the configuration name is set to "EMPTY", any existing trigger model settings are reset.
    	node[2].trigger.model.setblock(1, node[2].trigger.BLOCK_BUFFER_CLEAR, defbuffer1)
    	node[2].trigger.model.setblock(2, node[2].trigger.BLOCK_WAIT, node[2].trigger.EVENT_TSPLINK1, node[2].trigger.CLEAR_NEVER)
    	node[2].trigger.model.setblock(3, node[2].trigger.BLOCK_DELAY_CONSTANT, 0) 
    	node[2].trigger.model.setblock(4, node[2].trigger.BLOCK_DIGITIZE, node[2].defbuffer1, noReadings)
    	node[2].trigger.model.setblock(5, node[2].trigger.BLOCK_NOTIFY, node[2].trigger.EVENT_NOTIFY1)
    	node[2].trigger.model.setblock(6, node[2].trigger.BLOCK_BRANCH_COUNTER, nReading, 2)    
    	node[2].trigger.model.setblock(7, node[2].trigger.BLOCK_BRANCH_ALWAYS, 0)        
	end
    -- Configure TSP-Link Trigger Line 1 to detect trigger from 2601B-PULSE
    node[2].tsplink.line[1].reset()
    node[2].tsplink.line[1].mode = node[2].tsplink.MODE_TRIGGER_OPEN_DRAIN  
    node[2].trigger.tsplinkin[1].edge = node[2].trigger.EDGE_FALLING
end
]]


function completePulse()
	local startI        = 0.1
	local stopI         = 0.2
	local nPulse        = 3
	local pulsePeriod   = 100e-3
	local pulseWidth    = 10e-3
	local measAperture  = 10e-6
	local rangeV        = 5
	local rangeI        = 1
	local protectVsrc 	= 10
	local protectVsns	= 10
	local biasCurrent   = 0.1e-3
	local rangeSMU2461	= 1e-3
	local biasSMU2461 	= 0
	completePulse_CaseIII_2601B_PULSE_2461(startI,stopI,nPulse,pulsePeriod,pulseWidth,measAperture,rangeV,rangeI,protectVsrc,protectVsns,biasCurrent,rangeSMU2461,biasSMU2461,1)
end

function initializeTSPLINK() 
	local nodesFound = tsplink.reset()
	if nodesFound ~= 2 then
		print(string.format("TSPLINK Error: not Found 2nd Node."))
		exit()
	end
	local SMU2461_group = 1
	local SMU2461_node = node[2]
	SMU2461_node.tsplink.group = SMU2461_group
	SMU2461_node.execute(setSMU2461)
	waitcomplete(1)
	print("TSPLINK is sucessfully linked")
end

endscript
print("the script is loaded")

