
# Scanning Resistors Using 4W Measurement 

This example application demonstrates how to use the DAQ6510 to accurately measure resistance
across multiple devices. To obtain the best results, the 4-wire (Kelvin) measurement method and
offset compensation are used for this test.

Typical resistance measurements made using the 2-wire method source current through the test
leads and the device under test (DUT). The voltage is measured, and the resistance is calculated.
It is difficult to obtain accurate 2-wire resistance measurements when the DUT is lower than 100 Ω.
Typical lead resistances lie in the range of 1 mΩ to 10 mΩ. When the 2-wire method is applied to lowresistance
measurements, there is a small but significant voltage drop across the resistance of each
test lead. The voltage measured by the instrument is not the same as the voltage directly across the
DUT.

The 4-wire method is preferred for low-resistance measurements. With this configuration, the test
current is sourced through the DUT using one set of test leads, while a second set of SENSE leads
measures the voltage across the DUT. The voltage-sensing leads are connected as close to the
device under test as possible to avoid including the resistance of the test leads in the measurement.

Thermoelectric voltages (EMFs) can seriously affect low-resistance measurement accuracy. The
DAQ6510 can apply the offset-compensated ohms method (OCOMP), which makes one normal
resistance measurement and one using the lowest current source setting to eliminate EMFs.

For this example, you will use resistors of different low values across multiple channels of a 7700
multiplexer module and examine how the 4-wire measurement method provides a more accurate
reading than the 2-wire method. Fixed measurement ranges are applied in order to optimize scanning
speed and OCOMP is applied to correct for any EMF effects.

You will find examples for both the SPCI and the TSP command set implementations. 
* Each is written in Python 3
* Each uses sockets-based communications to control the DAQ6510
