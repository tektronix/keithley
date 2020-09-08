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
	
For Front Panel Operation:
	* Save this script to thumb drive and plug it into the instrument
	* Press MENU key->SRIPT->USB1
	* Select CurrentPulseSweepFrontPanelOperation.tsp and press ENTER key
	* Press RUN key  to run the script and result will be saved automatically as csv format

Parameters to be entered in Front Panel Operation:
	* Start Current : The current level of the first pulse in amps
	* Stop Current 	: The current level of the last pulse in amps
	* No of Pulses 	: Number of pulses in the sweep
	* Pulse Period 	: Time between start of consecutive pulses in microseconds
	* Pulse Width 	: Width of current pulses in microseconds
	* Aperture 		: Effective Integration time in microseconds
	* Meas Delay 	: Time from pulse start to measure start in microseconds
	* Range Voltage : Voltage measure range in volts
	* Range Current : Source and measure current Range in amps
	* Bias Current 	: Idle current level in amps(base level for pulses)

  
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
	local starti        = 1
	local stopi         = 10
	local npulse        = 10
	local pulse_period  = 1e-3
	local pulse_width   = 25e-6
	local meas_aperture = 1e-6
	local meas_delay    = 9e-6
	local rangev        = 10
	local rangei        = 10
	local bias_current  = 0
	
	local testItems = { }
	testItems[1] 	= {"Start Current"	,starti			}
	testItems[2] 	= {"Stop Current"	,stopi			}
	testItems[3] 	= {"No of Pulses"	,npulse			}
	testItems[4] 	= {"Pulse Period"	,pulse_period	}
	testItems[5] 	= {"Pulse Width"	,pulse_width	}
	testItems[6] 	= {"Aperture"		,meas_aperture	}
	testItems[7] 	= {"Meas Delay"		,meas_delay		}
	testItems[8] 	= {"Range Voltage"	,rangev			}
	testItems[9] 	= {"Range Current"	,rangei			}
	testItems[10] 	= {"Bias Current"	,bias_current	}	
	
	-- input parameters from front panel
	starti 			= inputParameters(testItems[1][1] ,"From -10 to +10 (A):"	, "+00.000"	,testItems[1][2]		,-10	,10		)
	stopi  			= inputParameters(testItems[2][1] ,"From -10 to +10 (A):"	, "+00.000"	,testItems[2][2]		,-10	,10		)
	npulse 			= inputParameters(testItems[3][1] ,"From 1 to 100 :"		, "000"		,testItems[3][2]		,1		,100	)
	pulse_period 	= inputParameters(testItems[4][1] ,"From 0.02 to 1000(ms):"	, "0000.00"	,testItems[4][2]*1000	,0.02	,1000	)/1000
	pulse_width 	= inputParameters(testItems[5][1] ,"From 10 to 500(us):"	, "000"		,testItems[5][2]*1000000,10		,500	)/1000000
	meas_aperture 	= inputParameters(testItems[6][1] ,"From 1 to 500(us):"		, "000"		,testItems[6][2]*1000000,1		,500	)/1000000
	meas_delay 		= inputParameters(testItems[7][1] ,"From 9 to 500(us):"		, "000"		,testItems[7][2]*1000000,9		,500	)/1000000
	rangev 			= inputParameters(testItems[8][1] ,"From 1,5,10(V):"		, "00"		,testItems[8][2]		,1		,10		)
	rangei 			= inputParameters(testItems[9][1] ,"From 1,5,10(A):"		, "00"		,testItems[9][2]		,1		,10		)
	bias_current 	= inputParameters(testItems[10][1],"From -250 to 250(ms):"	, "+000"	,testItems[10][2]*1000	,-250	,250	)/1000

	-- Call the function
	sweep_current_level(starti,stopi,npulse,pulse_period,pulse_width,meas_aperture,meas_delay,rangev,rangei,bias_current)
	
	-- save data to usb drive in csv file format
	saveData(smua.nvbuffer1.timestamps,smua.nvbuffer1,smua.nvbuffer2,testItems)
end

runTest()
