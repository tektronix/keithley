# Series 2400 Graphical Source Measure Units

These examples include those found in the User Manual, Application Notes, and other sources. The files in this directory will work with all [2400 Graphical SMUs](https://www.tek.com/en/products/keithley/source-measure-units/2400-graphical-series-sourcemeter), the sub directories will generally only work for those units, but might be able to be adapted. 

## Directory

### Specific to instruments:
[comment]: **[2450-SMU](./directory)**  

* **[2450-SMU](./2450-SMU/)**  
200V / 1A SMU with Triaxial outputs

* **[2460-SMU](./2460-SMU/)**  
100V / 1A SMU

* **[2461-SMU](./2461-SMU/)**  
100V / 10A (pulsed) SMU

* **[2470-SMU](./2470-SMU/)**  
1100V / 1A SMU with high-V triaxial outputs

### Instrument agnostic:

* **[Battery Cycler](./smu_battery_cycle_solution.py)**  
This python script can be used to perform battery cycling (charge/discharge) testing. See comments in the file for details. 

* **[Pulse V Measure I](./PulseV_MeasureI.tsp)**  
Defines an operation to toggle between two source levels when a timer object elapses. The timer object is also used as the stimulus for a digital output strobe; this gives some timing marks to have more insight into the trigger blocks rate of operation/speed.

* **[Source Constant Power](./SourceConstantPower24xx.tsp)**  
A TSP script that sources constant power by adjusting voltage or current.
