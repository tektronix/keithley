--[[Last Updated: $Date: 2020/03/06 $ $Change: 189427 $ 
	
	Copyright © Keithley Instruments, LLC.  All rights reserved.

	Part of the Keithley Instruments Potentiostat System.
	Users are permitted to modify but not distribute the software without prior written permission from Keithley.
	
	THIS SOFTWARE IS PROVIDED “AS-IS,” WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES OF ANY KIND, INCLUDING 
	BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
	NON-INFRINGEMENT OF INTELLECTUAL PROPERTY. IN NO EVENT SHALL KEITHLEY INSTRUMENTS, ITS AFFILIATES, 
	OFFICERS, EMPLOYEES, DIRECTORS, AGENTS, SUPPLIERS, OR OTHER THIRD PARTIES BE LIABLE FOR ANY DIRECT, 
	INDIRECT, INCIDENTAL, PUNITIVE, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT 
	OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
	
	This is framework code for the Potentiostat suite.

	Using this test script requires the Model 2450, 2460, or 2461 to have firmware 1.5.0 or greater.  
	The latest firmware can be found on the Keithley website, tek.com/keithley.

	]]
minimum_version = "1.5.0"
----------------
EC_FRAMEWORK_VERSION = "1.5"
MIN_EC_IMAGES_VERSION = "1.0"
acceptable_models = {"2450", "2460", "2461"}
----------------
button_height = 70
button_width = 160
option_height = 100
option_width = 200
analysis_table = nil
instr = smu
-------

--Cache statistics
cache_miss = 0
cache_hit = 0

CID = {
	CYAN = display.COLOR_VALUE_LABEL, 
	LIGHT_CYAN = 0x000DC0FF, 
	GREEN = 0x0024A11E, 
	LIGHT_GREEN = 0x0062F75B, 
	LTLT_GREY = display.COLOR_VALUE_VALUE, 
	DARK_GREY = 0x000808080, 
	PURPLE = 0x00FF00FF,
	UBER_DARK = 0x00202020
}

SYMBOL = {
	DELTA = string.char(185),
	MU = string.char(20),
	OMEGA = string.char(18),
	DEGREE = string.char(19)
}

tbl = { }
function tbl.make(settings)
	local ROWS = settings.rows
	local COLS = settings.cols
	local tbl = settings.table
	local cell = settings.cell
	local id = settings.screen_id
	local font = settings.font
	local has_col_header = settings.has_col_header
	
	if cell.padding == nil then
		cell.padding = { }
	end
	if cell.text_offset == nil then
		cell.text_offset = { }
	end
	
	if font == display.FONT_SMALL then
		if cell.height == nil then cell.height = 10 end
		if cell.padding.left == nil then cell.padding.left = 14 end
		if cell.padding.top == nil then cell.padding.top = 14 end
		if cell.text_offset.left == nil then cell.text_offset.left = 0 end
		if cell.text_offset.top == nil then cell.text_offset.top = 0 end
	elseif font == display.FONT_MEDIUM then
		if cell.height == nil then cell.height = 20 end
		if cell.padding.left == nil then cell.padding.left = 14 end
		if cell.padding.top == nil then cell.padding.top = 14 end
		if cell.text_offset.left == nil then cell.text_offset.left = 0 end
		if cell.text_offset.top == nil then cell.text_offset.top = -2 end
	else --if font == display.FONT_LARGE then
		if cell.height == nil then cell.height = 25 end
		if cell.padding.left == nil then cell.padding.left = 14 end
		if cell.padding.top == nil then cell.padding.top = 14 end
		if cell.text_offset.left == nil then cell.text_offset.left = 0 end
		if cell.text_offset.top == nil then cell.text_offset.top = -2 end
	end

	local table_id = { }
	
	for row = 1,table.getn(ROWS) do
		local x = tbl.x
		local y = tbl.y + ((row - 1) * (cell.height + cell.padding.top))
		local textx = x + cell.padding.left + cell.width + cell.text_offset.left --Text is right justified so we need to add cell width
		local texty = y + cell.height + cell.padding.top + cell.text_offset.top
		if string.sub(ROWS[row],1,string.len("-"))=="-" then
			loadstring('return function(t) t.row_separator'..row..'_upper = display.create('..id..', display.OBJ_LINE, '..(x + (cell.padding.left/2))..', '..(y + (cell.padding.top/2))..', '..(x + (cell.padding.left / 2) + (table.getn(COLS) * (cell.width + cell.padding.left)))..', '..(y + (cell.padding.top/2))..') end')()(table_id)
			loadstring('return function(t) display.setcolor(t.row_separator'..row..'_upper, '..CID.DARK_GREY..') end')()(table_id)
		end
		
		loadstring('return function(t) t.row'..row..'_col1 = display.create('..id..', display.OBJ_TEXT, '..textx..', '..texty..', "'..string.gsub(ROWS[row], "-", "")..'", display.COLOR_VALUE_LABEL, '..font..', display.JUST_RIGHT) end')()(table_id)
		
		if string.sub(ROWS[row],-string.len("-"))=="-" then
			loadstring('return function(t) t.row_separator'..row..'_lower = display.create('..id..', display.OBJ_LINE, '..(x + (cell.padding.left / 2))..', '..(y + cell.height + (3 * cell.padding.top / 2))..', '..(x + (cell.padding.left / 2) + (table.getn(COLS) * (cell.width + cell.padding.left)))..', '..(y + cell.height + (3 * cell.padding.top / 2))..') end')()(table_id)
			loadstring('return function(t) display.setcolor(t.row_separator'..row..'_lower, '..CID.DARK_GREY..') end')()(table_id)
		end
	end
	
	for col = 1,table.getn(COLS) do
		local x = tbl.x + ((col - 1) * (cell.width + cell.padding.left))
		local y = tbl.y
		local textx = x + cell.padding.left + cell.text_offset.left + cell.width / 2 --Text is center justified so we need to add helf the cell width
		local texty = y + cell.height + cell.padding.top + cell.text_offset.top
		if string.sub(COLS[col],1,string.len("-"))=="-" then
			loadstring('return function(t) t.col_separator'..col..'_left = display.create('..id..', display.OBJ_LINE, '..(x + (cell.padding.left / 2))..', '..(y + (cell.padding.top / 2))..', '..(x + (cell.padding.left / 2))..', '..(y + (cell.padding.top / 2) + (table.getn(ROWS) * (cell.height + cell.padding.top)))..') end')()(table_id)
			loadstring('return function(t) display.setcolor(t.col_separator'..col..'_left, '..CID.DARK_GREY..') end')()(table_id)
		end
		
		if has_col_header then
			loadstring('return function(t) t.row1_col'..col..' = display.create('..id..', display.OBJ_TEXT, '..textx..', '..texty..', "'..string.gsub(COLS[col], "-", "")..'", display.COLOR_VALUE_LABEL, '..font..', display.JUST_CENTER) end')()(table_id)
		end
		
		if string.sub(COLS[col],-string.len("-"))=="-" then
			loadstring('return function(t) t.col_separator'..col..'_right = display.create('..id..', display.OBJ_LINE, '..(x + cell.width + (3 * cell.padding.left / 2))..', '..(y + (cell.padding.top / 2))..', '..(x + cell.width + (3 * cell.padding.left / 2))..', '..(y + (cell.padding.top / 2) + (table.getn(ROWS) * (cell.height + cell.padding.top)))..') end')()(table_id)
			loadstring('return function(t) display.setcolor(t.col_separator'..col..'_right, '..CID.DARK_GREY..') end')()(table_id)
		end
	end
	
	table_id.is_created = true
	return table_id
