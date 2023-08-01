# Model 2790 SourceMeter Airbag Test System

These examples include those found in the User Manual, Application Notes, and other sources. The files in this directory will work with [Model 2790 SourceMeter Airbag Test System](https://www.tek.com/en/products/keithley/source-measure-units/2400-graphical-series-sourcemeter), the sub directories will generally only work for those units, but might be able to be adapted. 

## Directory

### Instrument agnostic:

* **[](./smu_battery_cycle_solution.py)**  
This Python script can be used to perform battery cycling (charge/discharge) testing. See comments in the file for details. 

* **[PulseTrain_SVMI](./PulseTrain_SVMI.tsp)**  
Defines an operation to toggle between two source levels when a timer object elapses. The timer object is also used as the stimulus for a digital output strobe; this gives some timing marks to have more insight into the trigger blocks rate of operation/speed.

* **[SimplePulse_SIMV](./SimplePulse_SIMV.tsp)**  
Defines just about the simplest pulse that sources current and measures voltage. Use it as a starter for simple pulse needs. It does not use the dedicated pulse mode present in the 2461 SMU.

* **[SimplePulse_SVMI](./SimplePulse_SVMI.tsp)**  
Defines just about the simplest pulse that sources voltage and measures current. Use it as a starter for simple pulse needs. It does not use the dedicated pulse mode present in the 2461 SMU.

* **[Source Constant Power](./SourceConstantPower24xx.tsp)**  
A TSP script that sources constant power by adjusting voltage or current.