# CVU

These examples are for external control of the 4200A CVU in user mode with the KXCI application running on it and using a PC.

Requirements

* Software: Any Clarius version
* KXCI terminal setup: String Terminator = None, Reading Delimiter= String Terminator, Set to ethernet mode
* KXCI Configuration (set within KCON): TH, String Terminator = None, Reading Terminator = String Terminator
* Python: Version 3.6 or later
* Dependencies:  **[instrcomms.py](https://github.com/tektronix/keithley/blob/main/Instrument_Examples/General/Instrument_Communication_Resouces/instrcomms.py)**,  pyVISA

## Directory

* **Cable compensation.py** This example performs allows the user to make cable compensation measurements (load, custom, open, and short) using the 4200A-SCS CVU via an ethernet connection.
* **Single Z Measurement.py** This example performs a single-point impedance measurement on a capacitor using the 4200A-SCS CVU via an ethernet connection. It configures the CVU to put the instrument into User Mode with a 30 mV AC signal and a 5 V DC bias. One impedance result is printed to the terminal.