end
function tbl.write(table_id, row, col, text, settings)
	if table_id == nil or row == nil or col == nil or text == nil or settings == nil or not table_id.is_created then return end
	local tbl = settings.table
	local cell = settings.cell
	local id = settings.screen_id
	local font = settings.font
	
	local x = tbl.x + ((col - 1) * (cell.width + cell.padding.left))
	local y = tbl.y + ((row - 1) * (cell.height + cell.padding.top))
	local textx = x + cell.padding.left + cell.width/2 + cell.text_offset.left	--Text is center justified so we need to add half the cell width
	local texty = y + cell.height + cell.padding.top + cell.text_offset.top
	loadstring('return function(t) if t.row'..row..'_col'..col..' ~= nil then display.settext(t.row'..row..'_col'..col..', "'..text..'") else t.row'..row..'_col'..col..' = display.create('..id..', display.OBJ_TEXT, '..textx..', '..texty..', "'..text..'", display.COLOR_VALUE_VALUE, '..font..', display.JUST_CENTER) end end')()(table_id)
end
function tbl.delete(table_id)
	for k,v in pairs(table_id) do display.delete(v) end
	table_id = nil
end

function get_bufferstats(buf, start_time, end_time)
	function init_cache(buf)
		cache = { }
		cache.stats = { }
		cache.stats.buffer = { }
		cache.stats.buffer.getstats = buffer.getstats(buf)
		cache.stats.cursor = { }
		cache.n = buf.n
		cache.first = { }
		cache.first.time = buf.relativetimestamps[1]
		cache.first.reading = buf.readings[1]
		cache.last = { }
		cache.last.time = buf.relativetimestamps[buf.n]
		cache.last.reading = buf.readings[buf.n]
		cache.dirty = false
	end
	
	function cache_cursor_stats(buf, start_time, end_time)
		cache.stats.cursor.start_time = start_time
		cache.stats.cursor.end_time = end_time
		cache.stats.cursor.getstats = buffer.getstats(buf, start_time, end_time)
	end
	
	function verify_cache(buf, start_time, end_time)
		if start_time ~= nil and end_time ~= nil then
			if cache.stats.cursor.getstats == nil or
				cache.stats.cursor.start_time ~= start_time or
				cache.stats.cursor.end_time ~= end_time then
				cache_miss = cache_miss + 1
				return false
			end
		else
			if cache.dirty or 
				cache.n ~= buf.n or
				cache.first.time ~= buf.relativetimestamps[1] or
				cache.first.reading ~= buf.readings[1] or 
				cache.last.time ~= buf.relativetimestamps[buf.n] or 
				cache.last.reading ~= buf.readings[buf.n] then
				cache_miss = cache_miss + 1
				return false
			end
		end
		cache_hit = cache_hit + 1
		return true
	end

	if buf == nil or buf.n == 0 then return nil end
	
	if cache == nil or not verify_cache(buf) then
		init_cache(buf)	--initialize cache
	end
	
	if start_time ~= nil and end_time ~= nil then
		if not verify_cache(buf, start_time, end_time) then
			cache_cursor_stats(buf, start_time, end_time)
		end
		
		return cache.stats.cursor.getstats
	else
		return cache.stats.buffer.getstats
	end
end

function get_version_number()
	local char_from, char_to = string.find(tostring(changelist), "%d+")
	if char_from ~= nil then
		return string.sub(tostring(changelist), char_from, char_to)
	else
		return ""
	end
end

