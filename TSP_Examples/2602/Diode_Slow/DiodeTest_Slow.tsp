--[[ DiodeTest_Slow.tsp

	Running this script creates functions which can be used to test diodes.  It
	also adds two menu selections to the SourceMeter display:  "DiodeTest_Slow" 
	and "DiodeTest_Fast".  Finally it runs the DiodeTest using smu=smua and 
	speed="SLOW" as defaults.  The user enters the number of diodes to test 
	from the front panel.
	
	The functions created are:
		1. Vfwd_Vrev(smu, irange, ilevel, srcdelay, vcmpl)
		2. DynZ(i1, v1, i2, v2)
		3. Ileakage(smu, vrange, vlevel, srcdelay, icmpl)
		4. TestStatus(testvalue, lolim, hilim)
		5. TestFail(teststatus)
		6. PartStatus(tst1fail, tst2fail, tst3fail, tst4fail, tst5fail, tst6fail)
		7. BinPart(tst1fail, tst2fail, tst3fail, tst4fail, tst5fail, tst6fail)
		8. DisplayTestStatus(testname, teststatus)
		9. DiodeTest(smu, ndiodes, speed)
	See detailed information listed in individual functions
	
	
	Revision History:
	This script was originally created by Keithley Instruments' Applications
	Engineering (Al Ivons) on 08 Apr 2005
]]	 

function Vfwd_Vrev(smu, irange, ilevel, srcdelay, vcmpl)

	-- This function performs a Forward Voltage Test or a Reverse Voltage Breakdown Test

	-- Pass parameters:
		-- smu is the SMU to use for the test (A or B); smua is the default if no SMU is specified
		-- irange is the source level used to select the source range
		-- ilevel is the test current level to use for the test
		-- srcdelay is the delay after the source is set before the measurement is started
		-- vcmpl is the voltage compliance limit for the test;
			-- vcmpl is also used to select the voltage measurement range 

	-- Default to smua if no smu is specified.
	if smu == nil then smu = smua end
	
	-- Prompt for input parameters if missing from pass list
  	  
	if ilevel == nil then
		ilevel = display.prompt("+0.000E+00", " Amps", "Enter Test Current.", 100E-6, -1, 1)
	end --if
	
	if irange == nil then irange = ilevel end
	
	if srcdelay == nil then
		srcdelay = display.prompt("00.000", " Seconds", "Enter Source Delay.", 0, 0, 20)	
	end --if

	if vcmpl == nil then
		vcmpl = display.prompt("+0.000E+00", " Volts", "Enter Compliance", 2, -40, 40)	
	end --if

	-- Temporary variables used by this function.
	local l_testcurrent, l_vmeasured

	-- Configure source and measure settings
	smu.source.func = smu.OUTPUT_DCAMPS
	smu.source.rangei = irange
	smu.source.leveli = ilevel
	smu.source.limitv = vcmpl
	smu.measure.rangev = vcmpl

	-- Wait before making measurement
	delay(srcdelay)
	
	-- Measure current and voltage
	l_testcurrent, l_vmeasured = smu.measure.iv()	

	--Set source output to zero
	smu.source.leveli = 0
	 
  	return l_vmeasured, l_testcurrent

end --function Vfwd_Vrev

function DynZ(i1, v1, i2, v2)

	--[[ This function calculates the Dynamic Impedance based on two forward voltage 
	or two reverse voltage measurements. ]] 
 
 	-- Pass parameters:
 		-- i1 is the test current used for first forward voltage measurement
 		-- v1 is the resulting voltage for first forward voltage measurement
 		-- i2 is the test current used for second forward voltage measurement
 		-- v2 is the resulting voltage for second forward voltage measurement 		
 		 		  
 	-- Temporary variables used by this function.
	local l_dz, l_denominator
	
	l_denominator = i2 - i1
	if l_denominator == 0 then l_denominator = 1E-37 end

		l_dz = (v2 - v1) / l_denominator	-- DynZ = (v2 - v1) / (i2 - i1)

	--	print(l_dz, l_denominator)
	
	return l_dz

end --function DynZ

