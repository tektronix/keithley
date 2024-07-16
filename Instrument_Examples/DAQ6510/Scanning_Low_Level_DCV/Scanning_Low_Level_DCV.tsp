-- Reset the instrument to the default settings
reset()
channelCount = 6
scanCount = 10
bufferSize = channelCount * scanCount
defbuffer1.capacity = bufferSize

scan.buffer = defbuffer1 -- not necessary when using the default buffer, but added to show command use case

-- set up channels
channel.setdmm("101:106", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_VOLTAGE, dmm.ATTR_MEAS_RANGE_AUTO, dmm.ON, dmm.ATTR_MEAS_AUTO_ZERO, dmm.ON, dmm.ATTR_MEAS_NPLC, 5)

-- set up Scan
scan.add("101:106")
scan.scancount = scanCount

-- set up trigger model
trigger.model.initiate()

-- print measurement data to console
i = 1
while i <= bufferSize do
	delay(2)
	lastIndex = defbuffer1.n
	printbuffer(i, lastIndex, defbuffer1.readings)
	i = lastIndex + 1
end

-- save buffer data from defbuffer1 to USB
buffer.save(defbuffer1, "/usb1/MyData.csv")