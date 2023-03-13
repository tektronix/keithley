--[[
	
Script: BatterySimluator_2400Interactive.tsp
Written by: Keithley Field Applications (Ken Positeri)
`
***********************************************************
*** Copyright 2023 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************
]]

--[[ 
General:
------------------------------------------------------------------------------
Average Current: Total Current / Number of readings
Multiplier:  Discharge Time in seconds / 3600
Total Charge Used = Average Current * Multiplier
Battery Percentage = Battery Capacity – Total Charge Used
Percentage Look Up
Battery Percentage vs. battery model
Vout total: V @ total battery percentage
Vout
	Vesr = current * esr
	Vout total = Vtotal - Vesr
battery level, batterycapacity, exitPrcent
]]

------------------------------------------------------------------------------
-- Desired upgrades to graphical display 
	-- X axis method set to All, Y axis set to SmartScale
	-- Add defbuffer1:Src to display. Default display: defbuffer1:MEAS add
	-- Remote text indicating battery percentage
------------------------------------------------------------------------------

-- Set Globals

	disSOC = 100  -- User supplied SOC default value
	disCAP = 1.0  -- User supplied battery capacity default value
	disiLIMIT = 1 -- User supplied default current limit
	disSELBAT = ""
	--filNum = 1  -- file number reference for saved data
	dataSave = 0  -- Save data to file flag
	disStart = display.BUTTON_OK
	modelSelect = 0 -- flag to select internal battery model or USB drive
	batName = "" -- Battery file name from USB drive
	intrpIndex = 0.00 -- interpolation battery index rounded to two decimals
	ESRIntFlag = 0
	sFlag = 0
	filMeasCount = 0 -- main counter for file storage selection
	filCount = 0  -- tracks current file to store data

	smu.measure.sense = smu.SENSE_4WIRE
-------------------------------------------------------------------------------
--     functions
-------------------------------------------------------------------------------

function SetUpPrompts()

	local dialog_text = ""
	local modnum = 2450
	local maxcurr = 1
	local l_k = 0
	local l_numFiles = 10  -- set the number of data files created to 10
	local l_capacity = 1  -- battery capacity

	reset()
	display.changescreen(display.SCREEN_HOME)
	eventlog.clear()

---- Default battery model selection -- Models to be created and embedded into the script  ---------------------------------------------------------------	
	l_dialog_text = "Select Model location"
    disSELBAT = display.input.option(l_dialog_text, "Internal", "USB Select")  -- display.BUTTON_OPTION1 (value 5), display.BUTTON_OPTION2 (value 6) respectively
    
    if disSELBAT == display.BUTTON_OPTION1 then  -- Default battery menu selection
		select_items = {}
		for i = 1, 10 do -- preload the display table items
			select_items[i] = ""
		end
		
		-- Additional models can be added to internal model selection as needed -------------------------
		num_items = 0
		num_items=0
		select_items[1] = "AAA-NiMH"  -- BatModelAAA()
		select_items[2] = "CR2032_30mA"  -- BatModelCR2032at30mA()
		select_items[3] = "CR2032_1mA"  -- BatModelCR2032at1mA()
		select_items[4] = "INR18650"  -- BatModelINR18650()
		select_items[5] = "CR2450"  -- BatModelCR2450()
		select_items[6] = "CR2016"  -- BatModelCR2016()
	
		l_dialog_text = "Select Battery Model File"
		NoFileSelected = true
		while NoFileSelected do
			batSel = display.input.option(l_dialog_text, select_items[1], select_items[2], select_items[3], select_items[4], select_items[5], select_items[6], select_items[7], select_items[8], select_items[9], select_items[10] )
 			batName = select_items[tonumber(string.sub(tostring(batSel),22))]
 			if batName ~= "" then NoFileSelected = false end
 		end
		if batSel == display.BUTTON_OPTION1 then
			BatModelAAA()
		elseif batSel == display.BUTTON_OPTION2 then
			BatModelCR2032at30mA()
		elseif batSel == display.BUTTON_OPTION3 then
			BatModelCR2032at1mA()
		elseif batSel == display.BUTTON_OPTION4 then
			BatModelINR18650()
		elseif batSel == display.BUTTON_OPTION5 then
			BatModelCR2450()
		elseif batSel == display.BUTTON_OPTION6 then
			BatModelCR2016()
		end
	end
----------------------------------------------------------------------------------------------------------------------------------------------------------    
	if disSELBAT == display.BUTTON_OPTION2 then  -- OPTION2
		TestForDrive()
    	select_items = ""
    	num_items = 0
    	USBfolder = fs.readdir("/usb1/")
		num_items=0
		select_items = {}
		for i=1,table.getn(USBfolder) do
    		filename=string.lower(USBfolder[i])
    		if string.find(filename, "csv") ~= nil then -- file is a CSV file  Condsider changing to .mdl extension
    			num_items = num_items + 1
    			select_items[num_items] = filename
    			-- debug print("file: "..filename)
    		end
    	end
    	--print(num_items)
    	if num_items == 0 then
			l_dialog_text = "NO CSV Files ON USB"
    		display.input.prompt(display.BUTTONS_OKCANCEL, l_dialog_text)
    		exit()
    	end
		for i=1,10 do
    		if i > num_items then select_items[i] = "" end -- fill table with at least 10 strings - null string if no file
    	end
		l_dialog_text = "Select Battery Model File"
		NoFileSelected = true
		while NoFileSelected do
			batSel = display.input.option(l_dialog_text, select_items[1], select_items[2], select_items[3], select_items[4], select_items[5], select_items[6], select_items[7], select_items[8], select_items[9], select_items[10] )
 			batName = select_items[tonumber(string.sub(tostring(batSel),22))]
 			if batName ~= "" then NoFileSelected = false end
 		end
 		
 		batModel(batName)

	end
	
	l_dialog_text = "State of Charge: 2-100%"
    disSOC = display.input.number(l_dialog_text, display.NFORMAT_INTEGER, 100, 1, 100) 
    
    -- Add Selection for Simulation End for SOC or Voltage
    l_dialog_text = "End State of Charge: 1-99%"
    disXSOC = display.input.number(l_dialog_text, display.NFORMAT_INTEGER, 20, 1, 99) 

	-- read battery model capacity
	l_dialog_text = "Battery Capacity: AH 10A max"
    disCAP = display.input.number(l_dialog_text, display.NFORMAT_DECIMAL, dftCap, 0.000001, 10) 
    
    -- adjust maximum and minimum capacity values as needed. 
	modnum = localnode.model	-- this will return a string value so account for it in the following if statement
	if modnum == "2450" or modnum == "2470" then	
		maxcurr = 1	
		l_dialog_text = "Test Current Limit 1A max"	
	else
		maxcurr = 7
		l_dialog_text = "Test Current Limit 7A max"
	end
    
    disiLIMIT = display.input.number(l_dialog_text, display.NFORMAT_DECIMAL, 1.0, 0.000001, maxcurr)
    
    l_dialog_text = "Device load >20 nF?"
    disHighC = display.input.prompt(display.BUTTONS_YESNO, l_dialog_text)
    if disHighC == display.BUTTON_YES then
    	smu.source.highc = smu.ON
    else
    	smu.source.highc = smu.OFF
    end
    
    l_dialog_text = "Save data to file?"
    disSaveData = display.input.prompt(display.BUTTONS_YESNO, l_dialog_text)
	if disSaveData == display.BUTTON_YES then
		dataSave = 1
		TestForDrive()
		-- Test for DATA directory -----------------------

		l_isfold = fs.is_dir("DATA")
		if l_isfold ~= true then
			l_status = file.mkdir("DATA")
		end
		--------------------------------------------------	

		l_dialog_text = "Enter data file name"
		filName = display.input.string(l_dialog_text, display.SFORMAT_ANY)

		filNumA = {}
		filNameA = {}

		foldName = filName
		file.mkdir(foldName)
		-------------------------------------------------------------------------------------------
		-- prompt to indicate file creation
		display.clear()
		display.changescreen(display.SCREEN_USER_SWIPE)
		display.settext(display.TEXT1, "Data Set Up")
		display.settext(display.TEXT2, "Creating User Files")
		-------------------------------------------------------------------------------------------
		for l_k = 1, l_numFiles do -- default create number of files specified by l_numFiles for data storage. Edit as needed
			filNameA[l_k] = foldName .. l_k
			filNameA[l_k] = "/usb1/" .. foldName.. "/".. filNameA[l_k] .. ".csv"
			
			filNumA[l_k] = file.open(filNameA[l_k], file.MODE_WRITE)
			--print(filNameA[l_k], filNumA[l_k])
			-- Write header into .csv file
			l_saveString = "Time" .. "," .. "Volt" .. "," .. "Current" .. "\n"
			file.write(filNumA[l_k], l_saveString)
			file.flush(filNumA[l_k])
			--file.close(filNumA[l_k])  -- Cannot close files until all files are created and assigned a file number.
			--filName = ""
		end
		--------------------------------------------
		-- Keep open until program ends?
		for l_k = 1, l_numFiles do  -- create eight files.
			file.close(filNumA[l_k])
		end
		--------------------------------------------
		-------------------------------------------------------------------------------------------
		-- prompt to indicate file creation
		display.settext(display.TEXT1, "Data Set Up")
		display.settext(display.TEXT2, "Complete")
		delay(.25)
		-------------------------------------------------------------------------------------------
	end	

	l_dialog_text = "Press OK to start test"
	disStart = display.input.prompt(display.BUTTONS_OKCANCEL, l_dialog_text)
	if disStart == display.BUTTONS_OK then
		Main(disiLIMIT,disCAP,disSOC,disXSOC)
	else
		exit()
	end
end		-- end SetUpPrompts

function DischargeCurrent(iLimit, batCpcty, SOC, exitPrcnt)

	filMeasCount = 0 -- main counter for file storage selection
	filCount = 1  -- tracks current file to store data starting at 1
			
	-- SOC(State of Charge) is in percent
	-- batCpcty is maximum battery capacity of battery model
	
	if iLimit == nil then iLimit = .9 end
	if batCpcty == nil then batCpcty = 1.0 end
	if SOC == nil then SOC = 100 end
	if exitPrcnt == nil then exitPrcnt = 50 end			-- This and the next line seem to be in conflict w/ one another; the next will always be the active setting.
	if exitPrcnt == nil then exitPrcnt = 2 end -- volts
	local l_AvgCurrent = 0
	local l_SumCurrent = 0
	local l_Multiplier = 1
	local l_TotalCharge = 0	-- used
	local l_ChargeRemain = 100
	local l_SOC = 100
	--local l_BatPrcnt = 100
	local l_DischargeTime = 0
	local l_TempTime = 0
	local l_BtCpcty = batCpcty
	local l_tmpBatCpcty = 0
	local l_StartCharge
	local l_rdCntr = 0
	local l_current = 0
	local l_minPrcnt = 0 -- read lowest value in battery table and set
	local l_timestamp = 0
	local l_startTime = 0
	local l_fractimestamp = 0
	local l_i = 0
	local l_j = 0
	local l_GrphData = 0  -- set the 2450 display graph mode state On or Off
	local l_wrtCount = 1
	local l_saveString
	local  l_blockCnt = 500  -- number of readings collected before writing to file
	local nplc = 0.05
	local l_dialog_text = ""
	
	tblCurrent = {}
	tblVolt = {}
	tblTime = {}
	defbuffer1.capacity = 1e6
	defbuffer1.clear()
	smu.measure.autozero.once()
	waitcomplete()
	--print(exitPrcnt) OK
	if exitPrcnt < l_minPrcnt then
		exitPrcnt = l_minPrcnt
	end
	
	if SOC < exitPrcnt then
		print("state of charge less than test exit")
	end

	l_SOC = SOC  -- State of Charge in percent
	
	smu.source.func = smu.FUNC_DC_VOLTAGE
----------------------------------------------------------------------------------
	
	batLvl = batVoc[SOC] 
	smu.source.level = batLvl  -- highest voltage in model
----------------------------------------------------------------------------------
	smu.source.ilimit.level = iLimit
	smu.measure.func = smu.FUNC_DC_CURRENT
	smu.measure.nplc = nplc
	smu.source.readback = smu.ON
	smu.source.output	= smu.ON
	smu.source.delay = 0
	smu.measure.autorange = smu.ON
	l_current, l_startTime, l_fractimestamp  = smu.measure.readwithtime()
	l_startTime = l_startTime + l_fractimestamp
	l_StartCharge = (batCpcty*(l_SOC/100))
-------------------------------------------------------------------------------------
-- Option to change to Remote Text window
	if l_GrphData == 1 then
		display.changescreen(display.SCREEN_GRAPH)
	else
		-------------------------------------------------------------------------------------------
		-- prompt to indicate file creation
		display.clear()
		display.changescreen(display.SCREEN_USER_SWIPE)
		-------------------------------------------------------------------------------------------
	end
-------------------------------------------------------------------------------------
	Vload = batLvl  -- set Vload with the test starting voltage level
	--while exitV > exitVoltage do
	print(l_SOC)
	while (l_SOC) > exitPrcnt do
		filMeasCount = filMeasCount + 1
		if filMeasCount == 1e6 then  -- maximum number of rows set to 1 million for each file
			filCount = filCount + 1  -- increment file counter index to a maximum of eight (2 million readings)
			filMeasCount = 0  -- reset maximum readings per file counter
		end
		l_i = l_i + 1  -- increment measurement reading count for average current
		l_current, l_timestamp, l_fractimestamp = smu.measure.readwithtime()
		if l_current < 0 then  -- prevent average current from charging beyond the 100% limit of the battery model.
			l_current = 0
		end
		l_DischargeTime = (l_timestamp + l_fractimestamp) - l_startTime
		l_SumCurrent = l_SumCurrent + l_current
		l_AvgCurrent = l_SumCurrent/l_i
		l_TotalCharge = calcAH(l_AvgCurrent, l_DischargeTime)
		l_ChargeRemain = l_StartCharge - l_TotalCharge
		l_BatLifeRem = l_SOC*(l_ChargeRemain/l_StartCharge)--*100
		--l_disBatLifeRem = Dround(l_BatLifeRem, 3)
		l_disBatLifeRem = Dround(l_SOC, 3)
		
		display.settext(display.TEXT1, "Capacity " .. batCpcty .. " Ah")
		display.settext(display.TEXT2, (l_disBatLifeRem .. " % Charge"))

		
		l_SOC = (l_ChargeRemain/batCpcty) * 100
		intrpIndex = l_SOC
		l_rndSOC = math.floor(l_SOC) -- return lower integer value
		print(l_SOC) 
		tblCurrent[l_i] = l_current  -- collect current reading for save to USB
		tblVolt[l_i] = Vload  -- collect voltage reading for save to USB
		tblTime[l_i] = (l_timestamp + l_fractimestamp) - l_startTime  -- collect timestamp reading for save to USB
		if l_i == 1 then
			sFlag = 0
		else
			sFlag = 1
		end
		Vload = VocAdjust(l_rndSOC,intrpIndex,l_current,sFlag)
		
-------------------------------------------------------------------------------------------------------------------
		-- Save test data to USB if selected in blocks defined by blockCnt
		
		if dataSave == 1 then
			if l_wrtCount == l_blockCnt then  -- write to USB Memory defined by l_blockCnt
				--print("wrtCount = ", l_wrtCount)
				filNumA[filCount] = file.open(filNameA[filCount], file.MODE_APPEND)
				-- write readings in blocks specified by blockCnt
				--for l_j = 1, l_blockCnt do
				--for l_j = l_i - l_blockCnt , l_i + l_blockCnt do
				for l_j = l_i - (l_blockCnt-1) , l_i do
					l_saveString = tblTime[l_j] .. "," .. tblVolt[l_j] .. "," .. tblCurrent[l_j] .. "\n"
					--print(filNumA[filCount],l_saveString)
					--print(l_saveString, l_i)
					file.write(filNumA[filCount], l_saveString)
				end
				file.flush(filNumA[filCount])
				file.close(filNumA[filCount])
				-----------------------------------------------------
				l_wrtCount = 0  -- reset counter for USB write function
				--defbuffer1.clear()
			end
			l_wrtCount = l_wrtCount + 1  -- increment block write index counter
			--print("l_i = ", l_i, " wrtCount = ", l_wrtCount)
		end
		
----------------------------------------------------------------------------------------------------------------

		smu.source.level = Vload
	end  -- while loop
	
	smu.source.output	= smu.OFF
	
	if dataSave == 1 then -- save remaining data to file
		if l_wrtCount > 1 and l_wrtCount < l_blockCnt then -- check for last readings in test then write to USB
			filNumA[filCount] = file.open(filNameA[filCount], file.MODE_APPEND)
			for l_j = l_i - (l_wrtCount-1) , l_i do
				-- write last readings to USB
				l_saveString = tblTime[l_j] .. "," .. tblVolt[l_j] .. "," .. tblCurrent[l_j] .. "\n"  -- cause of nil field error
				--print(l_saveString)
				file.write(filNumA[filCount], l_saveString)  
			end
			file.flush(filNumA[filCount])
			file.close(filNumA[filCount])
		end
		l_dialog_text = "Test Complete"
		disDone = display.input.prompt(display.BUTTONS_OK, l_dialog_text)
	end
	collectgarbage()
end		-- end DischargeCurrent

function VocAdjust(batIndex, intrpIndex, measCur, sFlag)

	-- batVOC and batESR to calculate loaded Vout
	-- InterpolateVocAdjust(batIndexD, intrpIndex)
	
	--local Imeas
	local lv_i,lv_j,lv_k = 0
	local Vout = 0
	local Vdrop = 0
	local batESRupper, batESRlower
	
	lv_i = batIndex
	
	
	btESR, btVoc = InterpolateVocAdjust(batIndex, intrpIndex, sFlag) -- commented out for pre-interpolation method
	
	-- Vdrop = batESR[lv_i]*measCur  pre-interpolation method
	Vdrop = btESR * measCur
	-----------------------------------------------------------------------
	-- switch to 6 and determine stepping
	-----------------------------------------------------------------------
	Vout = Dround(btVoc - Vdrop,8)  -- interpolated Voltage Open Circuit
	return Vout
end		-- end VocAdjust

function InterpolateVocAdjust(batIndexD, intrpIndex, sFlag)

	-- Interpolation for battery model
	--intrpIndex rounded to two decimal places
	--batIndexD is rounded down integer of the battery index 
	
	--local batESRupper, batESRlower
	local l_ESRrange, l_VOCrange
	local deltaESR,fnlESR
	local l_chkInteger = 1
	if batIndexD == nil then batIndexD = 100 end
	
	if batIndexD ~= 100 then
		l_ESRrange = batESR[batIndexD+1] - batESR[batIndexD]
		l_VOCrange = batVoc[batIndexD+1] - batVoc[batIndexD]  -- Mod
		
	else
		--print(batIndexD)
		l_ESRrange = batESR[batIndexD] - batESR[batIndexD-1]
		l_VOCrange = batVOC[batIndexD] - batVoc[batIndexD-1]
	end
	
	l_prcnt = IntrpRound(intrpIndex)
	
	deltaESR = l_ESRrange * l_prcnt
	deltaVOC = l_VOCrange * l_prcnt

	if sFlag == 0 then
		if l_prcnt == 0 then
			fnlESR = batESR[batIndexD+1]
			fnlVOC = batVoc[batIndexD+1] 
			--print("l_prcnt = ", l_prcnt, "fnlESR = ", fnlESR, " sFlag = ", sFlag)
		else
			fnlESR = batESR[batIndexD] + deltaESR
			fnlVOC = batVoc[batIndexD] + deltaVOC
		end
	else
		if l_prcnt == 0 then
			fnlESR = batESR[batIndexD]-- + deltaESR 
			fnlVOC = batVoc[batIndexD]-- + deltaVOC
			--print("l_prcnt = ", l_prcnt, "fnlESR = ", fnlESR, " sFlag = ", sFlag)
		else
			fnlESR = batESR[batIndexD] + deltaESR
			fnlVOC = batVoc[batIndexD] + deltaVOC
		end
	end
	
	return fnlESR, fnlVOC
end		-- end InterpolateVocAdjust

function calcAH(AvgCur, DisTime)

	local l_AmpHours
	l_Multiplier = DisTime/3600
	l_AmpHours = AvgCur * l_Multiplier
	return l_AmpHours
end		-- end calcAH

function Dround(number, n_decimal_places)		-- Round to n_decimal_places
	local mult = 10 ^ (n_decimal_places or 0)	-- Will use n_decimal_places, unless n_decimal_places = nil, then will use 0
	return math.floor(number * mult + 0.5) / mult
end 		-- Dround

function FormatData(dtype) -- not used

	--format.data = format.REAL64
	format.data = dtype
end			-- end FormatData

function batModel(modlName)  

	-- Find USB .csv file, read and parse into three separate tables
	local batTable = {}
	batSOC = {}
	batVoc = {}
	batESR = {}
	local l_j, l_k, l_m, cntr, tmpStr
	local nStrt = 1
	local nEnd = 1
	
	batModl = ("/usb1/".. modlName) -- ..".csv")
	file_num = file.open(batModl,file.MODE_READ)
	--file_num = file.open("/usb1/DuraQAAA.csv",file.MODE_READ)
	
	if file_num != nil then
		for l_j = 1, 104 do
			batTable[l_j] = file.read(file_num, file.READ_LINE)
			--print(batTable[l_j])	
			if l_j == 2 then
				-- line 2 example: Capacity=0.095AH
				tmpStr = string.find(batTable[2],"=")
				nStrt = tonumber(tmpStr)+1
				tmpStr = string.find(batTable[2],"A")
				nEnd = tonumber(tmpStr)-1
				--print(string.sub(batTable[2], nStrt, nEnd))
				dftCap = tonumber(string.sub(batTable[2], nStrt, nEnd))
				--print(dftCap)
			end
				
			--batSOC[l_j],batVoc[l_j],batESR[l_j] = file.read(file_num, file.READ_LINE)
			--print(batTable[l_j])
			if l_j > 3 then
				l_m = l_j - 4
				l_l = string.len(batTable[l_j])
				for l_k = 1, string.len(batTable[l_j]) do
					l_l = string.len(batTable[l_j])
					-- search for comma
					--string.find(string, comma, index)
					cntr1 = string.find(batTable[l_j],",",1)
					batSOC[l_m] = tonumber(string.sub(batTable[l_j], 1, cntr1-1))
					cntr2 = string.find(batTable[l_j],",",cntr1+1)
					batVoc[l_m] = tonumber(string.sub(batTable[l_j], cntr1+1, cntr2-1))
					batESR[l_m] = tonumber(string.sub(batTable[l_j], cntr2+1, (l_l-1)))
				end
				--print("SOC: ", batSOC[l_m], "batESR: ", batESR[l_m], "l_j: ", l_j, l_m)
				
			end	
		end
	end
	file.close(file_num)
end		-- end batModel

function CreateFolder()

	local l_status
	l_status = file.mkdir("DATA")
end		-- end CreateFolder

function TestForDrive()

	local l_status = file.usbdriveexists()
	if l_status == 0 then
		while l_status == 0 do
			-- print insert USB thumb drive to display and wait for OK
			l_dialog_text = "Insert USB drive, press OK to continue"
	    	disSaveData = display.input.prompt(display.BUTTONS_OK, l_dialog_text)
	    	l_status = file.usbdriveexists()
	    end
    end
end		-- end TestForDrive

function DataToFile(filName,curDat,curTimeStamp)

	l_isfold = fs.is_dir("DATA")
	
	if l_isfold ~= true then
		l_status = file.mkdir("DATA")
	end
	
	batModl = ("/usb1/DATA/".. filName ..".csv")
	file_num = file.open(batModl,file.MODE_WRITE)
	if file_num != nil then
		
	else
	
	end
end		-- DataToFile

function testcheck()

	l_dialog_text = "Test Another Device?"
    local retest = display.input.prompt(display.BUTTONS_YESNO, l_dialog_text)
    if retest == display.BUTTON_YES then
    	SetUpPrompts()
    end
end		-- end testcheck()


function Main(iComp, capacity, strtSOC, endPrcnt)

	if disSELBAT == display.BUTTON_OPTION2 then
		-- Read the battery model from USB stick
		--batModel("DuraQAAA")  -- test file
		batModel(batName)
	else
		-- Use default battery model
		--BatModelAAA()
		
	end
	
	--DischargeCurrent(iLimit, batCpcty, SOC, exitPrcnt)
	DischargeCurrent(iComp,capacity,strtSOC,endPrcnt)
	testcheck()  
end		-- end Main()

function IntrpRound(value)

	-- extract 10ths and 100th digits from number
	valLo = math.floor(value)
	prcnt = value - valLo
	return prcnt
end		-- end IntrpRound()

function CreateEmbeddedBatteryModel(modlName)

	-- Creates function for battery model to be used in default battery model selection
	-- Maximum of 10 models
	-- modlName is a known battery model file on the USB connected to SMU
	 batModel(modlName)
	 fil = string.sub(modlName,1,string.len(modlName)-4)  -- strip the .csv off
	 print("function BatModel"..fil.."()")
	 print("batSOC = {}")
	 print("batVoc = {}")
	 print("batESR = {}")
	 print("dftCap = "..dftCap)
	 print()
	 for i = 0, 100 do
	 	print("\tbatSOC["..i.."],batVoc["..i.."],batESR["..i.."] = "..batSOC[i]..","..batVoc[i]..","..batESR[i])
	 end
 print("end")
end		-- end CreateEmbeddedBatteryModel()

function BatModelAAA()

	batSOC = {}
	batVoc = {}
	batESR = {}
	dftCap = 1.6

	-- NiMH battery model
	batSOC[0],batVoc[0],batESR[0] = 0,0.799616158,1.441173077
	batSOC[1],batVoc[1],batESR[1] = 1,0.877276957,1.307088
	batSOC[2],batVoc[2],batESR[2] = 2,0.924137175,1.2232
	batSOC[3],batVoc[3],batESR[3] = 3,0.956328988,1.1972
	batSOC[4],batVoc[4],batESR[4] = 4,0.979998052,1.1292
	batSOC[5],batVoc[5],batESR[5] = 5,0.998947859,1.1178
	batSOC[6],batVoc[6],batESR[6] = 6,1.014129758,1.0838
	batSOC[7],batVoc[7],batESR[7] = 7,1.027683735,1.0694
	batSOC[8],batVoc[8],batESR[8] = 8,1.039003968,1.0659
	batSOC[9],batVoc[9],batESR[9] = 9,1.049511671,1.0486
	batSOC[10],batVoc[10],batESR[10] = 10,1.058845639,1.0407
	batSOC[11],batVoc[11],batESR[11] = 11,1.067588449,1.0342
	batSOC[12],batVoc[12],batESR[12] = 12,1.075814128,1.0297
	batSOC[13],batVoc[13],batESR[13] = 13,1.08308804,	1.0256
	batSOC[14],batVoc[14],batESR[14] = 14,1.089619637,1.0236
	batSOC[15],batVoc[15],batESR[15] = 15,1.095648885,1.0184
	batSOC[16],batVoc[16],batESR[16] = 16,1.101563573,0.9909
	batSOC[17],batVoc[17],batESR[17] = 17,1.107230902,0.9846
	batSOC[18],batVoc[18],batESR[18] = 18,1.112291455,0.9789
	batSOC[19],batVoc[19],batESR[19] = 19,1.117246628,0.9751
	batSOC[20],batVoc[20],batESR[20] = 20,1.121952653,0.9765
	batSOC[21],batVoc[21],batESR[21] = 21,1.126369,0.9773
	batSOC[22],batVoc[22],batESR[22] = 22,1.130583167,0.9741
	batSOC[23],batVoc[23],batESR[23] = 23,1.134788752,0.9701
	batSOC[24],batVoc[24],batESR[24] = 24,1.138893604,0.9699
	batSOC[25],batVoc[25],batESR[25] = 25,1.142908692,0.9687
	batSOC[26],batVoc[26],batESR[26] = 26,1.146977663,0.9698
	batSOC[27],batVoc[27],batESR[27] = 27,1.150765777,0.9766
	batSOC[28],batVoc[28],batESR[28] = 28,1.154463053,0.9800
	batSOC[29],batVoc[29],batESR[29] = 29,1.158066034,0.9817
	batSOC[30],batVoc[30],batESR[30] = 30,1.161787987,0.9810
	batSOC[31],batVoc[31],batESR[31] = 31,1.16514802,0.9811
	batSOC[32],batVoc[32],batESR[32] = 32,1.168332219,0.9821
	batSOC[33],batVoc[33],batESR[33] = 33,1.171619654,0.9848
	batSOC[34],batVoc[34],batESR[34] = 34,1.175128698,0.9858
	batSOC[35],batVoc[35],batESR[35] = 35,1.178292513,0.9867
	batSOC[36],batVoc[36],batESR[36] = 36,1.181332827,0.9857
	batSOC[37],batVoc[37],batESR[37] = 37,1.184208393,0.9855
	batSOC[38],batVoc[38],batESR[38] = 38,1.187041521,0.9803
	batSOC[39],batVoc[39],batESR[39] = 39,1.189912796,0.9775
	batSOC[40],batVoc[40],batESR[40] = 40,1.192804217,0.9764
	batSOC[41],batVoc[41],batESR[41] = 41,1.195711374,0.9780
	batSOC[42],batVoc[42],batESR[42] = 42,1.198742151,0.9716
	batSOC[43],batVoc[43],batESR[43] = 43,1.201519609,0.9743
	batSOC[44],batVoc[44],batESR[44] = 44,1.20444262,0.9745
	batSOC[45],batVoc[45],batESR[45] = 45,1.207385898,0.9692
	batSOC[46],batVoc[46],batESR[46] = 46,1.210441589,0.9662
	batSOC[47],batVoc[47],batESR[47] = 47,1.213363051,0.9689
	batSOC[48],batVoc[48],batESR[48] = 48,1.216342568,0.9697
	batSOC[49],batVoc[49],batESR[49] = 49,1.219405055,0.9681
	batSOC[50],batVoc[50],batESR[50] = 50,1.222527146,0.9703
	batSOC[51],batVoc[51],batESR[51] = 51,1.225778937,0.9640
	batSOC[52],batVoc[52],batESR[52] = 52,1.228907943,0.9671
	batSOC[53],batVoc[53],batESR[53] = 53,1.232120991,0.9671
	batSOC[54],batVoc[54],batESR[54] = 54,1.235365868,0.9635
	batSOC[55],batVoc[55],batESR[55] = 55,1.238511443,0.9663
	batSOC[56],batVoc[56],batESR[56] = 56,1.241568327,0.9636
	batSOC[57],batVoc[57],batESR[57] = 57,1.24459219,0.9636
	batSOC[58],batVoc[58],batESR[58] = 58,1.24770546,0.9672
	batSOC[59],batVoc[59],batESR[59] = 59,1.251061201,0.9677
	batSOC[60],batVoc[60],batESR[60] = 60,1.254178762,0.9659
	batSOC[61],batVoc[61],batESR[61] = 61,1.257364631,0.9656
	batSOC[62],batVoc[62],batESR[62] = 62,1.260612249,0.9647
	batSOC[63],batVoc[63],batESR[63] = 63,1.263945699,0.9607
	batSOC[64],batVoc[64],batESR[64] = 64,1.26734817,0.9487
	batSOC[65],batVoc[65],batESR[65] = 65,1.270858645,0.9363
	batSOC[66],batVoc[66],batESR[66] = 66,1.274421692,0.9276
	batSOC[67],batVoc[67],batESR[67] = 67,1.278230667,0.9211
	batSOC[68],batVoc[68],batESR[68] = 68,1.281969309,0.9196
	batSOC[69],batVoc[69],batESR[69] = 69,1.285781026,0.9201
	batSOC[70],batVoc[70],batESR[70] = 70,1.289615035,0.9169
	batSOC[71],batVoc[71],batESR[71] = 71,1.293655992,0.9096
	batSOC[72],batVoc[72],batESR[72] = 72,1.297661424,0.9172
	batSOC[73],batVoc[73],batESR[73] = 73,1.301854849,0.9088
	batSOC[74],batVoc[74],batESR[74] = 74,1.306200266,0.9077
	batSOC[75],batVoc[75],batESR[75] = 75,1.310551167,0.9056
	batSOC[76],batVoc[76],batESR[76] = 76,1.315077901,0.9070
	batSOC[77],batVoc[77],batESR[77] = 77,1.319554687,0.9073
	batSOC[78],batVoc[78],batESR[78] = 78,1.323979139,0.9071
	batSOC[79],batVoc[79],batESR[79] = 79,1.328493238,0.9085
	batSOC[80],batVoc[80],batESR[80] = 80,1.333248019,0.9115
	batSOC[81],batVoc[81],batESR[81] = 81,1.337665319,0.8796
	batSOC[82],batVoc[82],batESR[82] = 82,1.342136622,0.8828
	batSOC[83],batVoc[83],batESR[83] = 83,1.346678376,0.8728
	batSOC[84],batVoc[84],batESR[84] = 84,1.351610065,0.8627
	batSOC[85],batVoc[85],batESR[85] = 85,1.356422782,0.8581
	batSOC[86],batVoc[86],batESR[86] = 86,1.361350536,0.8519
	batSOC[87],batVoc[87],batESR[87] = 87,1.366564274,0.8515
	batSOC[88],batVoc[88],batESR[88] = 88,1.372448444,0.8456
	batSOC[89],batVoc[89],batESR[89] = 89,1.378650785,0.8412
	batSOC[90],batVoc[90],batESR[90] = 90,1.385554075,0.8332
	batSOC[91],batVoc[91],batESR[91] = 91,1.393227458,0.8328
	batSOC[92],batVoc[92],batESR[92] = 92,1.40214932,0.8363
	batSOC[93],batVoc[93],batESR[93] = 93,1.411665678,0.8288
	batSOC[94],batVoc[94],batESR[94] = 94,1.422282457,0.8307
	batSOC[95],batVoc[95],batESR[95] = 95,1.434371829,0.7935
	batSOC[96],batVoc[96],batESR[96] = 96,1.448869824,0.7887
	batSOC[97],batVoc[97],batESR[97] = 97,1.465159535,0.7895
	batSOC[98],batVoc[98],batESR[98] = 98,1.48487246,0.7960
	batSOC[99],batVoc[99],batESR[99] = 99,1.51069653,0.7917
	batSOC[100],batVoc[100],batESR[100] = 100,1.56419611,0.7863
	--Vout - 	1.464	intrpIndex - 	98
end



function BatModelCR2032at30mA()
	-- CR2032 discharged at 30 mA
	batSOC = {}
	batVoc = {}
	batESR = {}
	dftCap = 0.0245

	batSOC[0],batVoc[0],batESR[0] = 0,2.015205383,63.86667887
	batSOC[1],batVoc[1],batESR[1] = 1,2.227287293,50.32196045
	batSOC[2],batVoc[2],batESR[2] = 2,2.302425385,44.02949015
	batSOC[3],batVoc[3],batESR[3] = 3,2.342247009,39.82251485
	batSOC[4],batVoc[4],batESR[4] = 4,2.363197327,37.57616679
	batSOC[5],batVoc[5],batESR[5] = 5,2.379066467,35.83170573
	batSOC[6],batVoc[6],batESR[6] = 6,2.391929627,34.3343099
	batSOC[7],batVoc[7],batESR[7] = 7,2.402359009,33.02739461
	batSOC[8],batVoc[8],batESR[8] = 8,2.410541534,31.95025126
	batSOC[9],batVoc[9],batESR[9] = 9,2.417007446,31.10135396
	batSOC[10],batVoc[10],batESR[10] = 10,2.422260284,30.42360942
	batSOC[11],batVoc[11],batESR[11] = 11,2.426628113,29.88904317
	batSOC[12],batVoc[12],batESR[12] = 12,2.430324554,29.43916321
	batSOC[13],batVoc[13],batESR[13] = 13,2.433250427,29.11694845
	batSOC[14],batVoc[14],batESR[14] = 14,2.435829163,28.85971069
	batSOC[15],batVoc[15],batESR[15] = 15,2.438072205,28.66668701
	batSOC[16],batVoc[16],batESR[16] = 16,2.439910889,28.51257324
	batSOC[17],batVoc[17],batESR[17] = 17,2.44159317,28.38274638
	batSOC[18],batVoc[18],batESR[18] = 18,2.443435669,28.2333374
	batSOC[19],batVoc[19],batESR[19] = 19,2.445678711,28.0195872
	batSOC[20],batVoc[20],batESR[20] = 20,2.448051453,27.77900696
	batSOC[21],batVoc[21],batESR[21] = 21,2.450393677,27.5255839
	batSOC[22],batVoc[22],batESR[22] = 22,2.452758789,27.25168864
	batSOC[23],batVoc[23],batESR[23] = 23,2.454986572,27.01327006
	batSOC[24],batVoc[24],batESR[24] = 24,2.457122803,26.7616272
	batSOC[25],batVoc[25],batESR[25] = 25,2.459152222,26.52562459
	batSOC[26],batVoc[26],batESR[26] = 26,2.461559296,26.22159322
	batSOC[27],batVoc[27],batESR[27] = 27,2.462532044,26.20315552
	batSOC[28],batVoc[28],batESR[28] = 28,2.462543488,26.18586222
	batSOC[29],batVoc[29],batESR[29] = 29,2.464183807,26.00084941
	batSOC[30],batVoc[30],batESR[30] = 30,2.465797424,25.80998739
	batSOC[31],batVoc[31],batESR[31] = 31,2.467350006,25.62204997
	batSOC[32],batVoc[32],batESR[32] = 32,2.468833923,25.43334961
	batSOC[33],batVoc[33],batESR[33] = 33,2.470344544,25.2407074
	batSOC[34],batVoc[34],batESR[34] = 34,2.471817017,25.04412333
	batSOC[35],batVoc[35],batESR[35] = 35,2.473297119,24.83774821
	batSOC[36],batVoc[36],batESR[36] = 36,2.474781036,24.62565104
	batSOC[37],batVoc[37],batESR[37] = 37,2.476284027,24.40478007
	batSOC[38],batVoc[38],batESR[38] = 38,2.477779388,24.16890462
	batSOC[39],batVoc[39],batESR[39] = 39,2.479305267,23.9285787
	batSOC[40],batVoc[40],batESR[40] = 40,2.480854034,23.67121379
	batSOC[41],batVoc[41],batESR[41] = 41,2.48241806,23.40100606
	batSOC[42],batVoc[42],batESR[42] = 42,2.483913422,23.13359579
	batSOC[43],batVoc[43],batESR[43] = 43,2.485549927,22.82320658
	batSOC[44],batVoc[44],batESR[44] = 44,2.487224579,22.50289917
	batSOC[45],batVoc[45],batESR[45] = 45,2.48904419,22.16707865
	batSOC[46],batVoc[46],batESR[46] = 46,2.4908638,21.82680766
	batSOC[47],batVoc[47],batESR[47] = 47,2.492713928,21.48106893
	batSOC[48],batVoc[48],batESR[48] = 48,2.494560242,21.13202413
	batSOC[49],batVoc[49],batESR[49] = 49,2.496486664,20.77255249
	batSOC[50],batVoc[50],batESR[50] = 50,2.498435974,20.39909363
	batSOC[51],batVoc[51],batESR[51] = 51,2.500442505,20.01647949
	batSOC[52],batVoc[52],batESR[52] = 52,2.502559662,19.62623596
	batSOC[53],batVoc[53],batESR[53] = 53,2.504753113,19.22734579
	batSOC[54],batVoc[54],batESR[54] = 54,2.507019043,18.81739299
	batSOC[55],batVoc[55],batESR[55] = 55,2.509273529,18.41557821
	batSOC[56],batVoc[56],batESR[56] = 56,2.511638641,18.01274618
	batSOC[57],batVoc[57],batESR[57] = 57,2.514080048,17.61919657
	batSOC[58],batVoc[58],batESR[58] = 58,2.516670227,17.21547445
	batSOC[59],batVoc[59],batESR[59] = 59,2.519363403,16.80920919
	batSOC[60],batVoc[60],batESR[60] = 60,2.52217865,16.42545064
	batSOC[61],batVoc[61],batESR[61] = 61,2.525096893,16.05262756
	batSOC[62],batVoc[62],batESR[62] = 62,2.528190613,15.67204793
	batSOC[63],batVoc[63],batESR[63] = 63,2.531475067,15.29312134
	batSOC[64],batVoc[64],batESR[64] = 64,2.53490448,14.91800944
	batSOC[65],batVoc[65],batESR[65] = 65,2.538543701,14.55319723
	batSOC[66],batVoc[66],batESR[66] = 66,2.542327881,14.20974731
	batSOC[67],batVoc[67],batESR[67] = 67,2.546337128,13.86324565
	batSOC[68],batVoc[68],batESR[68] = 68,2.550460815,13.54827881
	batSOC[69],batVoc[69],batESR[69] = 69,2.554691315,13.22148641
	batSOC[70],batVoc[70],batESR[70] = 70,2.559036255,12.90931702
	batSOC[71],batVoc[71],batESR[71] = 71,2.56351471,12.62372335
	batSOC[72],batVoc[72],batESR[72] = 72,2.568130493,12.36788432
	batSOC[73],batVoc[73],batESR[73] = 73,2.572963715,12.10289002
	batSOC[74],batVoc[74],batESR[74] = 74,2.577919006,11.85239156
	batSOC[75],batVoc[75],batESR[75] = 75,2.58285141,11.53170268
	batSOC[76],batVoc[76],batESR[76] = 76,2.587802887,11.34084066
	batSOC[77],batVoc[77],batESR[77] = 77,2.592861176,11.18240356
	batSOC[78],batVoc[78],batESR[78] = 78,2.598003388,11.1928304
	batSOC[79],batVoc[79],batESR[79] = 79,2.603214264,11.26009623
	batSOC[80],batVoc[80],batESR[80] = 80,2.608531952,11.10153198
	batSOC[81],batVoc[81],batESR[81] = 81,2.61403656,11.00463867
	batSOC[82],batVoc[82],batESR[82] = 82,2.619655609,10.84518433
	batSOC[83],batVoc[83],batESR[83] = 83,2.625537872,10.68178813
	batSOC[84],batVoc[84],batESR[84] = 84,2.631599426,10.77562968
	batSOC[85],batVoc[85],batESR[85] = 85,2.637943268,10.4183197
	batSOC[86],batVoc[86],batESR[86] = 86,2.644645691,10.66169739
	batSOC[87],batVoc[87],batESR[87] = 87,2.651714325,10.24920146
	batSOC[88],batVoc[88],batESR[88] = 88,2.659183502,9.976959229
	batSOC[89],batVoc[89],batESR[89] = 89,2.667098999,9.970474243
	batSOC[90],batVoc[90],batESR[90] = 90,2.675613403,10.01269023
	batSOC[91],batVoc[91],batESR[91] = 91,2.684783936,10.05706787
	batSOC[92],batVoc[92],batESR[92] = 92,2.694862366,9.690221151
	batSOC[93],batVoc[93],batESR[93] = 93,2.706138611,8.729553223
	batSOC[94],batVoc[94],batESR[94] = 94,2.719097138,8.550516764
	batSOC[95],batVoc[95],batESR[95] = 95,2.73456192,8.378982544
	batSOC[96],batVoc[96],batESR[96] = 96,2.753948212,8.057785034
	batSOC[97],batVoc[97],batESR[97] = 97,2.779548645,8.137804159
	batSOC[98],batVoc[98],batESR[98] = 98,2.816135407,8.361053467
	batSOC[99],batVoc[99],batESR[99] = 99,2.877502441,8.957417806
	batSOC[100],batVoc[100],batESR[100] = 100,3.130088806,7.674280802
end

function BatModelAAA_T02()

	batSOC = {}
	batVoc = {}
	batESR = {}
	dftCap = 1.6

	batSOC[0],batVoc[0],batESR[0] = 0,0.51822590828,0.32742738724
	batSOC[1],batVoc[1],batESR[1] = 1,0.8985117504000651,0.2651786696606145
	batSOC[2],batVoc[2],batESR[2] = 2,0.9972673327411624,0.2628064132182001
	batSOC[3],batVoc[3],batESR[3] = 3,1.041785502346485,0.2622103629956624
	batSOC[4],batVoc[4],batESR[4] = 4,1.066777487489486,0.2618718140651935
	batSOC[5],batVoc[5],batESR[5] = 5,1.084875160574807,0.2613019943200737
	batSOC[6],batVoc[6],batESR[6] = 6,1.098659110295832,0.2607321697333922
	batSOC[7],batVoc[7],batESR[7] = 7,1.110229501739497,0.2600598319596517
	batSOC[8],batVoc[8],batESR[8] = 8,1.119808192710595,0.2588701248200151
	batSOC[9],batVoc[9],batESR[9] = 9,1.127047012631569,0.2584433511797116
	batSOC[10],batVoc[10],batESR[10] = 10,1.132123687371994,0.2592802004782048
	batSOC[11],batVoc[11],batESR[11] = 11,1.136612633813389,0.2601861923956718
	batSOC[12],batVoc[12],batESR[12] = 12,1.140421831877431,0.2612209320127174
	batSOC[13],batVoc[13],batESR[13] = 13,1.144042227989081,0.2622318240486297
	batSOC[14],batVoc[14],batESR[14] = 14,1.147582025829843,0.2635669652974208
	batSOC[15],batVoc[15],batESR[15] = 15,1.151631282076212,0.2645206451416373
	batSOC[16],batVoc[16],batESR[16] = 16,1.156125725945544,0.2646017062806557
	batSOC[17],batVoc[17],batESR[17] = 17,1.16054626300232,0.2647089888304351
	batSOC[18],batVoc[18],batESR[18] = 18,1.165173019230378,0.2646875381489627
	batSOC[19],batVoc[19],batESR[19] = 19,1.169814768927745,0.2639818258981121
	batSOC[20],batVoc[20],batESR[20] = 20,1.174505193748145,0.2631449699397029
	batSOC[21],batVoc[21],batESR[21] = 21,1.179181974674083,0.262191315554136
	batSOC[22],batVoc[22],batESR[22] = 22,1.183557928787539,0.2608204067497485
	batSOC[23],batVoc[23],batESR[23] = 23,1.187692353869693,0.2592778367999714
	batSOC[24],batVoc[24],batESR[24] = 24,1.190699069971626,0.2585911750738024
	batSOC[25],batVoc[25],batESR[25] = 25,1.193023429280593,0.2593278825441444
	batSOC[26],batVoc[26],batESR[26] = 26,1.195107199536762,0.2597832679675817
	batSOC[27],batVoc[27],batESR[27] = 27,1.196916094271169,0.2605485845655433
	batSOC[28],batVoc[28],batESR[28] = 28,1.198580735321597,0.2615213384354996
	batSOC[29],batVoc[29],batESR[29] = 29,1.200240589062365,0.2629613718390988
	batSOC[30],batVoc[30],batESR[30] = 30,1.202001528805993,0.264716124169757
	batSOC[31],batVoc[31],batESR[31] = 31,1.204500392311247,0.2655100768166566
	batSOC[32],batVoc[32],batESR[32] = 32,1.207597928741603,0.2656745926522189
	batSOC[33],batVoc[33],batESR[33] = 33,1.210899777045827,0.2649522071094252
	batSOC[34],batVoc[34],batESR[34] = 34,1.21451729169643,0.2635526876645402
	batSOC[35],batVoc[35],batESR[35] = 35,1.218141470955152,0.2621388805715916
	batSOC[36],batVoc[36],batESR[36] = 36,1.221365385494598,0.2606225131917402
	batSOC[37],batVoc[37],batESR[37] = 37,1.223616549741187,0.2607393264202949
	batSOC[38],batVoc[38],batESR[38] = 38,1.22556896461735,0.2612233162026019
	batSOC[39],batVoc[39],batESR[39] = 39,1.22750967651803,0.2619027793610646
	batSOC[40],batVoc[40],batESR[40] = 40,1.229403660996604,0.2624583243748832
	batSOC[41],batVoc[41],batESR[41] = 41,1.23132649725262,0.2631282806876893
	batSOC[42],batVoc[42],batESR[42] = 42,1.233290574110008,0.263404831308216
	batSOC[43],batVoc[43],batESR[43] = 43,1.235314531437668,0.2636933195285499
	batSOC[44],batVoc[44],batESR[44] = 44,1.237245261988287,0.2641987800523776
	batSOC[45],batVoc[45],batESR[45] = 45,1.239077519434808,0.2646279262699505
	batSOC[46],batVoc[46],batESR[46] = 46,1.240889276696922,0.2651095390319769
	batSOC[47],batVoc[47],batESR[47] = 47,1.242751563552611,0.26551485062
	batSOC[48],batVoc[48],batESR[48] = 48,1.244747350435103,0.2657389550693992
	batSOC[49],batVoc[49],batESR[49] = 49,1.246658998861552,0.2657175063906701
	batSOC[50],batVoc[50],batESR[50] = 50,1.248555845014255,0.2657866478236272
	batSOC[51],batVoc[51],batESR[51] = 51,1.250487974924311,0.2657914393899173
	batSOC[52],batVoc[52],batESR[52] = 52,1.252443708869967,0.2655744554252741
	batSOC[53],batVoc[53],batESR[53] = 53,1.254249257508214,0.2657341957277596
	batSOC[54],batVoc[54],batESR[54] = 54,1.255963720490642,0.265986880260817
	batSOC[55],batVoc[55],batESR[55] = 55,1.257526090521193,0.2657222748309918
	batSOC[56],batVoc[56],batESR[56] = 56,1.259131368007539,0.2662992475567686
	batSOC[57],batVoc[57],batESR[57] = 57,1.260766689441251,0.2667975145704635
	batSOC[58],batVoc[58],batESR[58] = 58,1.262514053308,0.2675008773991019
	batSOC[59],batVoc[59],batESR[59] = 59,1.264732737525979,0.2680182546514388
	batSOC[60],batVoc[60],batESR[60] = 60,1.267635965688961,0.2683377265839152
	batSOC[61],batVoc[61],batESR[61] = 61,1.270759958231915,0.2673340161002337
	batSOC[62],batVoc[62],batESR[62] = 62,1.274022484973246,0.2656650966500539
	batSOC[63],batVoc[63],batESR[63] = 63,1.277340788271302,0.2643394941191212
	batSOC[64],batVoc[64],batESR[64] = 64,1.280921861140968,0.262646710252702
	batSOC[65],batVoc[65],batESR[65] = 65,1.284716537297027,0.260624925042955
	batSOC[66],batVoc[66],batESR[66] = 66,1.288528849331144,0.2581978308673696
	batSOC[67],batVoc[67],batESR[67] = 67,1.291836432905921,0.2560758675706885
	batSOC[68],batVoc[68],batESR[68] = 68,1.294807821642405,0.25532960892
	batSOC[69],batVoc[69],batESR[69] = 69,1.297873159481491,0.2544975398201015
	batSOC[70],batVoc[70],batESR[70] = 70,1.301016718053385,0.2541661384121257
	batSOC[71],batVoc[71],batESR[71] = 71,1.30429068503402,0.2535510281242873
	batSOC[72],batVoc[72],batESR[72] = 72,1.307660008627748,0.2532553671294538
	batSOC[73],batVoc[73],batESR[73] = 73,1.311194287005587,0.2525615903952568
	batSOC[74],batVoc[74],batESR[74] = 74,1.314821119349977,0.2521514938518735
	batSOC[75],batVoc[75],batESR[75] = 75,1.318584107805994,0.2515459153965927
	batSOC[76],batVoc[76],batESR[76] = 76,1.322463457299657,0.2507043018039808
	batSOC[77],batVoc[77],batESR[77] = 77,1.326450767104189,0.2499365857082117
	batSOC[78],batVoc[78],batESR[78] = 78,1.330514113334828,0.2492618665644315
	batSOC[79],batVoc[79],batESR[79] = 79,1.334631586202431,0.248785033061261
	batSOC[80],batVoc[80],batESR[80] = 80,1.338883349005878,0.2481961306907722
	batSOC[81],batVoc[81],batESR[81] = 81,1.343264721751598,0.2475667121135301
	batSOC[82],batVoc[82],batESR[82] = 82,1.347697626365053,0.2468085289202531
	batSOC[83],batVoc[83],batESR[83] = 83,1.352186335679809,0.246095668137098
	batSOC[84],batVoc[84],batESR[84] = 84,1.356675506236217,0.245661744370423
	batSOC[85],batVoc[85],batESR[85] = 85,1.361165395805349,0.245227828168391
	batSOC[86],batVoc[86],batESR[86] = 86,1.365640076560128,0.2450966835008888
	batSOC[87],batVoc[87],batESR[87] = 87,1.370167195189705,0.2453231811484969
	batSOC[88],batVoc[88],batESR[88] = 88,1.374696432465953,0.2459120645078048
	batSOC[89],batVoc[89],batESR[89] = 89,1.379322754691304,0.2468466717926164
	batSOC[90],batVoc[90],batESR[90] = 90,1.384165532212139,0.2482581150740255
	batSOC[91],batVoc[91],batESR[91] = 91,1.389287941769239,0.2503633463880086
	batSOC[92],batVoc[92],batESR[92] = 92,1.394973001196458,0.2542304684753053
	batSOC[93],batVoc[93],batESR[93] = 93,1.401689190048992,0.2592586814765243
	batSOC[94],batVoc[94],batESR[94] = 94,1.409662742389872,0.2634763769108073
	batSOC[95],batVoc[95],batESR[95] = 95,1.418968778763491,0.263991342772513
	batSOC[96],batVoc[96],batESR[96] = 96,1.429937480903546,0.2613258031108185
	batSOC[97],batVoc[97],batESR[97] = 97,1.443054841622797,0.258319345421918
	batSOC[98],batVoc[98],batESR[98] = 98,1.459022528244396,0.2564382458297662
	batSOC[99],batVoc[99],batESR[99] = 99,1.478992167770344,0.25797131868004
	batSOC[100],batVoc[100],batESR[100] = 100,1.5050828457,0.26770114899
end

function BatModelCR2032at1mA()

	batSOC = {}
	batVoc = {}
	batESR = {}
	dftCap = 0.2125

	batSOC[0],batVoc[0],batESR[0] = 0,2.359600067,460.3881836
	batSOC[1],batVoc[1],batESR[1] = 1,2.413169861,440.4907227
	batSOC[2],batVoc[2],batESR[2] = 2,2.454479218,422.5769043
	batSOC[3],batVoc[3],batESR[3] = 3,2.488586426,401.9889832
	batSOC[4],batVoc[4],batESR[4] = 4,2.517593384,379.8179627
	batSOC[5],batVoc[5],batESR[5] = 5,2.54227829,359.6191406
	batSOC[6],batVoc[6],batESR[6] = 6,2.56332016,343.0099487
	batSOC[7],batVoc[7],batESR[7] = 7,2.58272171,322.2770691
	batSOC[8],batVoc[8],batESR[8] = 8,2.599098206,306.6062927
	batSOC[9],batVoc[9],batESR[9] = 9,2.613994598,287.1208191
	batSOC[10],batVoc[10],batESR[10] = 10,2.625728607,275.6004334
	batSOC[11],batVoc[11],batESR[11] = 11,2.637176514,264.5835877
	batSOC[12],batVoc[12],batESR[12] = 12,2.649646759,246.8986511
	batSOC[13],batVoc[13],batESR[13] = 13,2.661952972,228.1799316
	batSOC[14],batVoc[14],batESR[14] = 14,2.674003601,208.770752
	batSOC[15],batVoc[15],batESR[15] = 15,2.68497467,188.5147095
	batSOC[16],batVoc[16],batESR[16] = 16,2.69537735,169.7845459
	batSOC[17],batVoc[17],batESR[17] = 17,2.704998016,151.3252258
	batSOC[18],batVoc[18],batESR[18] = 18,2.71383667,134.5291138
	batSOC[19],batVoc[19],batESR[19] = 19,2.721469879,118.7591553
	batSOC[20],batVoc[20],batESR[20] = 20,2.728057861,102.1156311
	batSOC[21],batVoc[21],batESR[21] = 21,2.732593536,91.70532227
	batSOC[22],batVoc[22],batESR[22] = 22,2.7371521,83.59527588
	batSOC[23],batVoc[23],batESR[23] = 23,2.743808746,74.55062866
	batSOC[24],batVoc[24],batESR[24] = 24,2.751052856,66.05911255
	batSOC[25],batVoc[25],batESR[25] = 25,2.758331299,58.69293213
	batSOC[26],batVoc[26],batESR[26] = 26,2.765514374,52.52456665
	batSOC[27],batVoc[27],batESR[27] = 27,2.772129059,47.42431641
	batSOC[28],batVoc[28],batESR[28] = 28,2.778522492,42.96875
	batSOC[29],batVoc[29],batESR[29] = 29,2.782863617,39.54696655
	batSOC[30],batVoc[30],batESR[30] = 30,2.785095215,37.54043579
	batSOC[31],batVoc[31],batESR[31] = 31,2.786632538,35.67886353
	batSOC[32],batVoc[32],batESR[32] = 32,2.787986755,34.25979614
	batSOC[33],batVoc[33],batESR[33] = 33,2.788475037,33.53118897
	batSOC[34],batVoc[34],batESR[34] = 34,2.791061401,32.42492676
	batSOC[35],batVoc[35],batESR[35] = 35,2.794708252,31.19659424
	batSOC[36],batVoc[36],batESR[36] = 36,2.798667908,29.95300293
	batSOC[37],batVoc[37],batESR[37] = 37,2.802055359,28.98025513
	batSOC[38],batVoc[38],batESR[38] = 38,2.805473328,27.92739868
	batSOC[39],batVoc[39],batESR[39] = 39,2.808132172,27.77481079
	batSOC[40],batVoc[40],batESR[40] = 40,2.810310364,27.3513794
	batSOC[41],batVoc[41],batESR[41] = 41,2.812549591,26.76773071
	batSOC[42],batVoc[42],batESR[42] = 42,2.815040588,24.66583252
	batSOC[43],batVoc[43],batESR[43] = 43,2.817344666,24.31106567
	batSOC[44],batVoc[44],batESR[44] = 44,2.819602966,24.11270142
	batSOC[45],batVoc[45],batESR[45] = 45,2.822128296,23.98300171
	batSOC[46],batVoc[46],batESR[46] = 46,2.824848175,23.96774292
	batSOC[47],batVoc[47],batESR[47] = 47,2.827629089,23.82278442
	batSOC[48],batVoc[48],batESR[48] = 48,2.830047607,23.73886108
	batSOC[49],batVoc[49],batESR[49] = 49,2.832378388,23.69689941
	batSOC[50],batVoc[50],batESR[50] = 50,2.8344841,23.79226685
	batSOC[51],batVoc[51],batESR[51] = 51,2.836860657,23.78082275
	batSOC[52],batVoc[52],batESR[52] = 52,2.839084625,23.81896973
	batSOC[53],batVoc[53],batESR[53] = 53,2.841220856,23.89526367
	batSOC[54],batVoc[54],batESR[54] = 54,2.843334198,24.03259277
	batSOC[55],batVoc[55],batESR[55] = 55,2.845554352,24.29199219
	batSOC[56],batVoc[56],batESR[56] = 56,2.848293304,24.23858643
	batSOC[57],batVoc[57],batESR[57] = 57,2.850547791,24.40261841
	batSOC[58],batVoc[58],batESR[58] = 58,2.853107452,24.39117432
	batSOC[59],batVoc[59],batESR[59] = 59,2.855819702,24.39498901
	batSOC[60],batVoc[60],batESR[60] = 60,2.858406067,24.37591553
	batSOC[61],batVoc[61],batESR[61] = 61,2.861461639,24.44458008
	batSOC[62],batVoc[62],batESR[62] = 62,2.864620209,23.98681641
	batSOC[63],batVoc[63],batESR[63] = 63,2.865943909,23.67401123
	batSOC[64],batVoc[64],batESR[64] = 64,2.865631104,23.61297607
	batSOC[65],batVoc[65],batESR[65] = 65,2.864479065,23.56338501
	batSOC[66],batVoc[66],batESR[66] = 66,2.863117218,24.09362793
	batSOC[67],batVoc[67],batESR[67] = 67,2.863449097,24.2767334
	batSOC[68],batVoc[68],batESR[68] = 68,2.863983154,24.75357056
	batSOC[69],batVoc[69],batESR[69] = 69,2.866874695,24.78408814
	batSOC[70],batVoc[70],batESR[70] = 70,2.87046814,24.47509766
	batSOC[71],batVoc[71],batESR[71] = 71,2.872364044,24.08599854
	batSOC[72],batVoc[72],batESR[72] = 72,2.873069763,24.02877808
	batSOC[73],batVoc[73],batESR[73] = 73,2.87348938,24.10888672
	batSOC[74],batVoc[74],batESR[74] = 74,2.873847961,23.96011353
	batSOC[75],batVoc[75],batESR[75] = 75,2.873657227,23.96392822
	batSOC[76],batVoc[76],batESR[76] = 76,2.873756409,23.77319336
	batSOC[77],batVoc[77],batESR[77] = 77,2.873081207,23.89144898
	batSOC[78],batVoc[78],batESR[78] = 78,2.873142242,23.54431152
	batSOC[79],batVoc[79],batESR[79] = 79,2.871494293,23.89144898
	batSOC[80],batVoc[80],batESR[80] = 80,2.871940613,23.83804321
	batSOC[81],batVoc[81],batESR[81] = 81,2.872428894,23.49472046
	batSOC[82],batVoc[82],batESR[82] = 82,2.874103546,23.16665649
	batSOC[83],batVoc[83],batESR[83] = 83,2.8751297,22.97210693
	batSOC[84],batVoc[84],batESR[84] = 84,2.876426697,22.51434326
	batSOC[85],batVoc[85],batESR[85] = 85,2.876964569,22.37319946
	batSOC[86],batVoc[86],batESR[86] = 86,2.879947662,21.36993408
	batSOC[87],batVoc[87],batESR[87] = 87,2.88048172,20.87020874
	batSOC[88],batVoc[88],batESR[88] = 88,2.882026672,20.45059204
	batSOC[89],batVoc[89],batESR[89] = 89,2.881736755,19.70291138
	batSOC[90],batVoc[90],batESR[90] = 90,2.87739563,20.16067505
	batSOC[91],batVoc[91],batESR[91] = 91,2.876174927,20.03860474
	batSOC[92],batVoc[92],batESR[92] = 92,2.874572754,19.8059082
	batSOC[93],batVoc[93],batESR[93] = 93,2.873703003,19.44732666
	batSOC[94],batVoc[94],batESR[94] = 94,2.872119904,19.17266846
	batSOC[95],batVoc[95],batESR[95] = 95,2.870750427,19.02770996
	batSOC[96],batVoc[96],batESR[96] = 96,2.866901398,18.93997192
	batSOC[97],batVoc[97],batESR[97] = 97,2.869537354,17.4331665
	batSOC[98],batVoc[98],batESR[98] = 98,2.880569458,16.06750488
	batSOC[99],batVoc[99],batESR[99] = 99,2.923564911,14.66369629
	batSOC[100],batVoc[100],batESR[100] = 100,3.282222748,13.16452026
end


function BatModelEnerAA25mA()
	
	batSOC = {}
	batVoc = {}
	batESR = {}
	dftCap = 1.5147

	batSOC[0],batVoc[0],batESR[0] = 0,0.99954223633,0.034770965576
	batSOC[1],batVoc[1],batESR[1] = 1,1.0597233772,0.032806396484
	batSOC[2],batVoc[2],batESR[2] = 2,1.0900962353,0.0319480896
	batSOC[3],batVoc[3],batESR[3] = 3,1.1078789234,0.031356811523
	batSOC[4],batVoc[4],batESR[4] = 4,1.1202483177,0.031023025513
	batSOC[5],batVoc[5],batESR[5] = 5,1.1299102306,0.030698776245
	batSOC[6],batVoc[6],batESR[6] = 6,1.1375231743,0.030479431152
	batSOC[7],batVoc[7],batESR[7] = 7,1.1438522339,0.030307769775
	batSOC[8],batVoc[8],batESR[8] = 8,1.149461031,0.030126571655
	batSOC[9],batVoc[9],batESR[9] = 9,1.154263258,0.029945373535
	batSOC[10],batVoc[10],batESR[10] = 10,1.158261776,0.029649734497
	batSOC[11],batVoc[11],batESR[11] = 11,1.1623148918,0.029535293579
	batSOC[12],batVoc[12],batESR[12] = 12,1.1659042835,0.029430389404
	batSOC[13],batVoc[13],batESR[13] = 13,1.1693816185,0.029230117798
	batSOC[14],batVoc[14],batESR[14] = 14,1.172501564,0.029163360596
	batSOC[15],batVoc[15],batESR[15] = 15,1.1754090786,0.029096603394
	batSOC[16],batVoc[16],batESR[16] = 16,1.1783180237,0.029058456421
	batSOC[17],batVoc[17],batESR[17] = 17,1.1809251308,0.028924942017
	batSOC[18],batVoc[18],batESR[18] = 18,1.1834588051,0.028867721558
	batSOC[19],batVoc[19],batESR[19] = 19,1.1859078407,0.028781890869
	batSOC[20],batVoc[20],batESR[20] = 20,1.1880502701,0.028762817383
	batSOC[21],batVoc[21],batESR[21] = 21,1.1902799606,0.028696060181
	batSOC[22],batVoc[22],batESR[22] = 22,1.1925265789,0.028657913208
	batSOC[23],batVoc[23],batESR[23] = 23,1.194647789,0.028581619263
	batSOC[24],batVoc[24],batESR[24] = 24,1.1967175007,0.028619766235
	batSOC[25],batVoc[25],batESR[25] = 25,1.198807478,0.02857208252
	batSOC[26],batVoc[26],batESR[26] = 26,1.2008025646,0.028486251831
	batSOC[27],batVoc[27],batESR[27] = 27,1.202753067,0.028467178345
	batSOC[28],batVoc[28],batESR[28] = 28,1.2047002316,0.028457641602
	batSOC[29],batVoc[29],batESR[29] = 29,1.2065830231,0.028409957886
	batSOC[30],batVoc[30],batESR[30] = 30,1.2085959911,0.02833366394
	batSOC[31],batVoc[31],batESR[31] = 31,1.2105031013,0.028257369995
	batSOC[32],batVoc[32],batESR[32] = 32,1.2122359276,0.028285980225
	batSOC[33],batVoc[33],batESR[33] = 33,1.2139909267,0.028200149536
	batSOC[34],batVoc[34],batESR[34] = 34,1.2156498432,0.028209686279
	batSOC[35],batVoc[35],batESR[35] = 35,1.2173261642,0.028133392334
	batSOC[36],batVoc[36],batESR[36] = 36,1.2191531658,0.028066635132
	batSOC[37],batVoc[37],batESR[37] = 37,1.2207021713,0.028066635132
	batSOC[38],batVoc[38],batESR[38] = 38,1.2221517563,0.028038024902
	batSOC[39],batVoc[39],batESR[39] = 39,1.2237384319,0.027990341187
	batSOC[40],batVoc[40],batESR[40] = 40,1.2253086567,0.027875900269
	batSOC[41],batVoc[41],batESR[41] = 41,1.2267487049,0.027780532837
	batSOC[42],batVoc[42],batESR[42] = 42,1.2280037403,0.027742385864
	batSOC[43],batVoc[43],batESR[43] = 43,1.2291705608,0.027723312378
	batSOC[44],batVoc[44],batESR[44] = 44,1.2302598953,0.027675628662
	batSOC[45],batVoc[45],batESR[45] = 45,1.2312970161,0.027627944946
	batSOC[46],batVoc[46],batESR[46] = 46,1.2322225571,0.027675628662
	batSOC[47],batVoc[47],batESR[47] = 47,1.2330732346,0.027656555176
	batSOC[48],batVoc[48],batESR[48] = 48,1.2338573933,0.027618408203
	batSOC[49],batVoc[49],batESR[49] = 49,1.2345879078,0.027589797974
	batSOC[50],batVoc[50],batESR[50] = 50,1.2353124619,0.027599334717
	batSOC[51],batVoc[51],batESR[51] = 51,1.235973835,0.027599334717
	batSOC[52],batVoc[52],batESR[52] = 52,1.2365703583,0.027627944946
	batSOC[53],batVoc[53],batESR[53] = 53,1.2371344566,0.02758026123
	batSOC[54],batVoc[54],batESR[54] = 54,1.2375781536,0.027637481689
	batSOC[55],batVoc[55],batESR[55] = 55,1.2380025387,0.027618408203
	batSOC[56],batVoc[56],batESR[56] = 56,1.2384097576,0.027666091919
	batSOC[57],batVoc[57],batESR[57] = 57,1.2387669086,0.027647018433
	batSOC[58],batVoc[58],batESR[58] = 58,1.2391426563,0.027656555176
	batSOC[59],batVoc[59],batESR[59] = 59,1.2395076752,0.027704238892
	batSOC[60],batVoc[60],batESR[60] = 60,1.2398700714,0.027666091919
	batSOC[61],batVoc[61],batESR[61] = 61,1.2402770519,0.027751922607
	batSOC[62],batVoc[62],batESR[62] = 62,1.2406797409,0.027742385864
	batSOC[63],batVoc[63],batESR[63] = 63,1.2411286831,0.027761459351
	batSOC[64],batVoc[64],batESR[64] = 64,1.2416088581,0.027742385864
	batSOC[65],batVoc[65],batESR[65] = 65,1.2421190739,0.027780532837
	batSOC[66],batVoc[66],batESR[66] = 66,1.2426323891,0.027742385864
	batSOC[67],batVoc[67],batESR[67] = 67,1.243162632,0.027732849121
	batSOC[68],batVoc[68],batESR[68] = 68,1.2437214851,0.027751922607
	batSOC[69],batVoc[69],batESR[69] = 69,1.2442936897,0.027694702148
	batSOC[70],batVoc[70],batESR[70] = 70,1.2449531555,0.027713775635
	batSOC[71],batVoc[71],batESR[71] = 71,1.2455208302,0.027713775635
	batSOC[72],batVoc[72],batESR[72] = 72,1.2460916042,0.027732849121
	batSOC[73],batVoc[73],batESR[73] = 73,1.2467563152,0.027694702148
	batSOC[74],batVoc[74],batESR[74] = 74,1.2473714352,0.027675628662
	batSOC[75],batVoc[75],batESR[75] = 75,1.247941494,0.027675628662
	batSOC[76],batVoc[76],batESR[76] = 76,1.2485020161,0.027675628662
	batSOC[77],batVoc[77],batESR[77] = 77,1.2490508556,0.027694702148
	batSOC[78],batVoc[78],batESR[78] = 78,1.2496685982,0.027675628662
	batSOC[79],batVoc[79],batESR[79] = 79,1.250333786,0.027675628662
	batSOC[80],batVoc[80],batESR[80] = 80,1.2509119511,0.027637481689
	batSOC[81],batVoc[81],batESR[81] = 81,1.2514209747,0.027656555176
	batSOC[82],batVoc[82],batESR[82] = 82,1.2519519329,0.027618408203
	batSOC[83],batVoc[83],batESR[83] = 83,1.2524437904,0.027656555176
	batSOC[84],batVoc[84],batESR[84] = 84,1.2528781891,0.027589797974
	batSOC[85],batVoc[85],batESR[85] = 85,1.2532734871,0.027666091919
	batSOC[86],batVoc[86],batESR[86] = 86,1.2536826134,0.027637481689
	batSOC[87],batVoc[87],batESR[87] = 87,1.2540724277,0.027675628662
	batSOC[88],batVoc[88],batESR[88] = 88,1.2544531822,0.027694702148
	batSOC[89],batVoc[89],batESR[89] = 89,1.2548487186,0.027713775635
	batSOC[90],batVoc[90],batESR[90] = 90,1.2552630901,0.027694702148
	batSOC[91],batVoc[91],batESR[91] = 91,1.2557194233,0.027675628662
	batSOC[92],batVoc[92],batESR[92] = 92,1.2562973499,0.027780532837
	batSOC[93],batVoc[93],batESR[93] = 93,1.2570900917,0.027799606323
	batSOC[94],batVoc[94],batESR[94] = 94,1.258143425,0.027799606323
	batSOC[95],batVoc[95],batESR[95] = 95,1.2596042156,0.027780532837
	batSOC[96],batVoc[96],batESR[96] = 96,1.2618589401,0.027866363525
	batSOC[97],batVoc[97],batESR[97] = 97,1.2652552128,0.027980804443
	batSOC[98],batVoc[98],batESR[98] = 98,1.2705600262,0.027933120728
	batSOC[99],batVoc[99],batESR[99] = 99,1.2790315151,0.028057098389
	batSOC[100],batVoc[100],batESR[100] = 100,1.2918889523,0.027484893799
end

function BatModelINR18650()
	
	batSOC = {}
	batVoc = {}
	batESR = {}
	dftCap = 1.4266

	batSOC[0],batVoc[0],batESR[0] = 0,2.4995079041,0.062255859375
	batSOC[1],batVoc[1],batESR[1] = 1,2.8698234558,0.050964355469
	batSOC[2],batVoc[2],batESR[2] = 2,3.064868927,0.049896240234
	batSOC[3],batVoc[3],batESR[3] = 3,3.1787185669,0.049133300781
	batSOC[4],batVoc[4],batESR[4] = 4,3.261390686,0.048675537109
	batSOC[5],batVoc[5],batESR[5] = 5,3.3259773254,0.048522949219
	batSOC[6],batVoc[6],batESR[6] = 6,3.3778266907,0.048522949219
	batSOC[7],batVoc[7],batESR[7] = 7,3.41979599,0.048217773438
	batSOC[8],batVoc[8],batESR[8] = 8,3.4437103271,0.048294067383
	batSOC[9],batVoc[9],batESR[9] = 9,3.4547042847,0.048065185547
	batSOC[10],batVoc[10],batESR[10] = 10,3.4622688293,0.048217773438
	batSOC[11],batVoc[11],batESR[11] = 11,3.4683761597,0.048065185547
	batSOC[12],batVoc[12],batESR[12] = 12,3.4736709595,0.047988891602
	batSOC[13],batVoc[13],batESR[13] = 13,3.4784469604,0.04768371582
	batSOC[14],batVoc[14],batESR[14] = 14,3.4830970764,0.04768371582
	batSOC[15],batVoc[15],batESR[15] = 15,3.4879150391,0.04753112793
	batSOC[16],batVoc[16],batESR[16] = 16,3.4938392639,0.047454833984
	batSOC[17],batVoc[17],batESR[17] = 17,3.5021018982,0.047378540039
	batSOC[18],batVoc[18],batESR[18] = 18,3.5120353699,0.047302246094
	batSOC[19],batVoc[19],batESR[19] = 19,3.5217056274,0.047225952148
	batSOC[20],batVoc[20],batESR[20] = 20,3.5317459106,0.047225952148
	batSOC[21],batVoc[21],batESR[21] = 21,3.542049408,0.047073364258
	batSOC[22],batVoc[22],batESR[22] = 22,3.5510444641,0.046920776367
	batSOC[23],batVoc[23],batESR[23] = 23,3.5587158203,0.046997070313
	batSOC[24],batVoc[24],batESR[24] = 24,3.56590271,0.046997070313
	batSOC[25],batVoc[25],batESR[25] = 25,3.5731697083,0.046997070313
	batSOC[26],batVoc[26],batESR[26] = 26,3.5801696777,0.047073364258
	batSOC[27],batVoc[27],batESR[27] = 27,3.5866394043,0.047225952148
	batSOC[28],batVoc[28],batESR[28] = 28,3.5924224854,0.047149658203
	batSOC[29],batVoc[29],batESR[29] = 29,3.5975608826,0.047149658203
	batSOC[30],batVoc[30],batESR[30] = 30,3.6021614075,0.047225952148
	batSOC[31],batVoc[31],batESR[31] = 31,3.6064682007,0.047073364258
	batSOC[32],batVoc[32],batESR[32] = 32,3.6105918884,0.047073364258
	batSOC[33],batVoc[33],batESR[33] = 33,3.6145820618,0.046920776367
	batSOC[34],batVoc[34],batESR[34] = 34,3.6186141968,0.046920776367
	batSOC[35],batVoc[35],batESR[35] = 35,3.6226959229,0.046768188477
	batSOC[36],batVoc[36],batESR[36] = 36,3.6268692017,0.046768188477
	batSOC[37],batVoc[37],batESR[37] = 37,3.6311302185,0.046920776367
	batSOC[38],batVoc[38],batESR[38] = 38,3.6355743408,0.046615600586
	batSOC[39],batVoc[39],batESR[39] = 39,3.6402053833,0.046691894531
	batSOC[40],batVoc[40],batESR[40] = 40,3.6450309753,0.046691894531
	batSOC[41],batVoc[41],batESR[41] = 41,3.6501235962,0.046310424805
	batSOC[42],batVoc[42],batESR[42] = 42,3.6554794312,0.046691894531
	batSOC[43],batVoc[43],batESR[43] = 43,3.6611099243,0.046463012695
	batSOC[44],batVoc[44],batESR[44] = 44,3.6669921875,0.04638671875
	batSOC[45],batVoc[45],batESR[45] = 45,3.6732330322,0.046310424805
	batSOC[46],batVoc[46],batESR[46] = 46,3.6797943115,0.046310424805
	batSOC[47],batVoc[47],batESR[47] = 47,3.6866340637,0.04638671875
	batSOC[48],batVoc[48],batESR[48] = 48,3.6938972473,0.046157836914
	batSOC[49],batVoc[49],batESR[49] = 49,3.701499939,0.045928955078
	batSOC[50],batVoc[50],batESR[50] = 50,3.7093315125,0.045928955078
	batSOC[51],batVoc[51],batESR[51] = 51,3.7174835205,0.045852661133
	batSOC[52],batVoc[52],batESR[52] = 52,3.7258415222,0.045700073242
	batSOC[53],batVoc[53],batESR[53] = 53,3.7343540192,0.045738220215
	batSOC[54],batVoc[54],batESR[54] = 54,3.7428665161,0.045700073242
	batSOC[55],batVoc[55],batESR[55] = 55,3.7514438629,0.045700073242
	batSOC[56],batVoc[56],batESR[56] = 56,3.759929657,0.045509338379
	batSOC[57],batVoc[57],batESR[57] = 57,3.7681808472,0.045547485352
	batSOC[58],batVoc[58],batESR[58] = 58,3.7762928009,0.045394897461
	batSOC[59],batVoc[59],batESR[59] = 59,3.7842235565,0.045394897461
	batSOC[60],batVoc[60],batESR[60] = 60,3.7920417786,0.045394897461
	batSOC[61],batVoc[61],batESR[61] = 61,3.7997550964,0.045318603516
	batSOC[62],batVoc[62],batESR[62] = 62,3.8076553345,0.04524230957
	batSOC[63],batVoc[63],batESR[63] = 63,3.8157253265,0.045356750488
	batSOC[64],batVoc[64],batESR[64] = 64,3.8238792419,0.04524230957
	batSOC[65],batVoc[65],batESR[65] = 65,3.8322372437,0.045318603516
	batSOC[66],batVoc[66],batESR[66] = 66,3.8405799866,0.045280456543
	batSOC[67],batVoc[67],batESR[67] = 67,3.8487739563,0.045394897461
	batSOC[68],batVoc[68],batESR[68] = 68,3.8566150665,0.045204162598
	batSOC[69],batVoc[69],batESR[69] = 69,3.8642196655,0.045318603516
	batSOC[70],batVoc[70],batESR[70] = 70,3.8715553284,0.045166015625
	batSOC[71],batVoc[71],batESR[71] = 71,3.8785877228,0.045318603516
	batSOC[72],batVoc[72],batESR[72] = 72,3.8853683472,0.045127868652
	batSOC[73],batVoc[73],batESR[73] = 73,3.8916797638,0.044975280762
	batSOC[74],batVoc[74],batESR[74] = 74,3.8976192474,0.04508972168
	batSOC[75],batVoc[75],batESR[75] = 75,3.9036006927,0.044975280762
	batSOC[76],batVoc[76],batESR[76] = 76,3.9103393555,0.044822692871
	batSOC[77],batVoc[77],batESR[77] = 77,3.9179096222,0.045127868652
	batSOC[78],batVoc[78],batESR[78] = 78,3.9260807037,0.045166015625
	batSOC[79],batVoc[79],batESR[79] = 79,3.9348945618,0.045166015625
	batSOC[80],batVoc[80],batESR[80] = 80,3.9441642761,0.045127868652
	batSOC[81],batVoc[81],batESR[81] = 81,3.9537734985,0.04524230957
	batSOC[82],batVoc[82],batESR[82] = 82,3.9635238647,0.045204162598
	batSOC[83],batVoc[83],batESR[83] = 83,3.9734764099,0.045204162598
	batSOC[84],batVoc[84],batESR[84] = 84,3.9834060669,0.045356750488
	batSOC[85],batVoc[85],batESR[85] = 85,3.9929943085,0.04566192627
	batSOC[86],batVoc[86],batESR[86] = 86,4.0021133423,0.045547485352
	batSOC[87],batVoc[87],batESR[87] = 87,4.0104007721,0.045585632324
	batSOC[88],batVoc[88],batESR[88] = 88,4.0176467896,0.04566192627
	batSOC[89],batVoc[89],batESR[89] = 89,4.0240020752,0.045585632324
	batSOC[90],batVoc[90],batESR[90] = 90,4.0295314789,0.045852661133
	batSOC[91],batVoc[91],batESR[91] = 91,4.0344200134,0.045928955078
	batSOC[92],batVoc[92],batESR[92] = 92,4.038936615,0.046005249023
	batSOC[93],batVoc[93],batESR[93] = 93,4.0435295105,0.046081542969
	batSOC[94],batVoc[94],batESR[94] = 94,4.0485858917,0.046157836914
	batSOC[95],batVoc[95],batESR[95] = 95,4.0542831421,0.046157836914
	batSOC[96],batVoc[96],batESR[96] = 96,4.0608386993,0.046234130859
	batSOC[97],batVoc[97],batESR[97] = 97,4.0683059692,0.046195983887
	batSOC[98],batVoc[98],batESR[98] = 98,4.076795578,0.045928955078
	batSOC[99],batVoc[99],batESR[99] = 99,4.0863990784,0.045051574707
	batSOC[100],batVoc[100],batESR[100] = 100,4.1001338959,0.040664672852
end

function BatModelCR2016()
	
	batSOC = {}
	batVoc = {}
	batESR = {}
	dftCap = 0.1057

	batSOC[0],batVoc[0],batESR[0] = 0,0.314632416,214.9772644
	batSOC[1],batVoc[1],batESR[1] = 1,0.610729218,201.6067505
	batSOC[2],batVoc[2],batESR[2] = 2,0.879825592,172.8820801
	batSOC[3],batVoc[3],batESR[3] = 3,1.088310242,155.0598145
	batSOC[4],batVoc[4],batESR[4] = 4,1.216938019,153.2854614
	batSOC[5],batVoc[5],batESR[5] = 5,1.332958221,151.8914795
	batSOC[6],batVoc[6],batESR[6] = 6,1.48772049,151.9737244
	batSOC[7],batVoc[7],batESR[7] = 7,1.695186615,153.0990601
	batSOC[8],batVoc[8],batESR[8] = 8,1.949222565,158.0232849
	batSOC[9],batVoc[9],batESR[9] = 9,2.149055481,158.3502197
	batSOC[10],batVoc[10],batESR[10] = 10,2.276157379,157.9360962
	batSOC[11],batVoc[11],batESR[11] = 11,2.378490448,155.3961182
	batSOC[12],batVoc[12],batESR[12] = 12,2.412452698,154.6440125
	batSOC[13],batVoc[13],batESR[13] = 13,2.455524445,155.6434631
	batSOC[14],batVoc[14],batESR[14] = 14,2.490226746,156.791687
	batSOC[15],batVoc[15],batESR[15] = 15,2.518989563,157.9322815
	batSOC[16],batVoc[16],batESR[16] = 16,2.544849396,158.8859558
	batSOC[17],batVoc[17],batESR[17] = 17,2.566848755,159.6717835
	batSOC[18],batVoc[18],batESR[18] = 18,2.58864212,160.8734131
	batSOC[19],batVoc[19],batESR[19] = 19,2.609191895,156.9442749
	batSOC[20],batVoc[20],batESR[20] = 20,2.624649048,158.2832336
	batSOC[21],batVoc[21],batESR[21] = 21,2.640258789,157.3677063
	batSOC[22],batVoc[22],batESR[22] = 22,2.653621674,159.0499878
	batSOC[23],batVoc[23],batESR[23] = 23,2.667930603,156.627655
	batSOC[24],batVoc[24],batESR[24] = 24,2.680892944,155.2124023
	batSOC[25],batVoc[25],batESR[25] = 25,2.692802429,154.2778015
	batSOC[26],batVoc[26],batESR[26] = 26,2.70400238,153.1486511
	batSOC[27],batVoc[27],batESR[27] = 27,2.714496613,152.3742676
	batSOC[28],batVoc[28],batESR[28] = 28,2.724239349,151.8936157
	batSOC[29],batVoc[29],batESR[29] = 29,2.733215332,152.5154114
	batSOC[30],batVoc[30],batESR[30] = 30,2.741378784,153.91922
	batSOC[31],batVoc[31],batESR[31] = 31,2.748672485,155.3955078
	batSOC[32],batVoc[32],batESR[32] = 32,2.75428772,156.9137573
	batSOC[33],batVoc[33],batESR[33] = 33,2.759101868,159.7709656
	batSOC[34],batVoc[34],batESR[34] = 34,2.763141632,160.6559753
	batSOC[35],batVoc[35],batESR[35] = 35,2.766750336,162.689209
	batSOC[36],batVoc[36],batESR[36] = 36,2.769714356,165.1420593
	batSOC[37],batVoc[37],batESR[37] = 37,2.776035309,168.8499451
	batSOC[38],batVoc[38],batESR[38] = 38,2.782039642,169.6968079
	batSOC[39],batVoc[39],batESR[39] = 39,2.786472321,170.7458496
	batSOC[40],batVoc[40],batESR[40] = 40,2.792144775,171.3867188
	batSOC[41],batVoc[41],batESR[41] = 41,2.796447754,168.9071655
	batSOC[42],batVoc[42],batESR[42] = 42,2.799995422,175.6401062
	batSOC[43],batVoc[43],batESR[43] = 43,2.801452637,172.0542908
	batSOC[44],batVoc[44],batESR[44] = 44,2.804302216,173.5305786
	batSOC[45],batVoc[45],batESR[45] = 45,2.808235169,175.0602722
	batSOC[46],batVoc[46],batESR[46] = 46,2.812904358,174.2019653
	batSOC[47],batVoc[47],batESR[47] = 47,2.816932678,173.9730835
	batSOC[48],batVoc[48],batESR[48] = 48,2.821063995,173.0384827
	batSOC[49],batVoc[49],batESR[49] = 49,2.82509613,171.1921692
	batSOC[50],batVoc[50],batESR[50] = 50,2.829109192,168.2624817
	batSOC[51],batVoc[51],batESR[51] = 51,2.83278656,165.725708
	batSOC[52],batVoc[52],batESR[52] = 52,2.836498261,162.4946594
	batSOC[53],batVoc[53],batESR[53] = 53,2.840164185,156.8031311
	batSOC[54],batVoc[54],batESR[54] = 54,2.841632843,155.9448242
	batSOC[55],batVoc[55],batESR[55] = 55,2.843086243,153.7437439
	batSOC[56],batVoc[56],batESR[56] = 56,2.843532562,152.9808044
	batSOC[57],batVoc[57],batESR[57] = 57,2.845149994,152.4658203
	batSOC[58],batVoc[58],batESR[58] = 58,2.846038818,152.8739929
	batSOC[59],batVoc[59],batESR[59] = 59,2.846084595,152.2331238
	batSOC[60],batVoc[60],batESR[60] = 60,2.845462799,151.7524719
	batSOC[61],batVoc[61],batESR[61] = 61,2.844223023,154.7546387
	batSOC[62],batVoc[62],batESR[62] = 62,2.842189789,154.8309326
	batSOC[63],batVoc[63],batESR[63] = 63,2.840003967,158.4057617
	batSOC[64],batVoc[64],batESR[64] = 64,2.845142365,161.2663269
	batSOC[65],batVoc[65],batESR[65] = 65,2.84431839,162.0483398
	batSOC[66],batVoc[66],batESR[66] = 66,2.844165802,158.2832336
	batSOC[67],batVoc[67],batESR[67] = 67,2.843940735,165.9355164
	batSOC[68],batVoc[68],batESR[68] = 68,2.845378876,165.1420593
	batSOC[69],batVoc[69],batESR[69] = 69,2.846637726,165.5883789
	batSOC[70],batVoc[70],batESR[70] = 70,2.848049164,172.252655
	batSOC[71],batVoc[71],batESR[71] = 71,2.849498749,169.2085266
	batSOC[72],batVoc[72],batESR[72] = 72,2.850933075,159.6260071
	batSOC[73],batVoc[73],batESR[73] = 73,2.852375031,156.742096
	batSOC[74],batVoc[74],batESR[74] = 74,2.853122711,155.6451111
	batSOC[75],batVoc[75],batESR[75] = 75,2.854011536,162.2200012
	batSOC[76],batVoc[76],batESR[76] = 76,2.853580475,158.11026
	batSOC[77],batVoc[77],batESR[77] = 77,2.849185944,157.5163269
	batSOC[78],batVoc[78],batESR[78] = 78,2.847858429,157.6940308
	batSOC[79],batVoc[79],batESR[79] = 79,2.847187042,157.0074158
	batSOC[80],batVoc[80],batESR[80] = 80,2.84569931,158.7329407
	batSOC[81],batVoc[81],batESR[81] = 81,2.843933106,158.4425354
	batSOC[82],batVoc[82],batESR[82] = 82,2.842311859,158.5522461
	batSOC[83],batVoc[83],batESR[83] = 83,2.841968536,158.5999451
	batSOC[84],batVoc[84],batESR[84] = 84,2.842372894,158.7407532
	batSOC[85],batVoc[85],batESR[85] = 85,2.843986511,158.6580505
	batSOC[86],batVoc[86],batESR[86] = 86,2.842338562,157.2619629
	batSOC[87],batVoc[87],batESR[87] = 87,2.839801788,157.8824463
	batSOC[88],batVoc[88],batESR[88] = 88,2.837795258,157.2303772
	batSOC[89],batVoc[89],batESR[89] = 89,2.835632324,157.1311951
	batSOC[90],batVoc[90],batESR[90] = 90,2.832443237,152.4581909
	batSOC[91],batVoc[91],batESR[91] = 91,2.831859589,156.9595337
	batSOC[92],batVoc[92],batESR[92] = 92,2.831951141,158.7944031
	batSOC[93],batVoc[93],batESR[93] = 93,2.832431793,158.3900452
	batSOC[94],batVoc[94],batESR[94] = 94,2.833438873,157.1846008
	batSOC[95],batVoc[95],batESR[95] = 95,2.835338593,154.4914246
	batSOC[96],batVoc[96],batESR[96] = 96,2.837638855,151.5769959
	batSOC[97],batVoc[97],batESR[97] = 97,2.840286255,150.0968933
	batSOC[98],batVoc[98],batESR[98] = 98,2.843540192,153.3126831
	batSOC[99],batVoc[99],batESR[99] = 99,2.853492737,174.1409302
	batSOC[100],batVoc[100],batESR[100] = 100,3.295001984,180.3283691
end

function BatModelCR2450()
	
	batSOC = {}
	batVoc = {}
	batESR = {}
	dftCap = 0.5209

	batSOC[0],batVoc[0],batESR[0] = 0,2.257896423,704.3789595
	batSOC[1],batVoc[1],batESR[1] = 1,2.453659058,435.256958
	batSOC[2],batVoc[2],batESR[2] = 2,2.629749298,354.3266883
	batSOC[3],batVoc[3],batESR[3] = 3,2.701747894,285.9360133
	batSOC[4],batVoc[4],batESR[4] = 4,2.736503601,237.9686405
	batSOC[5],batVoc[5],batESR[5] = 5,2.755374908,209.0454102
	batSOC[6],batVoc[6],batESR[6] = 6,2.774143219,172.37541
	batSOC[7],batVoc[7],batESR[7] = 7,2.787445068,141.9849885
	batSOC[8],batVoc[8],batESR[8] = 8,2.795677185,125.0731639
	batSOC[9],batVoc[9],batESR[9] = 9,2.805168152,106.156178
	batSOC[10],batVoc[10],batESR[10] = 10,2.813724518,90.63329452
	batSOC[11],batVoc[11],batESR[11] = 11,2.821590424,79.16964017
	batSOC[12],batVoc[12],batESR[12] = 12,2.827468872,71.03161934
	batSOC[13],batVoc[13],batESR[13] = 13,2.834495544,62.22847181
	batSOC[14],batVoc[14],batESR[14] = 14,2.840934753,55.26420398
	batSOC[15],batVoc[15],batESR[15] = 15,2.848163605,49.54215808
	batSOC[16],batVoc[16],batESR[16] = 16,2.855041504,44.40698868
	batSOC[17],batVoc[17],batESR[17] = 17,2.861175537,40.17169659
	batSOC[18],batVoc[18],batESR[18] = 18,2.867198944,37.1492826
	batSOC[19],batVoc[19],batESR[19] = 19,2.871910095,34.71374512
	batSOC[20],batVoc[20],batESR[20] = 20,2.877510071,32.47383313
	batSOC[21],batVoc[21],batESR[21] = 21,2.880908966,31.4663618
	batSOC[22],batVoc[22],batESR[22] = 22,2.885627747,29.09929324
	batSOC[23],batVoc[23],batESR[23] = 23,2.888828278,28.22875977
	batSOC[24],batVoc[24],batESR[24] = 24,2.892089844,26.11600436
	batSOC[25],batVoc[25],batESR[25] = 25,2.893939972,25.90081631
	batSOC[26],batVoc[26],batESR[26] = 26,2.897060394,24.55100035
	batSOC[27],batVoc[27],batESR[27] = 27,2.899539948,23.95434257
	batSOC[28],batVoc[28],batESR[28] = 28,2.902786255,23.06424654
	batSOC[29],batVoc[29],batESR[29] = 29,2.906517029,21.46011744
	batSOC[30],batVoc[30],batESR[30] = 30,2.907798767,20.55045886
	batSOC[31],batVoc[31],batESR[31] = 31,2.910705566,19.57233136
	batSOC[32],batVoc[32],batESR[32] = 32,2.911540985,19.0050174
	batSOC[33],batVoc[33],batESR[33] = 33,2.913719177,18.27142178
	batSOC[34],batVoc[34],batESR[34] = 34,2.915725708,17.82148312
	batSOC[35],batVoc[35],batESR[35] = 35,2.917324066,17.05854367
	batSOC[36],batVoc[36],batESR[36] = 36,2.920097351,16.08041617
	batSOC[37],batVoc[37],batESR[37] = 37,2.919120789,16.50101099
	batSOC[38],batVoc[38],batESR[38] = 38,2.919776917,16.41297952
	batSOC[39],batVoc[39],batESR[39] = 39,2.920608521,16.20757274
	batSOC[40],batVoc[40],batESR[40] = 40,2.922397614,15.68916516
	batSOC[41],batVoc[41],batESR[41] = 41,2.923748016,15.14141376
	batSOC[42],batVoc[42],batESR[42] = 42,2.926399231,13.78181653
	batSOC[43],batVoc[43],batESR[43] = 43,2.925834656,13.98722331
	batSOC[44],batVoc[44],batESR[44] = 44,2.927066803,12.66675118
	batSOC[45],batVoc[45],batESR[45] = 45,2.928134918,12.41243803
	batSOC[46],batVoc[46],batESR[46] = 46,2.928478241,11.78643642
	batSOC[47],batVoc[47],batESR[47] = 47,2.92956543,11.70818622
	batSOC[48],batVoc[48],batESR[48] = 48,2.929473877,11.2484663
	batSOC[49],batVoc[49],batESR[49] = 49,2.932552338,10.63224597
	batSOC[50],batVoc[50],batESR[50] = 50,2.929897308,10.67137107
	batSOC[51],batVoc[51],batESR[51] = 51,2.931266785,10.20186987
	batSOC[52],batVoc[52],batESR[52] = 52,2.930854797,10.07471329
	batSOC[53],batVoc[53],batESR[53] = 53,2.932121277,9.350898938
	batSOC[54],batVoc[54],batESR[54] = 54,2.931713104,9.507399339
	batSOC[55],batVoc[55],batESR[55] = 55,2.933071137,8.832491361
	batSOC[56],batVoc[56],batESR[56] = 56,2.934825897,8.108677008
	batSOC[57],batVoc[57],batESR[57] = 57,2.934707642,8.265177409
	batSOC[58],batVoc[58],batESR[58] = 58,2.936740875,8.118458283
	batSOC[59],batVoc[59],batESR[59] = 59,2.937202454,7.864145132
	batSOC[60],batVoc[60],batESR[60] = 60,2.938697815,7.639175806
	batSOC[61],batVoc[61],batESR[61] = 61,2.93813324,7.668519631
	batSOC[62],batVoc[62],batESR[62] = 62,2.938800812,7.39464393
	batSOC[63],batVoc[63],batESR[63] = 63,2.937374115,7.482675406
	batSOC[64],batVoc[64],batESR[64] = 64,2.937137604,7.404425205
	batSOC[65],batVoc[65],batESR[65] = 65,2.937385559,7.345737555
	batSOC[66],batVoc[66],batESR[66] = 66,2.9373703,7.33595628
	batSOC[67],batVoc[67],batESR[67] = 67,2.940223694,7.150112054
	batSOC[68],batVoc[68],batESR[68] = 68,2.938182831,7.23814353
	batSOC[69],batVoc[69],batESR[69] = 69,2.938793182,7.071861854
	batSOC[70],batVoc[70],batESR[70] = 70,2.937129974,7.140330779
	batSOC[71],batVoc[71],batESR[71] = 71,2.938205719,7.032736754
	batSOC[72],batVoc[72],batESR[72] = 72,2.936717987,7.130549504
	batSOC[73],batVoc[73],batESR[73] = 73,2.936138153,6.983830379
	batSOC[74],batVoc[74],batESR[74] = 74,2.936210632,7.013174204
	batSOC[75],batVoc[75],batESR[75] = 75,2.935836792,6.915361453
	batSOC[76],batVoc[76],batESR[76] = 76,2.934856415,6.983830379
	batSOC[77],batVoc[77],batESR[77] = 77,2.934108734,6.993611654
	batSOC[78],batVoc[78],batESR[78] = 78,2.933349609,6.993611654
	batSOC[79],batVoc[79],batESR[79] = 79,2.932743073,7.042518029
	batSOC[80],batVoc[80],batESR[80] = 80,2.934513092,6.905580178
	batSOC[81],batVoc[81],batESR[81] = 81,2.932453156,7.062080579
	batSOC[82],batVoc[82],batESR[82] = 82,2.933643341,6.944705278
	batSOC[83],batVoc[83],batESR[83] = 83,2.931591034,7.101205679
	batSOC[84],batVoc[84],batESR[84] = 84,2.93157196,7.013174204
	batSOC[85],batVoc[85],batESR[85] = 85,2.931358337,7.159893329
	batSOC[86],batVoc[86],batESR[86] = 86,2.929096222,7.31639373
	batSOC[87],batVoc[87],batESR[87] = 87,2.931350708,7.287049905
	batSOC[88],batVoc[88],batESR[88] = 88,2.92798996,7.580488156
	batSOC[89],batVoc[89],batESR[89] = 89,2.928195953,7.648957081
	batSOC[90],batVoc[90],batESR[90] = 90,2.927074432,7.766332382
	batSOC[91],batVoc[91],batESR[91] = 91,2.92641449,7.922832783
	batSOC[92],batVoc[92],batESR[92] = 92,2.926681519,8.059770633
	batSOC[93],batVoc[93],batESR[93] = 93,2.927219391,8.059770633
	batSOC[94],batVoc[94],batESR[94] = 94,2.925933838,8.186927209
	batSOC[95],batVoc[95],batESR[95] = 95,2.925045013,8.049989358
	batSOC[96],batVoc[96],batESR[96] = 96,2.925071716,7.952176608
	batSOC[97],batVoc[97],batESR[97] = 97,2.923294067,7.678300907
	batSOC[98],batVoc[98],batESR[98] = 98,2.926643372,7.228362255
	batSOC[99],batVoc[99],batESR[99] = 99,2.942054749,7.169674604
	batSOC[100],batVoc[100],batESR[100] = 100,3.225662231,7.678300907
end


------------------------------------------------------------------
--  Test start up
------------------------------------------------------------------

SetUpPrompts() -- runs the script from here....