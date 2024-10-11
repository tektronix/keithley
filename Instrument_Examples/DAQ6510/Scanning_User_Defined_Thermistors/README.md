
# Scanning User Defined Thermistors

This example application demonstrates how to create a scan to measure user defined thermistors. 

A thermistor is a resistor whose value varies with temperature. The relationship is non-linear but well defined. These two-terminal devices are one of the most common and readily available temperature measurement devices. The semiconductor metal oxide makes them sensitive to small temperature changes. Thermistors work best in various temperatures and applications because they are durable and reliable. There are two types of thermistors:

Negative Temperature Coefficient (NTC) Thermistors
* Negative resistance to temperature relationship
* Resistance decreases as temperature increases

Positive Temperature Coefficient (PTC) Thermistors
* Positive resistance to temperature relationship
* Resistance increases as temperature increases
* Useful for applications such as fuses
	
This script is built for doing thermistors measurements based to the Steinhart-Hart equation.The Steinhart-Hart equation is a model relating the varying electrical resistance of a semiconductor to its varying temperatures. The equation is :
    1/T = A + B*ln(R)+ C(ln(R))^3
where
    T is the temperature (in kelvins),
	R is the resistance at T (in ohms)
	A, B and C are the Steinhart-Hart coefficients, which are characteristics specific to the bulk semiconductor material over a given temperature range of interest.
 
        
To set up for the Steinhart-Hart model, we must find three reference temperatures. First, find the temperature range of the desired thermistor and take note of it. Our first reference temperature will be the lowest temperature in the range. The second reference temperature is somewhere close to the middle of the range and is usually the standard temperature 25C. The third reference temperature is the highest temperature in the thermistor's range. After noting these temperatures, we find their corresponding resistance values. These are either listed in the thermistor's datasheet, or we source a temperature and measure the thermistor's resistance at each of these points. 
	
With this script you are limited to one model of thermistor (TDK B57164K, R25 = 2.2K) but you can start from this script and define as much variables as you want to define dedicated thermistor's curve. 
	
This script measure two thermistors 2.2K TDK B57164K on channels 111 and 116 from a DAQ6510's 7700 card. One Type K thermocouple is used on channel 112 to check the good results from channels 111 and 116.
