-- Reset the instrument to the default settings
reset()

-- Establish channel settings for the scan card configuration...
channel.setdmm("101", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_AC_VOLTAGE)
channel.setdmm("101", dmm.ATTR_MEAS_DETECTBW, dmm.DETECTBW_30HZ)
channel.setdmm("102:110", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_VOLTAGE)
channel.setdmm("111:114", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE)
channel.setdmm("111:114", dmm.ATTR_MEAS_TRANSDUCER, dmm.TRANS_THERMOCOUPLE)
channel.setdmm("111:114", dmm.ATTR_MEAS_THERMOCOUPLE, dmm.THERMOCOUPLE_K)
channel.setdmm("111:114", dmm.ATTR_MEAS_REF_JUNCTION, dmm.REFJUNCT_SIMULATED)
channel.setdmm("111:114", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE, dmm.ATTR_MEAS_SIM_REF_TEMP, 23)
channel.setlabel("101", "ACSource")
channel.setlabel("111", "Reg12VTemp")
channel.setlabel("112", "Reg5VTemp")
channel.setlabel("113", "LoadTemp1")
channel.setlabel("114", "LoadTemp2")
channel.setdmm("121", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_AC_CURRENT)
channel.setdmm("122", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_CURRENT)

-- Generate the scan...
scan.create("101:114,121,122")
scan.scancount = 10

-- Clear and size the buffer...
defbuffer1.clear()
defbuffer1.capacity = 10 * 16

-- Start the scan and wait...
trigger.model.initiate()
waitcomplete()

-- Extract the data...
printbuffer(1, defbuffer1.n, defbuffer1, defbuffer1.readings, defbuffer1.channels)