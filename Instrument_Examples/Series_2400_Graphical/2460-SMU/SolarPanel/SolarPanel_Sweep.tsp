--[[
This example demonstrates how to generate an I-V sweep on a solar panel.  
In this particular example the voltage is swept from 0V to 20V and the resulting current
is measured.  The maximum power, maximum current, maximum voltage, short circuit current,
and open circuit voltage are calculated and displayed in the Instrument Console along with
all the I-V sweep data. More information about this tsp code can be found in the 
View This First document.
--]]

--Define the number of points in the sweep.
num = 115

--Reset the Model 2460 and clear the buffer.
reset()

--Set the source and measure functions.
smu.measure.func = smu.FUNC_DC_CURRENT
smu.source.func = smu.FUNC_DC_VOLTAGE

--Configure the measurement settings.
smu.measure.terminals = smu.TERMINALS_FRONT
smu.measure.sense = smu.SENSE_4WIRE
smu.measure.autorange = smu.ON
smu.measure.nplc = 1

--Configure the source settings.
smu.source.highc = smu.OFF
smu.source.range = 20
smu.source.readback = smu.ON
smu.source.highc = smu.OFF
smu.source.ilimit.level = 4
smu.source.sweeplinear("SolarCell", 0, 20, num, 0.05)

--Start the trigger model and wait for it to complete.
trigger.model.initiate()
waitcomplete()

--Define initial values.
local voltage = defbuffer1.sourcevalues
local current = defbuffer1
local isc = current[1]
local mincurr = current[1]
local imax = current[1]
local voc = voltage[1]
local vmax = voltage[1]
local pmax = voltage[1]*current[1]

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
print("Pmax = ", pmax, ", Imax = ", imax, ", Vmax = ", vmax, ", Isc = ", isc, ",Voc = ", voc)

--Display values on the Model 2460 front panel.
display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT1, string.format("Pmax = %.4fW", pmax))
display.settext(display.TEXT2, string.format("Isc = %.4fA, Voc = %.2fV", isc, voc))