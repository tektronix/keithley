
# Mixed Function Multi-Channel Scanning

This example application demonstrates how to use the DAQ6510 to perform complex multi-channel,
mixed function scanning in a production-test environment.
The DAQ6510 can perform more than one function in a multichannel scan, providing a range of dataacquisition
options in a single test.
In this production environment the DAQ6510 is:
• Integrated into a test stand.
• Wired to a fixture that is connected to an active device under test (DUT).
• Quickly capturing DC volts and current, temperature, and AC volts and current.
Prior to the start of the scan, you can step through each of the configured channels on the DAQ6510,
which allows you to troubleshoot the test configuration. This allows you to view the readings of
individually closed channels to ensure that connections to the DUT are secure.

You will find examples for both the SPCI and the TSP command set implementations. 
* Each is written in Python 3
* Each uses sockets-based communications to control the DAQ6510
