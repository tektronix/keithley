--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

localnode.tsp

Programs the 260x to set various local node parameters such as the line frequency, prompts, and
showerror control.


Commands used in this example:
localnode.linefreq = <50/60>
Where:
		<50/60>		Represents the local country line frequency in Hz.
		
					To achieve optimum noise rejection when performing measurements at integer 
					NPLC apertures, the line frequency setting must match the frequency (50Hz or 60Hz) 
					of the AC power line. 

    				When used in an expanded system (TSP-Link), localnode.linefreq is sent to the 
    				Remote Master node only. Use node[N].linefreq (where N is the node number) to 
    				send the command to any node in the system.
						
localnode.prompts = <0/1>
Where:
		<0/1> 	 	Set to 0 to disable or 1 to enable.

					This attribute controls prompting. When it is set to 1, prompts are issued after 
					each command message is processed by the instrument. When it is set to 0, prompts 
					are not issued. 

    				The command messages do not generate prompts. The Model 260x generates prompts in 
    				response to command messages.

   					When the prompting mode is enabled, the Model 260x generates prompts in response to 
   					command messages. There are three prompts that might be returned:

     				1. TSP> is the standard prompt. This prompt indicates that everything is normal 
     				and the command is done processing.

    				2. TSP? is issued if there are entries in the error queue when the prompt is issued. 
    				Like the TSP> prompt, it indicates the command is done processing. It does not mean 
    				the previous command generated an error, only that there are still errors in the 
    				queue when the command was done processing.

    				3. >>>> is the continuation prompt. This prompt is used when downloading scripts 
    				or flash images. When downloading scripts or flash images, many command messages 
    				must be sent as a unit. The continuation prompt indicates that the instrument is 
    				expecting more messages as part of the current command.

    				Test Script Builder (TSB) requires prompts. It sets the prompting mode behind the 
    				scenes. If you disable prompting, use of the TSB will hang because it will be waiting 
    				for the prompt that lets it know that the command is done executing. DO NOT disable 
    				prompting with the use of the TSB.

   					When used in an expanded system (TSP-Link), localnode.prompt is sent to the Remote 
   					Master node only. Use node[N].prompt (where N is the node number) to send the 
   					command to any node in the system. See Section 9 for details on TSP-Link.
					
localnode.showerrors = <0/1>
Where:
		<0/1> 	 	Set to 0 to disable or 1 to enable.

					If this attribute is set to 1, for any errors that are generated, the unit will 
					automatically display the errors stored in the error queue, and then clear the queue. 
					Errors will be processed at the end of executing a command message (just prior to 
					issuing a prompt if prompts are enabled).

    				If this attribute is set to 0, errors will be left in the error queue and must be 
    				explicitly read or cleared. 

    				When used in an expanded system (TSP-Link), localnode.showerrors is sent to the 
    				Remote Master node only. Use node[N].showerrors (where N is the node number) to 
    				send the command to any node in the system. See Section 9 for details on TSP-Link.
					
Rev1: JLT 8.15.2005
Rev2: BCO 5.2.2019
]]--

-- Let's reset the 260x to a known default condition first
reset()

-- First we'll print the current instrument model

print(localnode.model)

-- Print the instrument description that shows up on instrument's LXI welcome page. The value of this attribute is also used as the instrument's mDNS service name.

print(localnode.description)

-- Lets disable error messaging to see what happens. We'll make some mistakes here too!
localnode.showerrors = 0

smua.measure.filter.type = 6			-- Sets the filter type to an invalid setting

-- We now have to query the 260x for the error message. I injected a delay so you can see what happens slowly.
delay(3)
errorcode, message, severity = errorqueue.next()
print(errorcode, message, severity)


-- Notice now how we get the normal 'TSP>' prompt. If we make the same error again, the error message
-- will automatically appear without having to query the 260x when the 'showerrors' parameter is
-- enabled. Let's see just that.
delay(5)
localnode.showerrors = 1
smua.measure.filter.type = 6			-- Sets the filter type to an invalid setting
