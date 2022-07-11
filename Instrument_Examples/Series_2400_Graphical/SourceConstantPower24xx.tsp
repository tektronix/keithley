--[[

***********************************************************
*** Copyright 2022 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Written by: Keithley Applications Engineering 

This script allows constant power to be sourced by modifying voltage or current.

Designed for the Series 2400 Graphical Series SMUs

To utilize console console commands set the global variable 'consoleControl' to true

For console control, use the master command: 'constantPower()'

Expected Input:
constantPower(Source, TargetSource, IncreaseSource, MaxSource, TargetPower, Sense)

]]

-- ********************** GLOBAL VARIABLES **********************

-- Variable for Console Control
consoleControl = false;

-- User Input Variables
source = "Voltage"
targetSource = 0.0
increaseSource = true
maxSourceLevel = 0.0
targetPower = 0.0
sense = true;

-- Generated Variables
currPower = 0.0
currSource = 0.0
currMeasure = 0.0

-- ************************* FUNCTIONS **************************

-- Input Functions

function set_source() 
    -- Get what the user wants to source
	optionID = display.input.option("Select Source", "Voltage", "Current")
	if optionID == display.BUTTON_OPTION1 then -- Voltage
		return "Voltage"

	elseif optionID == display.BUTTON_OPTION2 then -- Current
		return "Current"

	end
end

function set_starting_source()
    -- Gets the starting source value

    -- If source is Voltage
    if source == "Voltage" then
	    return display.input.number("Target/Starting Source Level", display.NFORMAT_PREFIX, 0, -1100, 1100)

    -- If source is Current
    else  
        return display.input.number("Target/Starting Source Level", display.NFORMAT_PREFIX, 0, -1.05, 1.05)  

    end
end

function can_increase_source() 
    -- Can the source be modified
	optionID = display.input.option("Can the script increase source?", "Yes", "No")
	if optionID == display.BUTTON_OPTION1 then -- Yes
		return true
	elseif optionID == display.BUTTON_OPTION2 then -- No
		return false
	end
end

function set_max_source_level()
    -- Gets the max source value

    -- If source is Voltage
    if source == "Voltage" then
	    return display.input.number("Max Voltage Level", display.NFORMAT_PREFIX, targetSource, targetSource, 1100)

    -- If source is Current
    else  
        return display.input.number("Max Current Level", display.NFORMAT_PREFIX, targetSource, targetSource, 1.05)  
        
    end
end

function set_target_power()
    -- Gets the target power level
	return display.input.number("Target Power", display.NFORMAT_PREFIX, 0, 0, 1000)
end

function can_use_sense() 
    -- Can the source be modified
	optionID = display.input.option("2-Wire or 4-Wire Sense?", "2-Wire", "4-Wire")
	if optionID == display.BUTTON_OPTION1 then -- 2-Wire
		return false
	elseif optionID == display.BUTTON_OPTION2 then -- 4-Wire
		return true
	end
end

-- General Functions

function generateScreen()

    -- Generates user swipe object and clears screen
    display.clear()

    powScreen = display.create(display.SCREEN_HOME, display.OBJ_SWIPE, "Source Power")

    display.create(powScreen, display.OBJ_TEXT, 15, 60, "Source:", 0x006281, display.FONT_6, display.JUST_LEFT)
    sourceOutput = display.create(powScreen, display.OBJ_TEXT, 225, 60, "0.00", 0xF5F5F5, display.FONT_6, display.JUST_LEFT)
	
    display.create(powScreen, display.OBJ_TEXT, 15, 130, "Measure:", 0x006281, display.FONT_6, display.JUST_LEFT)
    measureOutput = display.create(powScreen, display.OBJ_TEXT, 225, 130, "0.00", 0xF5F5F5, display.FONT_6, display.JUST_LEFT)
    
    display.create(powScreen, display.OBJ_TEXT, 15, 185, "Target Power:", 0x006281, display.FONT_4, display.JUST_LEFT)
    targetPowerOutput = display.create(powScreen, display.OBJ_TEXT, 195, 185, "0.00", 0xF5F5F5, display.FONT_4, display.JUST_LEFT)

    display.create(powScreen, display.OBJ_TEXT, 355, 185, "Current Power:", 0x006281, display.FONT_4, display.JUST_LEFT)
    currPowerOutput = display.create(powScreen, display.OBJ_TEXT, 550, 185, "0.00", 0xF5F5F5, display.FONT_4, display.JUST_LEFT)

end

