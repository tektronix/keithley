"""
    Send_and_Save_Arb_Waveform_Example.py
    
    Creates a sine waveform, sends it to the AFG31000's edit memory 1, and saves the waveform as a .tfwx file to the AFG31k's internal memory.
    
    For Sending an Arbitrary waveform as binary data, each point corresponds with 2 bytes.
    The value of the point ranges from 0x3FFE as the value of the highest point and 
    0x0000 as the value of the lowest point. For example with a sine wave that is 2 Vpp
    0x03FFE would correspond with the point at 1 V and 0x0000 corresponds with the point
    at -1 V.  
"""

import pyvisa
import math

resourceString = "" # Instrument resource string
    
# Configure Visa Connection
rm = pyvisa.ResourceManager()
instrument = rm.open_resource(resourceString)
instrument.timeout = 10000
if "SOCKET" in resourceString:
    instrument.write_termination = "\n"
    instrument.read_termination = "\n"
    instrument.send_end = True

# Generate sine wave
MAX_VALUE = 0x3FFE # Value of highest point (high peak) in hexidecimal
MIN_VALUE = 0x0000 # Value of lowest point (low peak) in hexidecimal
numPoints = 131072 # Number of points in of sine waveform

byteString = "" # Hold sine wave data as hexidecimal
for x in range(numPoints):
    # Get Sine Value
    angle = ((2*math.pi)/(numPoints-1))*x # Calculate angle for loop iteration
    sineValue = math.sin(angle) # Find sine of angle 
    # Convert Sign Value to Hexadecimal
    sineValue = round((sineValue+1)*(MAX_VALUE/2)) # Shift sine value up by 1 (get rid of negative values) and multiply by 1/2 MAX_VALUE
    hexValue = format(sineValue, '04X') # Convert sineValue to Hex
    byteString = byteString + hexValue # Store hexValue in Byte String

# Send double pulse waveform to AFG31k's edit memory
instrument.write(f"SOUR1:FUNC:SHAP EMEM1")# Configure Channel 1 to EMEM1
command = f"DATA:DATA EMEM1," # SCPI command for transfering waveform
data = bytes.fromhex(byteString) # Convert hex string to bytes
instrument.write_binary_values(command, data, datatype='b') # Transfer waveform

# Configure high and low voltage settings
instrument.write("SOURce1:VOLTage:LEVel:IMMediate:HIGH 1V") # Set amplitude
instrument.write("SOURce1:VOLTage:LEVel:IMMediate:LOW -1V") # Set offset

# Save channel 1 as a .tfwx file
instrument.write("MMEMory:STORe:TRACe EMEMory1,\"M:/sample1.tfwx\"")

rm.close() #Close Visa Connection
