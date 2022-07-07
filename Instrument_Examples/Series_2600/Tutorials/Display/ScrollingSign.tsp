--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

ScrollingSign.tsp

Programs the 260x front panel display to act like a Scrolling Sign.



Rev1: JLT 7.18.2005
Rev2: BCO 5.2.2019
]]--

-- Let's reset the 260x to a known default condition first
reset()

-- Let's set up an operation to get the number of times the sign will scroll from the front panel.

scrolltimes = display.prompt("+0000", " ", "Enter the number of scrolls", 5, 1, 100)


-- Let's make the scrolling sign flash across row 1. We will have to use a For..Loop to accomplish this.
-- Row 1 contains a total of 20 columns, but since the text could be longer, we need to loop as many
-- times as the length of the text. This will help us to set the cursor at the appropriate location. 
-- The other issue that we have to make sure of is that we blank out the columns
-- after the text has scrolled by. Otherwise the first or last character of our text, depending on which
-- way you scroll, will remain on the display. Let's scroll from right to left. Here we go!

display.clear()
display.screen = 3

scrolltext = "The "..localnode.model.." SourceMeter from Keithley Instruments"			
													-- Define the text message here to scrol
row = 1												-- Define the variable 'row'
textlength=string.len(scrolltext)					-- Get the length of the scroll text

for scrollamount = 1, scrolltimes do				-- Determines how many times the message will scroll
	for column =20, 1, -1  do						-- This control loop sets a right to left scroll
		display.setcursor(1,column)					-- Set the cursor to the next location on the row
			display.settext(scrolltext)				-- Display the text
	delay(.1)										-- Set a delay to scroll at a reasonable rate
	end									
	if (textlength-20)>0 then						-- If the messsage >20 characters, perform the following code.
		for loop = 1, textlength do					-- Loop for the lenght of the scroll text
			subtext=string.sub(scrolltext,loop,-1).."                     "
													-- Get a subset of the text in order to scroll partial
													-- sections of the text across the row. Concatenate 21
													-- blank spaces in order to make sure no remaining characters
													-- are left on the display and to give the appearance the text
													-- is scrolling.
			display.setcursor(1,1)					-- Set the cursor to row 1, column 1.
			display.settext(subtext)				-- Display the subset of the scroll text
			delay(.1)								-- Delay the same amount of time
		end
		display.setcursor(1,1)						-- Set the cursor to row 1, column 1
		display.settext(" ")						-- Display a blank space to eliminate leftover characters.
	end		
end