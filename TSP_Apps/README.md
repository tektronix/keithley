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

* **[Resistance Tolerance Meter](./Resistance_Tolerance_Meter.tspa)**  
Turns the DMM6500 or DAQ6510 into a dedicated resistor tolerance meter. You can set the expected value, number of resistors to be tested, and several other options. The app gives you an option to export the data when you're done. This is basically a wrapper of the limit test functionality.

* **[DAQ6510 Demo](./KE_DAQ6510_Demo.tsp)**  
Intended as a Sales helper tool, this script for the DAQ6510 provides a self-guided tour of the instrument's high-level features. Requires a Model 7700, 7702, 7706, 7707, 7708, or 7710 to be inserted into Slot 1 of the mainframe. 

* **[PONG](./PONG)**
This app is for showing off the playful side of TSP by offering a throw-back, retro-gaming experience in the form of PONG! Note that the app includes wiring instructions for the game controller station. 
 
## About TSP

The TSP language is largely based on Lua 5.0 with instrument specific commands and some features of later Lua versions. Check the Reference Manual of your instrument for more information on TSP and for supported instrument specific commands.  
[You can read more about Lua here.](https://www.lua.org/)
