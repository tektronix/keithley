"""Keithley PyVisa example code that connects to an instrument and prints its IDN twenty
    times.

Set INSTRUMENT_RESOURCE_STRING equal to your instrument's resource string, found using the
    VISA Interactive Control program.

Note that the instrcomms class file can be found at: 
    https://github.com/tektronix/keithley/tree/main/Instrument_Examples/General/Instrument_Communication_Resouces
    
    Copyright 2023 Tektronix, Inc.                      
    See www.tek.com/sample-license for licensing terms. 

"""

import time
from instrcomms import Communications

INST_RESOURCE_STR = (
    "USB0::0x05E6::0x6500::04429419::INSTR"  # Get from VISA Interactive Control
)

# ================================================================================
#
#    MAIN CODE STARTS HERE
#
# ================================================================================
def main():
    "Main code. Will print instrument IDN 10 times and print elapsed time taken to do so."
    start_time = time.time()  # Record start time

    my_instr = Communications(INST_RESOURCE_STR)
    my_instr.connect()

    my_instr.write("*RST")
    for _ in range(10):
        my_instr.write("*IDN?")
        print(my_instr.read())
        print(my_instr.query("*IDN?"))  # query is the same as write + read

    my_instr.disconnect()

    stop_time = time.time()  # Record stop time

    # Notify the user of completion and the data streaming rate achieved.
    print("done")
    print(f"Elapsed Time: {(stop_time-start_time):0.3f}s")


if __name__ == "__main__":
    main()
