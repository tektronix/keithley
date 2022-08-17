# TTI Apps

Keithley's TSP&reg; (Test Script Processor) enabled instruments have an on-board, user accessible processor. This allows the instruments to control themselves by writing functions or entire scripts that can be stored on the instrument itself and called either from an external computer or the front panel of the instrument. For our Touch, Test, Invent&reg; touchscreen enabled instruments, TSP can be used to take further control of the instruments' display and user interface to create mini, instrument specific applications, or Apps. TTI Apps have the extension .tspa to distinguish them from traditional .tsp scripts.

Touch, Test, Invent instruments include:
| Instrument Type |  |  |  |  |
| --- | --- | --- | --- | --- |
| Source Measure Units | [2450 SMU](https://www.tek.com/en/products/keithley/source-measure-units/2400-graphical-series-sourcemeter) | [2460 SMU](https://www.tek.com/en/products/keithley/source-measure-units/2400-graphical-series-sourcemeter) | [2461 SMU](https://www.tek.com/en/products/keithley/source-measure-units/2400-graphical-series-sourcemeter) | [2470 SMU](https://www.tek.com/en/products/keithley/source-measure-units/2400-graphical-series-sourcemeter) |
| Digital Multimeters | [DMM6500]((https://www.tek.com/en/products/keithley/digital-multimeter/dmm6500)) | [DMM7510](https://www.tek.com/en/products/keithley/digital-multimeter/dmm7510) | --- | --- |
| Data Acquisition Systems | [DAQ6510](https://www.tek.com/en/products/keithley/digital-multimeter/keithley-daq6510) | --- | --- | --- |

You can find officially supported, Keithley factory tested TTI Apps [here](https://www.tek.com/keithley/tsp-applications-for-touch-test-invent-models).

## About TSP

The TSP language is largely based on [Lua 5.0](https://www.lua.org/manual/5.0/) with instrument specific commands and some features of later Lua versions. Check the Reference Manual of your instrument for more information on TSP and for supported instrument specific commands.  
[You can read more about Lua here.](https://www.lua.org/)

## Directory

[comment]: **[Title](./file.tspa)**  

* **[TTI display API](./TTI_Display_API/)**  
This folder documents the unique commands and structure used to create TTI Apps. These commands give you control of the instruments' front-panel display and are not officially supported.

--------

* **[Calculator App](./CalculatorApp.tspa)**  
This app allows the user to perform basic calculator functions on Keithley's Touch, Test, Invent® Interface.

* **[Matrix Control](./DAQ6510_MatrxCtrl.tspa)**  
This app is for controlling and monitoring the states of the Model 7709 6x8 matrix cross points. The app detects active states upon launch and updates the UI accordingly. The user has an on-screen matrix of point to choose from as well as the ability to switch in the Row 1 and Row 2 connections to the DMM Input and Sense, respectively. 

* **[DAQ6510 7706 card Control](./DAQ6510_MultiFuncCtrl.tspa)**  
Provides hands-on front panel control of the Model 7706 multi-function module. The operator is able to manipulate the digital and analog output as well as the totalizer.

* **[Digital I/O Control](./DIOControlFull.tspa)**  
This app allows full control of the Digital I/O port.  It requires a communication card with a digital I/O port.

* **[Email Buffer](./email.tspa)**  
This app is in progress and can only be run from a computer right now.  It allows for emailing data buffers.

* **[DAQ6510 Demo](./KE_DAQ6510_Demo.tsp)**  
This script for the DAQ6510 provides a self-guided tour of the instrument's high-level features. Requires a Model 7700, 7702, 7706, 7707, 7708, or 7710 to be inserted into Slot 1 of the mainframe. 

* **[Let it Snow](./let_it_snow.tspa)**  
A simple, unoptimized holiday app to put falling snow right on the front panel of your instrument. It's surprisingly relaxing...

* **[PONG](./Pong.tspa)**  
This app is for showing off the playful side of TSP by offering a throw-back, retro-gaming experience in the form of PONG! Note that the app includes wiring instructions for the game controller station. 

* **[Probe Hold](./Probe_Hold.tspa)**  
This app adds a swipe screen to the home screen that detects stable readings and displays them on screen. The big reading is still what the DMM is currently measuring. There is a delete button to remove the last reading and a settings button. All readings ever displayed are stored in a separate buffer, called App_buffer, that can be exported just like any other buffer. defbuffer1 holds all the readings the DMM takes, like normal, so you can go back and review the exact measurements taken (though defbuffer1 clears when you change functions). Most functions are supported, the ones NOT supported are digitizing, temperature, continuity, or diode. You can swipe off the probe hold, but no measurements will take place while you’re away from it.  
Full description [here](https://forum.tek.com/viewtopic.php?f=617&t=141115).

* **[Resistance Tolerance Meter](./Resistance_Tolerance_Meter.tspa)**  
Turns the DMM6500 or DAQ6510 into a dedicated resistor tolerance meter. You can set the expected value, number of resistors to be tested, and several other options. The app gives you an option to export the data when you're done. This is basically a wrapper of the limit test functionality.
