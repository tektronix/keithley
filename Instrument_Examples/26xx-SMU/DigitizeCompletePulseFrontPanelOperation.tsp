--[[
################################################################################

Script File: DigitizeCompletePulse.tsp

    ************************************************************************
    *** Copyright Tektronix, Inc.                                        ***
    *** See www.tek.com/sample-license for licensing terms.              ***
    ************************************************************************

Description:
	This script is example code, which creates (and subsequently calls) a 
	single function that can be used with the Model 2601B-PULSE current pulser 
	to output and digitize one current pulse. The pulse is generated using the 
	instrument's Asynchronous Trigger Model. Using the dual 1MS/s digitizers 
	built into the current pulser, the voltage and current are sampled 
	simultaneously across the entire pulse. Upon completion, the data is 
	printed to the Test Script Builder Instrument Console in a format that is 
	suitable for copying and pasting into Microsoft Excel for graphing and 
	analysis.

Required Equipment:  1 Model 2601B-PULSE System SourceMeter instrument

Note:  The function does not perform any error checking.  It is the user's 
       responsibility to specify settings that are compatible with the 
       instrument model being used, and with its power envelope.
       
Note:  It is the user's responsibility to follow all safety guidelines given in 
       the instrument's Reference Manual.  This is especially critical if 
       voltages in excess of 42VDC will be present in the test circuits.  Such 
       voltage levels are hazardous. 
       
Function created by this script:
    * DigitizePulse(current_level,pulse_width,meas_aperture,rangev,rangei,source_protectv,sense_protectv,bias_current)
    
Example Usage:  digitize_pulse(10,50e-6,1e-6,10,10,40,20,0)

	
For Front Panel Operation:
	* Save this script to thumb drive and plug it into the instrument
	* Press MENU key->SRIPT->USB1
	* Select DigitizeCompletePulseFrontPanelOperation.tsp and press ENTER key
	* Press RUN key  to run the script and result will be saved automatically as csv format
		
Parameters to be entered in Front Panel Operation:
	* Current Level	: Peak current level of pulse in amps
	* Pulse Width 	: Width of current pulses in microseconds
	* Aperture		: Effective integration time in microseconds
	* Range Voltage	: Voltage measure range in volts
	* Range Current : Current source and measure range in amps
	* Source Protect: Voltage protection level at source terminals	
	* Sense Protect	: Voltage protection level at sense terminals
	* Bias Current	: Idle current level in amps (base level for pulses)
 
See additional detailed information in the individual functions.

################################################################################
--]]

function digitize_pulse(current_level,pulse_width,meas_aperture,rangev,rangei,source_protectv,sense_protectv,bias_current)