function verify_requirements()
	if localnode.version < minimum_version then
		print("Please upgrade to at least firmware version: "..minimum_version)
		eventlog.post("Unsupported firmware, please upgrade to at least firmware version "..minimum_version..".", eventlog.SEV_ERROR)
		exit()
	end
	
	if acceptable_models ~= nil then
		for i=1,table.getn(acceptable_models) do
			if acceptable_models[i] == localnode.model then
				return
			end
		end
	else
		return
	end
	
	print("Can not run on instrument: "..localnode.model)
	print("Allowed models: "..table_to_csv(acceptable_models))
	eventlog.post("Can not run on instrument: "..localnode.model..". Allowed models: "..table_to_csv(acceptable_models), eventlog.SEV_ERROR)
	exit()
end

function get_version_number(changelist)
	local char_from, char_to = string.find(tostring(changelist), "%d+")
	if char_from ~= nil then
		return string.sub(tostring(changelist), char_from, char_to)
	else
		return ""
	end
end

function print_debug(text)
	display.input.prompt(display.BUTTONS_OK, tostring(text))
	--display.settext(display.TEXT2, tostring(text))
	--display.changescreen(display.SCREEN_USER_SWIPE)
end

function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

function table_to_csv(tbl)
	local csv_string = ""
	for i=1,table.getn(tbl) do
		if csv_string ~= "" then
			csv_string = csv_string..', "'..tbl[i]..'"'
		else
			csv_string = '"'..tbl[i]..'"'
		end
	end
	
	return csv_string
end

function create_edit_option(screen, x, y, title, help_text, option_table)
	local option_string = table_to_csv(option_table.value)
	local obj
	
	obj = loadstring('return display.create('..screen..', display.OBJ_EDIT_OPTION, '..x..', '..y..', "'..title..'", "'..help_text..'", '..option_string..')')()
	if option_table.abbreviation ~= nil then
		option_string = table_to_csv(option_table.abbreviation)
		loadstring('display.setabbrv('..obj..', '..option_string..')')()
	end
	return obj
end

function popup_option_dialog(title, option_table)
	local option_string = table_to_csv(option_table.value)
	
	return loadstring('return display.input.option("'..title..'", '..option_string..')')()
end

function get_index_from_option_enum(option_enum)
	if option_enum == nil then return nil end
	local ret = tonumber(string.sub(tostring(option_enum), string.find(tostring(option_enum), "%d+")))
	if ret == nil then
		print_debug("ASSERT: "..value_enum.." not found")
		exit()
	end
	return ret
end

function get_index_from_value_enum(option_table, value_enum)
	for i=1,table.getn(option_table.value) do
		if option_table.value[i] == value_enum then
			return i
		end
	end
	print_debug("ASSERT: "..value_enum.." not found")
	exit()
	return nil
end

function get_index_from_range(option_table, range)
	for i=1,table.getn(option_table.range) do
		if option_table.range[i] == range then
			return i
		end
	end
	print_debug("ASSERT: "..range.." range not found")
	exit()
end

function decompose_table(name, t)
	ret = ""
	for k,v in pairs(t) do
		if type(v) == "string" then
			ret = ret..name..'['..k..'] = "'..v..'"\n'
		elseif type(v) == "table" then
			ret = ret..decompose_table(k, v)
		else
			ret = ret..name..'['..k..'] = '..v..'\n'
		end
	end
	return ret
end
--Loads all variables in file into a table
function load_from_file(filename, data_table, signature)
	local error_occured = false
	local line_counter = 1
	
	if file.usbdriveexists() == 0 then
		display.input.prompt(display.BUTTONS_OK, "USB flash drive not present.") 
		return nil
	end
	
	if not fs.is_file('/usb1/'..filename) then
		display.input.prompt(display.BUTTONS_OK, "Load failed. File not found.") 
		return nil
	end
	
	local f = io.open('/usb1/'..filename, 'r')
	local line = f:read()
	if signature ~= nil and string.gsub(string.gsub(line, '\n', ''), '%-%-', '') ~= signature then
		display.input.prompt(display.BUTTONS_OK, "Load aborted. Incorrect file signature.")
		return nil
	elseif signature ~= nil and string.gsub(string.gsub(line, '\n', ''), '%-%-', '') == signature then
		line = f:read()
		line_counter = line_counter + 1
	end
	
	data_table = data_table or { }
	while line do
		if string.find(line, '%-%-') == nil then
			local did_execute, f = pcall(loadstring('return function(t) t.'..line..' end'))
			if did_execute then
				f(data_table)
			else
				display.input.prompt(display.BUTTONS_OK, "Error reading line "..line_counter.." of "..filename..". Invalid syntax. Continuing to next line.")
				error_occured = true
			end
		end
		line = f:read()
		line_counter = line_counter + 1
	end
	f:close()
	if not error_occured then
		display.input.prompt(display.BUTTONS_OK, "Load successful.")
	else
		display.input.prompt(display.BUTTONS_OK, "Load completed with errors.")
	end
	return data_table
end

