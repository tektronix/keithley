

--[[

This Example does a scan with external trigger to pace a no function scan
An external trigger signal will also be generated when channel closed

NoFunc_Ext_Trig_Scan will run the program

NoFunc_Ext_Trig_Scan
Using 3706 or 3706-S with switching card with a the STP in Slot 1 

To Run: 

From Test Script Builder

1) Load TSP file to 3706 Memory 
	- Select the .tsp file of interest
	- Press the run arrow in Test Script Builder Main Menu 
	
2) Run Program
	- At the TSP> prompt in the Instrument Control Panel, type NoFunc_Ext_Trig_Scan(1)
		-Pass the number or scans that you want to run.  In the above example 1 is passed
	
	  
Required equipment:	
3706 System Switch and Multimeter
Multiplexer Switch Card with 

Rev: 1-EEB
	 1.1-Update Function Names-EEB
	 
	 
]]



function NoFunc_Ext_Trig_Scan(Scan_count)						--Function Name that is used to pass the number of scans
reset()														--Reset
scan.trigger.channel.stimulus = digio.trigger[2].EVENT_ID	--Configure Scan Channel Stimulus to Digital [2]
digio.trigger[2].mode = digio.TRIG_FALLING					--Configure Digital I/O line for falling edge input
digio.trigger[2].clear()									--Clear Digital line 2
digio.trigger[1].stimulus=scan.trigger.EVENT_CHANNEL_READY	--Configure Digital line[1] to scan channel ready output
digio.trigger[1].mode = digio.TRIG_FALLING					--Configure Digital I/O line for falling edge output
digio.trigger[1].pulsewidth=.001							--Configure output width
scan.create("1001:1010")									--Create Scan
scan.scancount=Scan_count									--Pass scan count from function call
scan.execute()												--Execute Scan
end															--End function

NoFunc_Ext_Trig_Scan(1)