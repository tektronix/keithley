See the [DMM7510 User's Manual](https://www.tek.com/manual/downloads?product_series=DMM7510%20&manual_type=301) for details and usage schematics for this TSP scripts.

# Testing a buck converter

A buck converter is a highly efficient switch mode DC-to-DC voltage step-down converter. It stores
energy in the form of a magnetic field on an inductor. In the on state, the switch is closed and the
input voltage charges the inductor. In the off state, the switch is open and the inductor discharges the
stored energy as current flow through the load. Some of the key measurements involved in testing a
buck converter are:

* Ripple noise on the output voltage
* Duty cycle from switch node voltage
* Inductor current linearity with varying load
* Power-up behavior

The following test will use the Texas Instruments LM25088 evaluation board (EVM) to demonstrate
the digitizing capabilities of the Model DMM7510. Modifications were made to the LM25088
evaluation board to realize a 50 kHz switching frequency. An input voltage of 12 V is used on all
subsequent tests.

Since the maximum output current of the LM25088 is 3 A, different resistive loads can be used to
achieve a variety of loading effects, as shown in the following tests.