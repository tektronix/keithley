"""
    ***********************************************************
    *** Copyright 2023 Tektronix, Inc.                      ***
    *** See www.tek.com/sample-license for licensing terms. ***
    ***********************************************************
    
    This example performs a family of curves test on a MOSFET,
    using the 4200A-SCS with three SMUs connected to a MOSFET
    via a LAN connection. It will output the ID-VD Curves of
    the MOSFET directly onto the KXCI interface.
"""

import time
from instrcomms import Communications

term = '\0' # terminating character for ethernet commands
INST_RESOURCE_STR = "TCPIP0::169.254.88.169::1225::SOCKET" # instrument resource string, obtained from NI MAX

my4200 = Communications(INST_RESOURCE_STR) # opens the resource manager in PyVISA with the corresponding instrument resource string
my4200.connect() # opens connections to the 4200A-SCS

my4200.write("DE"+term) 
my4200.write("CH1, 'VS', 'IS', 1, 3"+term) 
my4200.write("CH2, 'VD', 'ID', 1, 1"+term) 
my4200.write("CH3, 'VG', 'IG', 1, 2"+term) 
my4200.write("SS"+term) 
my4200.write("VR1, 0, 5, 0.1, 100e-3"+term) 
my4200.write("VP2, 1, 4, 100e-3"+term) 
my4200.write("VC1, 0, 100e-3"+term)
my4200.write("HT 0"+term) 
my4200.write("DT 0.001"+term) 
my4200.write("IT2"+term) 
my4200.write("RS 5"+term) 
my4200.write("RG 1, 100e-9"+term) 
my4200.write("RG 2, 100e-9"+term) 
my4200.write("RG 3, 100e-9"+term) 
my4200.write("SM"+term) 
my4200.write("DM1"+term) 
my4200.write("XN 'VD', 1, 0, 5"+term) 
my4200.write("YA 'ID', 1, 0, 0.04"+term) 
my4200.write("MD"+term)
my4200.write("ME1"+term) 

# wait for measurement to complete
status = my4200.query("SP"+term)

while int(status) != 1:
    status = my4200.query("SP"+term)
    time.sleep(1)

my4200.disconnect() # close communications with the 4200A-SCS


