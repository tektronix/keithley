
# Leakage Current and Insulation Resistance

To measure the leakage current or insulation resistance of a device, you need to apply a fixed voltage
to the device and measure the resulting current. Depending on the device under test, the measured
current is typically very small, usually less than 10 nA.

This application consists of two examples that demonstrate:
• How to use the Model 2450 to perform leakage current measurements on a capacitor
• How to use the Model 2450 to measure insulation resistance between the two conductors of a
coaxial cable

The only difference between these two application examples is that when you measure leakage
current, the results are returned in units of amperes. When you measure insulation resistance, the
results are returned in units of ohms.

The leakage current application applies the voltage for a specified period because the device needs
time to charge. In some cases, the resulting current is measured the entire time the device is biased.
In other cases, only one reading is made at the end of the soak period.


You will find examples for both the SPCI and the TSP command set implementations. 
* Each is written in Python 3
* Each uses sockets-based communications to control the DAQ6510
