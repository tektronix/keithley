# TSP Apps

Keithley's TSP&reg; (Test Script Processor) enabled instruments have an on-board, user accessable processor. This allows the instruments to control themselves by writing functions or entire scripts that can be stored on the instrument itself and called either from an external computer or the front panel of the instrument. For our Touch Test Invent&reg; touchscreen enabled instruments, TSP can be used to take further control of the instrument's display and user interface to create mini, instrument specific applications, or Apps. TSP Apps have the extension .tspa to distinquish them from traditional .tsp scripts.

You can find offically supported, Keithley factory tested TSP Apps [here](https://www.tek.com/keithley/tsp-applications-for-touch-test-invent-models).

## Directory

[comment]: **[Title](./file.tspa)**  

* **[Digital I/O Control](./DIOControlFull.tspa)**  
This app allows full control of the Digital I/O port.  It requries a communication card with a digital I/O port.

* **[Email Buffer](./email.tspa)**  
This app is in progress and can only be run from a computer right now.  It allows for emailing data buffers.

* **[Let it Snow](./let_it_snow.tspa)**  
A simple, unoptimized holiday app to put falling snow right on the front panel of your instrument. It's surprisingly relaxing...

* **[Probe Hold](./Probe_Hold.tspa)**  
This app adds a swipe screen to the home screen that detects stable readings and displays them on screen. The big reading is still what the DMM is currently measuring. There is a delete button to remove the last reading and a settings button. All readings ever displayed are stored in a separate buffer, called App_buffer, that can be exported just like any other buffer. defbuffer1 holds all the readings the DMM takes, like normal, so you can go back and review the exact measurements taken (though defbuffer1 clears when you change functions). Most functions are supported, the ones NOT supported are digitizing, temperature, continuity, or diode. You can swipe off the probe hold, but no measurements will take place while you’re away from it.  
Full description [here](https://forum.tek.com/viewtopic.php?f=617&t=141115)

## About TSP

The TSP language is largely based on Lua 5.0 with instrument specific commands and some features of later Lua versions. Check the Reference Manual of your instrument for more information on TSP and for supported instrument specific commands.  
[You can read more about Lua here.](https://www.lua.org/)