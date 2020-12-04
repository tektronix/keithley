
# Scan Temperature Using Thermocouples

This application example demonstrates how to use the DAQ6510 to log thermocouple-based
temperature measurement scans, using internal cold-junction compensation (CJC) correction, over a
24-hour period.

This type of test is typically performed when a device under test (DUT) is placed in an environmental
chamber and exposed to extreme conditions. The system captures data at different locations on the
DUT. The data is then exported from the DAQ6510 to a computer where a thermal profile is
generated. This thermal profile provides designers and consumers with a thorough understanding of
the thermal operating characteristics of their device or product.

You will find examples for both the SPCI and the TSP command set implementations. 
* Each is written in Python 3
* Each uses sockets-based communications to control the DAQ6510

| Example                                                | Language                                                     |
| ------------------------------------------------------ | ------------------------------------------------------------ |
| **[Long Term Scanning with Plotting]** | [![Python 3.6](https://img.shields.io/badge/python-3.6-&?labelColor=3E434A&colorB=006281&logo=python)](https://www.python.org/downloads/release/python-360/) |