function save_data_to_usb_with_prompt(data_table)
	local filename, string
	
	if file.usbdriveexists() == 0 then
		display.input.prompt(display.BUTTONS_OK, "USB flash drive not present.") 
		return nil
	end
	
	filename = display.input.string("File Name", display.SFORMAT_FILE_NAME)
	if filename == nil or filename == "" then
		display.input.prompt(display.BUTTONS_OK, "No filename specified.  Data not saved.") 
		return false
	end
	filename = filename..".csv"

	if fs.is_file('/usb1/'..filename) then
		local ans = display.input.prompt(display.BUTTONS_YESNO, "File already exists. Overwrite?")
		if ans == display.BUTTON_NO then return false end
	end
	
	local f = io.open('/usb1/'..filename, 'w+')
	if f == nil then
		display.input.prompt(display.BUTTONS_OK, "Unable to overwrite or create file.")
		return false
	end
	
	local prompt = display.prompt(display.BUTTONS_NONE, "Saving data to USB as "..filename.."...")
	--delay(0.5)
	table.insert(data_table, 1, "Keithley Instruments: "..SCRIPT_TITLE)
	table.insert(data_table, 2, "\nSystem Parameters")
	table.insert(data_table, 3, "Date/Time,"..os.date('%c', gettime()))
	table.insert(data_table, 4, "Model,"..localnode.model)
	table.insert(data_table, 5, "Serial Number,"..localnode.serialno)
	table.insert(data_table, 6, "Firmware,"..localnode.version)
	table.insert(data_table, 7, "Program Version,"..get_version_number(changelist))
	table.insert(data_table, 8, "EC Framework Version,"..EC_FRAMEWORK_VERSION)
	table.insert(data_table, 9, "")
	
	string = table.concat(data_table, "\n")
	f:write(string)
	
	f:flush()
	f:close()
	display.delete(prompt)
	display.input.prompt(display.BUTTONS_OK, "Data saved successfully.")
	return true
end

function save_to_file(filename, data_table, signature)
	if file.usbdriveexists() == 0 then
		display.input.prompt(display.BUTTONS_OK, "USB flash drive not present.") 
		return nil
	end

	if fs.is_file('/usb1/'..filename) then
		local ans = display.input.prompt(display.BUTTONS_YESNO, "File already exists. Overwrite?")
		if ans == display.BUTTON_NO then return false end
	end
	
	local f = io.open('/usb1/'..filename, 'w+')
	if f == nil then
		display.input.prompt(display.BUTTONS_OK, "Unable to overwrite or create file.")
		return false
	end
	
	if signature ~= nil then
		f:write('\-\-'..signature..'\n')
	end
	
	for k,v in pairs(data_table) do
		if type(v) == "string" then
			f:write(k..' = "'..v..'"\n')
		elseif type(v) == "table" then
			f:write(decompose_table(k, v))
		else
			f:write(k..' = '..v..'\n')
		end
	end
	f:flush()
	f:close()
	display.input.prompt(display.BUTTONS_OK, "Save successful.")
	return true
end

function sync_ui_to_data(ui_data_event_table, ui_element)
	local ui_element_object
	for i = 1, table.getn(ui_data_event_table) do
		--print("syncing "..ui_data_event_table[i].ui.." to "..ui_data_event_table[i].data)
		ui_element_object = loadstring('return '..ui_data_event_table[i].ui)()
		if (ui_element == nil or ui_element == ui_element_object) and ui_element_object ~= nil then
			local value = display.getvalue(ui_element_object)
			if value ~= nil then
				loadstring(ui_data_event_table[i].data..' = '..value)()
			end
		end
	end
end

function sync_data_to_ui(ui_data_event_table, ui_element)
	local ui_element_object
	for i = 1, table.getn(ui_data_event_table) do
		--print("syncing "..ui_data_event_table[i].data.." to "..ui_data_event_table[i].ui)
		ui_element_object = loadstring('return '..ui_data_event_table[i].ui)()
		if ui_element == nil or ui_element == ui_element_object then
			if ui_data_event_table[i].ui ~= nil then
				loadstring('if '..ui_data_event_table[i].ui..' ~= nil then display.setvalue('..ui_data_event_table[i].ui..', '..ui_data_event_table[i].data..') end')()
			end
			if ui_data_event_table[i].event ~= nil then
				loadstring('if '..ui_data_event_table[i].event..' ~= nil then '..ui_data_event_table[i].event..'('..ui_data_event_table[i].ui..','..ui_data_event_table[i].data..', true) end')()
			end
		end
	end
end

function verify_power_limits(source_value, source_func, limit_range)
	source_value = math.abs(source_value)
	source_func = source_func or instr.source.func
	limit_range = limit_range or instr.measure.range
	
	if source_func == instr.FUNC_DC_VOLTAGE then
		if source_value > I_RANGES.v_limit[get_index_from_range(I_RANGES, limit_range)] then
			return false
		end
	else
		if source_value > V_RANGES.i_limit[get_index_from_range(V_RANGES, limit_range)] then
			return false
		end
	end
	
	return true
end
--Statistics Functions

function get_mean(buf, start_time, end_time)
	if start_time ~= nil and end_time ~= nil then
		if start_time < 0 then start_time = 0 end
		if end_time < 0 then end_time = 0 end
		local mean = get_bufferstats(buf, start_time, end_time).mean
		if mean == nil then
			return nil
		end
		return mean
	else
		return get_bufferstats(buf).mean
	end
end

function get_stddev(buf, start_time, end_time)
	if start_time ~= nil and end_time ~= nil then
		if start_time < 0 then start_time = 0 end
		if end_time < 0 then end_time = 0 end
		local stddev = get_bufferstats(buf, start_time, end_time).stddev
		if stddev == nil then return nil end
		return stddev
	else
		return get_bufferstats(buf).stddev
	end
end

function get_time(buf)
	if buf == nil or buf.n == 0 then
		return nil
	else
		return buf.relativetimestamps[buf.n]
	end
