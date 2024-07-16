-- Reset the instrument to the default settings
reset()

-- Set up channel settings for Slot 1
channel.setdmm("101:110", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE)
channel.setdmm("101:110", dmm.ATTR_MEAS_TRANSDUCER, dmm.TRANS_THERMOCOUPLE)
channel.setdmm("101:110", dmm.ATTR_MEAS_THERMOCOUPLE, dmm.THERMOCOUPLE_K)
channel.setdmm("101:110", dmm.ATTR_MEAS_REF_JUNCTION, dmm.REFJUNCT_INTERNAL)
channel.setdmm("101:110", dmm.ATTR_MEAS_OPEN_DETECTOR, dmm.ON)

-- set up Scan
scan.create("101:110")

-- Set the scan count to 24hrs * 60min/hr = 1440
scan.scancount = 1440

-- Set the time between scans to 60s
scan.scaninterval = 6.000e+01

-- Ensure data gets written to a connected USB drive after each scan
scan.export("/usb1/scan24hr.csv", scan.WRITE_AFTER_SCAN, buffer.SAVE_RELATIVE_TIME)

-- Enable scan restart after power failure
scan.restart = scan.ON

-- Trigger to start the scan...
trigger.model.initiate()

-- Ensure that the display shows the SCAN swipe and carousel
display.changescreen(display.SCREEN_SCAN_SWIPE)