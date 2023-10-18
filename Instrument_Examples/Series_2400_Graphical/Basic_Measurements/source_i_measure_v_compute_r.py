"""
    This script shows how to configure the Model 2450 SourceMeter
    to source current, measure voltage, and compute the resistance
    value of the target device. If the resistance is outside the
    specified tolerance band then the instrument will issue a
    beep sound to the operator.
"""
import pyvisa

rm = pyvisa.ResourceManager()
SMU2450 = rm.open_resource("USB0::0x05E6::0x2450::04509653::INSTR")

# Reset the source meter
SMU2450.write("reset()")

# Set the source function to current mode and set the source level
#   and limit. Also enable true measurement readback for the source
#   instead of relying on programmed values. 
SMU2450.write("smu.source.func = smu.FUNC_DC_CURRENT")
SMU2450.write("smu.source.level = 1e-6")
SMU2450.write("smu.source.vlimit.level = 0.1")
SMU2450.write("smu.source.readback = smu.ON")

# Set measurement function to voltage mode and apply fixed ranging.
SMU2450.write("smu.measure.func = smu.FUNC_DC_VOLTAGE")
SMU2450.write("smu.measure.range = 0.2")

# Enable the output to force current, executes a measurement
#   to obtain a voltage reading, then disable the output.
SMU2450.write("smu.source.output = smu.ON")
SMU2450.write("smu.measure.read()")
SMU2450.write("smu.source.output = smu.OFF")

# Get measured voltage and current values from buffer with queries,
#   then compute resistance. 
voltage = float(SMU2450.query("printbuffer(1, 1, defbuffer1.readings)"))
current = float(SMU2450.query("printbuffer(1, 1, defbuffer1.sourcevalues)"))
resistance = voltage / current
print(resistance)

# If the resistance is out of expected tolerance, the operator
#   will be notified with a beep sound.
if not 29.5e3 < resistance < 30.5e3:
    SMU2450.write("beeper.beep(0.5, 220)")

# Close communication with the SMU.
SMU2450.close()
rm.close()