end
-------
function update_progress_bar(percent)
	if percent < 0 then percent = 0 end
	local cursorx_state, cursory_state
	
	if percent >= 100 then
		percent = 100	--prevent values >100%
		display.setfill(ui.home.progress_bar, 0, display.FILL_RIGHT)
		display.settext(ui.home.progress_text, "0%")
		display.setstate(ui.home.progress_text, display.STATE_INVISIBLE)
		display.setstate(ui.home.progress_bar, display.STATE_INVISIBLE)
		
		display.setstate(ui.home.cursor_label, display.STATE_ENABLE)
		display.setstate(ui.home.cursor_mode, display.STATE_ENABLE)
		if ui.home.cursor_prev == "Vertical" or ui.home.cursor_prev == "Both" then
			cursorx_state = display.STATE_ENABLE
		else
			cursorx_state = display.STATE_INVISIBLE
		end
		if ui.home.cursor_prev == "Horizontal" or ui.home.cursor_prev == "Both" then
			cursory_state = display.STATE_ENABLE
		else
			cursory_state = display.STATE_INVISIBLE
		end
	else
		display.setfill(ui.home.progress_bar, percent, display.FILL_RIGHT)
		display.settext(ui.home.progress_text, math.floor(percent).."%")
		display.setstate(ui.home.progress_bar, display.STATE_ENABLE)
		display.setstate(ui.home.progress_text, display.STATE_ENABLE)
		cursorx_state = display.STATE_INVISIBLE
		cursory_state = display.STATE_INVISIBLE
		
		display.setstate(ui.home.cursor_label, display.STATE_INVISIBLE)
		display.setstate(ui.home.cursor_mode, display.STATE_INVISIBLE)
	end
	
	for k,v in pairs(ui.home.cursorx) do
		if k ~= "x1" and k ~= "x2" then
			display.setstate(v, cursorx_state)
		end
	end
	
	for k,v in pairs(ui.home.cursory) do
		if k ~= "y1" and k ~= "y2" then
			display.setstate(v, cursory_state)
		end
	end
end

function hide_home_stats()
	for i=1,table.getn(ui.home.stat) do
		display.setstate(ui.home.stat[i].label, display.STATE_INVISIBLE)
		display.setstate(ui.home.stat[i].value, display.STATE_INVISIBLE)
	end
end

function show_home_stats()
	for i=1,table.getn(ui.home.stat) do
		display.setstate(ui.home.stat[i].label, display.STATE_ENABLE)
		display.setstate(ui.home.stat[i].value, display.STATE_ENABLE)
	end
end

--Event Handlers
function changeCursor()
	local CURSOR_MODES = {"None", "Vertical", "Horizontal", "Both"}
	local next_mode
	for i=1,table.getn(CURSOR_MODES) do
		if ui.home.cursor_prev == CURSOR_MODES[i] then
			if i==table.getn(CURSOR_MODES) then
				next_mode = CURSOR_MODES[1]
			else
				next_mode = CURSOR_MODES[i+1]
			end
			ui.home.cursor_prev = next_mode
			break
		end
	end
	
	local state
	if next_mode == "Vertical" or next_mode == "Both" then
		state = display.STATE_ENABLE
		if ui.home.cursorx.x1 > 9e30 or ui.home.cursorx.x2 > 9e30 then
			ui.home.cursorx.x1 = 0 
			ui.home.cursorx.x2 = 0
		end
		display.graph.cursor(ui.home.graph, display.CURSOR_VERTICAL, ui.home.cursorx.x1, ui.home.cursorx.x2)
	else
		state = display.STATE_INVISIBLE
		display.graph.cursor(ui.home.graph, display.CURSOR_VERTICAL, 9.9e37, 9.9e37)
	end
	for k,v in pairs(ui.home.cursorx) do
		if k ~= "x1" and k ~= "x2" then
			display.setstate(v, state)
		end
	end
	
	if next_mode == "Horizontal" or next_mode == "Both" then
		state = display.STATE_ENABLE
		if ui.home.cursory.y1 > 9e30 or ui.home.cursory.y2 > 9e30 then
			ui.home.cursory.y1 = 0 
			ui.home.cursory.y2 = 0
		end
		display.graph.cursor(ui.home.graph, display.CURSOR_HORIZONTAL, ui.home.cursory.y1, ui.home.cursory.y2)
	else
		state = display.STATE_INVISIBLE
		display.graph.cursor(ui.home.graph, display.CURSOR_HORIZONTAL, 9.9e37, 9.9e37)
	end
	for k,v in pairs(ui.home.cursory) do
		if k ~= "y1" and k ~= "y2" then
			display.setstate(v, state)
		end
	end
	
	display.settext(ui.home.cursor_mode, next_mode)
	cursor_event_handler()
end

function cursor_event_handler(cursorx1, cursorx2, cursory1, cursory2)
	if UPDATES_DISABLED or
		trigger.model.state() == trigger.STATE_RUNNING or 
		trigger.model.state() == trigger.STATE_WAITING or
		trigger.model.state() == trigger.STATE_ABORTING then return end
	
	if cursorx1 ~= nil then
		if cursorx1 < 9e30 and cursorx2 < 9e30 then	
			ui.home.cursorx.x1 = cursorx1
			ui.home.cursorx.x2 = cursorx2
		end
		if cursory1 < 9e30 and cursory2 < 9e30 then
			ui.home.cursory.y1 = cursory1
			ui.home.cursory.y2 = cursory2
		end
	end
	
	if ui.home.cursor_prev == "Vertical" or ui.home.cursor_prev == "Both" then
		local precision = 5
		
		display.settext(ui.home.cursorx.x1_value, "X1: "..display.format(ui.home.cursorx.x1, X_UNIT or "V", display.NFORMAT_USER, precision))
		display.settext(ui.home.cursorx.x2_value, "X2: "..display.format(ui.home.cursorx.x2, X_UNIT or "V", display.NFORMAT_USER, precision))
		display.settext(ui.home.cursorx.xd_value, SYMBOL.DELTA.."X: "..tostring(display.format(math.abs(ui.home.cursorx.x2-ui.home.cursorx.x1), X_UNIT or "V", display.NFORMAT_USER, precision)))
	end
	if ui.home.cursor_prev == "Horizontal" or ui.home.cursor_prev == "Both" then
		local precision = 5
		
		display.settext(ui.home.cursory.y1_value, "Y1: "..display.format(ui.home.cursory.y1, Y_UNIT or "A", display.NFORMAT_USER, precision))
		display.settext(ui.home.cursory.y2_value, "Y2: "..display.format(ui.home.cursory.y2, Y_UNIT or "A", display.NFORMAT_USER, precision))
		display.settext(ui.home.cursory.yd_value, SYMBOL.DELTA.."Y: "..tostring(display.format(math.abs(ui.home.cursory.y2-ui.home.cursory.y1), Y_UNIT or "A", display.NFORMAT_USER, precision)))
	end
