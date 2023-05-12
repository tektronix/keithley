# KXCI

These examples are for external control of the 4200A with the KXCI application running on it and using a PC.

## Directory

* **[CVU_sweep_GPIB_keithleyLib.py](./CVU_sweep_GPIB_keithleyLib.py/)**  
This example performs a C-V sweep on a MOSFET using the 4200A-SCS CVU via a GPIB connection. It will output a csv file containing the C-V measurements such that they may be plotted.

* **[family_curves_GPIB_keithleyLib.py](./family_curves_GPIB_keithleyLib.py/)**  
This example performs a family of curves test on a MOSFET, using the 4200A-SCS with three SMUs connected to a MOSFET via a GPIB connection. It will output the ID-VD Curves of the MOSFET directly onto the KXCI interface. 

* **[ffamily_curves_LAN_keithleyLib.py](./family_curves_LAN_keithleyLib.py/)**  
This example performs a family of curves test on a MOSFET, using the 4200A-SCS with three SMUs connected to a MOSFET via a LAN connection. It will output the ID-VD Curves of the MOSFET directly onto the KXCI interface. 
