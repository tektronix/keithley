--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

setup_poweron.tsp

This tutorial example will use the setup.poweron() function to set the 260x such that every time the 
instrument is powered up, it will use one of the saved setups. One of the setups can be the factory
defaults.

Commands Used:
setup.powereon = <n>
	Where:
	<n>			For an n setting of 0, the unit powers up to the factory default (reset) setup. 
				For an n setting of 1 to 5, the unit powers up to a user saved setup. 

			


Rev1: JLT 9.20.2005
Rev2: BCO 5.2.2019
]]--

print("Current Setup at Power on: "..setup.poweron)

setup.poweron = 0					--Power on to factory defaults

