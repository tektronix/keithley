# SMU

These examples are for external control of the 4200A SMU in system mode with the KXCI application running on it and using a PC.

Requirements

* Software: Any Clarius version
* KXCI terminal setup: String Terminator = None, Reading Delimiter= String Terminator, Set to ethernet mode
* KXCI Configuration (set within KCON): TH, String Terminator = None, Reading Terminator = String Terminator
* Python: Version 3.6 or later
* Dependencies:  **[instrcomms.py](../../../../General/Instrument_Communication_Resouces/instrcomms.py)**, time, pyVISA
* Optional dependencies (Need for the code to run, but can be modified to run with it. All lines are marked where these can be removed) plotly.express, pandas

## Directory

* **2 SMUs 0V.py** This example performs a static bias test using the 4200A-SCS.Both SMU1 and SMU2 are set to 0 V to monitor baseline current behavior. It measures current on both SMUs over time and logs the data to CSV.
* **4 SMUs 0V.py** This example configures all four SMUs on a 4200A-SCS to source 0 V with 1 µA compliance. It performs a fixed current measurement (100 nA) on each channel, takes 3 readings, and saves the results with timestamps to a CSV file.
* **Current sweep without plotting.py** This example performs a current sweep using the 4200A-SCS in list display mode. SMU2 sources current from 1 µA to 10 µA in 1 µA steps, while SMU1 holds constant current. It measures voltage and current on both SMUs and logs the data to CSV.
* **Current sweep.py** This example performs a current sweep using the 4200A-SCS in list display mode. SMU2 sources current from 1 µA to 10 µA in 1 µA steps, while SMU1 holds constant current. It measures voltage and current on both SMUs and logs the data to CSV. It outputs a Drain Current vs Drain Voltage graph.
* **family_of_curves data retrival GPIB.py** *This example requires a GPIB connection. Settings within KCON: String Terminator = LF, Reading Delimiter = Comma.* This example performs a family of curves measurement using the 4200A-SCS. It sweeps drain voltage (0-5 V) and steps gate voltage (1-4 V) using SMU2 and SMU3, while SMU1 holds source at 0 V. Data is segmented and saved in a Clarius-like format.
* **family_of_curves data retrival.py** This example performs a family of curves measurement using the 4200A-SCS. It sweeps drain voltage (0-5 V) and steps gate voltage (1-4 V) using SMU2 and SMU3, while SMU1 holds source at 0 V. Data is segmented and saved in a Clarius-like format.
* **Linear sweep without plotting.py** This example performs a VAR1 linear sweep using the 4200A-SCS in list display mode. SMU2 sweeps from 1 V to 5 V in 0.1 V steps while SMU1 holds 0 V. It measures voltage and current on both SMUs and logs the data to CSV.
* **Linear sweep.py** This example performs a VAR1 linear sweep using the 4200A-SCS in list display mode. SMU2 sweeps from 1 V to 5 V in 0.1 V steps while SMU1 holds 0 V. It measures voltage and current on both SMUs and logs the data to CSV. It outputs a Drain Current vs Drain Voltage graph.
* **List sweep.py** This example performs a custom list sweep using the 4200A-SCS. SMU1 sweeps from 0 to 1 V in 100 linear steps (defined via NumPy), while SMU2 holds 0 V. It measures voltage on both SMUs and logs the data to CSV.
* **Log sweep without plotting.py** This example performs a log-scale VAR1 sweep using the 4200A-SCS in list display mode. SMU2 sweeps from 1 V to 10 V (log10 scale) while SMU1 holds 0 V. It measures voltage and current on both SMUs and logs the data to CSV.
* **Log sweep.py** This example performs a log-scale VAR1 sweep using the 4200A-SCS in list display mode. SMU2 sweeps from 1 V to 10 V (log10 scale) while SMU1 holds 0 V.It measures voltage and current on both SMUs and logs the data to CSV. It outputs a Diode Forward I-V Sweep graph.
* **Multi-channel sweep without plotting.py** This example performs a multi-channel sweep using the 4200A-SCS. SMU1 performs a linear VAR1 sweep from 0 to 1 V, while SMU2 and SMU3 follow the same sweep using VAR1' ratio mode. It measures voltage and current on all three SMUs and logs the data to CSV.
* **Multi-channel sweep.py** This example performs a multi-channel sweep using the 4200A-SCS. SMU1 performs a linear VAR1 sweep from 0 to 1 V, while SMU2 and SMU3 follow the same sweep using VAR1' ratio mode. It measures voltage and current on all three SMUs and logs the data to CSV. It outputs a Drain Voltage vs Gate Current graph.
* **res2t.py** This example recreates the Clarius res2t test by performing a 2-terminal resistance sweep using the 4200A-SCS. It sweeps voltage from -1 V to 1 V on SMU1 while SMU2 holds 0 V, measures current, and calculates average resistance.
