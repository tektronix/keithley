--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

DisplayScreen.tsp

Sets and displays to the Instrument Console of TSB what the current function is of the SMU and the 
resolution.

Commands used in this example:

display.screen = <val>
Where:
		val				0 or 'display.SMUA'; 	Displays source-measure and compliance for SMU A. 
			    		1 or 'display.SMUB'; 	Displays source-measure and compliance for SMU B.
			    		2 or display.SMUA_SMUB;	Displays source-measure for SMU A and SMU B.
						3 or display.USER; 		Displays the user screen.
				
Rev1: JLT 7.16.2005
]]--

-- Let's reset the 260x to a known default condition first
reset()

-- Set the screen to SMUA
display.screen = 0
delay(2)							-- Set a short delay to see the screen.

-- Set the screen to SMUB
display.screen = display.SMUB
delay(2)							-- Set a short delay to see the screen.

-- Set the screen to SMUA & SMUB
display.screen = display.SMUA_SMUB
delay(2)							-- Set a short delay to see the screen.

-- Set the screen to USER
display.screen = 3
display.setcursor(1,1)
display.settext("User Screen")