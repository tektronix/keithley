"""
    ***********************************************************
    *** Copyright 2023 Tektronix, Inc.                      ***
    *** See www.tek.com/sample-license for licensing terms. ***
    ***********************************************************
    
    This example performs a family of curves test on a MOSFET,
    using the 4200A-SCS with three SMUs connected to a MOSFET
    via a GPIB connection. It will output the ID-VD Curves of
    the MOSFET directly onto the KXCI interface.
"""

from instrcomms import Communications

INST_RESOURCE_STR = "GPIB0::17::INSTR" # instrument resource string, obtained from NI-VISA Interactive
my4200 = Communications(INST_RESOURCE_STR) # opens the resource manager in PyVISA with the corresponding instrument resource string

my4200.connect() # opens connections to the 4200A-SCS

my4200.write("DE") 
my4200.write("CH1, 'VS', 'IS', 1, 3") 
my4200.write("CH2, 'VD', 'ID', 1, 1") 
my4200.write("CH3, 'VG', 'IG', 1, 2") 
my4200.write("SS") 
my4200.write("VR1, 0, 5, 0.1, 100e-3")
my4200.write("VP2, 1, 4, 100e-3") 
my4200.write("VC1, 0, 100e-3") 
my4200.write("HT 0")
my4200.write("DT 0.001") 
my4200.write("IT2") 
my4200.write("RS 5") 
my4200.write("RG 1, 100e-9") 
my4200.write("RG 2, 100e-9") 
my4200.write("RG 3, 100e-9") 
my4200.write("SM") 
my4200.write("DM1") 
my4200.write("XN 'VD', 1, 0, 5") 
my4200.write("YA 'ID', 1, 0, 0.04") 
my4200.write("MD") 
my4200.write("ME1") 

my4200.disconnect() # close communications with the 4200A-SCS




