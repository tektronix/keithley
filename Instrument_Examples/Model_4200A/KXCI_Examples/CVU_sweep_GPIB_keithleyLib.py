"""
    ***********************************************************
    *** Copyright 2023 Tektronix, Inc.                      ***
    *** See www.tek.com/sample-license for licensing terms. ***
    ***********************************************************
    
    This example performs a C-V sweep on a MOSFET using the
    4200A-SCS CVU via a GPIB connection. It will output a csv
    file containing the C-V measurements such that they may
    be plotted.
"""

from instrcomms import Communications
import csv

INST_RESOURCE_STR = "GPIB0::17::INSTR"  # instrument resource string, obtained from NI-VISA Interactive
my4200 = Communications(INST_RESOURCE_STR)  # opens the resource manager in PyVISA with the corresponding instrument resource string

my4200.connect()  # opens connections to the 4200A-SCS

my4200.write("BC")
my4200.write("DR1")
my4200.write(":CVU:RESET")
my4200.write(":CVU:MODE 1")
my4200.write(":CVU:MODEL 2")
my4200.write(":CVU:SPEED 2")
my4200.write(":CVU:ACZ:RANGE 0")
my4200.write(":CVU:FREQ 1E6")
my4200.write(":CVU:SWEEP:DCV 5, -5, -0.2")
my4200.write(":CVU:DELAY:SWEEP 0.1")
my4200.write(":CVU:TEST:RUN")

my4200._instrument_object.wait_for_srq()  # waits until data is ready by waiting for serial request coming from the 4200A-SCS

CpGp = my4200.query(":CVU:DATA:Z?")  # queries readings of Cp-Gp
Volt = my4200.query(":CVU:DATA:VOLT?")  # queries readings of Voltage

sep = ";"  # separator between Cp-Gp

VoltList = Volt.split(",")  # splits voltage list at commas
CpGpList = CpGp.split(",")  # splits Cp-Gp list at commas

CapList = []  # list only for capacitance values

for (z) in (CpGpList):  # separates the Cp-Gp list into only the Cp values, by removing the value after the semi-colon
    CapList.append(z.split(sep, 1)[0])

zipped_list = zip(VoltList, CapList)  # creates iterable zipped list

columns = ["Voltage (V)", "Capacitance (F)"]  # column headers
with open("output.csv", "w", newline="", encoding="utf-8") as f:  # opens and writes csv file
    writer = csv.writer(f)
    writer.writerow(columns)
    writer.writerows(zipped_list)

f.close()  # close stream
my4200.disconnect()  # close communications with the 4200A-SCS
