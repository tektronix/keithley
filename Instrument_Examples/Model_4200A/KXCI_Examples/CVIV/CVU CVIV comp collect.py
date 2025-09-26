"""
This example calls the "cvu_cviv_comp_collect" user module using the EX command
to setup the CVIV for CVU measurements and sets the CVU to use open compensation.
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
Details on the inputs for the cvu_cviv_comp_collect user module:

Inputs          | Definition
------          | ----------
CVU_ID          | string instrument identifier eg. "CVU1"
CVIV_ID         | string instrument identifier eg. "CVIV1"
CableLength	    | Cable length numbers used in setup...
                | valid numbers:  5.0: 1.5m CVIV 2W 
                |                 6.0: 1.5m CVIV 4W 0.75m
                |                 7.0: 1.5m CVIV 4W 0.61m Blue
Select_Open     | 1: Enable to run Open Comp on CVU; 0: Disable feature
Select_Short    | 1: Enable to run Short Comp on CVU; 0: Disable feature
Select_Load     | 1: Enable to run Load Comp on CVU; 0: Disable feature
LoadValue       | Load Value used for Load Compensation on CVU
Ch1_Mode        | CVIV Connection mode 
Ch2_Mode        | CVIV Connection mode
Ch3_Mode        | CVIV Connection mode
Ch4_Mode        | CVIV Connection mode

CVIV Connection Modes:

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

CV_2W_Mode      | CVIV CV 2 wire or 4 wire: 0: 4 Wire, 1: 2 Wire
Ch1_TermName    | CVIV Display Name for Ch1 Terminal (up to 6 characters will be displayed)
Ch2_TermName    | CVIV Display Name for Ch2 Terminal (up to 6 characters will be displayed)
Ch3_TermName    | CVIV Display Name for Ch3 Terminal (up to 6 characters will be displayed)
Ch4_TermName    | CVIV Display Name for Ch4 Terminal (up to 6 characters will be displayed)
TestName        | CVIV Display Name for Test (up to 16 characters will be displayed)
"""
# Call the cvu_cviv_comp_collect user module with open compsenation
my4200.query("EX cvivulib cvu_cviv_comp_collect (CVU1, CVIV1, 5.0, 1, 0, 0, 0, 2, 3, 0, 0, 1, One, Two, Three, Four, CVIV CV Comp, )")

# This is a loop to check the status of the test
# The SP command returns 0 or 1 when the test is done running
while True:
    status = my4200.query("SP")

    # Continues loop until the test is complete
    # Casting the status string to int makes the comparison simpler since it ignores the termination characters
    if int(status) in [0, 1]:
        print("Measurement Complete.")
        break

    # Continously prints the status of the test every second to the terminal
    print(f"Status: {status}")
    time.sleep(1)
    
my4200.disconnect() # Close communications with the 4200A-SCS
