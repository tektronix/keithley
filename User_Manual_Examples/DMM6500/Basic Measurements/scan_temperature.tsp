--[[

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This sequence of TSP commands scans a set of channels from the optional 2001-SCAN card to 
    make temperature measurements.

After the code executes, the reading is displayed in the Instrument Console of Test Script Builder.

Make sure the TERMINALS switch is set to REAR for these commands.

]]

-- Reset the instrument to the default settings.
reset()
-- Establish variables to make a measurement every 60 seconds 1440 times (24 hours).
local scanCnt = 24 * 60 -- 1440 minutes = 24 hours
local chanCnt = 10		-- we will account for channel 1 as the CJC measurement as well 
local totalRdgs = scanCnt * chanCnt
-- Empty the buffer and set it to the capacity calculated by totalRdgs.
defbuffer1.clear()
defbuffer1.capacity = totalRdgs
-- Set up the channels to measure temperature using type K thermocouples using internal reference junction.
channel.setdmm("1:10", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE)
channel.setdmm("1:10", dmm.ATTR_MEAS_UNIT, dmm.UNIT_CELSIUS)
channel.setdmm("1:10", dmm.ATTR_MEAS_NPLC, 1)
channel.setdmm("1:10", dmm.ATTR_MEAS_DIGITS, dmm.DIGITS_5_5)
channel.setdmm("1", dmm.ATTR_MEAS_TRANSDUCER, dmm.TRANS_CJC2001)
channel.setdmm("2:10", dmm.ATTR_MEAS_TRANSDUCER, dmm.TRANS_THERMOCOUPLE)
channel.setdmm("2:10", dmm.ATTR_MEAS_THERMOCOUPLE, dmm.THERMOCOUPLE_K)
channel.setdmm("2:10", dmm.ATTR_MEAS_REF_JUNCTION, dmm.REFJUNCT_EXTERNAL)
-- Set up the scan; channel 2 is first available channel on a 2001-TCSCAN card, 
-- however, we include channel 1 as part of the scan because it is measuring
-- our CJC temperature and we want to refresh its measurement with each
-- scan as well.
scan.create("1:10")
scan.scancount = scanCnt
-- Set the amount of time for each scan.
scan.scaninterval = 60.0
-- Write the data to a USB flash drive at the end of the scan.
scan.export("/usb1/scan24hr", scan.WRITE_AFTER_SCAN, buffer.COL_ALL)
-- Enable scan restart on power loss.
scan.restart = scan.ON
-- Start the scan.
trigger.model.initiate()
waitcomplete()
-- Get the data.
printbuffer(1, defbuffer1.n, defbuffer1)