function Ileakage(smu, vrange, vlevel, srcdelay, icmpl)

	--This function performs a Reverse Leakage Current Test
	
	-- smu is the SMU to use for the test (A or B); smua is the default if no SMU is specified
	-- vrange is the source level used to select the source range
	-- vlevel is the test voltage level to use for the test
	-- srcdelay is the delay after the source is set before the measurement is started
	-- icmpl is the current compliance limit for the test;
	-- icmpl is also used to select the current measurement range 

	-- Default to smua if no smu is specified.
	if smu == nil then smu = smua end

	-- Prompt for input parameters if missing from pass list
  	  
	if vlevel == nil then
		vlevel = display.prompt("+0.000E+00", " Volts", "Enter Test Voltage.", 1, -40, 40)
	end --if
	
	if vrange == nil then vrange = vlevel end
	
	if srcdelay == nil then
		srcdelay = display.prompt("00.000", " Seconds", "Enter Source Delay.", 0, 0, 20)	
	end --if
		
	if icmpl == nil then
		icmpl = display.prompt("+0.000E+00", " Amps", "Enter Compliance", 2, -40, 40)	
	end --if

	-- Temporary variables used by this function.
	local l_testvoltage, l_imeasured

	-- Configure source and measure settings
	smu.source.func = smu.OUTPUT_DCVOLTS
	smu.source.rangev = vrange
	smu.source.levelv = vlevel
	smu.source.limiti = icmpl
	smu.measure.rangei = icmpl

	-- Wait before making measurement
	delay(srcdelay)
	
	-- Measure current and voltage
	l_imeasured, l_testvoltage = smu.measure.iv()	

	--Set source output to 0
	smu.source.levelv = 0
		
	return l_testvoltage, l_imeasured

end --function Ileakage

function TestStatus(testvalue, lolim, hilim)
    
	--[[ This function determines the PASS/FAIL status of an individual test
	within the test sequence. It also creates a Boolean flag which is TRUE if
	the subject test fails.]] 
 
 	-- Pass parameters:
 		-- testvalue is the result (measurement or calculation) of an individual test
 		-- lolim is the minimum acceptable value for the subject test
 		-- hilim is the maximum acceptable value for the subject test	

	-- Temporary variables used by this function.
	local l_status
	local l_testfail

	if (testvalue >= lolim) and (testvalue <= hilim) then
		l_status = "PASS"
		l_testfail = false
	else
		l_status = "FAIL"
		l_testfail = true
	end --if
	
	return l_status, l_testfail

end --function TestStatus

function PartStatus(tst1fail, tst2fail, tst3fail, tst4fail, tst5fail, tst6fail)

	--[[ This function determines the GOOD/BAD status of the part based on the
	results of all of the tests in the test sequence. Any individual test failure
	causes the part to be BAD. ]] 
 
 	-- Pass parameters:
 		-- tst1fail is the Boolean FAIL flag for test #1 (Vf1)
 		-- tst2fail is the Boolean FAIL flag for test #2 (Vf2)
 		-- tst3fail is the Boolean FAIL flag for test #3 (DynZ)
 		-- tst4fail is the Boolean FAIL flag for test #4 (Ir1)
 		-- tst5fail is the Boolean FAIL flag for test #5 (Ir2)
 		-- tst6fail is the Boolean FAIL flag for test #6 (Vr)
 		 		
	-- Temporary variables used by this function.
	local l_status = "GOOD"

	if tst1fail or tst2fail or tst3fail or tst4fail or tst5fail or tst6fail then l_status = "BAD" end
	
	return l_status

end --function PartStatus

function BinPart(tst1fail, tst2fail, tst3fail, tst4fail, tst5fail, tst6fail, bins)
         
	--[[ This function increments the "Part Bins" table simulating the bins a component 
	handler may use.  The incremented bin corresponds to either the first test a part fails, 
	or to the ALL PASS/GOOD PART status. Note: The table "bins" is modified by this function. ]] 

	if tst1fail then			-- If part first failed Forward Voltage Test #1
		bins[2] = bins[2] + 1
	elseif tst2fail then		-- If part first failed Forward Voltage Test #2
		bins[3] = bins[3] + 1
	elseif tst3fail then		-- If part first failed Dynamic Impedance Test
		bins[4] = bins[4] + 1
	elseif tst4fail then		-- If first failed Reverse Leakage Current Test #1
		bins[5] = bins[5] + 1
	elseif tst5fail then		-- If first failed Reverse Leakage Current Test #2
		bins[6] = bins[6] + 1
	elseif tst6fail then		-- If first failed Reverse Voltage Breakdown Test
		bins[7] = bins[7] + 1
	else						-- Part is GOOD; does not fail any tests
		bins[1] = bins[1] + 1
	end --if

