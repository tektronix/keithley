# CVIV

These examples are for external control of the 4200A CVIV with the KXCI application running on it and using a PC.

Requirements

* Software: Any Clarius version
* KXCI terminal setup: String Terminator = None, Reading Delimiter= String Terminator, Set to ethernet mode
* KXCI Configuration (set within KCON): TH, String Terminator = None, Reading Terminator = String Terminator
* Python: Version 3.6 or later
* Dependencies:  **[instrcomms.py](https://github.com/tektronix/keithley/blob/main/Instrument_Examples/General/Instrument_Communication_Resouces/instrcomms.py)**, time, pyVISA
* Optional dependencies (Need for the code to run, but can be modified to run with it. All lines are marked where these can be removed) plotly.express, pandas

## Directory

* **CVIV configure CVU.py** This example calls the "cviv_configure" user module to setup the CVIV for CVU measurements using the KXCI UL Mode.
* **CVIV configure SMU.py** This example calls the "cviv_configure" user module to setup the CVIV for SMU measurements using the KXCI UL Mode.
* **CVIV mosfet test without plotting.py** This example performs both I-V and C-V measurements on an n-MOSFET using the 4200A-SCS. It uses the SMUs, CVU, and CVIV by calling the UL command. **CVIV Configure for SMU Measurements:** Calls the cviv_configure user module by using the UL command. It configures the CVIV for connection to the SMUs. **Vds-Id (Family of Curves):** This example performs a family of curves measurement using the 4200A-SCS. It sweeps drain voltage (0-5 V) and steps gate voltage (1-4 V) using SMU2 and SMU3, while SMU1 holds source at 0 V. Data is segmented and saved in a Clarius-like format. **CVIV Configure for CVU Measurements:** Calls the cviv_configure user module by using the UL command. It configures the CVIVV for connection to the CVU. **cv-nmosfet:** This example performs a C-V sweep on a nMOSFET from 5 V to -5 V using the 4200A-SCS CVU. It will output a csv file containing the C-V measurements.
* **CVIV mosfet test.py** This example performs both I-V and C-V measurements on an n-MOSFET using the 4200A-SCS. It uses the SMUs, CVU, and CVIV by calling the UL command. It plots the results of the SMU and CVU tests. **CVIV Configure for SMU Measurements:** Calls the cviv_configure user module by using the UL command. It configures the CVIV for connection to the SMUs. **Vds-Id (Family of Curves):** This example performs a family of curves measurement using the 4200A-SCS. It sweeps drain voltage (0-5 V) and steps gate voltage (1-4 V) using SMU2 and SMU3, while SMU1 holds source at 0 V. Data is segmented and saved in a Clarius-like format. It outputs the family of curves on a graph. **CVIV** **Configure for CVU Measurements:** Calls the cviv_configure user module by using the UL command. It configures the CVIV for connection to the CVU. **cv-nmosfet:** This example performs a C-V sweep on a nMOSFET from 5 V to -5 V using the 4200A-SCS CVU. It will output a csv file containing the C-V measurements. It outputs capacitance vs voltage on a graph.
* **CVU CVIV comp collect.py** This example calls the "cvu_cviv_comp_collect" user module using the KXCI UL mode to setup the CVIV for CVU measurements and sets the CVU to use open compensation.
