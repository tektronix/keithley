
# Measuring Low-Resistance Devices

This application example demonstrates how to use the Model 2450 to measure a low-resistance
device.

You may need to make low-resistance measurements (<10 ) in a number of applications. Typical
applications include continuity testing of cables and connectors, substrate vias, and resistors.
Typically, you make these resistance measurements by forcing a current and measuring the resulting
voltage drop. The Model 2450 automatically calculates the resistance. The measured voltage is
usually in the mV range or less. Built-in features of the Model 2450 optimize low-resistance
measurements, such as remote sensing and offset compensation.

You will find examples for both the SPCI and the TSP command set implementations. 
* Each is written in Python 3
* Each uses sockets-based communications to control the DAQ6510
