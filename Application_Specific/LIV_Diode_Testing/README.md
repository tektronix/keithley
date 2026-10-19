# LIV Diode Testing

These TSP scripts are for performing Light-Current-Voltage (LIV) testing with a photodiode with a [2601B-PULSE 10us Pulser/SMU](https://www.tek.com/products/keithley/source-measure-units/2601b-pulse-system-sourcemeter) and other instruments.

Case I is with a DMM6500 or DMM7510
Case II is with a 2602B SMU
Case III is with a 2461 SMU

[plot_liv.py](plot_liv.py) and [plot_pulse.py](plot_pulse.py) can be used for plotting the measurements. They save a .png of their graphs as well. They require numpy and matplotlib and work with any CaseI/II/III. 
By default, each will look for completePulse.txt or measurementLIV.txt, sample files are included here. You can easily replace this data with your own by using the Data Export capability of the TSP Toolkit Extension in VS Code. See this [technical brief for instructions](https://www.tek.com/en/documents/technical-brief/easy-data-export-with-tsp-toolkit).

See the code comments for more information.