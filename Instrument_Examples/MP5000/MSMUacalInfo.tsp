--[[
***********************************************************
*** Copyright 2026 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Purpose: This script demonstrates retrieving information on the ACAL (Automatic Calibration) system in MSMU modules installed in the MP5103 mainframe.

It creates functions that automate slot[Z].smu[X].acal commands from the Reference Manual. Some helper commands to format time are also included. 

allAcal() combines these functions to print ACAL validity and reasons for invalidity to the terminal. By default, it runs when the script is run. 

Author: Brad O. 10/5/2026

TODO: Allow finding other MP5103 mainframes over TSP-Link and iterate over them. 

]]


-- Functions
function utcToReadable(utcseconds, utcfractionalseconds) -- Converts a UTC timestamp in seconds and fractional seconds to a human-readable date in the format "YYYY-MM-DD HH:MM:SS.ssssss UTC"
    local seconds = utcseconds + (utcfractionalseconds or 0)

    -- os.date() only accepts an integer timestamp, so handle
    -- the fractional portion separately.
    local wholeSeconds = math.floor(seconds)
    local fraction = seconds - wholeSeconds

    return os.date("!%Y-%m-%d %H:%M:%S", wholeSeconds)
        .. string.format(".%06d", math.floor(fraction * 1000000 + 0.5))
        .. " UTC"
end

function utcDuration(seconds) -- Converts a duration in seconds to a human-readable format in the form "DD:HH:MM:SS"
    days = string.format("%02.f", math.floor(seconds/86400))
    hours = string.format("%02.f", math.floor(seconds/3600 - days*24))
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60 + days*1440)))
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins*60 - days*86400))
    return days..":"..hours..":"..mins..":"..secs
end

function findSMUs() -- Returns a table of slots in the mainframe that contain MSMU modules.  If no valid slots are found, returns an empty table.
    local validslots = {}
    for Z = 1,3 do
        if slot[Z] then
            checkSMU = string.find(slot[Z].model, "MSMU")
            if checkSMU then
                table.insert(validslots, Z)
            end
        end
    end
    return validslots
end

function findChannels(slotnum) -- Returns a table of valid channels in the specified slot. 
    local validchannels = {}
    for X = 1,2 do
        if slot[slotnum].smu[X] then
            table.insert(validchannels, X)
        end
    end
    return validchannels
end

function acalValid(slotnum, chnum, termprint) -- Returns a true/false table of ACAL validity for the specified slot and channel.
    termprint = termprint or false -- If optional termprint is true, ACAL validity will be printed to the terminal. 
    local validTable = {}
    table.insert(validTable, slot[slotnum].smu[chnum].acal.valid(slot[slotnum].smu[chnum].ACAL_I_SOURCE_OFFSET))
    table.insert(validTable, slot[slotnum].smu[chnum].acal.valid(slot[slotnum].smu[chnum].ACAL_I_MEASURE_OFFSET))
    table.insert(validTable, slot[slotnum].smu[chnum].acal.valid(slot[slotnum].smu[chnum].ACAL_AUX_ADC))

    if termprint then
        print("For", slot[slotnum].model, " Channel ", tostring(chnum)," in Slot ", tostring(slotnum))
        print("\tI Source Offset ACAL valid? ", validTable[1])
        print("\tI Measure Offset ACAL valid?", validTable[2])
        print("\tAux ADC ACAL valid?         ", validTable[3])
    end
    return validTable
end

function acalDue(slotnum, chnum, termprint) -- Returns a table of ACAL due dates in seconds since Jan 1, 1970 for the specified slot and channel.
    termprint = termprint or false -- If optional termprint is true, ACAL due dates will be printed to the terminal in readable format. 
    local dueTable = {}
    table.insert(dueTable, slot[slotnum].smu[chnum].acal.due(slot[slotnum].smu[chnum].ACAL_I_SOURCE_OFFSET))
    table.insert(dueTable, slot[slotnum].smu[chnum].acal.due(slot[slotnum].smu[chnum].ACAL_I_MEASURE_OFFSET))
    table.insert(dueTable, slot[slotnum].smu[chnum].acal.due(slot[slotnum].smu[chnum].ACAL_AUX_ADC))

    if termprint then
        print("For", slot[slotnum].model, " Channel ", tostring(chnum)," in Slot ", tostring(slotnum))
        print("\tI Source Offset ACAL due date: ", utcToReadable(dueTable[1]))
        print("\tI Measure Offset ACAL due date:", utcToReadable(dueTable[2]))
        print("\tAux ADC ACAL due date:         ", utcToReadable(dueTable[3]))
    end
    return dueTable
end

