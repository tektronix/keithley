# Keithley_DMM6500_Drivers
This effort supports series of requests for instrument drivers and/or examples that an act as foundation code for the operator of a Keithley DMM6500 or DAQ6510 digital multimeter/switching system. 

## Requirements
For Python-based examples, [Python 3.5](https://www.python.org/) or higher is known to work with the Python-based example. 

For Visual Studio-based examples, [Microsoft Visual Studio 2017](https://visualstudio.microsoft.com/vs/community/) - the "Community" version is good enough. 

### Supplemental Requirements...
When using a **Linux** environment with the Sockets Driver for the Python examples which use the Initial State tools for writing data to the cloud, you will first need to issue one of the following two commands at a terminal window to install the ISStreamer module:
- (Python 2.7) `sudo pip install ISStreamer`
- (Python 3) `sudo pip3 install ISStreamer`
   
When using a **Win10** environment with the Python Sockets Driver examples which use the Initial State tools for writing data to the cloud, you will first need to issue the following at a command prompt to install the ISStreamer module: 
- `pip install ISStreamer`


## Supported Instruments
DMM6500
DAQ6510



## Maintainer
Josh Brown [jbrown1234](https://github.com/jbrown1234)

Factory Applications Engineer - Keithley Instruments
