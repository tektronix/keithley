"""
This example performs a single-point impedance measurement on a capacitor
using the 4200A-SCS CVU via an ethernet connection. It configures the CVU
to put the instrument into User Mode with a 30 mV AC signal and a 5 V DC bias.
One impedance result is printed to the terminal.
Device used: 10 pF Capacitor 4-wire
"""

from instrcomms import Communications

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # instrument resource string, obtained from NI MAX
my4200 = Communications(INST_RESOURCE_STR) # opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" #Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" #Set PyVISA read terminator

my4200.query("BC") #Clear all readings from the buffer
my4200.query(":CVU:RESET") #Resets the CVU card
my4200.query(":CVU:MODE 0") #Sets the mode to User Mode
my4200.query(":CVU:MODEL 3") #Sets the measurement model to Cs, Rs
my4200.query(":CVU:SPEED 2") #Sets the measurement speed to quiet
my4200.query(":CVU:ACV 0.03") #Sets the AC drive voltage to 30 mV
my4200.query(":CVU:DCV 5") #Set the DC bias level to 5 V
my4200.query(":CVU:ACZ:RANGE 30e-6") #Select the 30 uA measurement range

Z = my4200.query(":CVU:MEASZ?") #Perform a single Z measurement
print("Impedance Value: ", Z)

my4200.disconnect() # Close communications with the 4200A-SCS