end

-------

function test_cleanup()
	smu.source.output = smu.OFF
	display.settext(ui.home.start_stop, "Start Test")
	update_progress_bar(100)	--Signal we're done
	display.setevent(ui.home.start_stop, display.EVENT_PRESS, "start_stop_event_handler(%id)")	--Reenable event handler
	display.setstate(ui.home.start_stop, display.STATE_ENABLE)
	display.setstate(ui.home.save, display.STATE_ENABLE)
	display.setstate(ui.home.autoscale, display.STATE_ENABLE)
end

function test_start()
	display.settext(ui.home.start_stop, "Stop Test")
	display.setstate(ui.home.start_stop, display.STATE_DISABLE)
	display.setstate(ui.home.save, display.STATE_INVISIBLE)
	display.setstate(ui.home.autoscale, display.STATE_DISABLE)
	display.setevent(ui.home.start_stop, display.EVENT_PRESS, "")	--Disable event handler
	update_progress_bar(0)	--Signal we're starting
end

function update_stats(stats_table, stats_data, value)
	if stats_table ~= nil and stats_data ~= nil then
		if ui.stats.step_select_value ~= nil then
			if value ~= nil then
				ui.stats.step_select_value = value
			end
			
			if stats_data.time[ui.stats.step_select_value] ~= nil then
				tbl.write(stats_table, 1, 2, display.format(stats_data.time[ui.stats.step_select_value], "s", display.NFORMAT_USER, 6), tbl_settings)
				tbl.write(stats_table, 2, 2, display.format(stats_data.numPts[ui.stats.step_select_value], "", display.NFORMAT_INTEGER, 6), tbl_settings)
				tbl.write(stats_table, 3, 2, display.format(stats_data.min[ui.stats.step_select_value], Y_UNIT or "", display.NFORMAT_USER, 6), tbl_settings)
				tbl.write(stats_table, 4, 2, display.format(stats_data.max[ui.stats.step_select_value], Y_UNIT or "", display.NFORMAT_USER, 6), tbl_settings)
				tbl.write(stats_table, 5, 2, display.format(stats_data.median[ui.stats.step_select_value], Y_UNIT or "", display.NFORMAT_USER, 6), tbl_settings)
				tbl.write(stats_table, 6, 2, display.format(stats_data.avg[ui.stats.step_select_value], Y_UNIT or "", display.NFORMAT_USER, 6), tbl_settings)
				tbl.write(stats_table, 7, 2, display.format(stats_data.stdev[ui.stats.step_select_value], Y_UNIT or "", display.NFORMAT_USER, 6), tbl_settings)
			else
				for row = 1, 6 do
					tbl.write(stats_table, row, 2, "", tbl_settings)
				end
			end
		else
			if stats_data.time ~= nil then	--Assume if time is set the rest are there
				tbl.write(stats_table, 1, 2, display.format(stats_data.time, "s", display.NFORMAT_USER, 6), tbl_settings)
				tbl.write(stats_table, 2, 2, display.format(stats_data.numPts, "", display.NFORMAT_INTEGER, 6), tbl_settings)
				tbl.write(stats_table, 3, 2, display.format(stats_data.min, Y_UNIT or "", display.NFORMAT_USER, 6), tbl_settings)
				tbl.write(stats_table, 4, 2, display.format(stats_data.max, Y_UNIT or "", display.NFORMAT_USER, 6), tbl_settings)
				tbl.write(stats_table, 5, 2, display.format(stats_data.median, Y_UNIT or "", display.NFORMAT_USER, 6), tbl_settings)
				tbl.write(stats_table, 6, 2, display.format(stats_data.avg, Y_UNIT or "", display.NFORMAT_USER, 6), tbl_settings)
				tbl.write(stats_table, 7, 2, display.format(stats_data.stdev, Y_UNIT or "", display.NFORMAT_USER, 6), tbl_settings)
			else
				for row = 1, 6 do
					tbl.write(stats_table, row, 2, "", tbl_settings)
				end
			end
		end
	end
end

function update_min_max(ui_element, display_format, min_value, max_value)
	local last_value = display.getvalue(ui_element)
	display.setminmax(ui_element, min_value, max_value)
	display.settext(ui_element, display.format(min_value, "s", display_format, 4).." to "..display.format(max_value, "s", display_format, 4))
	display.setvalue(ui_element, last_value)	--Workaround for PR60156
end

