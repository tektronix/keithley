-- Reset the instrument to the default settings
reset()
scanCount = 100

-- set up each channels function, range and offset compensation
channel.setdmm("101, 102", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_4W_RESISTANCE, dmm.ATTR_MEAS_RANGE, 100, dmm.ATTR_MEAS_OFFCOMP_ENABLE, dmm.OCOMP_ON)
channel.setdmm("103, 104", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_4W_RESISTANCE, dmm.ATTR_MEAS_RANGE, 10, dmm.ATTR_MEAS_OFFCOMP_ENABLE, dmm.OCOMP_ON)
channel.setdmm("105, 106", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_4W_RESISTANCE, dmm.ATTR_MEAS_RANGE, 1, dmm.ATTR_MEAS_OFFCOMP_ENABLE, dmm.OCOMP_ON)

-- set up Scan
scan.add("101,102,103,104,105,106")
scan.scancount = 100

-- set up trigger model
trigger.model.initiate()

-- wait till scan completes
waitcomplete()
