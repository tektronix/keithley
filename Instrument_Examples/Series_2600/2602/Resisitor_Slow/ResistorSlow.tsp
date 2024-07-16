--[[
ResistorSlow():

This program performs a resistance test on a 10kohm part. 

Required equipment:

(1) Keithley 2602 System Sourcemeter(c)
(1) Keithley 8101-04-TRX Test Fixture
(2) Keithley 2600-DEMO-TRX cables 

Rev1: JAC 4.7.2005
Rev2: Added Print Data Option
	  JAC 4.22.2005
	  
]]--

------------------ Keithley TSP Function ------------------
function res_test(smu,irange,ilevel,srcdelay,vcmpl)

--Source current on selected smu channel and measure voltage.
--Calculate and return resistance value.
  
--Pass parameters:
-- smu is the smu channel selected for the test (A or B); smua is default
-- irange is source current range; 1mA default
-- ilevel is source current value; 500 ua default
-- srcdelay is the delay after source is set before the measurement is started; 0s default
-- vcmpl is the voltage compliance limit and measurement range; 10V default   
    
    --default to smua if no smu specified
    if smu == nil then smu = smua end
    
    --prompt for input parameters if missing from list
    
    if ilevel == nil then
    	ilevel = display.prompt("0.000E+00", " Amps", "Enter Test Current.", 500E-6,-1E-3,1E-3)
    end --end if
    
    if irange == nil then irange = ilevel end
    
    if srcdelay == nil then
    	srcdelay = display.prompt("00.000", " Seconds", "Enter Source Delay.", 0,0,20)
    end --end if
    
    if vcmpl == nil then
    	vcmpl = display.prompt("+0.000E+00", " Volts", "Enter Voltage Compliance.", 2,-40,40)
    end --end if
    
    --Temporary variables used by this function	
    local l_vmeasured,l_isourced
    
    
    --Configure source and measure settings
    smu.source.func = smu.OUTPUT_DCAMPS
    smu.source.rangei = irange
    smu.source.leveli = ilevel
    smu.source.limitv = vcmpl
    smu.measure.rangev = vcmpl
    
    --wait before making measurement
    delay(srcdelay)
    
    --measure current and voltage
    l_isourced, l_vmeasured = smu.measure.iv()
    
    return l_vmeasured/l_isourced --Return quotient = resistance calculation
    
end --function res_test()


function test_status(testvalue, lolim, hilim)

	--Temporary variables used by this function.
	local l_status
	local l_testfail
	
	if (testvalue >= lolim) and (testvalue <= hilim) then
		l_status = "PASS"
		l_testfail = false
	else
	 	l_status = "FAIL"
    	l_testfail = true
	end --if
	
	return l_status,l_testfail
	
end --function test_status() 


function part_status(tst1fail)

	--Temporary variables used by this function.
	local l_status = "GOOD"
	
	if tst1fail then l_status = "BAD" end
	
	return l_status
	
end --function part_status()


function bin_part(tst1fail, bins)

	if tst1fail then --if first test fails increment bin
		bins[2] = bins[2] + 1 
	else 
		bins[1] = bins[1] + 1 --part is good
	end --if
	
end --function bin_part()


function DisplayTestStatus(testname,testvalue,teststatus,disp_delay)

	--This function displays individual test results on the front panel display.
	
	display.clear()
	display.setcursor(1,1)
	display.settext(testname)
	delay(disp_delay)
	display.settext(tostring(testvalue))
	delay(disp_delay)
	display.setcursor(2,1)
	display.settext("Test Status: "..teststatus)
	delay(disp_delay)

end --function DisplayTestStatus()	    
    

function DisplayPartStatus(partstatus,bins)

	--Temporary variables used by this function.
	local l_i
	
	display.clear()
	display.setcursor(1,1)
	display.settext("Part Status: "..partstatus)
	display.setcursor(2,1)
	display.settext("Bin Counts: ")
	
	for l_i = 1,2 do
		
		display.settext(tostring(bins[l_i]).." ")
	
	end --for

end --function DisplayPartStatus()

