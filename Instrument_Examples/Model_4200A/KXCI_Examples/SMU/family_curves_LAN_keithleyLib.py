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

INST_RESOURCE_STR = "TCPIP0::169.254.160.161::1225::SOCKET"  # instrument resource string, obtained from NI MAX
my4200 = Communications(INST_RESOURCE_STR)  # opens the resource manager in PyVISA with the corresponding instrument resource string

my4200.connect()  # opens connections to the 4200A-SCS
my4200._instrument_object.write_termination = "\0"  # Set PyVISA write terminator
my4200._instrument_object.read_termination = "\0"  # Set PyVISA read terminator

my4200.query("BC")
my4200.query("DE")
my4200.query("CH1, 'VS', 'IS', 1, 3")
my4200.query("CH2, 'VD', 'ID', 1, 1")
my4200.query("CH3, 'VG', 'IG', 1, 2")
my4200.query("SS")
my4200.query("VR1, 0, 5, 0.1, 100e-3")
my4200.query("VP2, 1, 4, 100e-3")
my4200.query("VC1, 0, 100e-3")
my4200.query("HT 0")
my4200.query("DT 0.001")
my4200.query("IT2")
my4200.query("RS 5")
my4200.query("RG 1, 100e-9")
my4200.query("RG 2, 100e-9")
my4200.query("RG 3, 100e-9")
my4200.query("SM")
my4200.query("DM1")
my4200.query("XN 'VD', 1, 0, 5")
my4200.query("YA 'ID', 1, 0, 0.04")
my4200.query("MD")
my4200.query("ME1")

# wait for measurement to complete
status = my4200.query("SP")

while int(status) != 1:
    status = my4200.query("SP")
    time.sleep(1)

my4200.disconnect()  # close communications with the 4200A-SCS