function create_top_screens()
	--Create screens
	ui.home = { }
	ui.home.stat = { }
	ui.home.root = display.create(display.ROOT, display.OBJ_SCREEN_HOME, "Potentiostat")
	ui.menu = { }
	ui.menu.root = display.create(display.ROOT, display.OBJ_SCREEN_MENU, "Settings", "Views", "Save/Load", "System")
	ui.stats = { }
	ui.stats.stat = { }
	ui.stats.root = display.create(display.ROOT, display.OBJ_SCREEN, "Statistics")
	ui.save = { }
	ui.save.root = display.create(display.ROOT, display.OBJ_SCREEN, "Save Settings")
	ui.load = { }
	ui.load.root = display.create(display.ROOT, display.OBJ_SCREEN, "Load Settings")

	if display.EVENT_ENDAPP then -- create an exit event handler to make sure output is turned off
		display.setevent(ui.home.root, display.EVENT_ENDAPP, "trigger.model.abort() trigger.model.load('empty') smu.reset()")
	end
end

function create_loading_screen() 
	ui.loading = {}
	ui.loading.root = display.create(display.ROOT, display.OBJ_SCREEN, "Loading, please wait...")
end

function destroy_loading_screen()
	display.changescreen(ui.home.root)
	for k,v in pairs(ui.loading) do
		display.delete(v)
	end
	ui.loading = nil
end

function create_top_controls()
	function save_version_strings()
		data.PROGRAM_VERSION = get_version_number(changelist)
		data.EC_FRAMEWORK_VERSION = EC_FRAMEWORK_VERSION
	end
	
	--Create ui.home controls
	ui.home.save = display.create(ui.home.root, display.OBJ_BUTTON, 799 - button_width, 429 - (button_height*2) - 10, "Save Data")
	display.setstate(ui.home.save, display.STATE_INVISIBLE)
	ui.home.start_stop = display.create(ui.home.root, display.OBJ_BUTTON, 799 - button_width, 429 - (button_height*3) - 10, "Start Test")
	ui.home.autoscale = display.create(ui.home.root, display.OBJ_BUTTON, 799 - button_width, 429 - (button_height*4) - 10, "Autoscale")
	display.setevent(ui.home.autoscale, display.EVENT_PRESS, 'display.graph.scalex(ui.home.graph, display.XSCALE_ALL) display.graph.scaley(ui.home.graph, display.YSCALE_ALL)')

	ui.home.progress_bar = display.create(ui.home.root, display.OBJ_RECT, 100, 429 - button_height, 500, 65)
	ui.home.progress_text = display.create(ui.home.root, display.OBJ_TEXT, (600-100)/2 + 100, 400, "0%", 0xFFFFCC, display.FONT_MEDIUM, display.JUST_CENTER)
	display.setfill(ui.home.progress_bar, 0, display.FILL_RIGHT)
	display.setcolor(ui.home.progress_bar, 0x006600, 0x00CC66)
	display.setstate(ui.home.progress_text, display.STATE_INVISIBLE)
	display.setstate(ui.home.progress_bar, display.STATE_INVISIBLE)
	
	local label_col_spacing = 185
	ui.home.cursor_label = display.create(ui.home.root, display.OBJ_TEXT, 10, 400, "Cursor", CID.CYAN, display.FONT_MEDIUM, display.JUST_LEFT)
	ui.home.cursorx = { }
	ui.home.cursorx.x1 = 0.4
	ui.home.cursorx.x2 = 0.6
	ui.home.cursorx.x1_value = display.create(ui.home.root, display.OBJ_TEXT, 90, 385, "X1: ", CID.GREEN, display.FONT_MEDIUM, display.JUST_LEFT)
	ui.home.cursorx.x2_value = display.create(ui.home.root, display.OBJ_TEXT, 90 + label_col_spacing, 385, "X2: ", CID.GREEN, display.FONT_MEDIUM, display.JUST_LEFT)
	ui.home.cursorx.xd_value = display.create(ui.home.root, display.OBJ_TEXT, 90 + (label_col_spacing * 2), 385, SYMBOL.DELTA.."X: ", CID.GREEN, display.FONT_MEDIUM, display.JUST_LEFT)
	ui.home.cursory = { }
	ui.home.cursory.y1 = 0.4
	ui.home.cursory.y2 = 0.6
	ui.home.cursory.y1_value = display.create(ui.home.root, display.OBJ_TEXT, 90, 415, "Y1: ", CID.GREEN, display.FONT_MEDIUM, display.JUST_LEFT)
	ui.home.cursory.y2_value = display.create(ui.home.root, display.OBJ_TEXT, 90 + label_col_spacing, 415, "Y2: ", CID.GREEN, display.FONT_MEDIUM, display.JUST_LEFT)
	ui.home.cursory.yd_value = display.create(ui.home.root, display.OBJ_TEXT, 90 + (label_col_spacing * 2), 415, SYMBOL.DELTA.."Y: ", CID.GREEN, display.FONT_MEDIUM, display.JUST_LEFT)
	for k,v in pairs(ui.home.cursorx) do
		if k ~= "x1" and k ~= "x2" then
			display.setstate(v, display.STATE_INVISIBLE)
		end
	end
	for k,v in pairs(ui.home.cursory) do
		if k ~= "y1" and k ~= "y2" then
			display.setstate(v, display.STATE_INVISIBLE)
		end
	end
	
	ui.home.cursor_mode = display.create(ui.home.root, display.OBJ_BUTTON, 799 - button_width, 429 - button_height + 5, "None")
	display.setevent(ui.home.cursor_mode, display.EVENT_PRESS, "changeCursor()")
	ui.home.cursor_prev = "None"
	
	ui.home.version = display.create(ui.home.root, display.OBJ_TEXT, 799 - button_width - 10, 12,  "version", CID.DARK_GREY, display.FONT_SMALL, display.JUST_RIGHT)
	ui.home.graph = display.create(ui.home.root, display.OBJ_GRAPH, 0, 0, 799 - button_width, 429 - button_height)
	display.setevent(ui.home.graph, display.EVENT_DRAG, "cursor_event_handler(%cursor_vert1, %cursor_vert2, %cursor_horz1, %cursor_horz2)")
	
	for i=1,2 do
		ui.home.stat[i] = { }
		ui.home.stat[i].label = display.create(ui.home.root, display.OBJ_TEXT, 600, ((i-1) * 50) + 20, STATS.value[i]..":", CID.LIGHT_CYAN, display.FONT_SMALL, display.JUST_LEFT)
		ui.home.stat[i].value = display.create(ui.home.root, display.OBJ_TEXT, 700, (((i-1) * 50) + 20 + 25), "1.2345", display.COLOR_VALUE_VALUE, display.FONT_SMALL, display.JUST_CENTER)
	end
	
	--Create ui.save controls
	ui.save.fileselect = display.create(ui.save.root, display.OBJ_EDIT_OPTION, 200, 20, "File Selection", "1 to 5", "1", "2", "3", "4", "5")
	ui.save.save = display.create(ui.save.root, display.OBJ_BUTTON, 400, 20, "Save Settings")
	display.setevent(ui.save.save, display.EVENT_PRESS, 'save_version_strings() sync_ui_to_data(ui_data_event_table) save_to_file(SAVED_SETUP_BASE_FILENAME..(display.getvalue(ui.save.fileselect))..".settings", data, SAVED_SETUP_BASE_FILENAME)')
	
	--Create ui.load controls
	ui.load.fileselect = display.create(ui.load.root, display.OBJ_EDIT_OPTION, 200, 20, "File Selection", "1 to 5", "1", "2", "3", "4", "5")
	ui.load.load = display.create(ui.load.root, display.OBJ_BUTTON, 400, 20, "Load Settings")
	display.setevent(ui.load.load, display.EVENT_PRESS, 'load_from_file(SAVED_SETUP_BASE_FILENAME..(display.getvalue(ui.load.fileselect))..".settings", data, SAVED_SETUP_BASE_FILENAME) sync_data_to_ui(ui_data_event_table)')
	
