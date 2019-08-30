
# Pre-scan Monitor

Many products need to be environmentally-stressed during performance testing. This is accomplished
by placing the device in a chamber where the temperature can be set and controlled and soaking the
DUT at the required set-point conditions. Temperature changes are not instantaneous so there is
some wait time between scans. The DAQ6510 can monitor the environment until the target
temperature has been reached at which point the instrument automatically begins the scan.

This application example demonstrates how to use a DAQ6510 to initiate a scan based on the
temperature of the environment around the device under test (DUT). This example will model a
situation where resistance DUTs are measured after the temperature exceeds 30 °C.

You will find examples for both the SPCI and the TSP command set implementations. 
* Each is written in Python 3
* Each uses sockets-based communications to control the DAQ6510
