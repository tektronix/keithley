--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Beeper.tsp

This example illustrates the use of the Beeper.Enable command.
The 2600 will alternate between enabled and disabled and will query
the state. The results will be returned in the Instrument Console



Rev1: JLT 5.23.2005
]]--

reset()

-- Enable Beeper
beeper.enable = 1
beeper.beep(0.1, 621)
isBeeperEnabled = beeper.enable
print("Beeper Enabled State = ", isBeeperEnabled)

-- Disable Beeper
beeper.enable = 1
beeper.beep(0.1, 2400)
isBeeperEnabled = beeper.enable
print("Beeper Enabled State = ", isBeeperEnabled)

-- Enable Beeper
beeper.enable = 0
beeper.beep(0.1, 2400)
isBeeperEnabled = beeper.enable
print("Beeper Enabled State = ", isBeeperEnabled)