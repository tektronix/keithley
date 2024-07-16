# Series 3706A Systems Switch/Multimeter

## Directory

[comment]: **[Insturment](./directory)**  

* **[DC Voltage Scan with Options and File Write](./DC_Voltage_Scan_with_Options_and_File_Write/)**  
Python code example for configuring a voltage scan and writing the results of the scan to a file. A TSP example is included as well which duplicates the scanning behavior, but does not inlcude an example of writing to the USB, though room is left to define that behavior.

* **[Three Reasons to Consider Solid State Switching](./Solid_State_Examples)**  
Python, C#, and TSP code examples from the appendices of the white paper "Three Reasons to Consider Solid State Switching" found [on tek.com](https://www.tek.com/document/whitepaper/three-reasons-consider-solid-state-switching-your-data-acquisition-system). Examples specifically target the DAQ6510 Data Acquisition and Multimeter System and Series 3706A System Switch/Multimeter. While these examples are intended to be used with the 7710 and 3724 solid state multiplexers (for the DAQ6510 and 3706A, respectively), they can also be used with other multiplexer card models. The biggest difference will be speed; secondary is channel compatibility.

* **[Trigger Scanning with Digital IO](./Trigger_Scanning_with_Digital_IO/)**  
TSP example code to trigger scans based on Digital I/O input. Examples are provided for triggering on a falling edge or triggering on rising/falling edges.