

--[[

This Example does different DMM Readings with scanning


Advance_Scan will be doing DCV, 1 NPLC and 10 V range

Advance_Scan
Using 3706 with switching card in slot 1

To Run:
There are three options to run this demonstration script. 

From Test Script Builder

1) Load TSP file to 3706 Memory 
	- Select the .tsp file of interest
	- Press the run arrow in Test Script Builder Main Menu 
	
2) Run Program
	- At the TSP> prompt in the Instrument Control Panel, type Advance_Scan()
	  
Required equipment:	
3706 System Switch and Multimeter
Multiplexer Switch Card


Rev: 1-EEB
	 1.1-Update Function names-EEB
]]

function Advance_Scan()
								
reset()										--Reset
-- Setup DC Volts
dmm.func = dmm.DC_VOLTS						--Set dmm function to DC volts
dmm.nplc=1									--Set NPLC
dmm.range=100								--Set Range
dmm.configure.set("mydcvolts")				--Save setup to mydcvolts
dmm.setconfig("1001:1005","mydcvolts")		--Assign configuration to channels
-- Setup Temperature
dmm.func = dmm.TEMPERATURE					--Set dmm funciton to Temperature
dmm.nplc=1									--Set NPLC
dmm.transducer=dmm.TEMP_THERMOCOUPLE		--Set Temperature sensor to Thermocouple
dmm.refjunction=dmm.REF_JUNCTION_INTERNAL	--Set CJC junction to internal
dmm.thermocouple=dmm.THERMOCOUPLE_J			--Set to J Thermocouple
dmm.units=dmm.UNITS_FAHRENHEIT				--Set units to Fahrenheit
dmm.configure.set("mytemp")					--save setup to mytemp
dmm.setconfig("1006:1010","mytemp")			--Assign configuration to channels
-- Setup 2 Wire ohms
dmm.func=dmm.TWO_WIRE_OHMS					--Set dmm function to 2 wire ohms
dmm.nplc=1									--Set NPLC
dmm.range=100								--Set range
dmm.configure.set("my2wire")				--save setup to my2wire
dmm.setconfig("1011:1015","my2wire")		--Assign configuration to channels
-- Setup Scan
reading_buffer=dmm.makebuffer(10000)		--Create buffer
scan.create("1001:1015")					--create scan list
scan.scancount=1							--Set scan count
scan.execute(reading_buffer)				--perform scan and save reading to buffer
printbuffer(1,15,reading_buffer)			--Print buffer


end

Advance_Scan()


