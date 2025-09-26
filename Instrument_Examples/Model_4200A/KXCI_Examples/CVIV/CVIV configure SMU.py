"""
This example calls the "cviv_configure" user module to setup the CVIV for
SMU measurements using the EX command.
"""

from instrcomms import Communications
import time

INST_RESOURCE_STR = "TCPIP0::192.0.2.0::1225::SOCKET" # Instrument resource string, obtained from NI MAX
my4200 = Communications(INST_RESOURCE_STR) # Opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # Opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0" # Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0" # Set PyVISA read terminator

my4200.query("UL") # Enter user library mode
"""
Details on the inputs for the cviv_configure user module:

Inputs          | Definition
------          | ----------
InstId          | char string instrument identifier, such as "CVIV1"
TwoWireMode     | 0: CV Four Wire, 1: CV Two Wire

Connection Mode Settings:

Setting | Mode					
------- | ----					
0       | OPEN					 
1       | SMU					 
2       | CV Hi					 
3       | CV Low				 
4       | CV Guard				 
5       | Ground Unit
6       | AC Coup AC Ground
7       | BiasT SMU CV HI
8       | BiasT SMU CV LO
9       | BiasT SMU LO I CV HI
10      | BiasT SMU LO I CV LO
11		| BiasT SMU AC Ground

Ch1_Mode        | Connection Mode
Ch2_Mode        | Connection Mode
Ch3_Mode        | Connection Mode
Ch4_Mode        | Connection Mode
Ch1_TermName    | Display Name for Ch1 Terminal (up to 6 characters will be displayed)
Ch2_TermName    | Display Name for Ch2 Terminal (up to 6 characters will be displayed)
Ch3_TermName    | Display Name for Ch3 Terminal (up to 6 characters will be displayed)
Ch4_TermName    | Display Name for Ch4 Terminal (up to 6 characters will be displayed)
TestName        | Display Name for Test (up to 16 characters will be displayed)
"""
# Call the cviv_configure user module for SMU measurements
my4200.query("EX cvivulib cviv_configure (CVIV1, 1, 1, 1, 1, 1, Source, Drain, Gate, Bulk, IV, )")

# This is a loop to check the status of the test
# The SP command returns 0 or 1 when the test is done running
while True:
    status = my4200.query("SP")

    # Continues loop until the test is complete
    # Casting the status string to int makes the comparison simpler since it ignores the termination characters
    if int(status) in [0, 1]:
        print("Setup Complete.")
        break

    # Continously prints the status of the test every second to the terminal
    print(f"Status: {status}")
    time.sleep(1)

my4200.disconnect() # Close communications with the 4200A-SCS
