--[[
From Application Note: 
Rechargeable Battery Charge/Discharge (Galvanic) Cycling Using 
the Keithley Model 2450 or Model 2460 SourceMeter® SMU Instrument
Link: https://www.tek.com/en/documents/application-note/rechargeable-battery-charge-and-discharge-galvanic-cycling-using-keithley

Written By: Keithley Applications Engineering

]]


--This code discharges a 2500 mAH 1.2 V battery to 0.9 V with a
--discharge current of 2.5A (1C).
--Prior to executing code, reset instrument from front panel and
--set the Output Off state of the Model 2460 to the High Z Mode
--Insert USB drive to save readings

--clear the buffer
defbuffer1.clear()

--Measurement Settings
smu.measure.func = smu.FUNC_DC_CURRENT
smu.measure.range = 2.5
smu.measure.sense = smu.SENSE_4WIRE

--Source Settings
smu.source.func = smu.FUNC_DC_VOLTAGE
smu.source.offmode = smu.OFFMODE_HIGHZ
smu.source.level = 0.9
smu.measure.terminals = smu.TERMINALS_REAR
smu.source.range = 0.9
smu.source.readback = smu.ON
smu.source.ilimit.level = 2.5

--Set the voltage limit for the battery to stop discharging
--Set the variable for number of iterations
voltLimit = 0.9001
iteration = 1

--Turn on the source output
smu.source.output = smu.ON

--Change display to user screen
display.changescreen(display.SCREEN_USER_SWIPE)

--Keep taking readings in the while loop until the measured voltage
--is equal to the voltage limit
while true do
    --Take a reading and get the current, voltage and relative timestamp
    curr = smu.measure.read(defbuffer1)
    volt = defbuffer1.sourcevalues[iteration]
    time = defbuffer1.relativetimestamps[iteration]
    hours = time/3600
    
    --Compare the measured voltage to the voltage limit
    --Exit the loop if it is
    if volt <= voltLimit then
        break
    end
    
    --Print the # of completed cycles, the voltage and the time for
    --the iteration. Display information on front panel
    print("Completed Cycles: ",iteration, "Voltage: ", volt, "Time: ", time)
    display.settext(display.TEXT1, string.format("Voltage = %.4fV", volt))
    display.settext(display.TEXT2, string.format("Current = %.2fA, Time = %.2fHrs", curr, hours))
    
    --Increment the number of iterations and wait 10 seconds
    iteration = iteration + 1
    delay(10)
end

--Turn the output off when the voltage limit is reached
smu.source.output = smu.OFF

FileNumber = file.open("/usb1/TestData.csv", file.MODE_WRITE)
file.write(FileNumber,"Current,Voltage,Seconds\n")

--Print out the measured values in a 4 column format
print("nIteration:\tCurrent:\tVoltage:\tTime:\n")

for i = 1, defbuffer1.n do
    print(i, defbuffer1[i], defbuffer1.sourcevalues[i], defbuffer1.relativetimestamps[i])
    file.write(FileNumber, string.format("%g,%g, %g\r\n",defbuffer1.readings[i], defbuffer1.
    sourcevalues[i],defbuffer1.relativetimestamps[i]))
end

file.close(FileNumber)