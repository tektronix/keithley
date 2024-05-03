--[[
 
     Purpose:  show how an event on one 2600B can be "echoed" to second 2600B
     
     Setup:  need two 2600B that have TSP-LINK connectors.
             Assign node 1 and 2 and use the cross-over cable to link them.
             On front panel, use the reset under TSPLINK to verify the link.
             
     Method:  Use a timer as stimulus for digital IO active lo pulse.
              Cause 10 pulses from DIO line 1 on rear DB25 connector.
              Echo the timer event_id on tsp-link for digital IO on second node to also pulse.        

    Written By: Keithley Applications Engineering (Andrea Clary)
    From the TekTalk Forum: https://my.tek.com/en/tektalk/source-measure-units/9b622205-b095-ee11-a81c-000d3a37f78a
 
 
]]--
 
function ConfigTSPLinkTriggers(nodenum)
    node[nodenum].tsplink.trigger[1].clear()
    node[nodenum].tsplink.trigger[1].mode        = tsplink.TRIG_FALLING
    node[nodenum].tsplink.trigger[2].clear()
    node[nodenum].tsplink.trigger[2].mode        = tsplink.TRIG_FALLING
    node[nodenum].tsplink.trigger[3].clear()
    node[nodenum].tsplink.trigger[3].mode        = tsplink.TRIG_FALLING
end
 
-- *********************
--
--  Main Program
--
-- *********************

reset()
errorqueue.clear()
 
if tsplink.state == "offline" then
    nodesFound = tsplink.reset()
    if nodesFound ~= 2 then
        print(string.format("Error: Found %d Nodes. Expecting 2.", nodesFound))
        exit()
    end
end
 
-- for each tsplink node    
ConfigTSPLinkTriggers(1)
ConfigTSPLinkTriggers(2)
 
-- configure a timer on node 1 to issue 10 events
-- upon receipt of one tsplink event_id
nodenum = 1
node[nodenum].trigger.timer[1].delay = 1e-3
node[nodenum].trigger.timer[1].stimulus = node[nodenum].tsplink.trigger[1].EVENT_ID
node[nodenum].trigger.timer[1].count = 10
node[nodenum].trigger.timer[1].passthrough = false
node[nodenum].trigger.timer[1].clear()
 
-- echo the timer event on tsplink two
node[nodenum].tsplink.trigger[2].stimulus = node[nodenum].trigger.timer[1].EVENT_ID
 
-- digital IO *could* use timer event directly on this same node
-- but it can also make use of the locally available tsplink two   
node[nodenum].digio.trigger[1].clear()
node[nodenum].digio.trigger[1].mode = digio.TRIG_FALLING
node[nodenum].digio.trigger[1].pulsewidth = 100e-6
--node[nodenum].digio.trigger[1].stimulus = node[nodenum].trigger.timer[1].EVENT_ID
node[nodenum].digio.trigger[1].stimulus = node[nodenum].tsplink.trigger[2].EVENT_ID  
 
-- this remote node cannot "see" the timer events on other node
-- this remote node must use the echoed event on tsplink two    
nodenum = 2
node[nodenum].digio.trigger[1].clear()
node[nodenum].digio.trigger[1].mode = digio.TRIG_FALLING 
node[nodenum].digio.trigger[1].pulsewidth = 100e-6
node[nodenum].digio.trigger[1].stimulus = node[nodenum].tsplink.trigger[2].EVENT_ID    
 
 
-- issue an assert to get the party started
node[1].tsplink.trigger[1].assert()     