--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

DisplayTrigger.tsp

This program places text on row 1 of the front panel display. The display will then wait 1 minute for a 
trigger. If TRIG key on the front panel is not pressed, the remainder of the code will execute and a second
text message will appear on row 2 of the front panel display


Commands used in this example:

display.trigger.clear()

display.trigger.wait(timeout)
Where:
		timeout			Set timeout in seconds

Rev1: JLT 7.16.2005
Rev2: BCO 5.2.2019
]]--

-- Let's put the text on the front panel on row 1
display.clear()
display.setcursor(1, 1, 0)
display.settext(localnode.model.." SourceMeter")
display.setcursor(2, 1, 0)
display.settext("Press TRIG to continue")
display.trigger.wait(60)
display.trigger.clear()
display.clear()
display.settext("Keithley Instruments")
