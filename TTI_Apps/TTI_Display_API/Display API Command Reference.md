<h1>TSP Display API Command Reference</h1>

This file serves as a command reference and appendix for the [TTI Display API](README.md).
You should read that document first and use it in tandem with this reference.

# Table of Contents

- [Table of Contents](#table-of-contents)
- [General Programming Notes](#general-programming-notes)
- [General Commands](#general-commands)
  - [display.changescreen()](#displaychangescreen)
  - [display.clear()](#displayclear)
  - [display.delete()](#displaydelete)
  - [display.format()](#displayformat)
  - [display.getvalue()](#displaygetvalue)
  - [display.prompt()](#displayprompt)
  - [display.waitevent()](#displaywaitevent)
- [Input Commands](#input-commands)
  - [display.input.number()](#displayinputnumber)
  - [display.input.option()](#displayinputoption)
  - [display.input.prompt()](#displayinputprompt)
  - [display.input.string()](#displayinputstring)
- [Graph Commands](#graph-commands)
  - [display.graph.add()](#displaygraphadd)
  - [display.graph.cursor()](#displaygraphcursor)
  - [display.graph.drawstyle()](#displaygraphdrawstyle)
  - [display.graph.markerlastcolor()](#displaygraphmarkerlastcolor)
  - [display.graph.markersize()](#displaygraphmarkersize)
  - [display.graph.removeall()](#displaygraphremoveall)
  - [display.graph.scaletrace()](#displaygraphscaletrace)
  - [display.graph.scalex()](#displaygraphscalex)
  - [display.graph.scaley()](#displaygraphscaley)
  - [display.graph.select()](#displaygraphselect)
- [Create Commands](#create-commands)
  - [display.create(): Button object](#displaycreate-button-object)
  - [display.create(): Circle object](#displaycreate-circle-object)
  - [display.create(): Edit Buffer object](#displaycreate-edit-buffer-object)
  - [display.create(): Edit Channel object](#displaycreate-edit-channel-object)
  - [display.create(): Edit Check object](#displaycreate-edit-check-object)
  - [display.create(): Edit Number object](#displaycreate-edit-number-object)
  - [display.create(): Edit Option object](#displaycreate-edit-option-object)
  - [display.create(): Edit Slider object](#displaycreate-edit-slider-object)
  - [display.create(): Edit String object](#displaycreate-edit-string-object)
  - [display.create(): Graph object](#displaycreate-graph-object)
  - [display.create(): Home Screen object](#displaycreate-home-screen-object)
  - [display.create(): Image object](#displaycreate-image-object)
  - [display.create(): Line object](#displaycreate-line-object)
  - [display.create(): List object (v1.7+)](#displaycreate-list-object-v17)
  - [display.create(): Menu Button object](#displaycreate-menu-button-object)
  - [display.create(): Menu Screen object](#displaycreate-menu-screen-object)
  - [display.create(): Popup Menu Screen object](#displaycreate-popup-menu-screen-object)
  - [display.create(): Progress Bar object](#displaycreate-progress-bar-object)
  - [display.create(): Rectangle object](#displaycreate-rectangle-object)
  - [display.create(): Screen object](#displaycreate-screen-object)
  - [display.create(): Swipe object](#displaycreate-swipe-object)
  - [display.create(): Text object](#displaycreate-text-object)
  - [display.create(): Timer object](#displaycreate-timer-object)
- [Set Commands](#set-commands)
  - [display.setabbrv()](#displaysetabbrv)
  - [display.setcell()](#displaysetcell)
  - [display.setcolor()](#displaysetcolor)
  - [display.setevent()](#displaysetevent)
  - [display.setfill()](#displaysetfill)
  - [display.setfont()](#displaysetfont)
  - [display.setknobaction() (v1.7.1+)](#displaysetknobaction-v171)
  - [display.setminmax()](#displaysetminmax)
  - [display.setpopupmenu() (v1.7.1+)](#displaysetpopupmenu-v171)
  - [display.setposition()](#displaysetposition)
  - [display.setstate()](#displaysetstate)
  - [display.settext()](#displaysettext)
  - [display.setthickness()](#displaysetthickness)
  - [display.setvalue()](#displaysetvalue)
    - [display.setvalue: Progress Bar](#displaysetvalue-progress-bar)

# General Programming Notes

In places within this file, you will see "(v1.x+)", this means the command only works with firmware versions greater than v1.x.

User supplied parameters to functions are specified as "inputs" in the form \<input\>, optional inputs are denoted as \[\<optional input\>\]. Where inputs have defaults, they are noted as \<input\> = default value. 



# General Commands

## display.changescreen()
display.changescreen(\[\<object id\>\])

| Input | Description |
| --| --|
| [\<object id\>] | object ID of display.OBJ_SCREEN_HOME, display.OBJ_SCREEN, display.OBJ_SCREEN_MENU; can be any built-in screen, see note.  |

- **NOTE:** The full list of built-in screens: 
    - display.SCREEN_APPS
    - display.SCREEN_CHANNEL_CONTROL (65xx only)
    - display.SCREEN_CHANNEL_SCAN (65xx only)
    - display.SCREEN_CHANNEL_SETTINGS (65xx only)
    - display.SCREEN_CHANNEL_SWIPE (65xx only)
    - display.SCREEN_FUNCTIONS_SWIPE (65xx/75xx only)
    - display.SCREEN_GRAPH
    - display.SCREEN_GRAPH_SWIPE
    - display.SCREEN_HISTOGRAM
    - display.SCREEN_HOME
    - display.SCREEN_HOME_LARGE_READING
    - display.SCREEN_MEAS_CALCULATIONS
    - display.SCREEN_MEAS_CONFIG_LISTS (65xx only)
    - display.SCREEN_MEAS_RBUFFERS
    - display.SCREEN_MEAS_SETTINGS
    - display.SCREEN_MENU
    - display.SCREEN_NONSWITCH_SWIPE (65xx only)
    - display.SCREEN_PROCESSING
    - display.SCREEN_QUICKSET
    - display.SCREEN_READING_TABLE
    - display.SCREEN_SCAN_SWIPE (65xx only)
    - display.SCREEN_SCRIPT_CREATE
    - display.SCREEN_SCRIPT_MANAGE
    - display.SCREEN_SCRIPT_RECORD
    - display.SCREEN_SCRIPT_RUN
    - display.SCREEN_SECONDARY_SWIPE (65xx/75xx only)
    - display.SCREEN_SETTINGS_SWIPE
    - display.SCREEN_SOURCE_CONFIG_LIST (24xx only)
    - display.SCREEN_SOURCE_PULSE (2461 only)
    - display.SCREEN_SOURCE_SETTINGS (24xx only)
    - display.SCREEN_SOURCE_SWEEP (24xx only)
    - display.SCREEN_SOURCE_SWIPE (24xx only)
    - display.SCREEN_STATS_SWIPE
    - display.SCREEN_SYS_CALIBRATION
    - display.SCREEN_SYS_COMMUNICATION
    - display.SCREEN_SYS_EVENT_LOG
    - display.SCREEN_SYS_INFO_MANAGE
    - display.SCREEN_SYS_SETTINGS
    - display.SCREEN_TRIG_CONFIGURE
    - display.SCREEN_TRIG_TEMPLATE
    - display.SCREEN_USER_SWIPE


- [Return to ToC](#table-of-contents)

## display.clear()
display.clear(\[\<id\>\])

| Input | Description |
| --| --|
| [\<object ID\>] | Object ID to be removed, one of display.OBJ\_SCREEN\_HOME, display.OBJ\_SCREEN, display.OBJ\_SCREEN\_MENU, display.OBJ\_TEXT |

- Returns:

- none

- **NOTE:** Clearing the home screen removes all the swipes

- **NOTE:** This command applies only to TEXT objects and custom screens


- [Return to ToC](#table-of-contents)

## display.delete()
display.delete(\<object id\>)

| Input | Description |
| --| --|
| \<object ID\> | Object ID of object to remove (all types) |

- Returns:

- none

- **NOTE:** If pre-created screen, the menu entry will be removed

- **NOTE:** If created object, that object will be removed

- [Return to ToC](#table-of-contents)

## display.format()
\<string\> = display.format(\<value\>, "\<unit\>", \<nformat\>, \<digits\>, \[\<range\>\])

| Input | Description |
| --| --|
| \<value\> |  number |
| \<unit\> | String of 3 or less characters |
| \<nformat\> | Specifies a formatting flag(s), see note |
| \<digits\> = 6 | Total number of displayed digits (4-9) |
| \[\<range\>\] | specifies the range formatter used, see note |

- Returns:

- \<string\>

- **NOTE:** valid formatting flags for \<nformat\> are:

| Flag | Affect |
| --| --|
| display.NFORMAT\_PREFIX | prefix only, don't follow user setting |
| display.NFORMAT\_EXPONENT | exponent only, don't follow user setting |
| display.NFORMAT\_DECIMAL | decimal only, don't follow user setting |
| display.NFORMAT\_INTEGER | integer only, don't follow user setting (must be between -2^31 and +2^31) |
| display.NFORMAT\_USER | Copy user setting |
| |
| The following options cannot be used by themselves, but may be OR'd in (using the '|' symbol) |
| display.NFORMAT\_NO\_UNIT\_SPACE | Use shorter x.xxxU |
| display.NFORMAT\_SHOW\_POSITIVE | Show + |

- **NOTE:** valid \<range\> flags are:
  - buffer.RANGE\_10T
  - buffer.RANGE\_1T
  - buffer.RANGE\_100G
  - buffer.RANGE\_10G
  - buffer.RANGE\_1G
  - buffer.RANGE\_100M
  - buffer.RANGE\_10M
  - buffer.RANGE\_1M
  - buffer.RANGE\_100k
  - buffer.RANGE\_10k
  - buffer.RANGE\_1k
  - buffer.RANGE\_100
  - buffer.RANGE\_10
  - buffer.RANGE\_1
  - buffer.RANGE\_100m
  - buffer.RANGE\_10m
  - buffer.RANGE\_1m
  - buffer.RANGE\_100u
  - buffer.RANGE\_10u
  - buffer.RANGE\_1u
  - buffer.RANGE\_100n
  - buffer.RANGE\_10n
  - buffer.RANGE\_1n

- [Return to ToC](#table-of-contents)

## display.getvalue()
\<value\> = display.getvalue(\<id\>)

| Input | Description |
| --| --|
| \<id\> | Object ID, see note |

- Returns:

- \<value\>

- **NOTE:** Allowable object id's for \<id\> are:

    - display.OBJ\_EDIT\_NUMBER
    - display.OBJ\_EDIT\_CHECK
    - display.OBJ\_EDIT\_STRING
    - display.OBJ\_EDIT\_OPTION
    - display.OBJ\_EDIT\_SLIDER
    - display.OBJ\_LIST

- **NOTE:** \<value\> is either a decimal number, string, checkbox (display.ON, display.OFF), or a 1-based index for options

- [Return to ToC](#table-of-contents)

## display.prompt()
\<object ID\> = display.prompt(\<buttons\>, "\<string\>")

| Input | Description |
| --| --|
| \<buttons\> | See note |
| \<string\> | The string to display in the dialog |

- Returns:

- \<object ID\>

- **NOTE:** valid \<buttons\> objects are:

    - display.BUTTONS\_NONE
    - display.BUTTONS\_OK
    - display.BUTTONS\_CANCEL
    - display.BUTTONS\_OKCANCEL
    - display.BUTTONS\_YESNO
    - display.BUTTONS\_YESNOCANCEL

- [Return to ToC](#table-of-contents)

## display.waitevent()
\<object id\>, \<sub id\> = display.waitevent(\[\<timeout\>\])

| Input | Description |
| --| --|
| [\<timeout\>] | Number of seconds to wait for an event, forever if not specified |

- Returns:

- \<object id\> = The object from which the event was generated

- \<sub\_ID\> = The type of event generated:
    - for display.input.\* 
      - display.BUTTON\_OK
      - display.BUTTON\_CANCEL
      - display.BUTTON\_YES
      - display.BUTTON\_NO
      - display.BUTTON\_OPTION1
      - display.BUTTON\_OPTION2
      - display.BUTTON\_OPTION3
      - display.BUTTON\_OPTION4
      - display.BUTTON\_OPTION5
      - display.BUTTON\_OPTION6
      - display.BUTTON\_OPTION7
      - display.BUTTON\_OPTION8
      - display.BUTTON\_OPTION9
      - display.BUTTON\_OPTION10)
    - for display.OBJ\_BUTTON 
      - display.BUTTON\_SELF
    - for display.OBJ\_BUTTON\_MENU 
      - display.BUTTON\_SELF
    - for display.OBJ\_EDIT\_SLIDER 
      - display.BUTTON\_OK (release)
      - display.BUTTON\_SELF (drag)
    - for all display.OBJ\_EDIT\_\* 
      - display.BUTTON\_OK

- **NOTE:** Use [display.setevent()](#displaysetevent) to turn events on or off

- [Return to ToC](#table-of-contents)

# Input Commands

These commands are already defined in your instrument's reference manual, but they are included here since they're often useful in Apps. 

- [Return to ToC](#table-of-contents)

## display.input.number()
\<sub id\> = display.input.number(\<title\>, \[\<format\>, \[\<default\>, \[\<min\>, \[\<max\>, \[\<unit\>\]\]\]\]\])
- See Reference manual


- [Return to ToC](#table-of-contents)

## display.input.option()
\<sub id\> = display.input.option(\<title\>, \<option1\>, \<option2\>, \[\<option3\>, ... \[\<option10\>\]\])

- See Reference manual for this syntax

\<channel\_list\> = display.input.option(\[\<channel\_subtype\>\])

| Input | Description |
| --| --|
| \[\<channel\_subtype\>\] | Channel type, see note |

- Returns:

- \<channel\_list\>

- **NOTE:** valid \<channel\_subtype\>s are:
    - channel.TYPE\_SWITCH
    - channel.TYPE\_BACKPLANE
    - channel.TYPE\_DIGITAL
    - channel.TYPE\_TOTALIZER
    - channel.TYPE\_DAC
    - channel.TYPE\_RADIO
    - channel.TYPE\_POLE

- **NOTE:** \<channel\_list\> is the string list specifying the channels selected.


- [Return to ToC](#table-of-contents)

## display.input.prompt()
\<sub id\> = display.input.prompt(\<buttons\>, "\<string\>")
- See Reference manual

- [Return to ToC](#table-of-contents)

## display.input.string()
\<sub id\> = display.input.string("\<title\>", \[\<format\>\])
- See Reference manual

# Graph Commands

The commands manipulate graph objects. Many of them work equivalently on the system graph screen. 

- [Return to ToC](#table-of-contents)

## display.graph.add()
display.graph.add(\<id\>)

display.graph.add(\<id\>, \<buffer1 name\>, \<element1\>, \<channel1\>, \[\<buffer2 name\>, \[\<element2\>, \[\<channel2\>\]\]\])

display.graph.add(\<id\>, \<buffer1 name\>, \[\<element1\>\], \[\<buffer2 name\>\], \[\<element2\>\])

| Input | Description |
| --| --|
| \<id\> | Object ID to place graph, see note |
| \<reading buffer\> | The reading buffer to be ploted |
| [\<element\>] | The piece of the reading buffer, see note |
| [\<reading buffer2\>] | X axis reading bugger name (defaults to same buffer as Y) |
| [\<element 2\>] | X axis reading buffer element, see note |

- Returns:

- None

- **NOTE:** use display.SCREEN\_GRAPH or API created graph as \<id\>

- **NOTE:** valid graph elements are:

    - display.ELEMENT\_DATA
    - display.ELEMENT\_EXTRA
    - display.ELEMENT\_SOURCE
    - display.ELEMENT\_TIME

- **NOTE:** \<element 2\> defaults to EXTRA when the reading buffer is FULL, WRITABLE\_FULL, or STANDARD on SMUs, otherwise defaults to TIME)

- **NOTE:** Adding a second trace which conflicts with first will error. For example, plotting by time and adding a trace configured for value by value. The graph type is driven by the first added trace.

**EXAMPLES:**
| Syntax | Outcome |
| --| --|
| display.graph.add(graph, defbuffer1) | defines an IV plot on SMUs<br>defines a time plot on DMMs |
| display.graph.add(graph, defbuffer1, display.ELEMENT\_DATA, defbuffer1. display.ELEMENT\_TIME) | defines a time plot on SMUs |
| display.graph.add(graph, defbuffer1) | defines an IV plot on writable buffer |
| display.graph.add(graph, defbuffer1, display.ELEMENT\_DATA, defbuffer1. display.ELEMENT\_TIME) | defines a time plot on writeable buffer |

- [Return to ToC](#table-of-contents)

## display.graph.cursor()
\<value1\>, \<value2\> = display.graph.cursor(\<id\>, \<cursor\>, \[\<value1\>, \<value2\>\])

| Input | Description |
| --| --|
| \<id\> | Object ID, see note |
| \<cursor\> | Cursor style, see note |
| [\<value 1\>] | is the position of cursor1 or 9.9e37 to turn it off (or is off) |
| [\<value 2\>] | is the position of cursor2 or 9.9e37 to turn it off (or is off) |

- Returns:

- \<value 1\>

- \<value 2\>

- **NOTE:** use display.SCREEN\_GRAPH or API created graph id as \<id\>

- **NOTE:** valid \<cursor\> styles are:
  - display.CURSOR\_HORIZONTAL
  - display.CURSOR\_VERTICAL
  - display.CURSOR\_TRIGGER

- **NOTE:** there really isn't a 1/2 or left/right. \<value1\> should be less than \<value2\> otherwise they will automatically be reversed.

- **NOTE:** trigger level lines will only be displayed with a single trace.

- [Return to ToC](#table-of-contents)

## display.graph.drawstyle()
display.graph.drawstyle(\<id\>, \<style\>)

| Input | Description |
| --| --|
| \<id\> | Object ID, see note |
| \<style\> | Drawing style, see note |

- Returns:

- none

- **NOTE:** use display.SCREEN\_GRAPH or API created graph id as \<id\>

- **NOTE:** valid drawing styles are:
    - display.STYLE\_LINE
    - display.STYLE\_MARKER
    - display.STYLE\_BOTH

- [Return to ToC](#table-of-contents)

## display.graph.markerlastcolor()
display.graph.markerlastcolor(\<id\>, \<color type\>, \[\<custom color\>\])

| Input | Description |
| --| --|
| \<id\> | Object ID of display.SCREEN _GRAPH or created graph |
| \<color type\> = display.MARKER_LAST_TRACE | color of the last marker<br>display.MARKER_LAST_TRACE (last marker matches the trace color)<br>display.MARKER_LAST_CUSTOM (the last marker appears in a custom color regardless of trace color) |
| [\<custom color\>] = Magenta | Must specify \<color type\> as display.MARKER\_LAST\_CUSTOM and then specify \<custom color\> as the desired color in the following format<br>Uses the same format of [other colors](README.md#colors).  Once the custom color is specified it remains the custom color setting until changed.  Therefore, if you desire to toggle last marker color between trace and custom, just use the first 2 parameters and set color type accordingly for trace or custom color. |

- **NOTE:** These last color marker settings apply to active trace only. As the active trace changes, these settings get applied to the new active trace.

- [Return to ToC](#table-of-contents)

## display.graph.markersize()
display.graph.markersize(\<id\>, \<size\>, \[\<last marker size\>\])

| Input | Description |
| --| --|
| \<id\> | Object ID of display.SCREEN _GRAPH or created graph |
| \<size\> = 1 | radius of the marker, valid values are 1 to 5. Markers appear as they do in built in graph. Values 2 to 5 change them to be circular markers with value representing the radius of the circular markers. |
| [\<last marker size\>] = 1 OR whatever \<size\> is | size of the most recent data point |

- **NOTE:** These marker size settings apply to active trace only.  As active trace changes, these settings get applied to the new active trace.

- [Return to ToC](#table-of-contents)

## display.graph.removeall()
display.graph.removeall(\<id\>)

| Input | Description |
| --| --|
| \<id\> | Object ID to be removed |

- Returns:

- None

- **NOTE:** use display.SCREEN\_GRAPH or API created graph id as \<id\>

- [Return to ToC](#table-of-contents)

## display.graph.scaletrace()
display.graph.scaletrace(\<id\>, \<trace\>)

| Input | Description |
| --| --|
| \<id\> | Object ID, see note |
| \<trace\> = display.TRACE_ACTIVE | display.TRACE_ALL (have all traces be synced and use the same scale settings for all traces being viewed on graph. As scale settings for X and Y change they will get applied to all traces)<br>display.TRACE_ACTIVE (only the active trace get updated as the X and Y scale settings change unless the scale setting already indicates that more that one trace gets changed based on that selection.) |

- **NOTE:** This command will only work on custom created graphs and will error if try to use with the built in system graph (display.SCREEN_GRAPH). The system graph always uses display.TRACE_ACTIVE.

- [Return to ToC](#table-of-contents)

## display.graph.scalex()
\[\<x\_min position\>, \<x\_max position \> =\] display.graph.scalex(\<id\>, \[\<x scale method\>, \[\<x axis type\>, \[\<x min position\>, \[\<x max position\>\]\]\]\])

| Input | Description |
| --| --|
| \<id\> | Object ID, see note |
| [\<x scale method\>] | Method to use when scaling, see note |
| [\<x axis type\>] | Is display.AXIS\_NORMAL or display.AXIS\_LOG |
| [\<x min position\>] | Number of the minimum position |
| [\<x max position\>] | Number of the maximum position. When not specified, the current span is kept and the graph is translated to the new minimum position |

- Returns:

- [\<x min position\>]

- [\<x max position\>]

- **NOTE:** return values are only valid when the objects event generation is set to ALL and the only argument passed in is the id (for example, "min, max = display.graph.scalex(\<id\>)").
- **NOTE:** use display.SCREEN\_GRAPH or API created graph id as \<id\>

- **NOTE:** valid scale methods are:
    - display.XSCALE\_SMART
    - display.XSCALE\_LATEST
    - display.XSCALE\_GROUP
    - display.XSCALE\_ALL
    - display.XSCALE\_AUTOBIN
    - display.XSCALE\_OFF

- **NOTE:** positions apply to selected trace only for multitrace

- [Return to ToC](#table-of-contents)

## display.graph.scaley()
\[\<x\_min position\>, \<x\_max position \> =\] display.graph.scaley(\<id\>, \[\<y scale method\>, \[\<y axis type\>, \[\<y min position\>, \[\<y max position\>\]\]\]\])

| Input | Description |
| --| --|
| \<id\> | Object ID, see note |
| [\<y scale method\>] | Method to use when scaling, see note |
| [\<y axis type\>] | is display.AXIS\_NORMAL, display.AXIS\_LOG |
| [\<y min position\>] | Number for the minimum position |
| [\<y max position\>] | Number of the maximum position. When not specified, the current span is kept and the graph is translated to the new minimum position |

- Returns:

- [\<y min position\>]

- [\<y max position\>]

- **NOTE:** return values are only valid when the objects event generation is set to ALL and the only argument passed in is the id (for example, "min, max = display.graph.scaley(\<id\>)").

- **NOTE:** use display.SCREEN\_GRAPH or API created graph id as \<id\>

- **NOTE:** valid scale methods are:
    - display.YSCALE\_SMART
    - display.YSCALE\_PER\_TRACE
    - display.YSCALE\_ALL
    - display.YSCALE\_SWIM
    - display.YSCALE\_SHARED
    - display.YSCALE\_OFF

- **NOTE:** positions apply to selected trace only for multitrace

- [Return to ToC](#table-of-contents)

## display.graph.select()
display.graph.select(\<id\>, \<buffer name\>, \[\<element1\>\], \[\<channel\>\])

| Input | Description |
| --| --|
| \<id\> | Object ID, see note |
| \<reading buffer\> | The reading buffer to select |

- Returns:

- none

- **NOTE:** use display.SCREEN\_GRAPH or API created graph id as \<id\>

- **NOTE:** \<element\> is the piece of the reading buffer:
  - display.ELEMENT\_DATA
  - display.ELEMENT\_EXTRA
  - display.ELEMENT\_SOURCE
  - display.ELEMENT\_TIME)

- **NOTE:** \<channel\> is a valid channel number

- **NOTE:** This is equivalent to the colored button in the graph swipe. 

- [Return to ToC](#table-of-contents)

# Create Commands

This section documents the various objects that can be created with display.create(). They all share the first 2 inputs: the \<parent id\> of the host object, and the display.OBJ_... name of the object being created.

## display.create(): Button object
\<object id\> = display.create(\<parent id\>, display.OBJ\_BUTTON, \<x\>, \<y\>, "\<text\>", \[\<width\>\])

| Input | Description |
| --| --|
| \<parent id\> | Parent id, see note |
| display.OBJ\_BUTTON | |
| \<x\> | Position of top left corner |
| \<y\> | |
| \<text\> | String to display in the button |
| \[\<width\>\] = Dynamic | button width where 0 \< width \<= 799 AND width \<= 799 - x |

- Returns:

- \<object ID\>

![Button object](/.github/media/image3.png)

- For convenience, button objects default their Press events to on.

- **NOTE:** valid parent id's are:
    - display.OBJ\_SWIPE
    - display.OBJ\_SCREEN
    - display.OBJ\_SCREEN\_HOME
    - display.OBJ\_SCREEN\_MENU

- [Return to ToC](#table-of-contents)

## display.create(): Circle object
\<object id\> = display.create(\<parent id\>, display.OBJ\_CIRCLE, \<x\>, \<y\>, \<radius\>)

| Input | Description |
| --| --|
| \<parent id\> | Parent ID, see note |
| display.OBJ\_CIRCLE | |
| \<x\> | X Coordinate of center |
| \<y\> | Y Coordinate of center |
| \<radius\> | Radius of the circle (must fit within screen) |

- Returns:

- \<object ID\>

![Circle object](/.github/media/image12.png)

- **NOTE:** valid parent id's are:
    - display.OBJ\_SWIPE
    - display.OBJ\_SCREEN
    - display.OBJ\_SCREEN\_HOME
    - display.OBJ\_SCREEN\_MENU


- [Return to ToC](#table-of-contents)

## display.create(): Edit Buffer object
\<object id\> = display.create(\<parent id\>, display.OBJ\_EDIT\_BUFFER, \<x\>, \<y\>, "\<label\>", "\<short\_description\>", \[\<flags\>\])

| Input | Description |
| --| --|
| \<parent id\> | See note |
| display.OBJ\_EDIT\_BUFFER | |
| \<x\> | |
| \<y\> | |
| \<label\> | String for label text |
| \<short\_description\> | string for the description text shown next to the object | 
| [\<flags\>] | special behavior, see note |

- Returns:

- \<object ID\>

- **NOTE:** valid parent id's are:
    - display.OBJ\_SWIPE
    - display.OBJ\_SCREEN
    - display.OBJ\_SCREEN\_HOME
    - display.OBJ\_SCREEN\_MENU

- **NOTE:** valid options for \<flags\> are:
    - display.RBUFF\_ADD\_CREATE (adds a create buffer option to bottom of list)
    - display.RBUFF\_ADD\_ACTIVE (adds the default buffer to edit button as the active buffer)


- [Return to ToC](#table-of-contents)

## display.create(): Edit Channel object
\<object id\> = display.create(\<parent id\>, display.OBJ\_EDIT\_CHANNEL, \<x\>, \<y\>, "\<label\>", "\<short\_description\>", \[\<channels\_selectable\>\], \[\<max\_selected\>\])

| Input | Description |
| --| --|
| \<parent id\> | See note |
| display.OBJ\_EDIT\_CHANNEL | |
| \<x\> | |
| \<y\> | |
| \<label\> | string for the label text |
| \<help\> | string for the description text shown next to the object |
| \[\<channels selectable\>\] | allows the user to allow only certain channels to be selected, see note | 
| \[\<max\_selected\>\] | restricts the number of channels that may be selected and press OK without error. If 1, only 1 channel may be selected. If 2, only 1 or 2 channels may be selected, etc. |

- Returns:

- \<object ID\>

- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- **NOTE:** \<channels selectable\> follows this syntax:
  - a CHAN\_TYPE should be bitwise or’d with a CHAN\_STYPE like so: 
    - `display.CHAN_TYPE_SWITCH | display.CHAN_STYPE_VOLTAGE` (only allows switch channels that can measure voltage to be selectable)
    - `display.CHAN_TYPE_SWITCH | display.CHAN_STYPE_AMP` (only allows switch channels that can measure current to be selectable)
  - CHAN\_TYPES:
    - display.CHAN\_TYPE\_ALL
    - display.CHAN\_TYPE\_BACKPLANE
    - display.CHAN\_TYPE\_DIGITAL
    - display.CHAN\_TYPE\_DAC
    - display.CHAN\_TYPE\_POLE
    - display.CHAN\_TYPE\_SWITCH
    - display.CHAN\_TYPE\_RADIO
    - display.CHAN\_TYPE\_TOTALIZER
  - CHAN\_STYPES:
    - display.CHAN\_STYPE\_VOLTAGE
    - display.CHAN\_STYPE\_AMP
    - display.CHAN\_STYPE\_ISOLATED
    - display.CHAN\_STYPE\_MATRIX
  - Can also bitwise or additional options:
    - display.CHAN\_SELECT\_NEED\_ALL (displays the "All" checkbox selector above the channel selectors which allows all channels to be selected at once)
    - display.CHAN\_SELECT\_ALLOW\_NONE (allows no channels to be selected and press OK without erroring)

- [Return to ToC](#table-of-contents)

## display.create(): Edit Check object
\<object id\> = display.create(\<parent id\>, display.OBJ\_EDIT\_CHECK, \<x\>, \<y\>, "\<label\>", "\<short\_description\>", \[\<default\>\])

| Input | Description |
| --| --|
| \<parent id\> | See note |
| Display.OBJ\_EDIT\_CHECK | |
| \<x\> | |
| \<y\> | |
| \<label\> | string for the label text |
| \<short\_description\> | string for the description text shown next to the object |
| [\<default\>] | Default state (0 or 1) |

- Returns:

- \<object ID\>

![Edit Check object](/.github/media/image8.png)

- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- [Return to ToC](#table-of-contents)

## display.create(): Edit Number object
\<object id\> = display.create(\<parent id\>, display.OBJ\_EDIT\_NUMBER, \<x\>, \<y\>, "\<label\>", "\<short\_description\>", \[\<nformat\>, \[\<default\>, \[\<min\>, \[\<max\>, \["\<unit\>", \[\<digits\>\]\]\]\]\])

| Input | Description |
| --| --|
| \<parent id\> | see note |
| display.OBJ\_EDIT\_NUMBER | |
| \<x\> | |
| \<y\> | |
| \<label\> | String for label text |
| \<short\_description\> | String for the description text shown next to the object |
| [\<nformat\>] | One or multiple formatting flags, see note |
| [\<default\>] = 0 | Default value to be displayed |
| [\<min\>] = -1e99 | Minimum allowed value |
| [\<max\>] = 1e99 | Maximum allowed value |
| [\<unit\>] | A string of up to 3 characters |
| [\<digits\>] = 6 | Number of digits to display (4-9) |

- Returns:

- \<object ID\>

![Edit Number object](/.github/media/image5.png)

- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- **NOTE:** valid formatting flags for \<nformat\> are:

| display.NFORMAT\_PREFIX | prefix only, don't follow user setting |
| --| --|
| display.NFORMAT\_EXPONENT | exponent only, don't follow user setting |
| display.NFORMAT\_DECIMAL | decimal only, don't follow user setting |
| display.NFORMAT\_INTEGER | integer only, don't follow user setting (must be between -2^31 and +2^31) |
| display.NFORMAT\_USER | Copy user setting |
| |
| The following options cannot be used by themselves, but may be OR'd in (using the '\|' symbol) |
| display.NFORMAT\_NO\_UNIT\_SPACE | Use shorter x.xxxU |
| display.NFORMAT\_SHOW\_POSITIVE | Show + |

- [Return to ToC](#table-of-contents)

## display.create(): Edit Option object
\<object id\> = display.create(\<parent id\>, display.OBJ\_EDIT\_OPTION, \<x\>, \<y\>, "\<label\>", "\<short\_description\>",  \<option1\>", "\<option2\>", \["\<option3\>", ... \["\<option10\>"\]\])

| Input | Description |
| --| --|
| \<parent id\> | See note |
| display.OBJ\_EDIT\_OPTION | |
| \<x\> | |
| \<y\> | |
| \<label\> | |
| \<help\> | |
| \<option1\> | String for option 1 label |
| \<option2\> | String for option 2 label |
| [\<optionN\>] | String for option N label (up to 10 total options) |

- Returns:

- \<object ID\>

![Edit Option object](/.github/media/image6.png)

- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- [Return to ToC](#table-of-contents)

## display.create(): Edit Slider object
\<object id\> = display.create(\<parent id\>, display.OBJ\_EDIT\_SLIDER, \<x\>, \<y\>, \<length\>, "\<label\>", \[\<orient\>, \[\<min tick\>, \[\<max tick\>, \[\<num positions\>, \[\<default\>\]\]\]\]\])

| Input | Description |
| --| --|
| \<parent id\> | See note |
| display.OBJ\_EDIT\_SLIDER | |
| \<x\> | |
| \<y\> | |
| \<length\> | |
| \<label\> | |
| [\<orient\>] = display.ORIENT_HORZ | Orientation, see note |
| [\<min tick\>] = 0 | Minimum entry value |
| [\<max tick\>] = 100 | Maximum entry value |
| [\<num positions\>] = 10 | Number of ticks on slider (including non-visible end ticks) |
| [\<default\>] = (max-min)/2 | Default value |

- Returns:

- \<object ID\>

![Horizontal Edit Slider object](/.github/media/image9.png)
![Vertical Edit Slider object](/.github/media/image10.png)

- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- **NOTE:** valid orientations for \<orient\> are:
  - display.ORIENT\_HORZ
  - display.ORIENT\_VERT

- **NOTE:** ticks will only be visible if \>10 pixels apart. If the number of ticks creates an interval of less than 3 pixels, the number of ticks will be adjusted to be equal to 3 pixels.

- [Return to ToC](#table-of-contents)

## display.create(): Edit String object
\<object id\> = display.create(\<parent id\>, display.OBJ\_EDIT\_STRING, \<x\>, \<y\>, "\<label\>", "\<short\_description\>", \[\<sformat\>\])

| Input | Description |
| --| --|
| \<parent id\> | See note |
| Display.OBJ\_EDIT\_STRING | |
| \<x\> | |
| \<y\> | |
| \<label\> | String for label text |
| \<short\_description\> | string for the description text shown next to the object |
| \[\<sformat\>\] | Specifies string formatting, see note |

- Returns:

- \<object ID\>

![Edit String object](/.github/media/image7.png)

- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- **NOTE:** valid string formats for \<sformat\> are:
  - display.SFORMAT\_ANY
  - display.SFORMAT\_UPPER\_LOWER
  - display.SFORMAT\_UPPER
  - display.SFORMAT\_BUFFER\_NAME
  - display.SFORMAT\_FILE\_NAME
  - display.SFORMAT\_IP\_ADDRESS

- [Return to ToC](#table-of-contents)

## display.create(): Graph object
\<object id\> = display.create(\<parent id\>, display.OBJ\_GRAPH, \<x\>, \<y\>, \<width\>, \<height\>)

| Input | Description |
| --| --|
| \<parent ID\> | Parent id, see note |
| display.OBJ\_GRAPH | |
| \<x\> | Coordinate of top left corner |
| \<y\> | |
| \<width\> | |
| \<height\> | |

- Returns:

- \<object ID\>

![Graph object](/.github/media/image16.png)

- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- [Return to ToC](#table-of-contents)

## display.create(): Home Screen object
\<object id\> = display.create(\<parent id\>, display.OBJ\_SCREEN\_HOME, \["\<title\>"\])

| Input | Description |
| --| --|
| display.ROOT | |
| Display.OBJ\_SCREEN\_HOME | |
| \<title\> = 'Home Screen' | String displayed at the top of the screen |

- Returns:

- \<object ID\>

- **NOTE:** Only 1 Home Screen object can exist at a time. It can be accessed from anywhere by pressing the HOME key on the instrument front panel. 

- [Return to ToC](#table-of-contents)

## display.create(): Image object
\<object id\> = display.create(\<parent id\>, display.OBJ\_IMAGE, \<x\>, \<y\>, "\<image name\>")

| Input | Description |
| --| --|
| \<parent ID\> | Parent id, see note |
| display.OBJ\_IMAGE | |
| \<x\> | Coordinate of top left corner |
| \<y\> | |
| \<image name\> | String of image name, specified in loadimage syntax |

- Returns:

- \<object ID\>

- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- **NOTE:** See the [API section on Images](README.md#images) for more info.

- [Return to ToC](#table-of-contents)

## display.create(): Line object
\<object id\> = display.create(\<parent id\>, display.OBJ\_LINE, \<x\>, \<y\>, \<x<sub>2</sub>\>, \<y<sub>2</sub>\>)

| Input | Description |
| --| --|
| \<parent id\> | Parent ID, see note |
| display.OBJ\_LINE | |
| \<x\> | Coordinate offset from parent |
| \<y\> | Coordinate offset from parent |
| \<x2\> | Coordinate offset from parent |
| \<y2\> | Coordinate offset from parent |

- Returns:

- \<object ID\>

- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- [Return to ToC](#table-of-contents)

## display.create(): List object (v1.7+)
\<object id\> = display.create(\<parent\_id\>, display.OBJ\_LIST, \<x\>, \<y\>, \<w\>, \<h\>, \[\<flags\>\])

| Input | Description |
| --| --|
| \<parent id\> | Parent id, see note |
| Display.OBJ\_LIST | The string to display in the dialog |
| \<x\> | |
| \<y\> | |
| \<width\> | |
| \<height\> | |
| \[\<flags\>] = none | Special behavior, see note |

- Returns:

- \<object ID\>

![Line object](/.github/media/image11.png)

- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- **NOTE:** valid \<flags\> are
  - display.LIST\_SELECT\_SINGLE – allow single selection
  - display.LIST\_SELECT\_MULTI – allow multi selection
  - display.LIST\_COLOR\_VALUES – color text to display.COLOR\_VALUE\_VALUE
  - display.LIST\_SELECT\_CELL – selection is per cell

- **Usage Notes:**
  - After the first row is populated with columns (using display.setcell()), no new columns may be added
  - display.setfont(\<list id\>, \<font\_id\>) – change text size of all text in list
  - display.setevent(\<object\_id\>)
  - \<r\>, \<c\> = display.getvalue(\<object\_id\>) – get row and column of user selection, indexed from 0
  - display.setcell(<object_id>, <row>, <column>, <string>) – see documentation
  - display.setcell(<object_id>, display.LIST_ROW_HEADER, <column>, <string>)
  - display.setcell(<object_id>, display.LIST_ROW_EMPTY, 1, <string>)

- **Example:**
````Lua
function update_text()
    display.settext(text1, tostring(display.getvalue(list2)))
end

id = display.create(display.ROOT, display.OBJ_SCREEN, "Test")
list2 = display.create(id, display.OBJ_LIST, 10, 220, 340, 160, display.LIST_SELECT_SINGLE)

-- add rows with text to list
display.setcell(list2, 1, 1, "Yello")
display.setcell(list2, 2, 1, "Toy")
display.setcell(list2, 3, 1, "Boy")

-- update the text with the row selected
text1 = display.create(id, display.OBJ_TEXT, 50, 50, "-1")
display.setevent(list2, display.EVENT_PRESS, "update_text()")
````

- [Return to ToC](#table-of-contents)

## display.create(): Menu Button object
\<object id\> = display.create(\<parent id\>, display.OBJ\_BUTTON\_MENU, \<col\>, \<row\>, \<goto id\>, \["\<text\> ", \["\<image name\>"\]\])

| Input | Description |
| --| --|
| \<parent id\> | Parent id, see note |
| display.OBJ\_BUTTON\_MENU | |
| \<col\> | Column of menu, 1-6, must be declared with Menu object |
| \<row\> | Row of menu, 1-4 |
| \<goto id\> | See note |
| \[\<text\>\] | Label of buttons |
| \[\<image name\>\] | String of image name specified with loadimage() |

- Returns:

- \<object ID\>

![Menu Button object](/.github/media/image4.png)

- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- **NOTE:** valid goto id's are:
  - id of user created .OBJ\_SCREEN\_\*
  - display.SCREEN\_GRAPH
  - display.SCREEN\_HISTOGRAM
  - display.SCREEN\_READING\_TABLE
  - display.SCREEN\_TRIG\_TEMPLATE
  - display.SCREEN\_TRIG\_CONFIGURE
  - display.SCREEN\_SCRIPT\_RUN
  - display.SCREEN\_SCRIPT\_MANAGE
  - display.SCREEN\_SCRIPT\_CREATE
  - display.SCREEN\_SCRIPT\_RECORD
  - display.SCREEN\_SYS\_EVENT\_LOG
  - display.SCREEN\_SYS\_COMMUNICATION
  - display.SCREEN\_SYS\_SETTINGS
  - display.SCREEN\_SYS\_CALIBRATION
  - display.SCREEN\_SYS\_INFO\_MANAGE
  - display.SCREEN\_QUICKSET
  - display.SCREEN\_MEAS\_SETTINGS
  - display.SCREEN\_MEAS\_CALCULATIONS
  - display.SCREEN\_MEAS\_CONFIG\_LISTS
  - display.SCREEN\_MEAS\_RBUFFERS

- [Return to ToC](#table-of-contents)

## display.create(): Menu Screen object
\<object id\> = display.create(\<parent id\>, display.OBJ\_SCREEN\_MENU, \<text col1\> , \[\<text col2\>, \[\<text col3\>, \[\<text col4\>, \[\<text col5\>, \[\<text col6\>\]\]\]\]\])

| Input | Description |
| --| --|
| display.ROOT | |
| Display.OBJ\_SCREEN\_MENU | |
| \<text col1\> | Title of menu column, the number of these sets the number of culumns |
| [\<text colN\>] | Other menu column titles, up to 6 total |

- Returns:

- \<object ID\>

- **NOTE:** The number of column titles distributes the column widths equally across the screen. You cannot add more, or remove, columns after creation.

- **NOTE:** Only 1 Menu Screen object can exist at a time. It can be accessed from anywhere by pressing the MENU key on the instrument front panel. 

- [Return to ToC](#table-of-contents)

## display.create(): Popup Menu Screen object
\<object id\> = display.create(\<parent id\>, display.OBJ\_POPUP\_MENU\_SCREEN , "\<item1\>", "\<item2\>", \["\<item3\>", ... \["\<item7\>"\]\])

| Input | Description |
| --| --|
| \<parent ID\> | Parent ID of display.OBJ_SCREEN or display.OBJ_SCREEN_HOME |
| display.OBJ_POPUP_MENU_SCREEN |  |
| \<item1\> | string for the 1st item to list in popup (hamburger) menu screen – maximum of 32 characters |
| \<item2\> | string for the 2nd item to list in popup (hamburger) menu screen – maximum of 32 characters |
| \[\<itemN\>\] | string for the Nth item to list in popup (hamburger) menu screen – maximum of 32 characters, up to N=7 |

- **NOTE:** At least 2 items must be specified.

- **NOTE:** The popup menu will use a size that accommodates the maximum width of the items being added to it.

- [Return to ToC](#table-of-contents)

## display.create(): Progress Bar object
\<object id\> = display.create(\<parent id\>, display.OBJ\_PROGRESS\_BAR, \<x\>, \<y\>, \<width\>, \<height\>)

| Input | Description |
| --| --|
| \<parent id\>  | Object id of display.OBJ_SWIPE, display.OBJ_SCREEN, display.OBJ_SCREEN_HOME |
| display.OBJ\_PROGRESS\_BAR | --|
| \<x\>  | \<x\> coordinate offset from the parent |
| \<y\> | \<y\> coordinate offset from the parent |
| \<width\> | --|
| \<height\> | --|

- **NOTE:** See [display.setvalue() - Progress Bar](#displaysetvalue--progress-bar) to change color of segments as the progress bar grows.

- [Return to ToC](#table-of-contents)

## display.create(): Rectangle object
\<object id\> = display.create(\<parent id\>, display.OBJ\_RECT , \<x\>, \<y\>, \<width\>, \<height\>, \[\<fill percent\>, \[\<fill direction\>\]\])

| Input | Description |
| --| --|
| \<parent ID\> | Parent ID, see note |
| display.OBJ\_RECT | |
| \<x\> | Coordinate of top left corner |
| \<y\> | |
| \<width\> | |
| \<height\> | |
| [\<fill percent\>] = 0 | How much to fill, 0-100 |
| [\<fill direction\>] = display.FILL\_UP | Direction to fill from, see note |

- Returns:

- \<object ID\>

![Rectangle object](/.github/media/image13.png)

- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- **NOTE:** valid fill directions are:
  - display.FILL\_LEFT
  - display.FILL\_RIGHT
  - display.FILL\_UP
  - display.FILL\_DOWN

- [Return to ToC](#table-of-contents)

## display.create(): Screen object
\<object id\> = display.create(\<parent id\>, display.OBJ\_SCREEN, "\<title\>", \[\<split y\>, \<split height\>\])

| Input | Description |
| --| --|
| display.ROOT | Parent id, must be display.ROOT for screen object |
| Display.OBJ\_SCREEN | |
| \<title\> | String displayed at top of screen |
| [\<split y\>] = no split | point where the screen is split allowing the bottom portion to be scrolled |
| [\<split height\>] | is the total height of the scrolled portion of the screen including the non-visible portion (must be specified with \<split y\>) |

- Returns:

- \<object ID\>

- **NOTE:** Primitive objects may not display properly on the scrolled portion of a split screen.

- [Return to ToC](#table-of-contents)

## display.create(): Swipe object
\<object id\> = display.create(display.SCREEN\_HOME, display.OBJ\_SWIPE, "\<title\>")

\<object id\> = display.create(display.SCREEN\_HOME, display.OBJ\_SWIPE, \<swipe id\>)

| Input | Description |
| --| --|
| display.SCREEN\_HOME | Swipe object must be located at display.SCREEN\_HOME |
| display.OBJ\_SWIPE | |
| \<title\> or \<swipe id\> | Create a new swipe or use existing, see note |

- Returns:

- \<object ID\>

- **NOTE:** You can have up to 10 swipes at a time. Swipes are always appended to the furtherst left spot.

- **NOTE:** valid existing swipes for \<swipe id\> are:
  - display.SCREEN\_USER\_SWIPE
  - display.SCREEN\_STATS\_SWIPE
  - display.SCREEN\_GRAPH\_SWIPE
  - display.SCREEN\_SETTINGS\_SWIPE
  - display.SCREEN\_SOURCE\_SWIPE (SMUs only)
  - display.SCREEN\_SECONDARY\_SWIPE (DMMs only)
  - display.SCREEN\_FUNCTIONS\_SWIPE (DMMs only)
  - display.SCREEN\_SCAN_SWIPE (65xx only)
  - display.SCREEN\_CHANNEL\_SWIPE (65xx only)
  - display.SCREEN\_NONSWITCH\_SWIPE (65xx only)

- [Return to ToC](#table-of-contents)

## display.create(): Text object
\<object id\> = display.create(\<parent id\>, display.OBJ\_TEXT , \<x\>, \<y\>, "\<text\>", \[\<foreground color\>, \[\<font\>, \[\<justification\>\]\]\])

| Input | Description |
| --| --|
| \<parent id\> | Parent id, see note |
| display.OBJ\_TEXT | |
| \<x\> | Anchor position (exact position depends on justification) |
| \<y\> | Text baseline |
| \<text\> | Text to display |
| [\<foreground color\>] | 0x00rrggbb where rr is 0-FF, must be given as decimal |
| [\<font\>] | Font size, see note |
| [\<justification\>] | Text justification, see note |

- Returns:

- \<object ID\>

![Text object](/.github/media/image14.png)

- **NOTE:** The Text object's width is determined by the text string, height is determined by the font.
  
- **NOTE:** valid parent id's are:
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- **NOTE:** See the [color section of the API](README.md#colors) for help with colors. 
  
- **NOTE:** valid font sizes are:
  - display.FONT\_SMALL
  - display.FONT\_MEDIUM
  - display.FONT\_LARGE
  - display.FONT\_HUGE(v1.6+))

- **NOTE:** valid justification options are:
  - display.JUST\_CENTER
  - display.JUST\_LEFT
  - display.JUST\_RIGHT

- [Return to ToC](#table-of-contents)

## display.create(): Timer object
\<object id\> = display.create(\<parent id\>, display.OBJ\_TIMER, \<period\> , \<count\>, \["\<command\>"\])

| Input | Description |
| --| --|
| \<parent id\> | See note |
| display.OBJ\_TIMER | |
| \<period\> | Time in seconds between timer PRESS events |
| \<count\> | Number of timer press events (or display.TIMER\_FOREVER) |
| [\<command\>] | A string to execute on timer expiration (e.g. "trigger.model.initiate()"), otherwise can listen for timer PRESS event |

- Returns:

- \<object ID\>

- **NOTE:** valid parent id's are:
  - display.ROOT
  - display.OBJ\_SWIPE
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SCREEN\_MENU

- **NOTE:** A timer is only active when it's parent object (object of \<parent id\> is enabled with [display.setstate()](#displaysetstate))

- [Return to ToC](#table-of-contents)

# Set Commands

These aren't their own library like graph and display, but it's helpful to group them together as they all share a purpose of changing object attributes after creation.

## display.setabbrv()
display.setabbrv(\<parent id\>, "\<option1\>", "\<option2\>", \["\<option3\>", ... \["\<option10\>"\]\])
| Input | Description |
| --| --|
| \<parent id\> | Must point towards a display.OBJ\_EDIT\_OPTION |
| \<option 1\> | New string for the selection |
| \<option 2\> | |
| [\<option N\>] | Up to 10 options total |

- Returns:

- None

- [Return to ToC](#table-of-contents)

## display.setcell()
display.setcell(\<id\>, \<row\>, \<column\>, "\<string\>")

| Input | Description |
| --| --|
| \<id\> | Object id of a display.OBJ\_LIST object |
| \<row\> | The row to set the value of, See note |
| \<column\> | The column to set the value of |
| \<string\> | The text to be displayed |

- Returns:

- None

- **NOTE:** \<row\> accepts special options:
  - display.LIST\_ROW\_HEADER can specify a header above row 0
  - display.LIST\_ROW\_EMPTY can specify no rows or columns and "uninitialized" text style

- **NOTE:** After the first row is populated with columns, no new columns may be added

- [Return to ToC](#table-of-contents)

## display.setcolor()
display.setcolor(\<id\>, \<foreground color\>, \[\<second color\>\])

| Input | Description |
| --| --|
| \<id\> | See note for allowable options |
| \<foreground color\> | 0x00rrggbb where rr is 0-FF, must be given as decimal |
| [\<second color\>] = background color of parent | Rectangle fill color or text background, not used elsewhere |

- Returns:

- None

- **NOTE:** See the [colors section](README.md#colors) of the API for more info.

- **NOTE:** allowable id's for \<id\> are:
  - display.OBJ\_TEXT
  - display.OBJ\_RECT
  - display.OBJ\_LINE
  - display.OBJ\_CIRCLE

- [Return to ToC](#table-of-contents)

## display.setevent()
display.setevent(\<id\>, \<event\>, \[\<on/off\>\])

display.setevent(\<id\>, \<event\>, \["\<command\>"\])

| Input | Description |
| --| --|
| \<id\> | Parent object to host event, see [Events table](README.md#events) |
| \<event\> | Event to edit, See [Events table](README.md#events) |
| [\<on/off\>] OR [\<command\>] | Boolean (0 or 1) to turn event on or off for display.waitevent() OR<br> command (passed as a string) to execute on event, replaces display.waitevent() |

- Returns:

- None

- **NOTE:** use display.EVENT\_ENDAPP to call cleanup functions with ending an app (reset(), delete buffers, createconfigscript, etc.)

- [Return to ToC](#table-of-contents)

## display.setfill()
display.setfill(\<id\>, \<fill percent\>, \<fill direction\>)

| Input | Description |
| --| --|
| \<id\> | ID of display.OBJ\_RECT |
| \<fill percent\> | Amount to fill the foreground against the background (0-100) |
| [\<fill direction\>] | Which way to fill, defaults to initial direction |

- Returns:

- None

- **NOTE:** Allowable fill directions are:
  - display.FILL\_LEFT
  - display.FILL\_RIGHT
  - display.FILL\_UP
  - display.FILL\_DOWN

- [Return to ToC](#table-of-contents)

## display.setfont()
display.setfont(\<id\>, \<font id\>)

| Input | Description |
| --| --|
| \<id\> | Id of display.OBJ\_TEXT or display.OBJ\_LIST|
| \<font\> | See note for allowable options |

- Returns:

- None

- **NOTE:** Allowable \<font\> options are:
  - display.FONT\_SMALL
  - display.FONT\_MEDIUM
  - display.FONT\_LARGE
  - display.FONT\_HUGE (v1.6+)
  - display.FONT\_1 (v1.7+)
  - display.FONT\_2 (v1.7+)
  - display.FONT\_3 (v1.7+)
  - display.FONT\_4 (v1.7+)
  - display.FONT\_5 (v1.7+)
  - display.FONT\_6 (v1.7+)
  - display.FONT\_7 (v1.7+)
  - display.FONT\_8 (v1.7+)
  - display.FONT\_9 (v1.7+)
  - display.FONT\_10 (v1.7+)

- [Return to ToC](#table-of-contents)

## display.setknobaction() (v1.7.1+)
display.setknobaction(\<id\>, \<action\>)

| Input | Description |
| --| --|
| \<id\> | Object id of display.OBJ_SCREEN or display.OBJ_HOME_SCREEN |
| \<action\> = display.ACTION\DEFAULT| display.ACTION\_EVENTS (the knob performs the actions defined by display.SET\_EVENT)<br>display.ACTION_DEFAULT (the knob performs the default system actions) |

- Returns:

- None

- [Return to ToC](#table-of-contents)

## display.setminmax()
display.setminmax(\<id\>, \<min\>, \<max\>)

| Input | Description |
| --| --|
| \<id\> | Object id from display.OBJ\_EDIT\_NUMBER or display.OBJ\_EDIT\_SLIDER |
| \<min\> | minimum value for number entry |
| \<max\> | maximum value for number entry |

- Returns:

- None

- [Return to ToC](#table-of-contents)

## display.setpopupmenu() (v1.7.1+)
display.setpopupmenu(\<id\>, \<item \#\>, \<Item state\>, \[ \<item text\>\])

| Input | Description |
| --| --|
| \<id\> | Object id of display.OBJ_POPUP_MENU_SCREEN | 
| \<item #\> | item number being updated with a new state or text |
| \<item state\> | display.POPUP\_STATE\_DISABLE (grays the specificed item so a user can't select it)<br>display.POPUP\_STATE\_ENABLE (allows user to select the item) | 
| \[\<item text\>\] | character array of 32 characters representing the new text to show for specified item number parameter |

- **NOTE:**  If the width needed to show \<item text\> is wider than the width of the present popup menu then the popup menu will increase in width to show the updated text correctly. However, the menu will not decrease in width if the new text width is shorter.

- [Return to ToC](#table-of-contents)

## display.setposition()
display.setposition(\<id\>, \<x\>, \<y\>, \[\<width\>, \<height\>\])

display.setposition(\<id\>, \<x\>, \<y\>, \[\<x<sub>2</sub>\>,\<y<sub>2</sub>\>\])

display.setposition(\<id\>, \<x\>, \<y\>, \[\<r\>\])

| Input | Description |
| --| --|
| \<id\> | Object id, see not for allowable parents |
| \<x\> | |
| \<y\> | |
| [\<width\>, \<height\>] OR [\<x2\>, \<y2\>] OR [\<r\>] | Depends on object called |

- Returns:

- None

- **NOTE:** Allowable object id's for \<id\> come from:
  - display.OBJ\_RECT
  - display.OBJ\_LINE
  - display.OBJ\_CIRCLE
  - display.OBJ\_IMAGE

- **NOTE:** \<x2\>,\<y2\> are used for line, \<r\> is used for circle. When not given, object is translated

- [Return to ToC](#table-of-contents)

## display.setstate()
display.setstate(\<id\>, \<state\>)

| Input | Description |
| --| --|
| \<id\> | Object id, see note |
| \<state\> | New state, see note |

- Returns:

- None

- **NOTE:** Allowable object id's for \<id\> come from:
  - display.OBJ\_RECT
  - display.OBJ\_LINE
  - display.OBJ\_CIRCLE
  - display.OBJ\_TEXT
  - display.OBJ\_IMAGE
  - display.OBJ\_GRAPH
  - display.OBJ\_BUTTON
  - display.OBJ\_EDIT\_NUMBER
  - display.OBJ\_EDIT\_CHECK
  - display.OBJ\_EDIT\_STRING
  - display.OBJ\_EDIT\_OPTION
  - display.OBJ\_EDIT\_SLIDER

- **NOTE:** Allowable states are:
  - display.STATE\_ENABLE – enable the object for use and make visible
  - display.STATE\_DISABLE – disable the object from edit (display.OBJ\_EDIT\_\* only)
  - display.STATE\_INVISIBLE – make the object invisible (not shown on screen)
  - display.STATE\_READONLY – show the object as read only (display.OBJ\_EDIT\_\* only)

- [Return to ToC](#table-of-contents)

## display.settext()
display.settext(\<id\>, "\<text\>")

| Input | Description |
| --| --|
| \<id\> | Object ID, see note |
| \<text\> | The new text string, see note |

- Returns:

- None

- **NOTE:** valid targets of \<id\> are:
  - display.OBJ\_TEXT
  - display.OBJ\_EDIT\_NUMBER
  - display.OBJ\_EDIT\_OPTION
  - display.OBJ\_EDIT\_STRING
  - display.OBJ\_EDIT\_CHECK
  - display.OBJ\_SCREEN
  - display.OBJ\_SCREEN\_HOME
  - display.OBJ\_SWIPE

- **NOTE:** \<text\> represents a variable target: 
  - for Text objects, the text is modified; 
  - for Edit objects, the help text is modified;
  - for Screen and Swipe objects, the title is modified

- [Return to ToC](#table-of-contents)

## display.setthickness()
display.setthickness(\<id\>, \<thickness\>)

| Input | Description |
| --| --|
| \<id\> | Object ID from display.OBJ\_RECT, display.OBJ\_LINE, display.OBJ\_CIRCLE |
| \<thickness\> | The line or border width in pixels |

- Returns:

- None

- [Return to ToC](#table-of-contents)

## display.setvalue()
display.setvalue(\<id\>, \<value\>)

display.setvalue(\<id\>, "\<value\>")

| Input | Description |
| --| --|
| \<id\> | Object id, see note |
| \<value\> | Depending on the object: a decimal number, string, checkbox (display.ON, display.OFF), or a 1-based index for options |

- Returns:

- None

- **NOTE:** Allowable object id's for \<id\> are:
  - display.OBJ\_EDIT\_NUMBER
  - display.OBJ\_EDIT\_CHECK
  - display.OBJ\_EDIT\_STRING
  - display.OBJ\_EDIT\_OPTION
  - display.OBJ\_EDIT\_SLIDER

### display.setvalue: Progress Bar

display.setvalue(\<id\>, \<percent\_fill\>, \<slide color\>)

| Input | Description |
| --| --|
| \<id\> | Object ID of display.OBJ\_PROGRESS\_BAR |
| \<percent\_fill\> | amount to fill, 0-100 |
| \<slide color\> | display.MARK\_GREEN<br>display.MARK\_YELLOW<br>display.MARK\_RED |

- **NOTE:** See [display.create() - Progress Bar](#displaycreate--progress-bar-object)