end -- function BinPart

function DisplayTestStatus(testname, testvalue, testunit, teststatus, disp_delay)

	-- This function displays individual test results on the front panel display
	
 	-- Pass parameters:
		-- testname is a the label to display to identify the test (e.g "Vf1: ")
 		-- testvalue is the result (measurement or calculation) of an individual test
		-- testunit is the unit to display with testvalue (e.g. "V", "A")
 		-- teststatus is the PASS/FAIL status of the subject test
 		-- disp_delay is a delay time used to pace the display 

	display.clear()
	display.setcursor (1,1)
	display.settext(testname)
	delay(disp_delay)
	display.settext(tostring(testvalue)..testunit)
	delay(disp_delay)
	display.setcursor (2,1)
	display.settext("Test Status: "..teststatus)
	delay(disp_delay)
   
end --function

function DisplayPartStatus(partstatus, bins)

	-- Temporary variables used by this function.
	local l_i

	display.clear()
	display.setcursor(1,1)
	display.settext("Part Status:  "..partstatus)

	display.setcursor(2,1)
	
	display.settext("Bin Counts: ")
	
	for l_i = 1, 7 do
	
		display.settext(tostring(bins[l_i]).." ")
--		display.settext("B"..tostring(l_i).."="..tostring(bins[l_i]).." ")
	end --for

end --function DisplayPartStatus

function DiodeTest(smu, ndiodes, speed)

	--[[ This function performs a complete diode test sequence consisting of 6 tests 
	(5 measurements and one calculation).  The tests include:
		2 Forward Voltage tests (vf1 and vf2)
		1 Dynamic Impedance test (dynz)
		2 Reverse Leakage Current tests (ir1 and ir2)
		1 Reverse Voltage Breakdown test (vr)
		
	The individual tests are executed in the order they are listed.  Test results are 
	inspected against limits and pass/fail status is displayed on the front panel.  
	Based on the pass/fail results the part is "binned."  Digital I/O port Bit 1 is set 
	high if the diode is GOOD and Bit 2 is set high if the part is BAD. ]]

	--[[ Revision History:
	This test executive function and related supporting functions were 
	originally created by Al Ivons on 07 Apr 2005 ]]
	
	-- Pass parameters:
		-- smu is the SMU to use for the test (A or B); smua is the default if no SMU is specified
		-- ndiodes is the number of diodes to test (i.e. number of times to repeat the test sequence)		
		-- speed is either FAST or SLOW and affects NPLC, delays, autozero, displays, etc.
			--"SLOW" is the default if no speed is specified
	
	-- Default to smua if no smu is specified.
	if smu == nil then smu = smua end

	-- Prompt user to enter Number of Diodes to Test if input parameter is missing.
