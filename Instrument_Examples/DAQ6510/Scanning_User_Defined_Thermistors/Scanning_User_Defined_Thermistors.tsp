---@diagnostic disable: undefined-global, lowercase-global
--[[
    
    Description:
    
    A thermistor is a resistor whose value varies with temperature. The relationship is non-linear but well defined. 
	These two-terminal devices are one of the most common and readily available temperature measurement devices. 
	The semiconductor metal oxide makes them sensitive to small temperature changes. Thermistors work best in various 
	temperatures and applications because they are durable and reliable. There are two types of thermistors, negative temperature 
	coefficient (NTC) and positive temperature coefficient(PTC) thermistors. NTCs display a negative resistance to 
	temperature relationship. This means that the resistance of an NTC thermistor will decrease as temperature increases. 
	Conversely, PTC thermistors have a positive resistance to temperature relationship, where resistance increases 
	as temperature increases. This makes them useful for applications such as fuses.
	
	This script is built for doing thermistors measurements based to the Steinhart-Hart equation.
    The Steinhart�Hart equation is a model relating the varying electrical resistance of a semiconductor to its varying temperatures. The equation is :

	1/T = A + B*ln(R)+ C(ln(R))^3
where

	T is the temperature (in kelvins),
	R is the resistance at T (in ohms)
	A, B and C are the Steinhart�Hart coefficients, which are characteristics specific to the bulk semiconductor material over a given temperature range of interest.
 
        
    To set up for the Steinhart-Hart model, we must find three reference temperatures. First, find the temperature range 
	of the desired thermistor and take note of it. Our first reference temperature will be the lowest temperature in the 
	range. The second reference temperature is somewhere close to the middle of the range and is usually the standard 
	temperature 25�C. The third reference temperature is the highest temperature in the thermistor�s range. After noting 
	these temperatures, we find their corresponding resistance values. These are either listed in the thermistor�s datasheet, 
	or we source a temperature and measure the thermistor�s resistance at each of these points. 
	
	With this script you are limited to one model of thermistor (TDK B57164K, R25 = 2.2K) but you can start from this script and define as much variables 
	as you want to define dedicated thermistor's curve. 
	
	This script measure two thermistors 2.2K TDK B57164K on channels 111 and 116 from a DAQ6510's 7700 card. 
	One Type K thermocouple is used on channel 112 to check the good results from channels 111 and 116.
	  
--]]

-- This function resets commands to their default settings and clears the buffers.
reset()

-- Set up temperature values (choose value a, b and c)
	t1Val = -55		-- For example, extracted from the thermistors 2.2K TDK B57164K's datasheet, it was choosed -20�C for t1Val, t1Val = -20. 
	t2Val = 25		-- For example, extracted from the thermistors 2.2K TDK B57164K's datasheet, it was choosed -20�C for t1Val, t1Val = 25.
	t3Val = 125 		-- For example, extracted from the thermistors 2.2K TDK B57164K's datasheet, it was choosed 100�C for t1Val, t1Val = 100.

-- Convert t1Val, t2Val and t3Val values from �C into Kelvin.
t1Val = t1Val + 273.15	
t2Val = t2Val + 273.15
t3Val = t3Val + 273.15

-- Set up resistance values	(choose value x, y and z).
-- x, y and z value are resistance values measured respectively at a, b and c temperatures
r1Val = 963000		-- For example, extracted from the thermistors 2.2K TDK B57164K's datasheet, it was calculated at -20�C for t1Val, r1Val = 19479.02 Ohms
r2Val = 10000		-- For thermistors commonly used in industry, the typical reference temperature is 25�C, and for this temperature the thermistor's R25 resistance is determined. Here R25 = 2.2KOhms.
r3Val = 165.3		-- For example, extracted from the thermistors 2.2K TDK B57164K's datasheet, it was calculated at 100�C for t1Val, r1Val = 135.55 Ohms

-- Deriving Steinhart-Hart Coefficients	
x1 = 1/t1Val
x2 = 1/t2Val
x3 = 1/t3Val

y1 = math.log(r1Val)
y2 = math.log(r2Val)
y3 = math.log(r3Val)

