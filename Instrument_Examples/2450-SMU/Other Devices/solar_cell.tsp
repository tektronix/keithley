--[[

***********************************************************
*** Copyright Tektronix, Inc.                      		***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

This example is from the 2450 User's Manual. Check there for more details on running this example.

In this application, a linear voltage sweep is configured to output voltage from 0 V to 0.53 V in 56
    steps. The instrument measures the resulting current from the solar cell during the sweep.  
    The instrument is programmed to display custom text on the USER swipe screen using the 
    display.changescreen and display.settext commands. After the test is finished, the display will 
    indicate the maximum power (Pmax), the short circuit current (ISC), and the open circuit voltage (VOC).

]]

--Define the number of points in the sweep.
num = 56
--Reset the instrument and clear the buffer.
reset()
--Set the source and measure functions.
smu.measure.func = smu.FUNC_DC_CURRENT
smu.source.func = smu.FUNC_DC_VOLTAGE
--Measurement settings.
smu.measure.terminals = smu.TERMINALS_FRONT
smu.measure.sense = smu.SENSE_4WIRE
smu.measure.autorange = smu.ON
smu.measure.nplc = 1
--Source settings.
smu.source.highc = smu.OFF
smu.source.range = 2
smu.source.readback = smu.ON
smu.source.ilimit.level = 1
smu.source.sweeplinear("SolarCell", 0, 0.53, num, 0.1)
--Start the trigger model and wait for it to complete.
trigger.model.initiate()
waitcomplete()
--Define initial values.
voltage = defbuffer1.sourcevalues
current = defbuffer1
isc = current[1]
mincurr = current[1]
imax = current[1]
voc = voltage[1]
vmax = voltage[1]
pmax = voltage[1]*current[1]
--Calculate values.
for i = 1, num do
    print(voltage[i],current[i],voltage[i]*current[i])
    if (voltage[i]*current[i] < pmax) then
        pmax = voltage[i]*current[i]
        imax = current[i]
        vmax = voltage[i]
    end
    if math.abs(current[i]) < math.abs(mincurr) then
        voc = voltage[i]
    end
end
pmax = math.abs(pmax)
imax = math.abs(imax)
print("Pmax = ", pmax, ", Imax = ", imax, ", Vmax = ", vmax, ", Isc = ", isc, ", ".."Voc = ", voc)
--Display values on the front panel.
display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT1, string.format("Pmax = %.4fW", pmax))
display.settext(display.TEXT2, string.format("Isc = %.4fA, Voc = %.2fV", isc, voc))