<h1>The TTI Display API</h1>

The user interfaces of the Keithley Touch, Test, Invent&reg; (TTI) products are designed to offer an easy-to-use and expansive user experience. 
It allows access to all the features and functionality of the TTI products. 
But as such, it may not offer the best experience for very specific applications.
Thus, the TTI Display API allows control of the Display for custom GUI applications and flexible additions to current System displays.

This documentation is provided as-is and should not be considered to be the same quality as published Tektronix / Keithley documentation. 
Where this documentation differs from the Reference Manual of your Keithley touchscreen instrument, it should be considered unofficial and unsupported. 
Keithley makes no guarantees of continuing to support the functionality of these commands in the future. 
Nor does Keithley make any guarantee that referenced commands work as described, though when such discrepancies are found we will strive to update this documentation.
They are provided here for those that like to tinker or would like to try using their Keithley touchscreen instrument in a new way.

Should you find an error or a way to improve this documentation (there are many places it could be improved!), please feel free to propose changes and submit a pull request or even open an issue as outlined in the [Contribution Guidelines](/CONTRIBUTING.md). 

The TTI display API allows TSP scripts to create custom display screens,
menus, etc. Combinations of screens can be used to tailor the user
experience to a specific desired application. This adapted experience
should allow for a clear and clean user experience specifically designed
for their application.