function acalAdjustDate(slotnum, chnum, termprint) -- Returns a table of the last ACAL adjust dates in seconds since Jan 1, 1970 for the specified slot and channel.
    termprint = termprint or false -- If optional termprint is true, dates of last acal adjustments will be printed to the terminal in readable format. 
    local adjustDateTable = {}
    table.insert(adjustDateTable, slot[slotnum].smu[chnum].acal.adjustdate(slot[slotnum].smu[chnum].ACAL_I_SOURCE_OFFSET))
    table.insert(adjustDateTable, slot[slotnum].smu[chnum].acal.adjustdate(slot[slotnum].smu[chnum].ACAL_I_MEASURE_OFFSET))
    table.insert(adjustDateTable, slot[slotnum].smu[chnum].acal.adjustdate(slot[slotnum].smu[chnum].ACAL_AUX_ADC))

    if termprint then
        print("For", slot[slotnum].model, " Channel ", tostring(chnum)," in Slot ", tostring(slotnum))
        print("\tI Source Offset ACAL adjust date: ", utcToReadable(adjustDateTable[1]))
        print("\tI Measure Offset ACAL adjust date:", utcToReadable(adjustDateTable[2]))
        print("\tAux ADC ACAL adjust date:         ", utcToReadable(adjustDateTable[3]))
    end
    return adjustDateTable
end

function acalTemperatureDelta(slotnum, chnum, termprint) -- Returns a table of the difference in temperature (in Celcius) between the current temperature and the temperature at which the ACAL was last performed for the specified slot and channel.
    termprint = termprint or false -- If optional termprint is true, ACAL temperature deltas will be printed to the terminal.
    local deltaTable = {}
    table.insert(deltaTable, slot[slotnum].smu[chnum].acal.temperaturedelta(slot[slotnum].smu[chnum].ACAL_I_SOURCE_OFFSET))
    table.insert(deltaTable, slot[slotnum].smu[chnum].acal.temperaturedelta(slot[slotnum].smu[chnum].ACAL_I_MEASURE_OFFSET))
    table.insert(deltaTable, slot[slotnum].smu[chnum].acal.temperaturedelta(slot[slotnum].smu[chnum].ACAL_AUX_ADC))

    if termprint then
        print("For", slot[slotnum].model, " Channel ", tostring(chnum)," in Slot ", tostring(slotnum))
        print("\tI Source Offset ACAL temperature delta: ", deltaTable[1])
        print("\tI Measure Offset ACAL temperature delta:", deltaTable[2])
        print("\tAux ADC ACAL temperature delta:         ", deltaTable[3])
    end
    return deltaTable
end

function acalDueDateDifference(slotnum,chnum, termprint) -- Returns a table of the difference in seconds between the current date and the ACAL due dates for the specified slot and channel.
    termprint = termprint or false -- If optional termprint is true, ACAL due date differences will be printed to the terminal in a readable format. 
    local diffTable = {}
    local now = os.time()
    local dueDateTable = acalDue(slotnum, chnum)
    for i = 1,3 do
        local diff = dueDateTable[i] - now -- a negative value indicates that the ACAL is overdue, a positive value indicates that the ACAL is not yet due.
        table.insert(diffTable, diff)
    end

    if termprint then
        print("For", slot[slotnum].model, " Channel ", tostring(chnum)," in Slot ", tostring(slotnum))
        print("\tI Source Offset ACAL date difference: ", utcDuration(diffTable[1]))
        print("\tI Measure Offset ACAL date difference:", utcDuration(diffTable[2]))
        print("\tAux ADC ACAL date difference:         ", utcDuration(diffTable[3]))
    end
    return diffTable
end

function allAcalValid(termprint) -- Returns a nested table of ACAL validity for all channels in all MSMU modules in the mainframe.
    termprint = termprint or false -- If termprint is true, ACAL validity will be printed to the terminal.
    local allvalids = {}
    local smuslots = findSMUs()
    for i, slotnum in ipairs(smuslots) do
        local channels = findChannels(slotnum)
        for j, chnum in ipairs(channels) do
            local validTable = acalValid(slotnum, chnum, termprint)
            table.insert(allvalids, {slotnum, chnum, validTable})
        end
    end
    return allvalids
end

function allAcal(termprint) -- Determines ACAL validity for all channels in all MSMU modules in the mainframe and prints the results to the terminal.
    termprint = termprint or false -- Final results will always be printed. If true, all details are printed
    local Procedures = {"ACAL_I_SOURCE_OFFSET", "ACAL_I_MEASURE_OFFSET", "ACAL_AUX_ADC"}
    local smuslots = findSMUs()
    for i, slotnum in ipairs(smuslots) do
        local channels = findChannels(slotnum)
        for j, chnum in ipairs(channels) do
            local validTable = acalValid(slotnum, chnum, termprint)
            --local dueTable = acalDue(slotnum, chnum, termprint)
            --local adjustDateTable = acalAdjustDate(slotnum, chnum, termprint)
            local deltaTable = acalTemperatureDelta(slotnum, chnum, termprint)
            local diffTable = acalDueDateDifference(slotnum, chnum, termprint)
            for k, v in ipairs(validTable) do
                if v == false then
                    print("!!", Procedures[k],"is not valid for", slot[slotnum].model, "Channel ", tostring(chnum), "in Slot ", tostring(slotnum))
                    print("\tDifference between current date and ACAL due date (max -30:00:00:00): ", utcDuration(diffTable[k]))
                    print("\tTemperature delta since last ACAL (max +/-5.00): ", deltaTable[k], "C")
                    local vflag = true
                end
            end
        end
        if not vflag then
            print("All ACAL Calibration Constants are valid for all channels in", slot[slotnum].model, "in slot", tostring(slotnum))
        end
    end
end

-- Main Script
allAcal()