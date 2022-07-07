--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

setup_save.tsp

This tutorial example will use the setup.save() function to store the present setup into one of five
locations in the 260x. If you save a setup into the same location, you will overwrite the setup
previously stored in that location

Commands Used:
setup.save(n)
	Where:
	<n>			Numbers 1 through 5 are used to designate user-setup locations. When you save at 
				one of these locations, the previous setup at that location is overwritten. 
 

			


Rev1: JLT 9.20.2005
]]--

-- This example will store a set of settings for the 260x. To test the different settings you may wish
-- to store, run the setup_recall.tsp script in this project so you can see the differences.

display.smua.digits = display.DIGITS_4_5				-- Set to 4.5 digit resolution
display.screen = 0

smua.measure.count = 1									-- Set reading count to 1.

smua.measure.filter.count = 10							-- Set filter count to 10
smua.measure.filter.enable = smua.FILTER_ON				-- Set filter on
smua.measure.filter.type = smua.FILTER_REPEAT_AVG		-- Set filter to repeat average type

smua.measure.nplc = 0.01								-- Set to 0.01 PLCs

smua.measure.rangei = 0.001								-- Set to 1mA range

setup.save(2)											-- Save in setup 2

-- Check if USB drive is inserted, then save setup to USB drive
if fs.is_dir("/usb1/") then
	setup.save("/usb1/KI_setup.set") -- The filename doesn't really matter, until you try to recall it!
end

-- You cannot "delete" a setup, but everytime you save a setup, the previous one is overwritten