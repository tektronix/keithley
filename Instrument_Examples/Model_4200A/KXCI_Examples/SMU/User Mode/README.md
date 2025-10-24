# SMU

These examples are for external control of the 4200A SMU in user mode with the KXCI application running on it and using a PC.

Requirements

* Software: Any Clarius version
* KXCI terminal setup: String Terminator = None, Reading Delimiter= String Terminator, Set to ethernet mode
* KXCI Configuration (set within KCON): TH, String Terminator = None, Reading Terminator = String Terminator
* Python: Version 3.6 or later
* Dependencies:  **[instrcomms.py](../../../../General/Instrument_Communication_Resouces/instrcomms.py)**, time, pyVISA
* Optional dependencies (Need for the code to run, but can be modified to run with it. All lines are marked where these can be removed) plotly.express, pandas

## Directory

* **Combined user mode example.py** This example uses the SMU KXCI's user mode to source a 100 nA current on SMU1, and sets SMU2 to be a voltage source, sourcing 5 volts.50 voltage readings are then taken on channel 1.
* **Source current and measure voltage.py** This example uses SMU KXCI's user mode to set SMU1 to source current, outputting 1 nA and measures one reading of voltage on SMU1.
* **Source voltage and measure current.py** This example uses SMU KXCI's user mode to set SMU1 to source voltage, ouputting 5 V and measures one reading of current on SMU1.
* **Source voltage from voltage source.py** This example uses SMU KXCI's user mode to set SMU1 to be a voltage source,outputting 5 V, and measures one reading of voltage on SMU1.
