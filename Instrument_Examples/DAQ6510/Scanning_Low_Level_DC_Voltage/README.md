
# Scanning Low-Level DC Voltage

This application example demonstrates how to use the DAQ6510 to accurately measure DC voltage
in a variety of ranges. To ensure accurate data, the NPLC (Number of Power Line Cycles) and
autozero options are used for this test.

The NPLC setting can be used to help reduce the induced noise originating from nearby AC
power-conditioning circuits. A desktop power supply or power-transmission lines would generate this
type of noise. Increasing NPLC cancels out this noise by integrating all sampled data collected in
multiples of AC signal periods (n * 1/(transmission line frequency) seconds). The more AC line cycles
used in the measurement, the more accurate the reading. The time required to conduct the scan also
increases.

The autozero function removes offset voltages that result from thermal EMFs. Thermal EMFs occur
when there is a temperature difference at junctions consisting of different materials. For example,
leads, instrument inputs, or card terminals. These EMFs adversely affect DCV measurement
accuracy by offsetting the measured voltage.
This example shows how to measure voltage in different ranges. To optimize scanning speed, you
should set a fixed range. If speed is not an issue, the measurement range can be set to auto.

You will find examples for both the SPCI and the TSP command set implementations. 
* Each is written in Python 3
* Each uses sockets-based communications to control the DAQ6510
