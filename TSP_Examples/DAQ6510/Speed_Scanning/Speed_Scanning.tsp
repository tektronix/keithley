-- Set up variables to be referenced during the scan
local scanCnt = 1000
local sampleCnt = 0
local chanCnt = 0
local actualRdgs = 0
local rcvBuffer = ""

-- Get the initial timestamp for end-of-run comparison
local x = os.clock()

-- Reset the instrument and clear the buffer
reset()
defbuffer1.clear()

-- Set up reading buffer format and establish scan count
format.data = format.ASCII
scan.scancount = scanCnt
-- Configure the scan channels for the Slot 1 card
channel.setdmm("101:120", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_VOLTAGE)
channel.setdmm("101:120", dmm.ATTR_MEAS_RANGE, 1)
channel.setdmm("101:120", dmm.ATTR_MEAS_RANGE_AUTO, dmm.OFF)
channel.setdmm("101:120", dmm.ATTR_MEAS_AUTO_ZERO, dmm.OFF)
channel.setdmm("101:120", dmm.ATTR_MEAS_DIGITS, dmm.DIGITS_4_5)
channel.setdmm("101:120", dmm.ATTR_MEAS_NPLC, 0.0005)
channel.setdmm("101:120", dmm.ATTR_MEAS_APERTURE, 8.33333e-06)
channel.setdmm("101:120", dmm.ATTR_MEAS_LINE_SYNC, dmm.OFF)
channel.setdmm("101:120", dmm.ATTR_MEAS_LIMIT_ENABLE_1, dmm.OFF)
channel.setdmm("101:120", dmm.ATTR_MEAS_LIMIT_ENABLE_2, dmm.OFF)

-- Dim the display...
display.lightstate = display.STATE_LCD_OFF

-- Generate the scan...
scan.create("101:120")
scan.scaninterval = 0.0
chanCnt = scan.stepcount

-- Calculate the overall sample count and use it to size the buffer
sampleCnt = scanCnt * chanCnt
defbuffer1.capacity = sampleCnt

-- Start the scan...
trigger.model.initiate()

-- Loop to capture and print readings
i = 1
while i <= sampleCnt do
	delay(0.5)
	myCnt = defbuffer1.n
	-- NOTE: Can be supplemented or replaced by writing to USB
	printbuffer(i, myCnt, defbuffer1.readings)
	i = myCnt + 1
end

-- Turn the display back on...
display.lightstate = display.STATE_LCD_50

-- Output the elapsed time to the user
print(string.format("Elapsed Time: %2f\n", os.clock() - x))