# CVU

These examples are for external control of the 4200A CVU in system mode with the KXCI application running on it and using a PC.

Requirements

* Software: Any Clarius version
* KXCI terminal setup: String Terminator = None, Reading Delimiter= String Terminator, Set to ethernet mode
* KXCI Configuration (set within KCON): TH, String Terminator = None, Reading Terminator = String Terminator
* Python: Version 3.6 or later
* Dependencies:  **[instrcomms.py](../../../../General/Instrument_Communication_Resouces/instrcomms.py)**, time, pyVISA
* Optional dependencies (Need for the code to run, but can be modified to run with it. All lines are marked where these can be removed) plotly.express, pandas

## Directory


* **cap vs freq without plotting.py** This example performs a frequency sweep on a capacitor while applying a fixed DC bias and measuring impedance using the 4200A-SCS CVU via an ethernet connection. It will output a csv file containing the C-V measurements such that they may be plotted.
* **cap vs freq.py** This example performs a frequency sweep on a capacitor while applying a fixed DC bias and measuring impedance using the 4200A-SCS CVU via an ethernet connection. It will output a csv file containing the C-V measurements. It outputs a Capacitance vs Frequency graph.
* **cap vs time without plotting.py** This example performs a time-based capacitance measurement on a capacitor using the 4200A-SCS CVU via an ethernet connection. A fixed DC bias of 1 V is applied while capacitance values are sampled every 100 ms for 250 total samples. It will output a csv file containing the C-V measurements such that they may be plotted.
* **cap vs time.py** This example performs a time-based capacitance measurement on a capacitor using the 4200A-SCS CVU via an ethernet connection. A fixed DC bias of 1 V is applied while capacitance values are sampled every 100 ms for 250 total samples. It will output a csv file containing the C-V measurements. It outputs a Capacitance vs Time graph.
* **CVU sweep cap without plotting.py** This example performs a C-V sweep on a capacitor using the 4200A-SCS CVU via an ethernet connection. It will output a csv file containing the C-V measurements such that they may be plotted.
* **CVU sweep cap.py**  This example performs a C-V sweep on a capacitor using the 4200A-SCS CVU via an ethernet connection. It will output a csv file containing the C-V measurements. It outputs a Capacitance vs Voltage graph.
* **CVU sweep diode without plotting.py** This example performs a C-V sweep on a diode using the 4200A-SCS CVU via an ethernet connection. It will output a csv file containing the C-V measurements such that they may be plotted.
* **CVU sweep diode.py** This example performs a C-V sweep on a diode using the 4200A-SCS CVU via an ethernet connection. It will output a csv file containing the C-V measurements. It outputs a Capacitance vs Voltage graph.
* **CVU sweep nMOSFET GPIB without plotting.py** This example performs a C-V sweep on a nMOSFET using the 4200A-SCS CVU via a GPIB connection. It will output a csv file containing the C-V measurements such that they may be plotted.
* **CVU sweep nMOSFET GPIB.py** This example performs a C-V sweep on a nMOSFET using the 4200A-SCS CVU via a GPIB connection. It will output a csv file containing the C-V measurements. It outputs a Capacitance vs Voltage graph.
* **CVU sweep nMOSFET without plotting.py** This example performs a C-V sweep on a nMOSFET using the 4200A-SCS CVU via an ethernet connection. It will output a csv file containing the C-V measurements such that they may be plotted.
* **CVU sweep nMOSFET.py** This example performs a C-V sweep on a nMOSFET using the 4200A-SCS CVU via an ethernet connection. It will output a csv file containing the C-V measurements. It outputs a Capacitance vs Voltage graph.
* **DC Voltage List Sweep without plotting.py** This example performs a DC voltage list sweep on a capacitor using the 4200A-SCS CVU via an ethernet connection. It applies a fixed AC bias of 30 mV and steps through a custom list of DC bias voltages (0 V, 0.5 V, 1 V, -0.5 V, -1 V), measuring the impedance at each point. It will output a csv file containing the C-V measurements such that they may be plotted.
* **DC Voltage List sweep.py** This example performs a DC voltage list sweep on a capacitor using the 4200A-SCS CVU via an ethernet connection. It applies a fixed AC bias of 30 mV and steps through a custom list of DC bias voltages (0 V, 0.5 V, 1 V, -0.5 V, -1 V), measuring the impedance at each point. It will output a csv file containing the C-V measurements. Ito outputs a Capacitance vs Voltage graph.