C = ((x3*(y1-y2)) - (x1*(y1-y2)) + (y1*x1) - (y1*x2) - (y3*x1) + (y3*x2)) / ( ((y3^3)*(y1-y2)) - (y1*(y2^3)) + (y1^4) - ((y1^3)*(y1-y2)) + (y3*(y2^3)) - (y3*(y1^3)) )
B = (x1 - x2 + (C*(y2^3)) - (C*(y1^3))) / (y1-y2)
A = x2 - (B*y2) - (C*(y2^3))

-- Configure the DAQ6510 for channels 111, 112 and 116. 
-- Set up 2W Resistance measurement on channels 111 and 116 where thermistors is connected.
-- Set up Temperature measurement on channel 112 (TCK, internal reference junction).

channel.setdmm("111", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_RESISTANCE)

channel.setdmm("112", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE,
dmm.ATTR_MEAS_THERMOCOUPLE, dmm.THERMOCOUPLE_K,
dmm.ATTR_MEAS_REF_JUNCTION, dmm.REFJUNCT_INTERNAL)

channel.setdmm("116", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_RESISTANCE)

-- This attribute determines which channels are set to be watch channels on the front panel.
display.watchchannels = '111:116'

-- This function creates a user-defined reading buffer names buffer, create custom unit of measure for use in buffer1
buffer1 = buffer.make(1000, buffer.STYLE_WRITABLE)
buffer.unit(buffer.UNIT_CUSTOM1, "dC")

-- This attribute sets the number of times the scan is repeated.
scanCount = 10

-- This function delays the execution of the commands that follow it.
channelDelay = 1

-- This command opens the specified channels and channel pairs.
channel.open("allslots")

-- Do the scan thanks to a 'for' loop. Measure channels 111, 112 and 116 and save data into buffer1 

for i = 1,scanCount do
	-- Take one measurement per channel closure
	dmm.measure.count = 1
	channel.close("111")
	-- Read measurment from default buffer
	reading, seconds, fractional = dmm.measure.readwithtime(defbuffer1)
	-- Use Steinhart-Hart equation to convert reading in ohms value into temp
	reading = 1 / ( A + (B*math.log(reading)) + (C*((math.log(reading))^3)) )  -- temp in kelvin
	-- Convert Kelvin into �C
	reading = reading - 273.15
	-- Establishes settings for custom buffer
	buffer.write.format(buffer1, buffer.UNIT_CUSTOM1, buffer.DIGITS_3_5)
 	-- Writes reading to custom buffer
	buffer.write.reading(buffer1, reading, seconds, fractional, 0, "111")
	channel.open("111")
	--This function delays the execution of the commands that follow it
	delay(channelDelay)
	
	-- Take one measurement per channel closure
	dmm.measure.count = 1
	channel.close("112")
	-- Read measurment from defualt buffer
	reading, seconds, fractional = dmm.measure.readwithtime(defbuffer1)
	-- Establishes settings for custom buffer
	buffer.write.format(buffer1, buffer.UNIT_CUSTOM1, buffer.DIGITS_3_5)
 	-- Writes reading to custom buffer
	buffer.write.reading(buffer1, reading, seconds, fractional, 0, "112")
	channel.open("112")
	--This function delays the execution of the commands that follow it
	delay(channelDelay)

	-- Take one measurement per channel closure
	dmm.measure.count = 1
	channel.close("116")
	-- Read measurment from default buffer
	reading, seconds, fractional = dmm.measure.readwithtime(defbuffer1)
	-- Use Steinhart-Hart equation to convert reading in ohms value into temp
	reading = 1 / ( A + (B*math.log(reading)) + (C*((math.log(reading))^3)) )  -- temp in kelvin
	-- Convert Kelvin into �C
	reading = reading - 273.15
	-- Establishes settings for custom buffer
	buffer.write.format(buffer1, buffer.UNIT_CUSTOM1, buffer.DIGITS_3_5)
 	-- Writes reading to custom buffer
	buffer.write.reading(buffer1, reading, seconds, fractional, 0, "116")
	channel.open("116")
	--This function delays the execution of the commands that follow it
	delay(channelDelay)
end