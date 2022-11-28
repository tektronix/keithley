# KickStart Template Projects
This folder contains full projects that can be loaded into, and run on Keithley's [Kickstart software](https://www.tek.com/products/keithley/keithley-control-software-bench-instruments/kickstart).

## How to use these projects
Download the .kzp file for the template project you want (see instructions in the [main README](/README.md#downloading-files)) and use KickStart's Open Project button to open the downloaded .kzp file. 

The test will open and you will see Simulated Instruments added to the left pane of KickStart, along with error messages for "Could not find..." whatever instruments the project uses. Use the "Instruments" button in the bottom right of the test window to swap these simulated instruments for real instruments on your bench. The test will then be ready to run. 

Each folder in this directory is accompanied by KickStart's .csv and .png exports showing expected results.

## Directory

[comment]: **[Title](./folder)**  

* **[NFET Ig-Vg Test](./NFET_ig-vg)**  
Test to see the gate current leakage occurring in a MOSFET device.

* **[NFET Vds-Id Test](./NFET_vds-id)**  
Test to see the relationship between Current and Voltage at the Drain of a MOSFET device.

* **[NFET Vgs-Id](./NFET_vgs-id)**  
Test to see the Threshold Voltage and Max Gain of a MOSFET device.

* **[Resistor Sweep](./resistor_sweep)**  
Test to see the relationship between Current and Voltage in a resistor when Voltage is sourced.

* **[Diode - Forward Bias - 1 Channel](./VFD_1channel)**  
Test to see the Forward Bias Voltage of a Diode using only 1 channel of a multichannel SMU (Ex: 2612B) or using 1 single-channel SMU (Ex: 2450).

* **[Diode - Forward Bias - 2 Channel](./VFD_2channel)**  
Test to see the Forward Bias Voltage of a Diode using both channels of a multichannel SMU (Ex: 2612B) or using 2 single-channel SMUs (Ex: 2450).

* **[Diode - Reverse Bias - 1 Channel](./VRD_1channel)**  
Test to see the Reverse Bias Voltage of a Diode using only 1 channel of a multichannel SMU (Ex: 2612B) or using 1 single-channel SMU (Ex: 2450).

* **[Diode - Reverse Bias - 2 Channel](./VRD_2channel)**  
Test to see the Reverse Bias Voltage of a Diode using both channels of a multichannel SMU (Ex: 2612B) or using 2 single-channel SMUs (Ex: 2450).