function ResistorTest(smu,nresistors,speed, returndata)

	--[[This function performs a resistor test and the measurement
	is compared to defined pass/fail limits. The results are displayed on the front
	panel.
	]]--

    --Default to smua if no smu specified
    if smu == nil then smu = smua end
    
    --Prompt user for number of resistors
    if nresistors == nil then
    	nresistors = display.prompt("0000"," Resistors", "Enter number of devices to test", 1, 1, 9999)
    end
    
    if speed == nil then speed = "SLOW" end	
    	
	--Save settings in temporary variables so that they can be restored.
	local l_s_func = smu.source.func
	local l_s_autorangei = smu.source.autorangei
	local l_s_rangei = smu.source.rangei
	local l_m_autorangev = smu.measure.autorangev
	local l_v_rangev = smu.measure.rangev
	local l_d_screen = display.screen

	--Test inspection limits
	local l_res_lolimit = 10.2E+3 
	local l_res_hilimit = 9.8E+3
	
	--Variables used to configure source and measure in res_test()
	local l_res_isource_range = 1E-3
	local l_res_isource_level = 500E-6
	local l_res_source_delay = 0.1 --"SLOW" default
	if speed == "FAST" then l_res_source_delay = 0  end
	local l_res_vcmpl = 40
	
	--Variable used to configure measurement time
	local l_res_nplc = 1 --"Slow" default
	if speed == "FAST" then l_res_nplc = 0.001 end  

	--Variable used to store number of devices to test
	local l_nresistors = nresistors --
	
    --Boolean flag used to select Autozero state
	local l_azero_on = true --"Slow" default
	if speed == "FAST" then l_azero_on = false end  

	--Boolen flag used for display state (true == on, false == off)
	local l_disp_on = true --"SLOW" is default
	if speed == "FAST" then l_disp_on = false end
	
    --Display delay
	local l_delay = 1 --"Slow" default
	if speed == "FAST" then l_delay = 0 end
	
	--Variable to hold Print decision
	local l_return_data = returndata
	
	--Tables used to hold test data and pass/fail
	--local l_res_isourced = {}
	--local l_res_vmeasured = {}
	local l_res_calc = {}
	local l_res_status = {}
	local l_res_fail = {}
	
	--Table to hold good/bad part status for cumulative results of all tests
	local l_part_status = {}
	
	--Table used to count simulated bin entries
	local l_bins = {0,0} --intialize to 0
	
	--Variables to hold timing information
	local l_start_time,l_stop_time,l_elapsed_time
	
	--Counter
	local l_i
	
	--**Initial 2602 Setup**--
	--2 wire sensing is used as default
	
    smu.reset()
	smu.source.func = smu.OUTPUT_DCVOLTS
    smu.source.levelv = 0
    smu.sense = smu.SENSE_LOCAL   
 	smu.measure.nplc = l_res_nplc

 	if l_azero_on then
 		smu.measure.autozero = smu.AUTOZERO_AUTO
 	else
 		smu.measure.autozero = smu.AUTOZERO_ONCE
 	end --end if
 	
	
 	digio.writeport(0) --Set unprotected bits to 0 
 	
 	errorqueue.clear() --Clear the error queue
 	
 	--**Run Test**--
 	
 	if speed == "FAST" then
 		display.clear()
 		display.setcursor(1,1)
 		display.settext("Test in Progress")
 		display.setcursor(2,1)
 		display.settext("Testing "..tostring(l_nresistors).." Parts")
 	end --if
 	
 	timer.reset()
 	l_start_time = timer.measure.t()
 	smu.source.output = smu.OUTPUT_ON
 	
 	for l_i = 1,l_nresistors do

--Retreive data
 	    l_res_calc[l_i] = res_test(smu,l_res_isource_range, l_res_isource_level,l_res_source_delay,l_res_vcmpl)

--Print Data
	if l_return_data == "yes" then
	    --print(l_return_data)
		printdata(l_i, l_res_calc[l_i])--pass variable to printdata()
	end --if
	
--Determine Pass/fail
        l_res_status[l_i],l_res_fail[l_i] = test_status(l_res_calc[l_i],l_res_lolimit,l_res_hilimit)    
         
--Determine part status
		l_part_status[l_i] = part_status(l_res_fail[l_i])
		
        if l_disp_on then DisplayTestStatus("Ohms: ", l_res_calc[l_i],l_res_status[l_i],l_delay) end
     
	    --Bin the part
	    bin_part(l_res_fail,l_bins)
	

	    if l_disp_on then DisplayPartStatus(l_part_status[l_i],l_bins) end
	    delay(3*l_delay)
	
	    if l_part_status[l_i] == "GOOD" then
		    digio.writebit(2,1) --Set bit 2 Hi, DUT pass
			delay(l_delay)
			digio.writebit(2,0) --Set bit 2 Lo
		else
	    	digio.writebit(8,1) --Set bit 8 Hi, DUT fails
			delay(l_delay)
			digio.writebit(8,0) --Set bit 8 Lo
		end --if
 	
 	end --for

	smu.source.output = smu.OUTPUT_OFF
	
	l_stop_time = timer.measure.t()
	l_elapsed_time = l_stop_time - l_start_time
	
	for l_i = 1,2 do
		display.settext(tostring(l_bins[l_i].." "))
	end --for
	delay(5)
	
	display.clear()
	
	--Update display and restore settings
	 smu.source.func =  l_s_func
	 smu.source.autorangei = l_s_autorangei
	 smu.source.leveli = 0
	 smu.source.rangei = l_s_rangei 
	 smu.measure.autorangev = l_m_autorangev
	 smu.measure.rangev = l_v_rangev
	 display.screen = l_d_screen 
	
end --function ResistorTest()

function printdata(i,data)
--print data to immediate window
	--Local Variable
	local l_i = i --Loop count
	local l_data = data
	
	if l_i == 1 then
		print("Readings (Ohms):")
	end --for
	
	print(l_data)
	
end --function printdata()


display.loadmenu.add("ResistorTest_Slow","ResistorTest(smua,nil,'SLOW','no')")
display.loadmenu.add("ResistorTest_Fast", "ResistorTest(smua,nil,'FAST','no')")

ResistorTest(smua, nil, 'SLOW','yes')

	
	--delay(disp_delay)
	