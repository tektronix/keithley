
--[[

This is an example to do a single DMM Measurement
This Example does same DMM Readings with no switching
DMM needs to be configured once then a specified number of 
readings are taken after being triggered


This will have two setups

Each setup will be doing DCV, 1 NPLC and 10 V range

Single_Measure_1()
Single 3706, no switch cards, reading VIA Analog Backplane, Single reading

Single_Measure_2()
Single 3706, no switch cards, reading VIA Analog Backplane, 5 readings


To Run:
1) Load TSP file to 3706 Memory 
	- Select the .tsp file of interest
	- Press the run arrow in Test Script Builder Main Menu 
	
2) Run Program
	- At the TSP> prompt in the Instrument Control Panel, type Single_Measure_1() or Single_Measure_2()
	
	  
Required equipment:	
3706 System Switch and Multimeter

Rev: 1-EEB
	 1.1-Update Function Names-EEB
	 


]]--


function Single_Measure_1()
reset()									-- reset
dmm.func = dmm.DC_VOLTS					-- Set dmm function
dmm.nplc=1								-- Set NPLC
dmm.range=100							-- Set Range
print(dmm.measure())					-- Take dmm measure and print reading
end

function Single_Measure_2()

reset()									-- reset
reading_buffer=dmm.makebuffer(10)		-- configure reading buffer
dmm.func = dmm.DC_VOLTS					-- set dmm function
dmm.nplc=1								-- set nplc
dmm.range=10							-- set range
dmm.measurecount=5						-- set measure count
dmm.measure(reading_buffer)				-- trigger measure and store reading in buffer
print(printbuffer(1,5, reading_buffer))	-- print buffer

end

--Function Copy and Paste
Single_Measure_1()
--Single_Measure_2()



