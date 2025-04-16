# 2400 Graphical SMU Electrochemical Solutions

This Directory holds electrochemical scripts for the [2400 Graphical Series SMUs](https://www.tek.com/en/products/keithley/source-measure-units/2400-graphical-series-sourcemeter). These scripts were designed for the 2450-EC, 2460-EC and 2461-EC Potentiostat and Galvanostat Solutions. These model numbers have been discontinued and the scripts are no longer officially supported. To contribute to these scripts or suggest corrections, please see the [Contribution Guidelines](/CONTRIBUTING.md)

## Support Material

The following documents are provided to support the use of this application:

* **[EChem Users Manual](./077110403_Mar2020_ECHEM_UM.pdf)**  
User manual covering all available solutions and set up

* **[EChem Scripts Release Notes](./077110403_Mar2020_ECHEM_UM.pdf)**  
Release notes for latest file versions (March 2020)

## Required Files

These files must be loaded onto the instrument before using the tests. They provide the GUI elements for front panel use.
* **[GUI Framework](./EC_Framework.tsp)**  
GUI Framework for front panel use

* **[GUI images](./EC_Images.tsp)**  
Images used by GUI during front panel use

## Test Directory
[comment]: **[Title](./directory)**  

Note: these files must be used in conjunction with the above required files as is. They can also be modified for remote only use. 

* **[Cyclic Voltammetry](./CyclicVoltammetry.tsp)**  
Cyclic voltammetry, a type of potential sweep method, is the most commonly-used measurement electrochemical technique. In a cyclic voltammetry experiment, the working electrode potential is ramped linearly versus time. The current that flows through the circuit is measured. The resulting I-V data provides important electrochemical properties about the analyte under investigation. This application is configured and run from the front panel of the instrument. 
See section 2 in the [User Manual](./077110403_Mar2020_ECHEM_UM.pdf).

* **[Open Circuit Potential](./OpenCircuitPotential.tsp)**  
The open-circuit potential (OCP) of an electrochemical cell is the voltage between the reference and working electrodes. When the open-circuit potential is measured, a voltmeter with high impedance is used to measure the voltage with no current or voltage applied to the cell. Because of its high input impedance, your galvanostat can be used to make OCP measurements when configured for 4-wire measurements
See section 3 in the [User Manual](./077110403_Mar2020_ECHEM_UM.pdf).

* **[Potential Pulse and Square Wave](./PotentialPulseAndSquareWave.tsp)**  
In the Potential Pulse and Square Wave test, the SMU potentiostat supplies a series of up to 100,000  potential pulses. At the end of each pulse, the SourceMeter instrument measures the resulting current. You can select both the peak and base levels of the pulses, as well as the period, pulse width, and sample time.
See section 4 in the [User Manual](./077110403_Mar2020_ECHEM_UM.pdf).

* **[Current Pulse and Square Wave](./CurrentPulseAndSquareWave.tsp)**  
In the Current Pulse and Square Wave test, the SMU galvanostat supplies a series of up to 100,000 current pulses. At the end of each pulse, the SourceMeter instrument measures the resulting potential. You can select both the peak and base levels of the pulses, as well as the period, pulse width, and sample time. See section 5 in the [User Manual](./077110403_Mar2020_ECHEM_UM.pdf).

* **[Chronoamperometry](./Chronoamperometry.tsp)**  
In the chronoamperometry test, your SMU potentiostat steps the potential to a user-defined value where it is held constant for a specified period. As this potential is held, the instrument measures the resulting current at user-defined time intervals. The SMU potentiostat can repeat this process for up to ten defined steps. 
See section 6 in the [User Manual](./077110403_Mar2020_ECHEM_UM.pdf).

* **[Chronopotentiometry](./Chronopotentiometry.tsp)**  
In the chronopotentiometry test, your SMU steps the supplied current to a user-defined value where it is held constant for a specified period. As this current is held, the instrument measures the resulting potential at user-defined time intervals. The SMU galvanostat can repeat this process for up to ten defined steps. 
See section 7 in the [User Manual](./077110403_Mar2020_ECHEM_UM.pdf).