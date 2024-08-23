
# Streaming Examples

This GitHub repository features automation examples that stream data from the DMM to the controlling PC during execution. 

## Directory

[comment]: **[Title](./directory)**  

* **[Stream Data from a DMM6500](./00_Stream_Data_from_DMM6500)**  
Holds the following: <br>
  * Stream_DMM6500.py - An example that shows the user how to stream digitized readings from the instrument to the PC as fast as possible. This is the core example that shows how to...
    * Connect to an instrument using a raw sockets connection.
    * Upload a script file holding several callable functions embedded within it.
    * Execute the different functions and pull large blocks (or chunks) of data from the instrument to the PC. 
	* The user can change the triggering type expectations by specifying the script (lua) file to be uploaded.
  * functions_V3.lua - This script file holds the TSP function blocks for triggering the DMM6500 using the TSP-Link lines (requires the TSP-Link accessory cards) and getting the readings. 
  * functions_V4_EXT_Trig.lua - This script file holds the TSP function blocks for triggering the DMM6500 using the External Output & External Input trigger lines (on the rear panel of the instrument) and getting the readings.
* **[Dual Meters V and I TSP-Link Triggered](./01_Dual_Meters_V_and_I_TSP_Link_Triggered)**
This example assumes the user has two DMM6500's with TSP-Link accessory cards. The Python code will upload the complementary TSP script file and configure one meter for digitized voltage and the other for digitized current. Both meters will be triggered at the same instant and readings from each are streamed back to the controlling PC. 
 
