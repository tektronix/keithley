
--[[

This Example does a Thermocouple Scan


Temp_Scan will be doing K T/C Scan

Temp_Scan
Using 3706 with switching card with a CJC on the STP in Slot 1 (3720,3721)

To Run:

From Test Script Builder

1) Load TSP file to 3706 Memory 
	- Select the .tsp file of interest
	- Press the run arrow in Test Script Builder Main Menu 
	
2) Run Program
	- At the TSP> prompt in the Instrument Control Panel, type Temp_Scan()
	  
Required equipment:	
3706 System Switch and Multimeter
Multiplexer Switch Card with CJC on STP.


Rev: 1-EEB
	 1.1-Update Function Names-EEB
	 

]]



function Temp_Scan()								--create function called Setup_1()
reset()												--reset instrument
reading_buffer=dmm.makebuffer(1000)					--create buffer
dmm.func = dmm.TEMPERATURE							--set function to Temperature
dmm.nplc=1											--set NPLC
dmm.transducer=dmm.TEMP_THERMOCOUPLE				-- set sensor to T/C
dmm.refjunction=dmm.REF_JUNCTION_INTERNAL			--set Reference Junction to internal
dmm.thermocouple=dmm.THERMOCOUPLE_K					--set T/C to K
dmm.units=dmm.UNITS_FAHRENHEIT						--set units to F
dmm.configure.set("mytemp")							--save DMM setting to mytemp
dmm.setconfig("1001:1005,1017:1021","mytemp")		--assign mytemp setting to channels
scan.create("1001:1005,1017:1021")					--create scan list
scan.execute(reading_buffer)						--execute scan and save readings to buffer
printbuffer(1,10,reading_buffer)					--print readings from buffer

end													--end function

Temp_Scan()
