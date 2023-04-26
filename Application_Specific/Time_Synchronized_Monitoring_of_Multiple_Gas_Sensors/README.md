
# Time Synchronized Monitoring of Multiple Gas Sensors

This GitHub repository features automation examples used for gas sensor monitoring made using multiple Keithley 2450 Interactive SourceMeter Instruments.

## Directory

[comment]: **[Title](./directory)**  

* **[MS01_SetupAndRun.tsp](./MS01_SetupAndRun.tsp)**  
  * Configures the TSP-Linked SMUs for Source Voltage, Measure Resistance.
  * Builds three different variations of trigger model:
	* One for the master to act as the main initiator for the trigger to all units to measure.
	* One for the primary acceptor to coordinate the measure complete from all acceptors and notification back to the master.
	* One for remaining acceptors to receive trigger events and to report back measure completion
  * Configures/sizes the default buffers to accommodate up to 5.1M readings per run 
	
* **[MS02_ExportData.tsp](./MS02_ExportData.tsp)** 
  * Creates a timestamped CSV on a connected USB drive. 
  * Extracts the data from all connected instrument nodes.
  * Writes all data to USB and uses the relative times of the master for timestamps. 

 
