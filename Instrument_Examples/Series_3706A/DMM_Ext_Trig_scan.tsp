

--[[

This Example does a scan with external trigger to pace an internal measure scan
An external trigger signal will also be generated when channel closed

DMM_Ext_Trigger will run the program

DMM_Ext_Trigger
Using 3706 with switching card with a the STP in Slot 1 

To Run:

From Test Script Builder

1) Load TSP file to 3706 Memory 
	- Select the .tsp file of interest
	- Press the run arrow in Test Script Builder Main Menu 
	
2) Run Program
	- At the TSP> prompt in the Instrument Control Panel, type DMM_Ext_Trigger(1)
		-Pass the number or scans that you want to run.  In the above example 1 is passed
	
	  
Required equipment:	
3706 System Switch and Multimeter
Multiplexer Switch Card with 

Rev: 1-EEB
	 1.1-Update Function Names-EEB
	 
]]



function DMM_Ext_Trigger(Scan_count)						--Function Name that is used to pass the number of scans
reset()														--Reset
reading_buffer=dmm.makebuffer(1000)							--Configure Buffer
dmm.func = dmm.DC_VOLTS										--Set measurement function
dmm.nplc=1													--Set NPLC
dmm.range=10												--Set Range
dmm.configure.set("mydcvolts")								--Save Configuration
dmm.setconfig("1001:1010","mydcvolts")						--Assign configuration to channels
-- scan.bypass allows unit to fall through the channel stimulus the first time
--through the trigger model.  This is useful if you have two unit in external trigger
--mode, one needs to go first to "prime the pump".  
--by turning bypass off, 3706 will wait for a trigger BEFORE taking the first measurement
scan.bypass=scan.OFF										--Turns scan bypass off, it is on by default
scan.trigger.channel.stimulus = digio.trigger[2].EVENT_ID	--Configure Scan Channel Stimulus to Digital [2]
digio.trigger[2].mode = digio.TRIG_FALLING					--Configure Digital I/O line for falling edge input
digio.trigger[2].clear()									--Clear Digital line 2
digio.trigger[1].stimulus=scan.trigger.EVENT_MEASURE_COMP	--Configure Digital line[1] to scan channel ready output
digio.trigger[1].mode = digio.TRIG_FALLING					--Configure Digital I/O line for falling edge output
digio.trigger[1].pulsewidth=.001							--Configure output width
scan.create("1001:1010")									--Create Scan
scan.scancount=Scan_count									--Pass scan count from function call
scan.execute(reading_buffer)								--Execute Scan
printbuffer(1,10,reading_buffer)							--Print reading in buffer
end															--End function

DMM_Ext_Trigger(1)

