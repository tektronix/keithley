-- monitor temperature on channel 101
reset()
channel.setdmm("101", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE, dmm.ATTR_MEAS_TRANSDUCER, dmm.TRANS_THERMOCOUPLE, dmm.ATTR_MEAS_THERMOCOUPLE, dmm.THERMOCOUPLE_K, dmm.ATTR_MEAS_REF_JUNCTION, dmm.REFJUNCT_INTERNAL) channel.setdmm("101", dmm.ATTR_MEAS_UNIT, dmm.UNIT_CELSIUS)

-- set limit high on monitor and trigger scan when high limit exceeds
scan.monitor.channel = "101"
scan.monitor.limit.high.value = 30
scan.monitor.mode = scan.MODE_HIGH

-- scan 2-wire resistance on channel 102:105
channel.setdmm("102:105", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_RESISTANCE, dmm.ATTR_MEAS_RANGE_AUTO, dmm.ON)

-- create scan
scan.create("101:105")
scan.scancount = 10

-- initiates the monitoring of channel 101 conditions, which will enable the scan when it crosses the temperature threshold.
trigger.model.initiate()