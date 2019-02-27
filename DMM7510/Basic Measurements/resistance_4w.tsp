--[[

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This sequence of TSP commands makes a single high accuracy resistance measurement when a
    device under test is connected to the Model DMM7510. Kelvin connections and offset
    compensation are used.

After the code executes, the reading is displayed in the Instrument Console of Test Script Builder.

]]

--Reset the Model DMM7510 to the default settings
reset()
--Set the measure function to 4-wire resistance
dmm.measure.func = dmm.FUNC_4W_RESISTANCE
--Enable autozero (set to dmm.OFF to disable)
dmm.measure.autozero.enable = dmm.ON
--Enable offset compensation (set to dmm.OFF to disable)
dmm.measure.offsetcompensation.enable = dmm.ON
--Set the number of power line cycles to 1
dmm.measure.nplc = 1
--Read the resistance value
print(dmm.measure.read())