# PMU

These examples are for external control of the 4200A PMU with the KXCI application running on it and using a PC. 

Requirements

* Software: Clarius Version 1.13 or later (exception: pmu_scope_annotated.py)
* KXCI terminal setup: String Terminator = None, Reading Delimiter= String Terminator, Set to ethernet mode
* KXCI Configuration (set within KCON): TH, String Terminator = None, Reading Terminator = String Terminator
* Python: Version 3.6 or later
* Dependencies: **[instrcomms.py](../../../General/Instrument_Communication_Resouces/instrcomms.py)**, time, pyVISA
* Optional dependencies (Need for the code to run, but can be modified to run with it. All lines are marked where these can be removed)
plotly.express, pandas, plotly.graph_objects (used  in 4 chan sync test, 4 chan sync test segarb, pmu segarb b, pmu segarb complete, pulse vds-id prelim test LLEC), plotly_subplot (used in pmu segarb b)


## Directory

* **[-35V to 35V without plotting.py](./-35V%20to%2035V%20without%20plotting.py)**
This example creates a SegARB waveform measure sequences that outputs 35 V then -35 V and return data in waveform capture mode. 

* **[-35V to 35V.py](./-35V%20to%2035V.py)**
This example creates a SegARB waveform measure sequences that outputs 35 V then -35 V and return data in waveform capture mode. It will output a graph onto a broswer containing Current vs Time measurements.

* **[1 chan pulse train without plotting.py](./1%20chan%20pulse%20train%20without%20plotting.py)**
This example creates a 5V amplitude pulse train on channel 1 and returns data in waveform capture mode. 

* **[1 chan pulse train.py](./1%20chan%20pulse%20train.py)**
This example creates a 5V amplitude pulse train on channel 1 and returns data in waveform capture mode. It will output a graph onto a browser containing Voltage vs Time measurements.

* **[1 chan sweep without plotting.py](./1%20chan%20sweep%20without%20plotting.py)**
This example runs a sweep on channel 1, starting from 0 to 5V in 0.2V steps, and returns the data in pulse IV mode. 

* **[1 chan sweep.py](./1%20chan%20sweep.py)**
This example runs a sweep on channel 1, starting from 0 to 5V in 0.2V steps, and returns the data in pulse IV mode. It will output a graph onto a browser containing Current vs Voltage measurements.

* **[4 chan sync test segarb without plotting.py](./4%20chan%20sync%20test%20segarb%20without%20plotting.py)**
This example synchronizes 4 PMU channels using SegARB to output 1V, 2V, 3V, and 4V on channels 1 through 4 respectively, and reutrns data in waveform capture mode. 

* **[4 chan sync test segarb.py](./4%20chan%20sync%20test%20segarb.py)**
This example synchronizes 4 PMU channels using SegARB to output 1V, 2V, 3V, and 4V on channels 1 through 4 respectively, and reutrns data in waveform capture mode. It will output a graph onto a browser containing Voltage vs Time measurements.

* **[4 chan sync test without plotting.py](./4%20chan%20sync%20test%20without%20plotting.py)**
This example synchronizes 4 PMU channels using pulse train to output 1V, 2V, 3V, and 4V on channels 1 through 4 respectively, and returns data in waveform capture mode.

* **[4 chan sync test.py](./4%20chan%20sync%20test.py)**
This example synchronizes 4 PMU channels using pulse train to output 1V, 2V, 3V, and 4V on channels 1 through 4 respectively, and returns data in waveform capture mode. It will output a graph onto a browser containing Voltage vs Time measurements.

* **[pmu_scope_annotated.py](./pmu_scope_annotated.py/)**  
This program outputs five square wave pulses (2V, 50e-6s) from a 4225-PMU without the 4225-RPMs. This code uses ethernet to communicate to the 4200A.

* **[pmu segarb b without plotting.py](./pmu%20segarb%20b%20without%20plotting.py)**
This example is a KXCI recreation of the Clarius pmu SegARB b test with a 82 segment sequence, and returns data in pulse IV mode. 

* **[pmu segarb b.py](./pmu%20segarb%20b.py)**
This example is a KXCI recreation of the Clarius pmu SegARB b test with a 82 segment sequence, and returns data in pulse IV mode. It will output two graphs onto a browser containing Voltage vs Time and Current vs Time measurements.

* **[pmu segarb complete without plotting.py](./pmu%20segarb%20complete%20without%20plotting.py)**
This example is a KXCI recreation of the Clarius pmu SegARB complete test with a 82 segment sequence, and returns data in waveform capture mode.

* **[pmu segarb complete.py](./pmu%20segarb%20complete.py)**
This example is a KXCI recreation of the Clarius pmu SegARB complete test with a 82 segment sequence, and returns data in waveform capture mode. It will output a graph onto a browser containing Voltage vs Time measurements.

* **[pulse IV segarb without plotting.py](./pulse%20IV%20segARB%20without%20plotting.py)**
This example creates a SegARB waveform measure sequence that outputs various voltage values on channel 1, and returns data in pulse IV mode.

* **[pulse IV segarb.py](./pulse%20IV%20segARB.py)**
This example creates a SegARB waveform measure sequence that outputs various voltage values on channel 1, and returns data in pulse IV mode. It will output a graph onto a browser containing Current vs Voltage measurements.

* **[pulse vds-id with LLEC without plotting.py](./pulse%20vds-id%20with%20LLEC%20without%20plotting.py)**
This example is a KXCI recreation of the Clarius pulse-vds-id test with a pulse amplitude step on channel 1 from 2 to 4 V in 0.5 V steps, and a pulse amplitude sweep on channel 2 from 0 to 5 V in 0.2 V steps. It returns data back in pulse IV mode. 

* **[pulse vds-id with LLEC.py](./pulse%20vds-id%20with%20LLEC.py)**
This example is a KXCI recreation of the Clarius pulse-vds-id test with a pulse amplitude step on channel 1 from 2 to 4 V in 0.5 V steps, and a pulse amplitude sweep on channel 2 from 0 to 5 V in 0.2 V steps. It returns data back in pulse IV mode. It will output a graph onto a browser containing Current vs Voltage measurements.

* **[simple segarb pulse without plotting.py](./simple%20segarb%20pulse%20without%20plotting.py)**
This example creates a SegARB waveform measure sequence that outputs a 1V sequence with configured rise and fall times on channel 1, returning data back in waveform capture mode.

* **[simple segarb pulse.py](./simple%20segarb%20pulse.py)**
This example creates a SegARB waveform measure sequence that outputs a 1V sequence with configured rise and fall times on channel 1, returning data back in waveform capture mode. It will output a graph onto a browser containing Voltage vs Time measurements.
