
# Measuring Low-Resistance Devices

This application example demonstrates how to use a Model 2450, 2460, or 2461 to measure a 
low-resistance device.

You may need to make low-resistance measurements (<10 Ω) in a number of applications. Typical
applications include continuity testing of cables and connectors, substrate vias, and resistors.
Typically, you make these resistance measurements by forcing a current and measuring the resulting
voltage drop. The SourceMeter automatically calculates the resistance. The measured voltage is
usually in the mV range or less. Built-in features of the SourceMeter optimize low-resistance
measurements, such as remote sensing and offset compensation.

You will find examples for both the SPCI and the TSP command set implementations. 
* Each is written in Python 3
* Each uses sockets-based communications to control the SourceMeter