The TTI display API, when combined with scripting creates a [TTI App](#tti-apps), or a script based application which takes over the user
interface of the product.

The TTI display API is designed to be both limiting and flexible. There
is an intentional attempt to limit the number of commands to keep the
API clear and concise. In some case this creates more complexity in the
command arguments. Due to this command complexity, SCPI is not
supported.

<h1>Table of Contents</h1>

- [OBJECTS](#objects)
  - [Screen Objects](#screen-objects)
  - [Swipe Objects](#swipe-objects)
  - [Other Objects](#other-objects)
  - [Object ID](#object-id)
  - [Object Placement](#object-placement)
  - [Object Attributes](#object-attributes)
    - [Colors](#colors)
- [EVENTS](#events)
  - [Superloop Paradigm](#superloop-paradigm)
  - [Callback Paradigm](#callback-paradigm)
- [GRAPH](#graph)
- [IMAGES](#images)
- [STRING FORMAT](#string-format)
  - [Special Characters](#special-characters)
- [PROGRAMMING CONSIDERATIONS](#programming-considerations)
  - [Resource Usage](#resource-usage)
  - [TTI Apps](#tti-apps)
    - [How are TTI Apps different from TSP scripts?](#how-are-tti-apps-different-from-tsp-scripts)
    - [Header](#header)
    - [Icons](#icons)
  - [Tips and Tricks](#tips-and-tricks)
    - [Loading Screen](#loading-screen)
- [EXAMPLES](#examples)
  - [CUSTOM SCREEN](#custom-screen)
  - [CUSTOM SWIPE](#custom-swipe)
  - [3 Column Menu](#3-column-menu)
  - [Screen with Graph](#screen-with-graph)
  - [3 Graphs on one Screen](#3-graphs-on-one-screen)
  - [Swipe Screen Carousel](#swipe-screen-carousel)
- [Display API Command Reference](#display-api-command-reference)

# OBJECTS

An object is the fundamental building block of the TTI UI. Each UI
object represents an element on the front panel which interacts with a
user. UI objects can be created, destroyed, and manipulated in a various
way depending on the type and class of the object. UI objects become the
vehicle in which commands in a script interact with the user. 

The available objects are some of the same objects used by the TTI
products. They interact with the physical keys, touch, and knob (when
available) in the same manner as other TTI objects. 

## Screen Objects

On a TTI instrument, objects are organized into screens. Each screen
takes over the entire display, contains a title, and can hold many
objects. There are 4 types of screens:

  - Home Screen (via HOME key)

  - Menu Screen (via MENU key)

  - Built-in Screens (shipped with product)

  - Custom Screens (created with the display API)

Screens can be put on the display using TSP commands, some physical
keys, or an object called a menu button (normally organized on a menu
screen).

Screens can extend past the viewable area of the display. The area
beyond view can be scrolled into view with the knob or a finger gesture.
The top portion of the screen can be split off and fixed if desired.

![Screen object](/.github/media/image1.png)

## Swipe Objects

Swipes are much like screens except they are a smaller size and are only
available as children of the Home Screen. There can be up to 10 swipes.
Like screens, there are both Custom and Built-in swipes.

Built-in Screens and Swipes can commingle with Custom Screens and Swipes.
Custom Screens and Swipes are denoted by a unique orange-brown highlight
color.

![Swipe object](/.github/media/image2.png)

## Other Objects

There are multiple types of objects which can be divided into classes.
Each object type serves a specific purpose on the TTI user interface.

1.  Input Dialogs
    
    1.  Input dialogs popup at any point in time on the center of the
        current screen. They are used to gain a response from the user.
        The user cannot navigate around these dialogs. There are 4 types
        of input dialogs: Use one of these specific types to input a
        specific type of variable.
        
        1.  **Number** - An Input Number Dialog allows the user to input a floating point or integer number
        
        1.  **String** - A String Dialog allows the user to input a text string
        
        2.  **Options** - An Options Dialog allows the user to input a
            single selection from a group of options
        
        3.  **Prompt** - A Prompt Dialog allows the user to input an enumerated response from to a question

1.  Input Primitives
    
    1.  Input primitives are the fundamental input objects on a
        screen. They are used to gain a response from the user. In some
        cases they also show the present value or setting. It is up to
        the user to decide when to interact with an Input Primitive
        object. There are 7 types of input primitives:
        
        1.  **Button** – A Button drives an Event to TTI (more later)
            <br>![Button object](/.github/media/image3.png)
            
        2.   **Menu Button** – A Menu Button contains an image and allows a user to
    change screens.
            <br>![Menu Button object](/.github/media/image4.png)
        
        1.  **Edit Number** – An Edit Number allows the user to input a floating
    point or integer number
            <br>![Edit Number object](/.github/media/image5.png)

        1.  **Edit Option** – An Edit Option allows the user to input a single
    selection from a group of options
            <br>![Edit Option object](/.github/media/image6.png)

        1.  **Edit String** – An Edit String allows the user to input a text string
            <br>![Edit String object](/.github/media/image7.png)

        2.  **Edit Check** – An Edit Check allows the user to input an On/Off or
    Enable/Disable response
            <br>![Edit Check object](/.github/media/image8.png)

        1.  **Edit Slider** – An Edit Slider allows the user to select a number by
    sliding a handle across a number line
            <br>![Horizontal Edit Slider object](/.github/media/image9.png)
            <br>![Vertical Edit Slider object](/.github/media/image10.png)


2.  Primitives
    
    1.  Primitives are for conveying information to the user. They offer
        no input capabilities. However, they offer a number of output
        capabilities, such as position, font, color, fill, etc. There
        are 5 types of input primitives:
        
        1.  **Line**
            <br>![Line object](/.github/media/image11.png)

        2.  **Circle**
            <br>![Circle object](/.github/media/image12.png)

        3.  **Rectangle**
            <br>![Rectangle object](/.github/media/image13.png)

        4.  **Text**
            <br>![Text object](/.github/media/image14.png)

        5.  **Image**

        6.  **Graph**
            <br>![Graph object](/.github/media/image16.png)

        7.  **Timer**
            
              A timer provides a periodic update mechanism for screens. A timer can only generate an Event. A timer is active when its parent object is visible. There is no included graphical representation of a timer.

## Object ID

Every created object is given an object id when defined. 
This ID is used by the display API commands to reference the object you trying to manipulate and to determine what objects are sending events (more later). 
Custom objects' ids are stored in user defined variables. 
Built-In objects' ids are handled using a constant stored by the instrument, e.g. display.SCREEN_HOME is the constant for the Home screen. 

Object IDs are also used to connect objects together. 
All objects require a parent object to hold it, this parent id is required by all display.create() commands.
This parent is normally a screen or a swipe. 
Screens may also be parented off the “System” or ROOT, the highest level TTI object.

At startup, there will be a number of pre-created objects:

1.  System
2.  Built-in Screens
3.  Built-in Swipes
4.  User Swipes

## Object Placement

Objects are placed on the screen at an X, Y location. 
The TTI screen is sized from 0 to 799 from left to right (X), and 0 to 429 from top to bottom (Y).
The X, Y position specifies the position of the objects origin.
Different objects have different origins. 
Objects can have different widths and heights. 
Depending on object type these may be definable or fixed.

Because of an objects origin, width, and/or height, it may not
necessarily be allowed at all positions. Position checking is also not
perfect and is only meant for general guidelines. You may still find you
can place objects partially off screen. The object will be clipped
without incident. Objects may also be placed on top of each other in
which case interaction with that object is undefined.

## Object Attributes

Different object types have different configurable attributes. 
The object attributes and which objects support them are listed below. 
Certain attributes can only be set on object creation (On Create) while some can be changed after creation (Dynamic). 
See individual commands for details.

| _Attribute_ | _Description or Expected Values_ | _On Create Objects_ | _Dynamic Objects_ |
| --- | --- | --- | --- |
| X,Y | Position of the object | Primitives<br>Input Primitives | Primitives
| W, H | Size of the object  | Rectangle<br>Circle (W is Radius)<br>Line (W, H is X2, Y2)<br>Graph | Rectangle<br>Circle (W is Radius)<br>Line (W, H is X2, Y2)
| Abbreviations | Option text to appear on screen button | | Edit Option |
| Color, Foreground | [Color](#colors) | Text | Rectangle<br>Line<br>Circle<br>Text |
| Color, Secondary | [Color](#colors) | | Text (Background)Rectangle (Fill) |
| Event Filter | Whether an event is tied to the object or not | | Screen<br>Button<br>Menu Button<br>Edit Number<br>Edit String<br>Edit Option<br>Edit Check Box<br>Edit Slider<br>Graph<br>Timer |
| Fill Direction | Left, Right, Up, or Down | Rectangle | Rectangle |
| Fill Percent | Number between 0 and 100 | Rectangle | Rectangle |
| Font | Large, Medium, or Small | Text | |
| Image | Name of Image | Menu Button<br>Image | |
| Justification | Left, Right, or Center | Text | Text |
| Min | minimum value | Edit Slider<br>Edit Number | Edit Slider<br>Edit Number |
| Max | maximum value | Edit Slider<br>Edit Number | Edit Slider<br>Edit Number |
| State | Visible<br>Enable | | Primitives<br>Input Primitives |
| State | Disable | | Button<br>Edit Number<br>Edit String<br>Edit Option<br>Edit Check Box<br>Edit Slider |
| State | Read Only | | Edit Number<br>Edit String<br>Edit Option<br>Edit Check Box<br>Edit Slider |
| Text | Text of object | Screen (Title)<br>Swipe (Title)<br>Button<br>Button Menu<br>Text<br>Edit Number (Help)<br>Edit String (Help)<br>Edit Option (Help)<br>Edit Check Box (Help) | Screen (Title)<br>Swipe (Title)<br>Button<br>Button Menu<br>Text<br>Edit Number (Help)<br>Edit String (Help)<br>Edit Option (Help)<br>Edit Check Box (Help) |
| Thickness | 1-10 | | LineRectangleCircle |
| Value (Get/Set) | Number or String | Edit Number<br>Edit Check Box | Edit Number<br>Edit String<br>Edit Option<br>Edit Check Box<br>Edit Slider |


### Colors

TTI Instruments display 24 bit color as defined by either Decimal or Hex values. 
The Hex value is in the standard format 0xRRGGBB. 
There are various sites online that will convert between a color, hex value, and decimal value for you.

Certain colors used by the system are stored as named constants. 
You may use these constants in place of a decimal/hex color value. 
You are not required to use these colors for your own apps, however, you should not use these colors for any purpose other than their listed usage.

For example:
`display.setcolor(text_id, 0x0d0c0ff)` and `display.setcolor(text_id, display.COLOR_EDIT_TITLE)` are equivalent. 

| _TSP Color Constant_ | _Decimal Value_ | _Hex Value_ | _Usage_ |
| --- | --- | --- | --- |
| display.COLOR\_EDIT\_TITLE | 901375 | 0DC0FF | The rgb color of the Edit object's title text. |
| display.COLOR\_EDIT\_HELP | 8421504 | 808080 | The rgb color of the Edit object's help text. |
| display.COLOR\_VALUE\_LABEL | 294566 | 047EA6 | The rgb color of the label that is associated with a changing value. For example, the "Average:" part of "Average: 1.23 V" |
| display.COLOR\_VALUE\_VALUE | 14737632 | E0E0E0 | The rgb color of the value that is associated with a changing value. For example, the "1.23 V" part of "Average: 1.23 V" |
| display.COLOR\_SCREEN\_BACKGROUND | 2573 | 000A0D | The rgb color of the Screen object's background. |
| display.COLOR\_SWIPE\_BACKGROUND | 1644825 | 191919 | The rgb color of the Swipe object's background. |
| display.COLOR\_MEASUREMENT | 6485851 | 62F75B | The rgb color of the Home screen measurement. |

The colors used by the graph traces (in hexadecimal) are:

| _Color_ | _Graph Trace ID_ | 
| -- | -- |
| 0x0024A11E | CID\_GRAPH\_TRACE\_1 |
| 0x00047ea6 | CID\_GRAPH\_TRACE\_2 |
| 0x00FF8000 | CID\_GRAPH\_TRACE\_3 |
| 0x00A68064 | CID\_GRAPH\_TRACE\_4 |
| 0x00B386EF | CID\_GRAPH\_TRACE\_5 |
| 0x006D8DB6 | CID\_GRAPH\_TRACE\_6 |
| 0x00E7986B | CID\_GRAPH\_TRACE\_7 |
| 0x00678318 | CID\_GRAPH\_TRACE\_8 |
| 0x00C32555 | CID\_GRAPH\_TRACE\_9 |
| 0x00EFD4F1 | CID\_GRAPH\_TRACE\_10 |
| 0x00BB4C26 | CID\_GRAPH\_TRACE\_11 |
| 0x00C1DF76 | CID\_GRAPH\_TRACE\_12 |
| 0x000EC44A | CID\_GRAPH\_TRACE\_13 |
| 0x00F77785 | CID\_GRAPH\_TRACE\_14 |
| 0x0067437E | CID\_GRAPH\_TRACE\_15 |
| 0x00E56CE1 | CID\_GRAPH\_TRACE\_16 |
| 0x0079B9A8 | CID\_GRAPH\_TRACE\_17 |
| 0x006D3837 | CID\_GRAPH\_TRACE\_18 |
| 0x00D1AD3C | CID\_GRAPH\_TRACE\_19 |
| 0x00626DCE | CID\_GRAPH\_TRACE\_20 |



# EVENTS

Events are how user inputs to the TTI UI are attached to a script. Many
of the object types are capable of generating events. For example, the
following action generate events:

  - a button press
  - changing a value on an edit object
  - pan/zoom on a graph

Events are a general concept across object types. However, not all
objects support events, or the same kind of events. See the
documentation on the specific object to see which events it can
generate. This table shows what object/event pairings are valid:

| \<id\> from | \<event\> (when it is generated) | Substitute for \<event\><br><sub>[See below](#using-events-to-integrate-with-the-display) |
| --- | --- | --- |
| display.OBJ\_BUTTON<br>display.OBJ\_EDIT\_STRING<br>display.OBJ\_EDIT\_NUMBER<br>display.OBJ\_EDIT\_OPTION<br>display.OBJ\_EDIT\_CHECK<br>display.OBJ\_LIST | display.EVENT\_PRESS (when pressed) |%id<br>%value (value is either a lua number or string in quotes) |
| display.OBJ\_EDIT\_SLIDER | display.EVENT\_PRESS (with finger lift)<br>display.EVENT\_DRAG (without finger lift) | %id, %value (value is an integer) |
| display.OBJ\_TIMER | display.EVENT\_PRESS (when timer expires) | |
| display.OBJ\_GRAPH | display.EVENT\_SCALE (with SmartScale, pan, and/or zoom)<br>display.EVENT\_DRAG (when cursors are in the act of moving)<br>display.EVENT\_PRESS (when you touch the graph; gives both scaled point and nearest data point (or overflow if none) as of v1.6)<br>display.EVENT\_CURSOR (when cursors are released after a move or reset via a pan/zoom) | %id<br>%xmin<br>%xmax<br>%ymin<br>%ymax<br>%xdatapt (v1.6+)<br>%ydatapt (v1.6+)<br>%xscaledpt (v1.6+)<br>%yscaledpt (v1.6+) |
| display.OBJ\_SCREEN<br>display.OBJ\_SCREEN\_HOME<br>display.OBJ\_SWIPE | display.EVENT\_PRESS (on the show of the screen)<br>display.EVENT_KNOB_ROTATE (v1.7.1+,only on instruments with front panel knob) (when knob is turned) <br>display.EVENT_KNOB_ENTER (v1.7.1+, only on instruments with front panel knob) (when knob is pressed in)<br>display.EVENT\_ENDAPP (when the App is closed) | %id<br>%value (where value is a number representing the knob value). |
| display.OBJ\_SCREEN\_MENU | display.EVENT\_PRESS (on the show of the screen)<br>display.EVENT\_ENDAPP (when the App is closed) |
| display.OBJ\_POPUP\_MENU\_SCREEN (v1.7.1+) | display.EVENT\_PRESS (when you select an item from the screen) | %id, %value

For convenience, button objects default their press events to on. Other objects do not have any events enabled by default.

There are two paradigms on how to handle events in your script i.e. how your app functions. 
The superloop method keeps running the screen. 
It is best when you want a single screen (or sequence of screens) to take over the instrument. 
The callback method integrates with the display. 
It is best used when your TTI App utilizes portions of the existing display.

## Superloop Paradigm

This method allows the script to remain running and the user input is
handled within the script. The script can be running a test and handling
the UI simultaneously. While this method keeps more control over the
instrument execution, it doesn’t allow for any other system UI screens
to execute because they will insist the script needs to be exited.

The example below creates objects which generate events. Running this
script will create the objects and wait for events. Though the user can
interact with the display, the script does not exit. As the user
interacts with the objects on the display, the instrument will fill the
rectangle.

````Lua
scrn_id = display.create(display.ROOT, display.OBJ_SCREEN, "CHEMISTRY FUN")
display.create(scrn_id, display.OBJ_TEXT, 10, 50, "Mixture")
display.create(scrn_id, display.OBJ_TEXT, 10, 70, "My Test")
display.create(scrn_id, display.OBJ_TEXT, 10, 90, "Mixture")
rect_id = display.create(scrn_id, display.OBJ_RECT, 100, 100, 100, 100)
display.setthickness(rect_id, 5)
start_button_id = display.create(scrn_id, display.OBJ_BUTTON, 300, 100, "Start Test")
stop_button_id = display.create(scrn_id, display.OBJ_BUTTON, 300, 150, "Stop Test")
button_id = display.waitevent(10)
if (button_id == start_button_id) then
  for i = 1, 100 do
    display.setfill(rect_id, dmm.measure.read() / 100)
    button_id = display.waitevent(0)
    if (button_id == stop_button_id) then 
      i = 100 
    end
  end
end
````

Pros:
1)  Allows for app to be easily understood and adapted by designers by
    using a FSM method
2)  Allows for best-case responsiveness to any sort of event (new
    reading, trigger model state change, button press)
3)  Allows the designed to fine tune interactions that would otherwise
    be impossible from the callback method

Cons:
1)  Accounting for every state transition can become complicated as the
    app becomes more complex.
2)  Only one script can run at a time on the unit, so only one superloop
    app may be running at any time. For example, this method would not
    be ideal for integrated swipe screens because they would need to
    allow other scripts to run at any time.

## Callback Paradigm

In this method a script is run which creates all the screens and adds
TSP commands to display object events. The script then exits, but leaves
a variety of functions still in TSP memory. When the user interacts with
the UI, the events will run Lua commands which can execute these
functions. Or, execute existing system UI screens with their own
commands. This method allows for a more seamless integration with
existing system UI screens.

For convenience, the commands tied to events have an event time value substitution. 
These substitutions provide access to object attributes associated with an event. 
For example, "%value" in the command string of an event tied to a Edit Number object will be replaced with the set number of that Edit Number object at the time of the event. 
This saves an extra command being used to retrieve the value attribute from the object.

The example below creates 4 objects which generate events. Running this
script will create the objects, hook up the command, and exit. The
script does not remain running but instead returns control to the user.
As the user interacts with the objects on the display, the instrument
will beep.

````Lua
id = display.create(display.ROOT, display.OBJ_SCREEN, "Test")
num_id = display.create(id, display.OBJ_EDIT_NUMBER, 400, 250, "Frequency", "100-1000")
chk_id = display.create(id, display.OBJ_EDIT_CHECK, 200, 250, "Line 1", "Line 2")
str_id = display.create(id, display.OBJ_EDIT_STRING, 200, 150, "Set Me", "To anything")
but_id = display.create(id, display.OBJ_BUTTON, 600, 150, "Beep")
display.setevent(num_id, display.EVENT_PRESS, "number_press_event(%value)")
display.setevent(chk_id, display.EVENT_PRESS, "check_press_event(%value)")
display.setevent(but_id, display.EVENT_PRESS, "button_press_event()")
display.setevent(str_id, display.EVENT_PRESS, "string_press_event(%id, %value)")

function number_press_event(v)
  beeper.beep(0.5, v)
end

function check_press_event(v)
  if (v == 1) then beeper.beep(0.5\*v, 100) end
end

function button_press_event()
  beeper.beep(0.5, 200)
end

function string_press_event(id, v)
  new_value = string.format("%s(%d)", v, id)
  display.setvalue(str_id, new_value)
end
````
Pros:
1)  Allows apps to be “integrated” to the UI, without needing to “End
    App” ever
2)  Allows more than one app to be “running” at the same time
    1.  Can have two custom swipe screens integrated with callbacks at
        the same time, and can have them only actively run by using a
        timer with a parent from the respective swipe screens
    2.  In reality, more than one app with callbacks will always be
        executed sequentially via the Lua command input queue, with no
        preemption over each other (first come, first served)
3)  Avoids inherent explosion of state machine complexity

Cons:
1)  Can only be triggered via built-in display events (user button
    press/swipe, timer elapsed, screen shown/hidden).
    1.  Not able to to respond with best-case performance to new
        readings added to the buffer, trigger model state transition,
        external IO interactions
    2.  Still able to respond to the above events by using a timer and
        polling their states periodically
2)  One “integrated” app could possibly affect the performance of
    another (designer has to be aware that other callbacks from other
    unknown apps might want to run too)

# GRAPH

A graph is a highly specialized object. It contains a number of
specialized commands to manipulate it. The commands allow for
programmatic graph manipulation which would have normally been left to
the user. In all cases, these commands work equally on user created
graph objects and the built in graph screen.

Some of the capabilities include:

  - Adding multiple traces

  - Changing graph scales

  - Changing graph types

  - Adding markers and/or lines

  - Manipulating and retrieving cursors

  - Selecting a trace

# IMAGES

Menu Button and Image objects require an image. Because of the size of
images and their binary nature, they are not integrated with the script.
Instead, images ride along with a scripts as a separate entity. Though
not part of the command portion of a script, images are best put in the
same file or downloaded as a script and associated with the script. When
an image is associated with a script, user actions like save and load
will also apply to the image.

Images must be of a standard PNG format (compressed 24 bit with Alpha).
Transparency is supported. 
The PNGs must be converted to an ASCII format. 
There are various online tools to convert PNG files to base64 ASCII. 

Because they are stored in a binary manner, they are not loaded via Lua
commands. Images are intercepted by the shell using the following
commands:

````Lua
loadimage <image name> [<script name>]
endimage
````

Images can be loaded into the run time environment and/or stored
permanently on the instrument.

For example, to create an image and immediately have it available to the
UI, but not stored, send the following:
````Lua
loadimage myimg
<base64 PNG image>
endimage
````

This will make the image immediately available to any Lua UI commands
sent from the command line or run from a script. When the instrument is
power cycled, the image will be lost.

To store the image permanently on the instrument, it must be linked to a
script. For example, send the following:
````Lua
loadimage myimg myscript
<base64 PNG image>
endimage
````

The image is now loaded into the system, but is not yet available for
use. When the script “myscript” is run, the image will be sent to the
display and available to any commands in the script. When the script is
saved permanently on the instrument, the image will be saved with it. If
the script is deleted, the image will also be destroyed. Multiple images
can be linked to the same script.

Therefore, the easiest way to make an app is to combine images and a
script into a single file. For example,

app.tspa:
````Lua
loadscript app
<script>
endscript

loadimage myimg1 app
<base64 PNG image>
endimage

loadimage myimg2 app
<base64 PNG image>
endimage
````

Images loaded from a thumb drive as a single file are automatically
associated with their script.

Currently Test Script Builder (TSB) does not support images. Check your
TSB documentation for image support. If you write a script utilizing the
TTI display API without images, everything will work normally. If you
would like to use images with your TTI display script, write your
script, including image references, normally with TSB. The script will
run fine, but you will see ‘?’ in place of any images. In order to get
images into the instrument, put the images onto a flash drive in a
single file as described previously. No script is actually needed in the
file. Use the TTI interface to ‘run’ this ‘script’. The images will be
loaded into the instrument and remain present until powered down.
Therefore, TSB can be used to continue development of the script portion
of the App. When your script is finalized, combine the script and
images into a single file to deliver to your final customer.

# STRING FORMAT

As a convenience, the display API allows access to its internal string
format routines for numbers. This functionality allows you to utilize
prefix notation (mV), scientific notation (e<sup>-3</sup>), integer,
units, digits, etc. It even has the ability to follow the user’s display
preference as noted on the System Settings Screen.

For example,

Input: `print(display.format(0.5, "V", display.NFORMAT\_PREFIX, 6))`

Output: 500.000 mV

valid formatting flags for \<nformat\> are:
| _Flag_ | _Description_ |
| --- | --- |
| display.NFORMAT\_PREFIX | prefix only, don't follow user setting |
| display.NFORMAT\_EXPONENT | exponent only, don't follow user setting |
| display.NFORMAT\_DECIMAL | decimal only, don't follow user setting |
| display.NFORMAT\_INTEGER | integer only, don't follow user setting (must be between -2^31 and +2^31) |
| display.NFORMAT\_USER | Copy user setting |
|
| The following options cannot be used by themselves, but may be OR'd in (using the '\|' symbol) |
| display.NFORMAT\_NO\_UNIT\_SPACE | Use shorter x.xxxU |
| display.NFORMAT\_SHOW\_POSITIVE | Show + |

## Special Characters

There are some special characters available for general usage in
strings. The \<title\>, \<text\>, \<label\>, \<short description\>, and \<help\> fields allow the following special characters:

| _Escape Code_ | _Character_ | _Name_ |
| --- | --- | --- |
| \18 | Ω | Ohm |
| \19 | ° | Degree |
| \20 | μ | Mu |
| \21 | | Thin Space (less than 'i') |
| \178 | <sup>2</sup> | Superscript 2 |
| \179 | <sup>3</sup> | Superscript 3 | 
| \185 | ∆ | Delta |
| \188 | 1/x | Reciprocal Symbol |
| \189 | v/v | DCV Ratio Symbol |

For example, `display.settext(id, "ohm=\18 degree=\19 mu=\20")`.

The escape codes must have a space after them, so the thin space must also include a regular space if not ending the string

# PROGRAMMING CONSIDERATIONS

## Resource Usage

Remember, your script will be integrated into the TTI operating
environment. Care should be taken to avoid your TTI App from becoming a
burden on the instrument's operations.

  - Use events to drive actions rather than forcing actions with a loop.

  - Try to avoid loops or intensive processing without yielding time
    with delay(). A call to delay() ensures the instrument is given a
    slice of time to make readings, etc.

  - Use display.EVENT_ENDAPP events to clean up when your app is closed; don't leave clutter in system memory.

  - Use Lua local variables over global variables whenever possible

  - Use Lua single variables instead of tables for time sensitive sections of code

  - Do not call to change an object when there is really no change. For example,
      - calling set position with an X of 20.2 and then again with an X of 20.4
      - always setting a color to red or green even though it may already be that color

## TTI Apps

The commands in this display API, combined with other TSP scripting documented in the instrument reference manual, can be used to create special TSP scripts known as TTI Apps.

### How are TTI Apps different from TSP scripts?
 
Here are the differences in implementation:
* TTI Apps use the `.tspa` extension rather than `.tsp`, this is how the instruments differentiate them.
* TTI Apps appear in the dedicated Apps menu within Touch, Test, Invent instruments, separate from the scripts menus. 

Those are the only enforced differences. By convention, these rules also apply:
* TTI Apps utilize the TTI display API TSP commands to create custom GUIs.
  * TTI Apps always have a GUI, though the GUI isn't required to be the only way of interacting with the App.
* TTI Apps have a standardized header comment block. The instruments pull from these comments to populate the Apps menu.
* TTI Apps can be cleanly ended by the user. Ending an App returns the instrument either to its default power-on state, or to the state the instrument was in before the App was run (use the display.EVENT_ENDAPP event).

### Header

Each script requires a header embedded in Lua comments at the start of the script. 
The header will contains keywords and values like so (for
example):
````Lua
-- $Title: Hello world
-- $Description: An app to say hello to the world.
-- $Version: 0.1
-- $Icon: helloworld_icon
-- $Product: DAQ6510, DMM6500
````
| *Keyword*     |*Value* |
| --- | --- |
| $Title:  | Name of the app, it must not have spaces (\< 40 characters)|
| $Description:  | A short description which will appear in the Apps Menu (\< 240 characters)|
| $Product:  | Comma separated model numbers representing the instruments which can run the script without errors. Options are 2450, 2460, 2461, 2470, DMM6500, DAQ6510|
| $Version:  | Version number of the app (increment manually on every app release). Default is 1. Must be an integer (up to 255) \< v1.7.1. Can be a string like 1.1.0a (v1.7.1+)|
| Optional Keywords:||
| $Requires:  | The minimum firmware version required to run the script, for example, 1.7.1. When in doubt, set to the firmware version the app was developed on. |
| $Tag:  | Comma separated single words used for searching and classification. “Beta” keyword will be appended to the menu title.|
| $Icon:  | The name of the image which should be used for the App icon button. |
| $ImageUnload:  | If True, destroys all images associated with script upon exiting |

**Note:** Title, Description, Product, Version, and Requires should always be included. The other Keywords are optional. 

### Icons
App Icons are loaded just like [images](#images). Take this example:
````Lua
loadimage iconName appName
<base64 PNG image>
endimage
````
appName must match the name of the app used for the $Title: tag in the header. imgName must match the $Icon: tag in the header. Icons should be 60x60 pixels in size and included in the app's `.tspa` file.

## Tips and Tricks

### Loading Screen

When screens are being built, its best practice to have a loading
screen. This allows complex screens to be drawn in the background. It is
much slower creating objects on a screen that is visible.

````Lua
main_screen_id = display.create(display.ROOT, display.OBJ_SCREEN, "Main Screen")

loading_screen_id = display.create(display.ROOT, display.OBJ_SCREEN, "Loading, please wait...")

function_that_populates_main_screen()
display.changescreen(main_screen_id)
display.delete(loading_screen_id) -- delete the loading screen
loading_screen_id = nil -- then delete the object id
````

# EXAMPLES

## CUSTOM SCREEN

To add a custom screen on the UI, create the screen and save the ID. Use
the screen ID to parent addition objects on that screen.

````Lua
id = display.create(display.ROOT, display.OBJ_SCREEN, "Super Screen")
num_id = display.create(id, display.OBJ_EDIT_NUMBER, 500, 250,"Frequency", "100-1000")
chk_id = display.create(id, display.OBJ_EDIT_CHECK, 200, 250, "Line 1", "Line 2")
str_id = display.create(id, display.OBJ_EDIT_STRING, 200, 150, "Set Me", "To anything")
but_id = display.create(id, display.OBJ_BUTTON, 600, 150, "Beep")
line_id = display.create(id, display.OBJ_LINE, 100, 100, 700, 100)
````

![Custom screen example](/.github/media/image17.png)

To turn the line red.

`display.setcolor(line_id, 0xff0000)`

![Custom Screen example with red line](/.github/media/image18.png)

To turn the line red based on a reading or green based on a reading.

````Lua 
reading = dmm.measure.read()
if (reading > 1) then
  new_line_color = 0xff0000
else
  new_line_color = 0x00ff00
end
if (line_color ~= new_line_color) then
  display.setcolor(line_id, new_line_color)
  line_color = new_line_color
end
````

## CUSTOM SWIPE

To add a custom swipe on the TTI Home Screen, create the swipe and save
the ID. Use the screen ID to parent additional objects on that swipe.
Swipes are unique in that they must be parented off the Home Screen.

````Lua
display.clear(display.SCREEN_HOME)
id1 = display.create(display.SCREEN_HOME, display.OBJ_SWIPE,"Control")
display.create(id1, display.OBJ_TEXT, 110, 80, "Closed:", display.COLOR_VALUE_LABEL, display.FONT_LARGE)
display.create(id1, display.OBJ_TEXT, 110, 110, "101", display.COLOR_VALUE_VALUE, display.FONT_LARGE)
display.create(id1, display.OBJ_TEXT, 210, 110, "109,112", display.COLOR_VALUE_VALUE)
display.create(id1, display.OBJ_BUTTON, 500, 15, "Close New")
display.create(id1, display.OBJ_BUTTON, 500, 75, "Close Next")
display.create(id1, display.OBJ_BUTTON, 500, 135, "Open All")
````

![Custom Swipe Example](/.github/media/image19.png)

There can be multiple Swipes in any order on the Home Screen. In the
previous example, the clear command was used to clear out any existing
Home Screen swipe before adding our new swipe. Without that command the
new swipe will be added to the end of the list of existing swipes. Up to
10 Swipes are allowed.

Existing swipes can be added back to the Home Screen event after
deleted.

`display.create(display.SCREEN_HOME, display.OBJ_SWIPE, display.SCREEN_GRAPH_SWIPE)`

![Multiple custom swipes](/.github/media/image20.png)

By clearing the swipes and adding them again, any swipe order can be
achieved. The new swipe can be removed by deleting the object referenced
by its ID.

`display.delete(id1)`

## 3 Column Menu

The following example creates a 3 column menu with 2 menu buttons. The
first button goes to an existing reading table screen. The second goes
to a newly created custom screen. If the user presses the physical MENU
key, this screen will be brought to the front.

````Lua 
menu_id = display.create(display.ROOT, display.OBJ_SCREEN_MENU, "Col1", "Col2", "Col3") 
display.create(menu_id, display.OBJ_BUTTON_MENU, 1, 1, display.SCREEN_READING_TABLE) 
my_screen_id = display.create(display.ROOT, display.OBJ_SCREEN, "My Screen") 
display.create(menu_id, display.OBJ_BUTTON_MENU, 2, 1, my_screen_id) 
display.changescreen(menu_id)
````

## Screen with Graph

The following example creates a screen with a graph on it. When the user
drags the cursor, an event will make cursor two jump ahead. When the
user lets go, the instrument will beep.

````Lua 
home_id = display.create(display.ROOT, display.OBJ_SCREEN_HOME, "My Home") 
graph_id = display.create(home_id, display.OBJ_GRAPH, 30, 10, 600, 300) 
display.graph.add(graph_id, defbuffer1, display.ELEMENT_DATA, defbuffer1, display.ELEMENT_TIME) 
display.graph.cursor(graph_id, display.CURSOR_VERTICAL, 0, 10) 
display.setevent(graph_id, display.EVENT_DRAG, "drag_event(%cursor_vert1, %cursor_vert2)") 
display.setevent(graph_id, display.EVENT_CURSOR, "button_press_event()") 

function drag_event(v1, v2) 
  display.graph.cursor(graph_id, display.CURSOR_VERTICAL, v1, v2+.000004) 
end 

function button_press_event() 
  beeper.beep(0.2, 200) 
end
````

## 3 Graphs on one Screen

The following example creates 3 graphs on the same screen with cursors.

````Lua
id = display.create(display.ROOT, display.OBJ_SCREEN, "Page 1")
g1 = display.create(id, display.OBJ_GRAPH, 30, 10, 300, 190)
g2 = display.create(id, display.OBJ_GRAPH, 400, 10, 300, 190)
g3 = display.create(id, display.OBJ_GRAPH, 30, 240, 700, 180)
display.graph.add(g1, defbuffer1, display.ELEMENT_DATA)
display.graph.add(g2, defbuffer1, display.ELEMENT_DATA)
display.graph.add(g3, defbuffer1, display.ELEMENT_DATA)
display.graph.cursor(g1, display.CURSOR_VERTICAL, 0, 10)
display.setevent(g1, display.EVENT_DRAG, display.ON)
display.graph.cursor(g2, display.CURSOR_HORIZONTAL, 0, 10)
display.graph.cursor(g3, display.CURSOR_TRIGGER, 0, 10)
````

## Swipe Screen Carousel

The following example creates a swipe screen with a carousel of readings. 
A progress bar shows the position of the viewed reading within the reading buffer. 
This example shows the use of primitive drawing routines, colors, and modifying created objects.

````Lua 
display.clear(display.SCREEN_HOME) 
id = display.create(display.SCREEN_HOME, display.OBJ_SWIPE, "Carousel") 

-- build carousel 
c0 = display.COLOR_VALUE_VALUE 
x, y = 18, 100 
for i = 1, 8 do 
  s = string.format("%d",103+i) 
  p = (-0.5\*math.mod(i, 7.1)+3.5)/7 
  color = (((c0 & 0x0000ff)\*p) & 0x0000ff) | (((c0 & 0x00ff00)\*p) & 0x00ff00) | (((c0 & 0xf0000f)\*p) & 0xff0000) 
  display.create(id, display.OBJ_TEXT, x+28, y, s, color,   display.FONT_SMALL) 
  display.create(id, display.OBJ_TEXT, x+8, y+20, "1.23456 V", color, display.FONT_SMALL) 
  x = x + 95 
end 

-- carousel indicator 
r = display.create(id, display.OBJ_RECT, 578, y-20, 97, 47) 
display.setcolor(r, 0xf0f0f0) 
r = display.create(id, display.OBJ_RECT, 15, y-20-5, 578+97-7, 47+10) 
display.setcolor(r, 0x008000) 
display.setthickness(r, 3) 

-- progress bar 
y = 30 
r = display.create(id, display.OBJ_RECT, 50, y, 250, 10, 100) 
display.setcolor(r, 0x00f000, 0x00f000) 
r = display.create(id, display.OBJ_RECT, 300, y, 450, 10, 100) 
display.setcolor(r, 0x305030, 0x305030) 

-- carousel position 
r = display.create(id, display.OBJ_RECT, 100, y-7, 200, 24) 
display.setcolor(r, 0x008000) 
display.setthickness(r, 3)
````

![Carousal Example](/.github/media/image21.png)

# Display API Command Reference

See the [Display API Command Reference here](Display%20API%20Command%20Reference.md).
