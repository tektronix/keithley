"""
    This script shows the programmer how they might use the 
    Visa Resource Manager to list the instrument resource 
    strings for all connected devices. 
"""
import pyvisa

# Instantiate a resource manager object. 
rm = pyvisa.ResourceManager()

# Returns all resources (matching ?*::INSTR) retrieved by rm.
print(rm.list_resources())

rm.close()