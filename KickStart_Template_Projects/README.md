# KickStart Template Projects
This folder contains full projects that can be loaded into, and run on Keithley's [Kickstart software](https://www.tek.com/products/keithley/keithley-control-software-bench-instruments/kickstart).

## How to use these projects
Download the .kzp file for the template project you want (see instructions in the [main README](/README.md#downloading-files)) and use KickStart's Open Project button to open the downloaded .kzp file. 

The test will open and you will see Simulated Instruments added to the left pane of KickStart, along with error messages for "Could not find..." whatever instruments the project uses. Use the "Instruments" button in the bottom right of the test window to swap these simulated instruments for real instruments on your bench. The test will then be ready to run. 

Each folder in this directory is accompanied by KickStart's .csv and .png exports showing expected results.

## Directory

[comment]: **[Title](./folder)**  

* **[BJT Gummel Plot](./BJT_Gummel)**  
Find the logarithm of the base current as a function of the emitter-base voltage in a BJT device. (Linear graph included)

* **[BJT Vce-Ic](./BJT_vce_ic)**  
Find the relationship between current and voltage at the collector of a BJT device.

* **[BJT Vc Saturation](./BJT_vcsat)**  
Find the saturation voltage between the collector and emitter terminals of a BJT device.

* **[Diode - Forward Bias - 1 Channel](./VFD_1channel)**  
Find the forward bias voltage of a diode using only 1 channel of a multichannel SMU (Ex: 2612B) or using 1 single-channel SMU (Ex: 2450).

* **[Diode - Forward Bias - 2 Channel](./VFD_2channel)**  
Find the forward bias voltage of a diode using both channels of a multichannel SMU (Ex: 2612B) or using 2 single-channel SMUs (Ex: 2450).

* **[Diode - Reverse Bias - 1 Channel](./VRD_1channel)**  
Find the reverse bias voltage of a diode using only 1 channel of a multichannel SMU (Ex: 2612B) or using 1 single-channel SMU (Ex: 2450).

* **[Diode - Reverse Bias - 2 Channel](./VRD_2channel)**  
Find the reverse bias voltage of a diode using both channels of a multichannel SMU (Ex: 2612B) or using 2 single-channel SMUs (Ex: 2450).

* **[NFET Ig-Vg](./NFET_ig-vg)**  
Find the gate current leakage occurring in a MOSFET device.

* **[NFET Vds-Id](./NFET_vds-id)**  
Find the relationship between current and voltage at the Drain of a MOSFET device.

* **[NFET Vgs-Id](./NFET_vgs-id)**  
Find the threshold voltage and Max Gain of a MOSFET device.

* **[Resistor Sweep](./resistor_sweep)**  
Find the relationship between current and voltage in a resistor when voltage is sourced.