
# Measuring I-V Characteristics of FETs

This example application demonstrates how to use two Model 2450 instruments to perform I-V
characterization of field effect transistors (FETs). The Model 2450 is a good choice for semiconductor
device testing because it can quickly and accurately source and measure both current and voltage.

Determining the I-V parameters of FETs helps you ensure that they function properly in their intended
applications, and that they meet specifications. There are many I-V tests that you can perform with
the Model 2450, including gate leakage, breakdown voltage, threshold voltage, transfer
characteristics, and drain current. The number of Model 2450 instruments required for testing
depends on the number of FET terminals that must be biased and measured.

This application shows you how to perform a drain family of curves (Vds-Id) on a three-terminal
MOSFET. The MOSFET is the most commonly used FET because it is the basis for digital integrated
circuits.


You will find examples for both the SPCI and the TSP command set implementations. 
* Each is written in Python 3
* Each uses sockets-based communications to control the DAQ6510
