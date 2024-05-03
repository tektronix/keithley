# Model 2790 SourceMeter Airbag Test System

These examples include those found in the User Manual, Application Notes, and other sources. The files in this directory will work with [Model 2790 SourceMeter Airbag Test System](https://www.tek.com/en/products/keithley/switching-and-data-acquisition-systems/2790-airbag-and-electrical-device-test-system). 

## Directory

### Instrument Examples

* **[Bridgewire](./Airbag_Test/Airbag_Bridgewire.py)**  
This example code verifies the current source then measures the resistance of each bridgewire. 

* **[Contact Verify](./Airbag_Test/Airbag_Contact_Verify.py)**  
This example code checks the contacts to a dual inflator airbag connected to banks 1 and 2 on a Keithley 2790. See Application Note "Testing Dual Airbag Inflators and Modules with the Model 2790 SourceMeter Switch System" for more information.

* **[Insulation Resistance](./Airbag_Test/Airbag_Insulation_Resistance.py)**  
This example code tests the insulation resistance between the bridgewires and the housing. The voltage source value is tested prior to the resistances. Selecting S1I ohms function automatically sets the measurement function to DC Volts and measure range to 1 V.
    
* **[Shunt Bar](./Airbag_Test/Airbag_Shunt_Bar.py)**  
This example code tests the shunt bars or shorting clips of the airbag. The first shunt is tested without dry circuit and the second is tested with dry circuit. Also, selecting S1I ohms function automatically sets the measurement function to DC Volts and measure range to 1 V.