end

local function create_global_tables()
	--NOTE: Use find and replace when changing *.value strings to avoid breaking lookups
	
	STATS = {
		value = {"Average", "Median", "Stddev", "Test t"},
		func = {get_mean, get_median, get_stddev, get_time}
	}
	
	ONOFF_TYPE = {value = {"On", "Off"}}
	
	if localnode.model == "2450" then
		I_RANGES = {
			value = {"10\21nA", "100\21nA", "1\21\20A", "10\21\20A", "100\21\20A", "1\21mA", "10\21mA", "100\21mA", "1\21A"},
			range = {10e-9, 100e-9, 1e-6, 10e-6, 100e-6, 1e-3, 10e-3, 100e-3, 1},
			v_limit = {210, 210, 210, 210, 210, 210, 210, 210, 21}
		}
		V_RANGES = {
			value = {"20\21mV", "200\21mV", "2\21V", "20\21V"},
			range = {20e-3, 200e-3, 2, 20},
			i_limit = {1.05, 1.05, 1.05, 1.05}
		}
	elseif localnode.model == "2460" or localnode.model == "2461" then
		I_RANGES = {
			value = {"1\21\20A", "10\21\20A", "100\21\20A", "1\21mA", "10\21mA", "100\21mA", "1\21A", "4\21A", "5\21A", "7\21A"},
			range = {1e-6, 10e-6, 100e-6, 1e-3, 10e-3, 100e-3, 1, 4, 5, 7},
			v_limit = {105, 105, 105, 105, 105, 105, 105, 21, 10.5, 7.35}
		}
		V_RANGES = {
			value = {"200\21mV", "2\21V", "7\21V", "10\21V", "20\21V"},
			range = {200e-3, 2, 7, 10, 20},
			i_limit = {7.35, 7.35, 7.35, 5.25, 4.2}
		}
	end
end

function init_toplevel()
	verify_requirements()
	
	ui = { }
	ui_data_event_table = { }
	data = { }
	--instr.digitize.func = instr.FUNC_DIGITIZE_CURRENT
	
	--[[if buf == nil then
		collectgarbage()
		buf = buffer.make(0.5e6)--, buffer.STYLE_COMPACT)
		buf2 = buffer.make(9.5e6)
		buf.fillmode = buffer.FILL_CONTINUOUS
	end
	defbuffer2.capacity = 10
	defbuffer1.capacity = 10
	]]
	create_global_tables()
	--create_top_screens()
	--create_loading_screen()
	--create_top_controls()
	--update_stats()
	
	--destroy_loading_screen()
end

local function main()
	verify_requirements()
	
	if not EC_Images then
		if fs.is_file("/usb1/EC_Images.tsp") then
			EC_Images = script.load("/usb1/EC_Images.tsp")
		end
	end
	if EC_Images then
		EC_Images.run()
	else
		print("Unable to load EC_Images.tsp!")
		display.input.prompt(display.BUTTONS_OK, "Unable to load EC_Images.tsp!")
		exit()
	end
	
	if EC_IMAGES_VERSION < MIN_EC_IMAGES_VERSION then
		print("EC_Images version "..MIN_EC_IMAGES_VERSION.." or greater required, please update.")
		display.input.prompt(display.BUTTONS_OK, "EC_Images version "..MIN_EC_IMAGES_VERSION.." or greater required, please update.")
		exit()
	end
	
	init_toplevel()
	print("EC Framework v"..EC_FRAMEWORK_VERSION.." loaded!")
end
main()