--Reset the instrument to the default settings.
reset()

--Establish variables to make a measurement every 60 seconds 1440 times (24 hours).
local scanCnt = 24 * 60 --1440 minutes = 24 hours
local chanCnt = 9
local totalRdgs = scanCnt * chanCnt

--Empty the buffer and set it to the capacity calculated by totalRdgs.
defbuffer1.clear()
defbuffer1.capacity = totalRdgs

-- Set up the channels to measure temperature using type K thermocouples using internal reference junction.
channel.setdmm("2:10", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE)
channel.setdmm("2:10", dmm.ATTR_MEAS_UNIT, dmm.UNIT_CELSIUS)
channel.setdmm("2:10", dmm.ATTR_MEAS_NPLC, 1)
channel.setdmm("2:10", dmm.ATTR_MEAS_DIGITS, dmm.DIGITS_5_5)
channel.setdmm("2:10", dmm.ATTR_MEAS_TRANSDUCER, dmm.TRANS_THERMOCOUPLE)
channel.setdmm("2:10", dmm.ATTR_MEAS_THERMOCOUPLE, dmm.THERMOCOUPLE_K)
channel.setdmm("2:10", dmm.ATTR_MEAS_REF_JUNCTION, dmm.REFJUNCT_INTERNAL)

-- Set up the scan; channel 2 is first available channel on a 2001-TCSCAN card.
scan.create("2:10")
scan.scancount = scanCnt

-- Set the amount of time for each scan.
scan.scaninterval = 60.0

-- Write the data to a USB flash drive at the end of the scan.
scan.export("/usb1/TempData", scan.WRITE_AFTER_SCAN, buffer.COL_ALL)

-- Start the scan.
trigger.model.initiate()
waitcomplete()

-- Get the data.
printbuffer(1, defbuffer1.n, defbuffer1)