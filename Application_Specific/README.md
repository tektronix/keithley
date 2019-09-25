
# Application Specifc Code

This GitHub repository stores application specifc code for one or multiple Keithley Instruments products.

## Directory

[comment]: **[Title](./directory)**  

* **[Amp-hour Measurement with DMM6500](./Amp-Hour_Measurement)**  
TSP script for the DMM6500 to measure Amp-hours (charge) or Watt-hours (energy). Written to be run entirely from the front panel.

* **[Battery Simulation](./Battery_Simulation/2281S_Battery_Models)**  
Holds a repository of battery models for the [2281S-20-6 Dynamic Model Battery Simulator](https://www.tek.com/tektronix-and-keithley-dc-power-supplies/2281s).

* **[Three Reasons to Consider Solid State Switching](./Three_Reasons_to_Consider_Solid_State_Switching_Examples)**  
Python, C#, and TSP code examples from the appendices of the white paper "Three Reasons to Consider Solid State Switching" found [on tek.com](https://www.tek.com/document/whitepaper/three-reasons-consider-solid-state-switching-your-data-acquisition-system). Examples specifically target the DAQ6510 Data Acquisition and Multimeter System and Series 3706A System Switch/Multimeter. While these examples are intended to be used with the 7710 and 3724 solid state multiplexers (for the DAQ6510 and 3706A, respectively), they can also be used with other multiplexer card models. The biggest difference will be speed; secondary is channel compatibility.

* **[Increase 4-Wire Resistance Measurement Capability with Common-side Ohms](./Increase_4-Wire_Resistance_Measurement_Capability_with_Common-side_Ohms)**  
C# code examples to target increased 4-wire measurement bandwidth per multiplexer card using the Common-side Ohms functionality. 
