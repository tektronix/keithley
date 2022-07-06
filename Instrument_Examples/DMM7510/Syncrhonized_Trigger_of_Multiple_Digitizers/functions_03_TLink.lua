readings_captured = 0
start_index = 1
end_index = 1

function rst()
	reset()
end

function cnfgTrig(isMaster, tLinkLine)
	tsplink.line[tLinkLine].mode = tsplink.MODE_TRIGGER_OPEN_DRAIN
    if isMaster == 1 then
        trigger.tsplinkout[tLinkLine].stimulus = trigger.EVENT_NOTIFY1
    end
end

function beepIt(dur, freq)
	beeper.beep(dur, freq)
end

function cnfgDigi(doCurrent, sampleRate, myRange)
	if doCurrent == 0 then
        dmm.digitize.func = dmm.FUNC_DIGITIZE_VOLTAGE
    else
        dmm.digitize.func = dmm.FUNC_DIGITIZE_CURRENT
	end
    dmm.digitize.samplerate = sampleRate
    dmm.digitize.range = myRange
end

function cnfgBuff(iCapacity, chunkSize)
	defbuffer2.capacity = 10
    defbuffer1.capacity = iCapacity
    
    start_index = 1
    end_index = chunkSize -- added this here for initialization purposes
end

function cnfgTrigModel(isMaster, iCapacity)
	if (isMaster == 1) then
        trigger.model.setblock(1, trigger.BLOCK_NOTIFY, trigger.EVENT_NOTIFY1)
        trigger.model.setblock(2, trigger.BLOCK_WAIT, trigger.EVENT_TSPLINK1)
        trigger.model.setblock(3, trigger.BLOCK_MEASURE_DIGITIZE, defbuffer1, iCapacity)
    else
        trigger.model.setblock(1, trigger.BLOCK_WAIT, trigger.EVENT_TSPLINK1)
        trigger.model.setblock(2, trigger.BLOCK_MEASURE_DIGITIZE, defbuffer1, iCapacity)
    end
    
    waitcomplete()
end

function setDisplay(myScreen, text1, text2)
	if (myScreen == 0) then	-- HOME 
        display.changescreen(display.SCREEN_HOME)
    elseif (myScreen == 1) then -- PROCESSING
        display.changescreen(display.SCREEN_PROCESSING)
    elseif (myScreen == 2) then	-- USER with text
        display.changescreen(display.SCREEN_USER_SWIPE)
        display.settext(display.TEXT1, text1)
        display.settext(display.TEXT2, text2)
    end
end

function trig()
	readings_captured = 0
	trigger.model.initiate()
end

function setDataFmt()
	format.data = format.SREAL
    format.byteorder = format.LITTLEENDIAN
end

function get_data(chunkSize)
	while (defbuffer1.n - readings_captured) < chunkSize do
		delay(0.001)
	end
	printbuffer(start_index, end_index, defbuffer1.readings, defbuffer1.relativetimestamps)
	start_index = start_index + chunkSize
	end_index = end_index + chunkSize
	readings_captured = readings_captured + chunkSize
end

print("functions loaded")