--  	display.clear()
	if ndiodes == nil then
		ndiodes = display.prompt("0000", " Diodes", "Enter how many diodes to test.", 1, 1, 9999)	
	end --if

	-- Default to "SLOW" if no speed is specified.
	if speed == nil then speed = "SLOW" end
	
	-- ***** Temporary variables used by this function *****

	-- Save settings in temporary variables so they can be restored at the end.
	local l_s_func = smu.source.func
	local l_s_autorangei = smu.source.autorangei
	local l_s_rangei = smu.source.rangei
	local l_s_leveli = smu.source.leveli 
	local l_m_autorangev = smu.measure.autorangev
	local l_m_rangev = smu.measure.rangev
	local l_d_screen = display.screen

	-- Test Inspection Limits (based on Keithley P/N PL-118-1)
	local l_vf1_lowlim = 3.078		-- Low inspection limit for vf1
    local l_vf1_highlim = 3.762		-- High inspection limit for vf1
	local l_vf2_lowlim = 3.366		-- Low inspection limit for vf2
    local l_vf2_highlim = 4.114		-- High inspection limit for vf2
    local l_dynz_lowlim = -26.4		-- Low inspection limit for dynz
    local l_dynz_highlim = 69.1		-- High inspection limit for dynz
    local l_ir1_lowlim = -2E-5		-- Low inspection limit for ir1
    local l_ir1_highlim = 0			-- High inspection limit for ir1
	local l_ir2_lowlim = -20E-5		-- Low inspection limit for ir2
    local l_ir2_highlim = 0			-- High inspection limit for ir2
    local l_vr_lowlim = -39.1		-- Low inspection limit for vr
    local l_vr_highlim = -28.9		-- High inspection limit for vr
      
	-- Source and measure settings are based on Keithley P/N PL-118-1
	-- Variables used to configure source and measure settings for vf1 test
    local l_vf1_isrc_rng = 0.005
    local l_vf1_isrc_lev = 0.005
    local l_vf1_src_del = 0.1		--"SLOW" value is default
	if speed == "FAST" then l_vf1_src_del = 0 end
    local l_vf1_vcmpl = 10

	-- Variables used to configure source and measure settings for vf2 test
    local l_vf2_isrc_rng = 0.02
    local l_vf2_isrc_lev = 0.02
    local l_vf2_src_del = 0.1		--"SLOW" value is default
	if speed == "FAST" then l_vf2_src_del = 0 end
    local l_vf2_vcmpl = 10
    
	-- Variables used to configure source and measure settings for ir1 test 
    local l_ir1_vsrc_rng = 40
    local l_ir1_vsrc_lev = -20
    local l_ir1_src_del = 0.1		--"SLOW" value is default
	if speed == "FAST" then l_ir1_src_del = 0 end
    local l_ir1_icmpl = 100E-6

	-- Variables used to configure source and measure settings for ir2 test
    local l_ir2_vsrc_rng = 40
    local l_ir2_vsrc_lev = -25
    local l_ir2_src_del = 0.1		--"SLOW" value is default
	if speed == "FAST" then l_ir2_src_del = 0 end
    local l_ir2_icmpl = 100E-6
    
	-- Variables used to configure source and measure settings for vr test
    local l_vr_isrc_rng = 100E-6
    local l_vr_isrc_lev = -100E-6
    local l_vr_src_del = 0.1		--"SLOW" value is default
	if speed == "FAST" then l_vr_src_del = 0 end
    local l_vr_vcmpl = 40
    
    -- Integration time used for all measurements
	-- Expressed in terms of powerline cycles (PLC)
 	local l_nplc = 1			--"SLOW" value is default
 	if speed == "FAST" then l_nplc = 0.001 end
 	
	-- Boolean flag used to select autozero mode (true = auto and false = once)
	local l_azero_on = true		--"SLOW" value is default
	if speed == "FAST" then l_azero_on = false end
	 	 	
	-- Boolean flag used to select state of the display (true = on and false = off)	 	
 	local l_disp_on = true		--"SLOW" value is default
	if speed == "FAST" then l_disp_on = false end
	
	-- Delay (in seconds) to slow sequence down for viewing when speed = "SLOW"
	local l_delay = 1			--"SLOW" value is default
	if speed == "FAST" then l_delay = 0 end
			
	-- Tables used to hold test data and pass/fail status for vf1 test
    local l_vf1_test_curr = {}
    local l_vf1_data = {}
	local l_vf1_status = {}
	local l_vf1_fail = {}

	-- Tables used to hold test data and pass/fail status for vf2 test
    local l_vf2_test_curr = {}
	local l_vf2_data = {}
	local l_vf2_status = {}
	local l_vf2_fail = {}

	-- Tables used to hold test data and pass/fail status for dynz test
	local l_dynz_data = {}
	local l_dynz_status = {}
	local l_dynz_fail = {}

	-- Tables used to hold test data and pass/fail status for ir1 test
    local l_ir1_test_volt = {}
	local l_ir1_data = {}
	local l_ir1_status = {}
	local l_ir1_fail = {}

	-- Tables used to hold test data and pass/fail status for ir2 test
    local l_ir2_test_volt = {}
	local l_ir2_data = {}
	local l_ir2_status = {}
	local l_ir2_fail = {}

	-- Tables used to hold test data and pass/fail status for vr test
    local l_vr_test_curr = {}
	local l_vr_data = {}
	local l_vr_status = {}
	local l_vr_fail = {}
	
	-- Table to hold good/bad part status based on cumulative results of all tests
	local l_part_status = {}
	
	-- Table used to count parts put into simulated bins of a component handler
	local l_bins = {0,0,0,0,0,0,0}  -- Initially set all bins to zero

	-- Variables to hold timing information
	local l_start_time, l_stop_time, l_elapsed_time

	-- Counter variable
	local l_i
      
	-- ***** Perform initial setup of the 2602 *****
	-- Individual test functions will configure source and measure settings as necessary.
	-- For simplicity, LOCAL (2-wire) voltage sensing is used.
	-- It is straightforward to change to REMOTE (4-wire) sensing. 

	smu.reset()
	smu.source.func = smu.OUTPUT_DCVOLTS
	smu.source.levelv = 0
	smu.sense = smu.SENSE_LOCAL		-- use smu.SENSE_REMOTE for 4-w sensing
	smu.measure.nplc = l_nplc

	if l_azero_on then
		smu.measure.autozero = smu.AUTOZERO_AUTO
	else
		smu.measure.autozero = smu.AUTOZERO_ONCE
	end --if

	digio.writeport(0)		-- Set all unprotected bits to zero
	
	errorqueue.clear()		-- Clear the error queue
   
	-- ############################## RUN TEST ##############################
	
	if speed == "FAST" then
		display.clear()
		display.setcursor (1,1)
		display.settext("Test In Progress")
		display.setcursor (2,1)
		display.settext("Testing "..tostring(ndiodes).." Parts")		
	end --if     

	timer.reset()
	l_start_time = timer.measure.t()

	smu.source.output = smu.OUTPUT_ON
	
	for l_i = 1, ndiodes do

		-- Perform Forward Voltage Test #1 (Vf1)

		l_vf1_data[l_i], l_vf1_test_curr[l_i] = Vfwd_Vrev(smu, l_vf1_isrc_rng, l_vf1_isrc_lev, l_vf1_src_del, l_vf1_vcmpl)
		l_vf1_status[l_i], l_vf1_fail[l_i] = TestStatus(l_vf1_data[l_i], l_vf1_lowlim, l_vf1_highlim)
		if l_disp_on then DisplayTestStatus("Vf1 = ", l_vf1_data[l_i], "V", l_vf1_status[l_i], l_delay) end

		-- Perform Forward Voltage Test #2 (Vf2)
				
		l_vf2_data[l_i], l_vf2_test_curr[l_i] = Vfwd_Vrev(smu, l_vf2_isrc_rng, l_vf2_isrc_lev, l_vf2_src_del, l_vf2_vcmpl)
		l_vf2_status[l_i], l_vf2_fail[l_i] = TestStatus(l_vf2_data[l_i], l_vf2_lowlim, l_vf2_highlim)
		if l_disp_on then DisplayTestStatus("Vf2 = ", l_vf2_data[l_i], "V", l_vf2_status[l_i], l_delay) end

		-- Perform Dynamic Impedance Test (DynZ)
		
		l_dynz_data[l_i] = DynZ(l_vf1_test_curr[l_i], l_vf1_data[l_i], l_vf2_test_curr[l_i], l_vf2_data[l_i])
		l_dynz_status[l_i], l_dynz_fail[l_i] = TestStatus(l_dynz_data[l_i], l_dynz_lowlim, l_dynz_highlim)
		if l_disp_on then DisplayTestStatus("DynZ: ", l_dynz_data[l_i], " Ohm", l_dynz_status[l_i], l_delay) end

		-- Perform Reverse Leakage Current Test #1 (Ir1)
		
		l_ir1_test_volt[l_i], l_ir1_data[l_i] = Ileakage(smu, l_ir1_vsrc_rng, l_ir1_vsrc_lev, l_ir1_src_del, l_ir1_icmpl)
		l_ir1_status[l_i], l_ir1_fail[l_i] = TestStatus(l_ir1_data[l_i], l_ir1_lowlim, l_ir1_highlim)
		if l_disp_on then DisplayTestStatus("Ir1 = ", l_ir1_data[l_i], "A", l_ir1_status[l_i], l_delay) end
				
		-- Perform Reverse Leakage Current Test #2 (Ir2)
		
		l_ir2_test_volt[l_i], l_ir2_data[l_i] = Ileakage(smu, l_ir2_vsrc_rng, l_ir2_vsrc_lev, l_ir2_src_del, l_ir2_icmpl)
		l_ir2_status[l_i], l_ir2_fail[l_i] = TestStatus(l_ir2_data[l_i], l_ir2_lowlim, l_ir2_highlim)
		if l_disp_on then DisplayTestStatus("Ir2 = ", l_ir2_data[l_i], "A", l_ir2_status[l_i], l_delay) end

		-- Perform Reverse Voltage Breakdown Test (Vr)
		
		l_vr_data[l_i], l_vr_test_curr[l_i] = Vfwd_Vrev(smu, l_vr_isrc_rng, l_vr_isrc_lev, l_vr_src_del, l_vr_vcmpl)
		l_vr_status[l_i], l_vr_fail[l_i] = TestStatus(l_vr_data[l_i], l_vr_lowlim, l_vr_highlim)
		if l_disp_on then DisplayTestStatus("Vr = ", l_vr_data[l_i], "V", l_vr_status[l_i], l_delay) end

		-- Determine cumulative part status
		
		l_part_status[l_i] = PartStatus(l_vf1_fail[l_i], l_vf2_fail[l_i], l_dynz_fail[l_i], l_ir1_fail[l_i], l_ir2_fail[l_i], l_vr_fail[l_i])		

		-- Bin the part
		
		BinPart(l_vf1_fail[l_i], l_vf2_fail[l_i], l_dynz_fail[l_i], l_ir1_fail[l_i], l_ir2_fail[l_i], l_vr_fail[l_i], l_bins) 

		if l_disp_on then DisplayPartStatus(l_part_status[l_i], l_bins) end
		delay(3 * l_delay)

		if l_part_status[l_i] == "GOOD" then
			digio.writebit(1,1)		-- Set Bit 1 HIGH
            delay(l_delay)			-- Delay a little
            digio.writebit(1,0)     -- Set Bit 1 LOW
		else                 		-- If "BAD" then ...
			digio.writebit(2,1)     -- Set Bit 2 HIGH
            delay(l_delay)			-- Delay a little
            digio.writebit(2,0)     -- Set Bit 2 LOW
		end --if
		
	end --for
	
	smu.source.output = smu.OUTPUT_OFF
	
	l_stop_time = timer.measure.t()
	l_elapsed_time = l_stop_time - l_start_time
	
	display.clear()
	display.setcursor (1,1)
	display.settext("Parts per sec = "..tostring(ndiodes / l_elapsed_time))
	display.setcursor(2,1)
	display.settext("Bin Count: ")             
	for l_i = 1, 7 do
		display.settext(tostring(l_bins[l_i]).." ")
	end --for
	delay(5)

	-- Update the front panel display and restore modified settings.
	smu.source.func = l_s_func 
	smu.source.autorangei = l_s_autorangei
	smu.source.rangei = l_s_rangei
	smu.source.leveli = l_s_leveli
	smu.measure.autorangev = l_m_autorangev
	smu.measure.rangev = l_m_rangev
	display.clear()
	display.screen = l_d_screen

end --function DiodeTest

print("FUNCTIONS CREATED")

display.loadmenu.add("DiodeTest_Slow", "DiodeTest(smua, nil, 'SLOW')")
display.loadmenu.add("DiodeTest_Fast", "DiodeTest(smua, nil, 'FAST')")

print("MENU ITEMS ADDED")

DiodeTest(smua, nil, "SLOW")

