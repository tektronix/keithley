
# Application Specifc Code

This GitHub repository stores application specifc code for one or multiple Keithley Instruments products.

## Directory

[comment]: **[Title](./directory)**  

* **[Amp-hour Measurement with DMM6500](./Amp-Hour_Measurement)**  
TSP script for the DMM6500 to measure Amp-hours (charge) or Watt-hours (energy). Written to be run entirely from the front panel.

* **[Battery Simulation](./Battery_Simulation/2281S_Battery_Models)**  
Holds a repository of battery models for the [2281S-20-6 Dynamic Model Battery Simulator](https://www.tek.com/tektronix-and-keithley-dc-power-supplies/2281s).

* **[Custom Thermistor](./Custom_Thermistor)**  
Allows the usage of custom Steinhart–Hart coefficients to compute the temperature of a thermistor.

* **[Hall Effect Test Suite](./Hall_Effect_Test_Software/)**  
Files to be used with LabVIEW 2018 for controlling a 3765 plug-in card for a 3706A to preform Hall Effect and van der Pauw measurements. A current source (recommend Keithley Model 6221) is also required. Optional picoammeter and nanovoltmeter (recommnd Keithley models 6485 or 6487, Keithley model 2182A) can improve your measurements. A stand-alone, containerized version of this software is available [on tek.com](https://www.tek.com/en/search?op=&keywords=Keithley+Hall+Effect+Test+Suite+%28NOT+SUPPORTED%29&sort=&facets=_templatename%3DSoftware%26parsedsoftwaretype%3DApplication) as the last supported version (part Number: KHETS-2.0). If you make future fixes to the software, please make a pull request against this folder and update the .zip file. The .zip file contains the files in this directory.

* **[Increase 4-Wire Resistance Measurement Capability with Common-side Ohms](./Increase_4-Wire_Resistance_Measurement_Capability_with_Common-side_Ohms)**  
C# and Python code examples to target increased 4-wire measurement bandwidth per multiplexer card using the Common-side Ohms functionality. 