function updateDisplay()

    -- Updates Current & Voltage
    if smu.source.func == smu.FUNC_DC_VOLTAGE then
        -- Voltage Source
        display.settext(sourceOutput, display.format(currSource, "V", display.NFORMAT_DECIMAL, 4))
        display.settext(measureOutput, display.format(currMeasure, "A", display.NFORMAT_DECIMAL, 4))

    elseif smu.source.func == smu.FUNC_DC_CURRENT then
        -- Current Source
        display.settext(sourceOutput, display.format(currSource, "A", display.NFORMAT_DECIMAL, 4))
        display.settext(measureOutput, display.format(currMeasure, "V", display.NFORMAT_DECIMAL, 4))

    else
        -- Catch Errors
        display.settext("ERROR")
    end

    -- Updates Power
    display.settext(targetPowerOutput, display.format(targetPower, "W", display.NFORMAT_DECIMAL, 4))
    display.settext(currPowerOutput, display.format(currPower, "W", display.NFORMAT_DECIMAL, 4))

end

function updateSourceType()

    -- What is the requested source?
    if source == "Voltage" then

        -- Sets source to Voltage
        smu.source.func = smu.FUNC_DC_VOLTAGE -- Source
        smu.measure.func = smu.FUNC_DC_CURRENT -- Measure
        smu.source.ilimit.level = 1.05

    else -- source == "Current"

        -- Sets source to Current
        smu.source.func = smu.FUNC_DC_CURRENT -- Source
        smu.measure.func = smu.FUNC_DC_VOLTAGE -- Measure
        smu.source.vlimit.level = 1100

    end

end

function run()

    -- Resets SMU
    smu.reset()
	opc()

    -- Generates and updates the screen
    generateScreen()

    -- Updates display
    updateDisplay()

    -- Sets source and measure
    updateSourceType()

    -- Sets output source
    smu.source.level = targetSource
    currSource = smu.source.level

    -- Sets the device to 2-Wire or 4-Wire Sense
    if sense == false then -- 2-Wire
        smu.measure.sense = smu.SENSE_2WIRE
	elseif sense == true then -- 4-Wire
        smu.measure.sense = smu.SENSE_4WIRE
	end

    -- Turn on source output & sets default settings
    smu.source.output = smu.ON
    
    -- While output is on
    while smu.source.output == smu.ON do

        -- Calculates current power with target
        currSource = smu.source.level
        currMeasure = smu.measure.read()
        currPower = currSource * currMeasure 

        -- If current power is too low AND source can be increased AND source is below limit
        if ((currPower + 0.001) < targetPower) and increaseSource and (currSource + 0.001) < maxSourceLevel then

            smu.source.level = targetPower / smu.measure.read() 

        -- If current power is too high 
        elseif ((currPower - 0.001) > targetPower) then

            smu.source.level = targetPower / smu.measure.read() 

        -- Power is +/- 0.001 or mUnits from target
        else

            -- Keep source constant until measure changes

        end
        
        -- Updates Display
        updateDisplay()

        -- Switches back to measuring Current/Voltage
        updateSourceType()

    end
    
end

-- Console Functions

function constantPower(c_source, c_targetSource, c_increaseSource, c_maxSourceLevel, c_targetPower, c_sense)

    -- Sets console input to global variables
    source = c_source
    targetSource = c_targetSource
    increaseSource = c_increaseSource
    if increaseSource then
        -- Sets max source level
        maxSourceLevel = c_maxSourceLevel
    else
        -- Sets max source level as starting source
        maxSourceLevel = targetSource
    end
    targetPower = c_targetPower
    sense = c_sense

    run()

end

function clear()

    -- Resets SMU
    reset() 

    -- Turns off output
    smu.source.output = smu.OFF

    -- Resets inputs
    source = "Voltage"
    targetSource = 0.0
    increaseSource = true
    maxSourceLevel = 0.0
    targetPower = 0.0
    sense = true;

end

-- ************************* MAIN PROGRAM **************************

-- Resets the 2400
reset() 

if consoleControl == false then

    -- Prints out Info for user
    print('This script can be ran from the screen of the 2470')
    
    -- Input from front panel
    source = set_source()
    updateSourceType()
    targetSource = set_starting_source()
    increaseSource = can_increase_source() 
    if increaseSource then
        -- Sets max source level
        maxSourceLevel = set_max_source_level()
    else
        -- Sets max source level as starting source
        maxSourceLevel = targetSource
    end
    targetPower = set_target_power()
    sense = can_use_sense()

    -- Runs the script with the user input settings
    run()

end -- consoleControl == true