--[[
    This function configures and initiates a single current pulse for the 
    2601B-PULSE pulser. The pulse is generated using the instrument's 
	Asynchronous Trigger Model. The voltage and current are sampled 
	simultaneously across the entire pulse. The effective sample rate is 
	1/meas_aperture. The sampling nominally starts 10us before the start of the 
	pulse and stops 10us after the end of the pulse. 
	
	The pre-pulse acquisition interval is controlled using a standard Trigger 
	Timer. The total acquistion time is the product of the measure count and 
	the effective sample rate. The Pulse Width is controlled by the new pulser 
	command for the pulse width, which provides more precise timing than a 
	Trigger Timer. Upon completion, the data is printed to the Test Script 
	Builder Instrument Console in a format that is suitable for copying and 
	pasting into Microsoft Excel for graphing and analysis.
        
    Prerequisites:  None
    
    Pass Parameters:
        * current_level     : Peak current level of pulse in amps
        * pulse_width       : Width of current pulses in seconds
        * meas_aperture     : Effective integration time in seconds
        * rangev            : Voltage measure range in volts
        * rangei            : Current source and measure range in amps
        * source_protectv   : Voltage protection level at source terminals
        * sense_protectv    : Voltage protection level at sense terminals
        * bias_current      : Idle current level in amps (base level for pulse)
            
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
    smua.pulser.rangei                  = rangei
    smua.pulser.rangev                  = rangev

	-- Set the idle current level
    smua.source.leveli                  = bias_current

	-- Set voltage protection levels
    smua.pulser.protect.sourcev         = source_protectv
    smua.pulser.protect.sensev          = sense_protectv
	
	-- Config Trigger Timer 1 to delay pulse start 10us after measurements begin
    trigger.timer[1].reset()
    trigger.timer[1].count			= 1  
    trigger.timer[1].delay          = 10e-6
    trigger.timer[1].passthrough	= false
    trigger.timer[1].stimulus		= trigger.generator[1].EVENT_ID

    -- Configure source portion of Trigger Model to perform 1-point list sweep
    smua.trigger.source.action 		= smua.ENABLE
    smua.trigger.source.listi({current_level})   
    smua.trigger.source.pulsewidth 	= pulse_width 
    smua.trigger.source.stimulus 	= trigger.timer[1].EVENT_ID
 
	-- Configure measure portion of Trigger Model and related measure settings
	smua.trigger.measure.action		= smua.ASYNC
    smua.trigger.measure.stimulus 	= trigger.generator[1].EVENT_ID
    smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2) -- I in nvbuffer1
                                                            -- V in nvbuffer2
    smua.measure.interval			= 0 -- Digitize as fast as possible (1MS/s)
    smua.pulser.measure.aperture 	= meas_aperture
    smua.measure.count              = math.ceil((pulse_width + 2*10e-6) / meas_aperture)

    -- Turn on the output
    smua.source.output              = smua.OUTPUT_ON

    -- Initiate Trigger Model and allow to reach Source Action Event Detector
    smua.trigger.initiate()
    delay(0.001)
    
    -- Start measurements and Trig Timer 1 and wait for Trig Model to complete
    trigger.generator[1].assert()
    waitcomplete()

    -- Turn off the output and disable the current pulser
    smua.source.output 				= smua.OUTPUT_OFF
    smua.pulser.enable 				= smua.DISABLE
    
    -- Output the data in tab-separated format
    print("\nTime (s)\tCurrent (A)\tVoltage (V)")
    for i = 1, smua.nvbuffer1.n do
        print(smua.nvbuffer1.timestamps[i],smua.nvbuffer1[i],smua.nvbuffer2[i])
    end --for

end --function digitize_pulse()


function inputParameters(paramName,inputCondition,digitCondition,valueDefault,valueMin,valueMax)
	strMin = tostring(valueMin)
	strMax = tostring(valueMax)
	display.clear()
	display.settext("Enter "..paramName.."$N"..inputCondition)
	inputValue = display.inputvalue(digitCondition, valueDefault, valueMin, valueMax)
	display.screen = display.SMUA
	return inputValue
end

function saveData(timeBuffer,voltBuffer,currentBuffer,inputTestCondition)
	local osTime = "Data "..string.gsub(os.date(),':','_')
	local fileHandle = nil	
	local fileName
	local createFileName = function()
		display.clear()
		display.setcursor(1,1)
		display.settext("Saving Data to")
		display.setcursor(2,1)
		display.settext(osTime)
		fileName = "/usb1/"..osTime..".csv"		
		usbStatus = fs.is_dir("/usb1/")
		while usbStatus == false do
			beeper.beep(1,1900)
			display.clear()
			display.setcursor(1,1)
			display.settext("Insert USB drive")
			display.setcursor(2,1)
			display.settext("press any key to continue")		
			display.waitkey()
			usbStatus = fs.is_dir("/usb1/")
		end
	end
	
	local extractTestCondition = function()
		fileHandle:write(string.format('Test Time,%s\n',osTime))	
		fileHandle:write(string.format('Test Condition\n'))
        for _, step in ipairs(inputTestCondition) do
            fileHandle:write(string.format('%16s, %12.4e\n',step[1],step[2]))    
        end
    end

	local buildCSV = function(timeBuffer,currentBuffer,voltBuffer)
		fileHandle:write(string.format('\n%12s,%12s,%12s\n',"Time (s)","Current (A)","Voltage (V)"))
		for i = 1, currentBuffer.n do
			fileHandle:write(string.format('%12.4e,%12.4e,%12.4e\n',timeBuffer[i],currentBuffer[i],voltBuffer[i]))
		end --for
		display.screen = display.SMUA
	end
      
	createFileName()
	fileHandle = io.open(fileName, "w") 
	if io.type(fileHandle) == nil then
		display.clear()
		display.setcursor(1,1)
		display.settext("File cannot open")
		return 
	end
    extractTestCondition()
	buildCSV(timeBuffer,voltBuffer,currentBuffer)
    fileHandle:close()  
end

function runTest()

	-- Default Setup
	local current_level     = 0.05
	local pulse_width       = 25e-6
	local meas_aperture     = 1e-6
	local rangev            = 10
	local rangei            = 10
	local source_protectv   = 40
	local sense_protectv    = 20
	local bias_current      = 0
	
	local testItems = { }
	testItems[1] 	= {"Current Level"	,current_level		}
	testItems[2] 	= {"Pulse Width"	,pulse_width		}
	testItems[3] 	= {"Aperture"		,meas_aperture		}
	testItems[4] 	= {"Range Voltage"	,rangev				}
	testItems[5] 	= {"Range Current"	,rangei				}
	testItems[6] 	= {"Source Protect"	,source_protectv	}
	testItems[7] 	= {"Sense Protect"	,sense_protectv		}
	testItems[8] 	= {"Bias Current"	,bias_current		}	
	
	-- input parameters from front panel
	current_level	= inputParameters(testItems[1][1] ,"From -10 to +10(A):"	, "+00.000"	,testItems[1][2]		,-10	,10		)
	pulse_width 	= inputParameters(testItems[2][1] ,"From 10 to 500(us):"	, "000"		,testItems[2][2]*1000000,10		,500	)/1000000
	meas_aperture 	= inputParameters(testItems[3][1] ,"From 1 to 500(us):"		, "000"		,testItems[3][2]*1000000,1		,500	)/1000000
	rangev 			= inputParameters(testItems[4][1] ,"From 1,5,10(V):"		, "00"		,testItems[4][2]		,1		,10		)
	rangei 			= inputParameters(testItems[5][1] ,"From 1,5,10(A):"		, "00"		,testItems[5][2]		,1		,10		)
	source_protectv	= inputParameters(testItems[6][1] ,"From 2 to 40(V):"		, "00.00"	,testItems[6][2]		,2		,40		)
	sense_protectv	= inputParameters(testItems[7][1] ,"From 0.05 to 20(V):"	, "00.00"	,testItems[7][2]		,0.05	,20		)
	bias_current 	= inputParameters(testItems[8][1] ,"From -250 to 250(ms):"	, "+000"	,testItems[8][2]*1000	,-250	,250	)/1000

	-- Call the function
	digitize_pulse(current_level,pulse_width,meas_aperture,rangev,rangei,source_protectv,sense_protectv,bias_current)
	
	-- save data to usb drive in csv file format
	saveData(smua.nvbuffer1.timestamps,smua.nvbuffer1,smua.nvbuffer2,testItems)
end

runTest()
