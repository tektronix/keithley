There examples are intended for use with the 4200A-SCS Parameter Analyzer using the KXCI application. They will only work with Clarius version 1.13 or later.

All of the code was written in python, and requires python 3.6 to run, and it was tested using python version 3.11 and 3.12.

The KXCI terminal setup is as follows: String Terminator = None, Reading Delimiter= String Terminator, Set to ethernet mode.

Required dependencies: Instrcomms, time, and pyvisa
Optional dependencies (Need for the code to run, but can be modified to run with it. All lines are marked where these can be removed)
plotly.express, pandas, plotly.graph_objects (used  in 4 chan sync test, 4 chan sync test segarb, pmu segarb b, pmu segarb complete, pulse vds-id prelim test LLEC), plotly_subplot (used in pmu segarb b)

Instrcomms can be found at the following link: https://github.com/tektronix/keithley/blob/main/Instrument_Examples/General/Instrument_Communication_Resouces/instrcomms.py

The KXCI configuration, as set within KCON, used to create these scripts was: ETH, String Terminator = None, Reading Terminator = String Terminator. If these settings are not configured the same, the scripts may fail. 

-35V to 35V without plotting:
This example creates a SegARB waveform measure sequences that outputs 35 V then -35 V and return data in waveform capture mode. 

-35V to 35V:
This example creates a SegARB waveform measure sequences that outputs 35 V then -35 V and return data in waveform capture mode. It will output a graph onto a broswer containing Current vs Time measurements.

1 chan pulse train without plotting:
This example creates a 5V amplitude pulse train on channel 1 and returns data in waveform capture mode. 

1 chan pulse train:
This example creates a 5V amplitude pulse train on channel 1 and returns data in waveform capture mode. It will output a graph onto a browser containing Voltage vs Time measurements.

1 chan sweep without plotting:
This example runs a sweep on channel 1, starting from 0 to 5V in 0.2V steps, and returns the data in pulse IV mode. 

1 chan sweep:
This example runs a sweep on channel 1, starting from 0 to 5V in 0.2V steps, and returns the data in pulse IV mode. It will output a graph onto a browser containing Current vs Voltage measurements.

4 chan sync test segarb without plotting:
This example synchronizes 4 PMU channels using SegARB to output 1V, 2V, 3V, and 4V on channels 1 through 4 respectively, and reutrns data in waveform capture mode. 

4 chan sync test segarb:
This example synchronizes 4 PMU channels using SegARB to output 1V, 2V, 3V, and 4V on channels 1 through 4 respectively, and reutrns data in waveform capture mode. It will output a graph onto a browser containing Voltage vs Time measurements.

4 chan sync test without plotting:
This example synchronizes 4 PMU channels using pulse train to output 1V, 2V, 3V, and 4V on channels 1 through 4 respectively, and returns data in waveform capture mode.

4 chan sync test:
This example synchronizes 4 PMU channels using pulse train to output 1V, 2V, 3V, and 4V on channels 1 through 4 respectively, and returns data in waveform capture mode. It will output a graph onto a browser containing Voltage vs Time measurements.

pmu segarb b without plotting:
This example is a KXCI recreation of the Clarius pmu SegARB b test with a 82 segment sequence, and returns data in pulse IV mode. 

pmu segarb b:
This example is a KXCI recreation of the Clarius pmu SegARB b test with a 82 segment sequence, and returns data in pulse IV mode. It will output two graphs onto a browser containing Voltage vs Time and Current vs Time measurements.

pmu segarb complete without plotting:
This example is a KXCI recreation of the Clarius pmu SegARB complete test with a 82 segment sequence, and returns data in waveform capture mode.

pmu segarb complete:
This example is a KXCI recreation of the Clarius pmu SegARB complete test with a 82 segment sequence, and returns data in waveform capture mode. It will output a graph onto a browser containing Voltage vs Time measurements.

pulse IV segarb without plotting:
This example creates a SegARB waveform measure sequence that outputs various voltage values on channel 1, and returns data in pulse IV mode.

pulse IV segarb:
This example creates a SegARB waveform measure sequence that outputs various voltage values on channel 1, and returns data in pulse IV mode. It will output a graph onto a browser containing Current vs Voltage measurements.

pulse vds-id with LLEC without plotting:
This example is a KXCI recreation of the Clarius pulse-vds-id test with a pulse amplitude step on channel 1 from 2 to 4 V in 0.5 V steps, and a pulse amplitude sweep on channel 2 from 0 to 5 V in 0.2 V steps. It returns data back in pulse IV mode. 

pulse vds-id with LLEC:
This example is a KXCI recreation of the Clarius pulse-vds-id test with a pulse amplitude step on channel 1 from 2 to 4 V in 0.5 V steps, and a pulse amplitude sweep on channel 2 from 0 to 5 V in 0.2 V steps. It returns data back in pulse IV mode. It will output a graph onto a browser containing Current vs Voltage measurements.

simple segarb pulse without plotting: 
This example creates a SegARB waveform measure sequence that outputs a 1V sequence with configured rise and fall times on channel 1, returning data back in waveform capture mode.

simple segarb pulse: 
This example creates a SegARB waveform measure sequence that outputs a 1V sequence with configured rise and fall times on channel 1, returning data back in waveform capture mode. It will output a graph onto a browser containing Voltage vs Time measurements.