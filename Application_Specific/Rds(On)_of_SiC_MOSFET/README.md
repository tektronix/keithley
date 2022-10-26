# Rds(on) of SiC MOSFET

This folder contains supplemental TSP code to a series of videos made by Keithley Applications Engineer Andrea Clary using a [2461 High Current Source Measure Unit and a 2450 SMU](https://www.tek.com/products/keithley/source-measure-units/2400-graphical-series-sourcemeter). 

* Part 1: Introduction to 10Amp Pulse for Rds(On): https://www.youtube.com/watch?v=C_YqjNgO68Y
* Part 2: Front Panel Setup and Compare to Scope: https://www.youtube.com/watch?v=ZIx0ERuzkew
* Part 3: Explanation of Trigger Blocks for Pulsed IV: https://www.youtube.com/watch?v=9n4mgW2Btig
* Part 4: About Test Script Builder and TSP: https://www.youtube.com/watch?v=mizxVYp-ezc

She uses a Cree Silicon Carbide MOSFET, part# C2M0160120D, testing drain-source Resistance in the On State (i.e. Rds(On)) with a 10 Amp pulse using the 2461 SMU. The gate voltage is controlled manually with a 2450 SMU. 

[Rdson_digitize.tsp](./Rdson_digitize.tsp) is used in Part 1, then walked through in Part 4. 

[Rdson_digitize_with_timing_marks.tsp](./Rdson_digitize_with_timing_marks.tsp) is explained in Part 4 and does basically the same as the first script, but uses the Digital I/O port of the 2461 to trigger external equipment. 