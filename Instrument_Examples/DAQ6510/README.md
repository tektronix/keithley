# DAQ6510 Examples

These code examples are a good place to start learning how to work with your [DAQ6510 Data Acquisition and Logging, Multimeter System](https://www.tek.com/en/products/keithley/digital-multimeter/keithley-daq6510) over a remote interface. 

## Directory

[comment]: **[Instrument](./directory)**  

* **[Frequency Scanning](./Frequency_Scanning/)**  
Example in C# and Visual Basic to scan frequency, see code comments for more. 

* **[Initialize LabVIEW with RS-232](./LabVIEW_Initialize_with_RS232_Option/)**  

* **[Load and Run a TSP Script](./Load_and_Run_a_TSP_Script_File/)**  
Visual Basic example (with dummy TSP script) to load and run a TSP file.

* **[Long Term Scanning with Plotting](./Long_Term_Scan_with_Plotting/)**  
Python example to scan thermocouples over 24+ hours and plot results with matplotlib. See README in directory for more.

* **[Mixed Function Multi-Channel Scanning](./Mixed_Function_Multi-Channel_Scanning/)**  
Python and Visual Basic examples to perform more complex scans with multiple measurement functions. See README in directory for more. 

* **[Mixed Signal Scanning](./Mixed_Signal_Scanning/)**  
Python and MatLab example with RS-232 to set up and execute a scan with multiple measurement functions. 

* **[Model 7707](./Model_7707/)**  
Zipped C# project to control the DIO ports on the 7707 Differential Multiplexer Switch Card and TSP Script to configure the same card. See README in directory for more.

* **[Pre-Scan Monitor](./Pre-Scan_Monitor/)**  
Python examples with TSP and SCPI commands to wait for a temperature chamber to come up to temperature before executing a scan. See README in directory for more. 

* **[Scan Temperature using Thermocouples](./Scan_Temperaure_Using_Thermocouples/)**  
Python and Visual Basic examples to scan temperature with thermocouples. See README in directory for more. 

* **[Scanning Low Level DC Voltage](./Scanning_Low_Level_DC_Voltage/)**  
Python examples demonstrating the use of NPLC and Autozero functions to accurately measure low voltage. See README in directory for more. 

* **[Scannig Resistors with 4W Measurement](./Scanning_Resistors_Using_4W_Measurement/)**  
Python examples to scan ressitance measurements with a preference for 4-wire/Kelvin connections. See README in directory for more. 

* **[Speed Scanning for Increased Throughput](./Speed_Scanning_for_Increased_Test_Throughput/)**  
Python examples demonstrating differences in scan speed between the 7700, 7703, and 7710 multiplexer modules. See README in directory for more. 

* **[Three Ways to Manage Scanning](./Three_Ways_To_Manage_Scanning/)**  
Three python examples demonstrating different ways to control a scan: a traditional triggered approach, a manual approach, and a interval triggered approach. See README in directory for more. 

* **[Use the DAQ6510 to Control a Temperature Chamber](./Use_the_DAQ6510_to_Control_a_Temperature_Chamber/)**  
TSP script accompanying the Application Note: [Combined Temperature Control and Data Acquisition Control](https://www.tek.com/documents/how-guide/combined-temperature-control-and-data-acquisition-control) which demonstrates controlling a TestEquity Model 115A Temperature Controller while making DUT measurements. See video supplement [on YouTube](https://youtu.be/za0dFierQkI).

* **[Using the 7701 as a Switch](./Using%20the%20Model%207701%20Multiplexer%20in%20a%20Switching-Only%20Application/)**  
Python example to use the 7701 card as a switch matrix without DAQ measurement. See PDF in directory. 
