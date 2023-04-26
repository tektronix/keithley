--[[
	
Script: Synchronized Measurement of Sensors Across TSP Nodes - Setup and Execution
Written by: Keithley Applications Engineering (Josh Brown)
`
***********************************************************
*** Copyright 2023 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************
]]

reset()
waitcomplete()
node_count = node[1].tsplink.initialize()
waitcomplete()

function configure_tsplink(nodenum)
	if nodenum == 1 then
		-- The master node, node 1, will start the sampling via TSP-Link line 1 which is stimulated by the Notification 1 Event
		node[nodenum].tsplink.line[1].mode 				= node[nodenum].tsplink.MODE_SYNCHRONOUS_MASTER		
		node[nodenum].trigger.tsplinkout[1].stimulus 	= node[nodenum].trigger.EVENT_NOTIFY1
		
		-- The master awaits a notification via TSP-Link line 2 that all subordinates are done with measurement
		node[nodenum].tsplink.line[2].mode 				= node[nodenum].tsplink.MODE_SYNCHRONOUS_ACCEPTOR
		node[nodenum].trigger.tsplinkin[2].clear()
		node[nodenum].trigger.tsplinkin[2].edge 		= node[nodenum].trigger.EDGE_FALLING
	elseif nodenum == 2 then
		-- The primary acceptor, node 2, controls the end measurement stimulus to the master.
		node[nodenum].tsplink.line[2].mode 				= node[nodenum].tsplink.MODE_SYNCHRONOUS_MASTER		
		node[nodenum].trigger.tsplinkout[2].stimulus 	= node[nodenum].trigger.EVENT_NOTIFY1 
		
		node[nodenum].tsplink.line[1].mode 				= node[nodenum].tsplink.MODE_SYNCHRONOUS_ACCEPTOR	
		node[nodenum].trigger.tsplinkin[1].clear()
		node[nodenum].trigger.tsplinkin[1].edge 		= node[nodenum].trigger.EDGE_FALLING
		
		-- The primary acceptor plays a secondary role in coordinating the measurement alignment of all accptors
		-- before issuing a trigger event back to the master to indicate all measurements are complete. 
		node[nodenum].tsplink.line[3].mode 				= node[nodenum].tsplink.MODE_SYNCHRONOUS_MASTER		
		node[nodenum].trigger.tsplinkout[3].stimulus 	= node[nodenum].trigger.EVENT_NOTIFY2
	else
		-- All remaining SMUs only act as sychronous acceptors
		node[nodenum].tsplink.line[1].mode 				= node[nodenum].tsplink.MODE_SYNCHRONOUS_ACCEPTOR	
		node[nodenum].trigger.tsplinkin[1].clear()
		node[nodenum].trigger.tsplinkin[1].edge 		= node[nodenum].trigger.EDGE_FALLING
		
		node[nodenum].tsplink.line[3].mode 				= node[nodenum].tsplink.MODE_SYNCHRONOUS_ACCEPTOR	
		node[nodenum].trigger.tsplinkin[3].clear()
		node[nodenum].trigger.tsplinkin[3].edge 		= node[nodenum].trigger.EDGE_FALLING
	end
end

function configure_trigger_model(nodenum)	
	if nodenum == 1 then
		-- Targeting the master node
		node[nodenum].trigger.model.setblock( 1, node[nodenum].trigger.BLOCK_BUFFER_CLEAR, 			node[nodenum].defbuffer1)
		node[nodenum].trigger.model.setblock( 2, node[nodenum].trigger.BLOCK_NOTIFY,				node[nodenum].trigger.EVENT_NOTIFY1)
		node[nodenum].trigger.model.setblock( 3, node[nodenum].trigger.BLOCK_WAIT, 					node[nodenum].trigger.EVENT_TSPLINK1)
		node[nodenum].trigger.model.setblock( 4, node[nodenum].trigger.BLOCK_MEASURE_DIGITIZE, 		node[nodenum].defbuffer1)
		node[nodenum].trigger.model.setblock( 5, node[nodenum].trigger.BLOCK_WAIT, 					node[nodenum].trigger.EVENT_TSPLINK2)
		--node[nodenum].trigger.model.setblock( 6, node[nodenum].trigger.BLOCK_BRANCH_ON_EVENT, 		node[nodenum].trigger.EVENT_DISPLAY, 8)	-- if the trigger key is pressed branch to where the trigger model is stopped
		node[nodenum].trigger.model.setblock( 6, node[nodenum].trigger.BLOCK_BRANCH_ALWAYS, 		2)
		--node[nodenum].trigger.model.setblock( 8, trigger.BLOCK_NOP)
	elseif nodenum == 2 then
		-- Targeting the primary acceptor node
		node[nodenum].trigger.model.setblock( 1, node[nodenum].trigger.BLOCK_BUFFER_CLEAR, 			node[nodenum].defbuffer1)
		node[nodenum].trigger.model.setblock( 2, node[nodenum].trigger.BLOCK_WAIT, 					node[nodenum].trigger.EVENT_TSPLINK1)
		node[nodenum].trigger.model.setblock( 3, node[nodenum].trigger.BLOCK_MEASURE_DIGITIZE, 		node[nodenum].defbuffer1)
		--node[nodenum].trigger.model.setblock( 4, node[nodenum].trigger.BLOCK_DELAY_CONSTANT, 		500e-3)	-- used for test purposes
		node[nodenum].trigger.model.setblock( 4, node[nodenum].trigger.BLOCK_NOTIFY,				node[nodenum].trigger.EVENT_NOTIFY2)
		node[nodenum].trigger.model.setblock( 5, node[nodenum].trigger.BLOCK_WAIT, 					node[nodenum].trigger.EVENT_TSPLINK3)
		node[nodenum].trigger.model.setblock( 6, node[nodenum].trigger.BLOCK_NOTIFY,				node[nodenum].trigger.EVENT_NOTIFY1)
		node[nodenum].trigger.model.setblock( 7, node[nodenum].trigger.BLOCK_WAIT, 					node[nodenum].trigger.EVENT_TSPLINK2)
		node[nodenum].trigger.model.setblock( 8, node[nodenum].trigger.BLOCK_BRANCH_ALWAYS, 		2)
	else
		-- Targeting the remaining acceptors
		node[nodenum].trigger.model.setblock( 1, node[nodenum].trigger.BLOCK_BUFFER_CLEAR, 			node[nodenum].defbuffer1)
		node[nodenum].trigger.model.setblock( 2, node[nodenum].trigger.BLOCK_WAIT, 					node[nodenum].trigger.EVENT_TSPLINK1)
		node[nodenum].trigger.model.setblock( 3, node[nodenum].trigger.BLOCK_MEASURE_DIGITIZE, 		node[nodenum].defbuffer1)
		node[nodenum].trigger.model.setblock( 4, node[nodenum].trigger.BLOCK_WAIT, 					node[nodenum].trigger.EVENT_TSPLINK3)
		node[nodenum].trigger.model.setblock( 5, node[nodenum].trigger.BLOCK_BRANCH_ALWAYS, 		2)
	end
end

function configure_source_measure(nodenum, vlevel, ilimit, use_rear_terminals)
	node[nodenum].smu.measure.unit 				= node[nodenum].smu.UNIT_OHM
	node[nodenum].smu.measure.autorange 		= node[nodenum].smu.ON
	node[nodenum].smu.measure.autozero.enable 	= node[nodenum].smu.OFF

	node[nodenum].smu.source.ilimit.level 	= ilimit
	node[nodenum].smu.source.level 			= vlevel
	node[nodenum].smu.source.readback 		= node[nodenum].smu.OFF
	node[nodenum].smu.source.range 			= vlevel
	node[nodenum].smu.source.autorange 		= node[nodenum].smu.OFF
	node[nodenum].smu.source.autodelay 		= node[nodenum].smu.OFF
	node[nodenum].smu.source.delay 			= 0.0
	
	if use_rear_terminals == true then
		node[nodenum].smu.terminals = node[nodenum].smu.TERMINALS_REAR
	else
		node[nodenum].smu.terminals = node[nodenum].smu.TERMINALS_FRONT
	end
	
	node[nodenum].smu.source.output 		= node[nodenum].smu.ON
	
	-- Perform a measurement to flush the initial settling out of the way...
	local dummmy = node[nodenum].smu.measure.read()
	delay(1.0)
end

function configure_buffers(nodenum, buffersize)
	-- First, downsize the default buffer 2 to the minimum to make room for readings to default buffer 1...
	node[nodenum].defbuffer2.capacity = 10
	
	-- Passing in 0 will adjust the capacity to the maximum available per remaining memory. 
	if buffersize == nil then
		-- Modifying to only account for 1M readings. The line frequency for the target customer
		-- gives 20 ms best case measurement timing. The customer only needs 3 days of sampling
		-- and 1M readings would cover almost 14 days. There is not reason to be excessive. 
		node[nodenum].defbuffer1.capacity = 1000000
	else
		if buffersize > 7000000 then
			node[nodenum].defbuffer1.capacity = 0
		else
			node[nodenum].defbuffer1.capacity = buffersize
		end
	end 
end

function abort_trigger_models()
	-- This function stops all trigger model commands on the instrument.
	node[1].trigger.model.abort()
	
	-- Q: Does this need to be sent for all nodes or just the master? I think the latter.
end

function toggle_output_state(nodenum, state)
	if state == 0 then
		node[nodenum].smu.source.output = node[nodenum].smu.OFF
	else
		node[nodenum].smu.source.output = node[nodenum].smu.ON
	end
end

function restart_testing()
	-- Enable output, take a dummy measurement...
	local dummmy = 0.0
	
	for j = node_count, 1, -1 do				-- address nodes in reverse order to ensure node 1 is intiated last
		toggle_output_state(j, 1)
		dummmy = node[nodenum].smu.measure.read()
		node[i].trigger.model.initiate()
	end 
end

function export_data_to_usb_drive()
	-- Check for presence of USB drive
	if (file.usbdriveexists() == 1) then
		response = display.BUTTON_YES
	else
		response = display.input.prompt(display.BUTTONS_YESNO, "Insert a USB flash drive.\nPress Yes to write data or No to not write data.")
	end
	
	if (response == display.BUTTON_YES) then
		if (file.usbdriveexists() == 1) then
			filename = os.date("/usb/data_%Y-%m-%d_%H-%M-%S.csv") 			-- timestamp the file name
			filenumber = file.open(filename, file.MODE_WRITE)
			
			file.write(filenumber, "Relative Time,Node 1 Readings,Node 2 Readings,Node 3 Readings,Node 4 Readings,Node 5 Readings,Node 6 Readings,Node 7 Readings,Node 8 Readings\n")
			
			-- Print out the measured values in a two-column format.
			print("\nIteration:\tReading:\tNode 1:\tNode 2:\tNode 3:\tNode 4:\Node 5:\tNode 6:\tNode 7:\tNode 8: \n")
			
			for i = 1, table.getn(node[1].defbuffer1) do
				print(node[1].defbuffer1.relativetimestamps[i], node[1].defbuffer1.readings[i], 
				                                                   node[2].defbuffer1.readings[i],
				                                                   node[3].defbuffer1.readings[i],
				                                                   node[4].defbuffer1.readings[i],
				                                                   node[5].defbuffer1.readings[i],
				                                                   node[6].defbuffer1.readings[i],
				                                                   node[7].defbuffer1.readings[i],
				                                                   node[8].defbuffer1.readings[i])
				file.write(filenumber, string.format("%g,%g,%g,%g,%g,%g,%g,%g,%g\n", node[1].defbuffer1.relativetimestamps[i], node[1].defbuffer1.readings[i],
																															   node[2].defbuffer1.readings[i],
																															   node[3].defbuffer1.readings[i],
																															   node[4].defbuffer1.readings[i],
																															   node[5].defbuffer1.readings[i],
																															   node[6].defbuffer1.readings[i],
																															   node[7].defbuffer1.readings[i],
																															   node[8].defbuffer1.readings[i]
																															   ))
			end
			file.close(filenumber)
		else
			response = display.input.prompt(display.BUTTONS_OK,
			"No drive detected. Allow more time after inserting a drive.")
		end
	end
end

function halt_tests_export_data()
	abort_trigger_models()
	for j = 1, node_count do
		toggle_output_state(j, 0)
	end
	export_data_to_usb_drive()
end

-- MAIN SCRIPT STARTS HERE --
for i=1, node_count do
	configure_tsplink(i)
	configure_trigger_model(i)
	configure_buffers(i, 10000000)
	configure_source_measure(i, 5.0, 1.0e-3)
	waitcomplete()
end


for j = 2, node_count do
	-- Start trigger models on all subordinates first...
	node[j].trigger.model.initiate()
	delay(0.5)
end

response = display.input.prompt(display.BUTTONS_YESNO, "Press Yes to start the test.")
if (response == display.BUTTON_YES) then
	node[1].trigger.model.initiate()
end
waitcomplete()
