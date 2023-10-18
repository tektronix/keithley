""" 
    This script provides an example of how a programmer might issue
    a query for an instrument's identification string as well as 
    a simple command write. 
"""
import pyvisa
rm = pyvisa.ResourceManager()

# Start communicating with the target instrument with the name inst_1
SMU2450 = rm.open_resource("USB0::0x05E6::0x2450::04509653::INSTR")

# Try querying the command for the first time. The response
#   should contain the instrument manufacturer name, model, 
#   serial number, and firmware version in answer.
answer = SMU2450.query("*IDN?")

# Display the response.
print(answer)

# Issue a universal instrument reset.
SMU2450.write("*RST")

# Close communication with the device and the resource manager.
SMU2450.close()
rm.close()