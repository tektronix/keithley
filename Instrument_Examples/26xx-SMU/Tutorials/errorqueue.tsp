--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

errorqueue.tsp

This example shows how to query the 260x for error messages if the 'localnode.showerrors' is diabled.


Commands used in this example:
errorqueue.clear()
Where:
					Clears all entries out of the error/event queue.
					
count = errorqueue.count
Where:
		count		The number of entries in the error/event queue.
		
errorcode, message, severity = errorqueue.next()
Where:
		errorcode   Returns the error code number for the entry.
		message   	Returns the message that describes the entry.
		severity    Returns the severity level (0, 10, 20, 30 or 40).
		
					Entries are stored in a first-in, first-out (FIFO) queue. This function reads the 
					oldest entry and removes it from the queue.

  					Error codes and messages are listed in Table B-2 in Appendix B of the 2600 Reference 
  					manual.

  					If there are no entries in the queue, code 0, Queue Is Empty is returned.

  					Returned severity levels include the following:

   						0   Informational  Indicates no error: Queue is Empty.

   						10  Informational  Indicates an event or a minor error. 
   						    Examples: Reading Available and Reading Overflow.

   						20   Recoverable  Indicates possible invalid user input. Operation will 
   						     continue but action should be taken to correct the error. 
   						     Examples: Exponent Too Large and Numeric Data Not Allowed.

   						30   Serious  Indicates a serious error and may require technical assistance. 
   						     Example: Saved calibration constants corrupted.

   						40   Fatal  Indicates that the Model 260x is non-operational and will require 
   						     service. Examples: Bad SMU AFPGA image size, SMU is unresponsive and 
   						     Communication Timeout with DFPGA.
					
Rev1: JLT 8.15.2005
]]--

-- Let's reset the 260x to a known default condition first
reset()

-- To visually see how this works, we need to turn off the showerrors parameter from localnode.
localnode.prompts = 1
localnode.showerrors = 0

-- Let's create a loop that imbeds some errors.

for x = 1, 10 do
	print("The loop count = ", x)
	smua.measure.autozero = x			-- Sets the filter type to an invalid setting
end
smua.source.rangev = 60000000			-- One more error

-- We will query for the number of error messages, get the messages, and print them. We'll finally 
-- clear the error queue.

count = errorqueue.count
print("")
print("The number of error messages in the queue is: ",string.format("%s",count))

for errorloop = 1, count do
	errorcode, message, severity = errorqueue.next()
	print(string.format("%s",errorcode), ": ",message,", Severity = ",string.format("%s",severity))
end	

errorqueue.clear()
localnode.showerrors = 1