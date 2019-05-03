--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

DisplayText1.tsp

Programs the 260x to input and output text and information from the front panel display. The example sequences
through a series of examples to highlight functionality.


Commands used in this example:

display.clear()
Where:
		 	 		Clears the display of the 260x.
		 	 		
<annun> = display.getannunciators()
Where:
		annun 		Returns the bitmap value for annunciators that are turned on.
		
<row>,<column> = display.getcursors()
Where:
		row			Returns the row value for the current location of the cursor.
		column		Returns the column value for the current location of the cursor.
		
display.setcursor(row, column)
Where:
		row			Sets the row value for the location where the cursor is to be set.
		column		Sets the column value for the location where the cursor is to be set.
		
display.settext(text)
Where:
		text	Displays the 'text' at the current cursor location defined by the 'display.setcursor' command.

text = display.gettext(embellished, row, column_start, column_end)
Where:
		embellished		Set to false to return text as a simple character string. 
						Set to true to include all character codes.

		row    			Set to 1 or 2 to select which row to read text. If not included, text from both rows 
						are read.

		column_start   Set to starting column for reading text. Default is 1.

		column_end   	Set to ending column for reading text. Default is 20 (Row 1) or 32 (Row 2).


Rev1: JLT 7.16.2005
Rev2: BCO 5.2.2019
]]--

-- Let's reset the 260x to a known default condition first
reset()
display.clear()
-- Let's get the annunciator information first. The data will be printed in TSB's Instrument Console.
-- Annunciators are the small text icons along the very top of the display, they indicate things like whether the SMU is in remote operation.

annun = display.getannunciators()
print("Annunciators = ",annun)
delay(2)

-- We can also get the cursor data. This command reads the present position of the cursor for the user display.

row, column  = display.getcursor()
print("The cursor is located at row",row," and column ",column)
delay(2)

-- When you run this the result will tell you that the cursor is at row 1 and at column 1. Let's change the 
-- position of the cursor so we can place text on Row 2 starting at Column 5.

display.setcursor(2,5)

-- With the cursor in Row 2 and Column 5, let's put some user text at this position using the
-- 'display.settext' command. We'll display the usual "Hello World" text.

display.settext("Hello World")
delay(2)

-- Let's make this "Hello World" text scroll across row 2. We will have to use a For..Loop to accomplish this.
-- Row 2 contains a total of 32 columns, thus we will need a loop that loops 32 times and sets the cursor 
-- at the appropriate location. The other issue that we have to make sure of is that we blank out the columns
-- after the text has scrolled by. Otherwise the first or last character of "Hello World", depending on which
-- way you scroll, will remain on the display. Let's run this first example to see what happens. Here we go!

display.clear()
row = 2
for column= 1, 33 do
	display.setcursor(2,column)
	display.settext("Hello World")
	delay(.05)
end	
delay(2)

-- Did you see all of the "H"'s left on the screen? Let's add some code to eliminate the H's.

display.clear()
row = 2
for column= 1, 33 do
	if column >1 then
		display.setcursor(2,column-1)
		display.settext(" ")
	end	
	display.setcursor(2,column)
	display.settext("Hello World")
	delay(.1)
	if column == 33 then
		display.setcursor(2,column-1)
		display.settext(" ")
	end	
end	
delay(1)

-- If we want to be truly adventurous, we can make the text scroll back and forth a couple of times. This will
-- require loops to go in both directions. Let's make this operation go for three times. Here we go!

display.clear()
row = 2
for operation= 1, 3 do
	for column= 1, 21 do
		if column >1 then
			display.setcursor(2,column-1)
			display.settext(" ")
		end	
		display.setcursor(2,column)
		display.settext("Hello World")
		delay(.1)
		if column == 33 then
			display.setcursor(2,column-1)
			display.settext(" ")
		end	
	end
	for column= 21, 1, -1 do
		if column == 1 then
			display.setcursor(2,12)
			display.settext(" ")
		end	
		if column >1 then
			display.setcursor(2,column+11)
			display.settext(" ")
		end	
		display.setcursor(2,column)
		display.settext("Hello World")
		delay(.08)
	end	
end	
delay(2)

-- We can now use the 'display.gettext() command to get the text displayed on the front panel. We'll set the
-- display to contain some text and then retrieve the text by looping through the columns and the row

toprowtext = localnode.model.." SourceMeter"
toplength = string.len(toprowtext)
bottomrowtext = "Keithley Instruments"
bottomlength = string.len(bottomrowtext)
display.clear()
display.setcursor(1,1)
display.settext(toprowtext)
display.setcursor(2,1)
display.settext(bottomrowtext)

-- Get Row 1 information
for column = 1, toplength do
	text = display.gettext(false,1, column,toplength)
	print(text)
end	

-- Get Row 2 information
for column = 1, bottomlength do
	text = display.gettext(false,2, column, bottomlength)
	print(text)
end	

