"""*********************************************************************************
        Copyright 2019 Tektronix, Inc.
        See www.tek.com/sample-license for licensing terms.
*********************************************************************************"""

"""*********************************************************************************
        
        This example shows how to programmatically configure the Model 2015 to 
        perform a distortion measurement then return the results. Note that even
        though THD is chosen as the primary distortion type, the user can also 
        directly query the THD+n and RMS value of the sampled stimulus. Because
        there is no query command for SINAD, it is computed by taking the inverse
        of the THD+noise measurement since frequency and voltage are of the same
        bandwidth. 
        
        To test without an external instrument, connect the function generator
        output on the rear of the Model 2015 (SOURCE OUTPUT) to the front or rear
        voltage inputs (INPUT HI/LO) and set the FRONT/REAR switch accordingly. 

*********************************************************************************"""

import pyvisa as visa
import pyvisa.constants as pyconst
import time
from datetime import datetime
import sys
import os
import time
import math

echo_commands = 0
pure_sockets = 0

"""*********************************************************************************
    Function: instrument_connect(resource_mgr, instrument_object, instrument_resource_string, 
                                 timeout, do_id_query, do_reset, do_clear) 

    Purpose: Open an instance of an instrument object for remote communication.

    Parameters:
        resource_mgr (object) - Instance of a resource manager object.

        instrument_object (object) - Instance of an instrument object to be initialized
                                     within this function. 

        instrument_resource_string (string) - The VISA resource string associated with
                                              a specific instrument defining its connection
                                              characteristics (communications type, model,
                                              serial number, etc.)
        timeout (int) - Time in milliseconds to wait before the communication transaction
                        with the target instrument is considered failed (timed out)
        do_id_query (int) - A flag that determines whether or not to query and print the 
                            instrument ID string. 
        do_reset (int) - A flag that determines whether or not to issue a reset command to
                         the instrument during this connection. 
        do_clear (int) - A flag that determines whether or not to issue a clear command to 
                         the instrument during this connection. 

    Returns:
        None

    Revisions:
        2019-08-07    JJB    Initial revision.
*********************************************************************************"""


def instrument_connect(resource_mgr,
                       instrument_object,
                       instrument_resource_string,
                       timeout, do_id_query,
                       do_reset,
                       do_clear,
                       baud_rate=9600,
                       data_bits=8,
                       parity=pyconst.Parity.none,
                       stop_bits=pyconst.StopBits.one,
                       flow_control=0,
                       read_terminator="\n"):

    instrument_object = resource_mgr.open_resource(instrument_resource_string)

    # Check for the SOCKET as part of the instrument ID string and set the following accordingly...
    if "SOCKET" in instrument_resource_string:
        instrument_object.write_termination = "\n"
        instrument_object.read_termination = "\n"
        instrument_object.send_end = True
    elif "ASRL" in instrument_resource_string:
        instrument_object.baud_rate = baud_rate
        instrument_object.data_bits = data_bits
        instrument_object.parity = parity   #pyconst.Parity.odd
        instrument_object.stop_bits = stop_bits     #pyconst.StopBits.one
        instrument_object.flow_control = flow_control
        instrument_object.write_termination = "\n"
        instrument_object.read_termination = read_terminator
        instrument_object.send_end = True
    elif "GPIB" in instrument_resource_string:
        # do nothing or something...
        print("GPIB")
        pure_sockets = 0
    elif "USB" in instrument_resource_string:
        # do nothing or something...
        print("USB")
        pure_sockets = 0
    else:
        # Assume a sockets connection; set the flag
        pure_sockets = 1

    if do_id_query == 1:
        print(instrument_query(instrument_object, "*IDN?"))
    if do_reset == 1:
        instrument_write(instrument_object, "*RST")
    if do_clear == 1:
        instrument_object.clear()
    instrument_object.timeout = timeout
    return resource_mgr, instrument_object


"""*********************************************************************************
    Function: instrument_write(instrument_object, my_command)

    Purpose: Issue controlling commands to the target instrument.

    Parameters:
        instrument_object (object) - Instance of an instrument object.

        my_command (string) - The command issued to the instrument to make it 
                              perform some action or service. 
    Returns:
        None

    Revisions:
        2019-08-21    JJB    Initial revision.
*********************************************************************************"""


def instrument_write(instrument_object, my_command):
    if echo_commands == 1:
        print(my_command + "\n")
    instrument_object.write(my_command)
    return


"""*********************************************************************************
    Function: instrument_read(instrument_object)

    Purpose: Used to read commands from the instrument.

    Parameters:
        instrument_object (object) - Instance of an instrument object.

    Returns:
        <<<reply>>> (string) - The requested information returned from the 
                    target instrument. Obtained by way of a caller
                    to instrument_read().

    Revisions:
        2019-08-21    JJB    Initial revision.
*********************************************************************************"""


def instrument_read(instrument_object):
    return instrument_object.read()


"""*********************************************************************************
    Function: instrument_query(instrument_object, my_command)

    Purpose: Used to send commands to the instrument  and obtain an information string from the instrument.
             Note that the information received will depend on the command sent and will be in string
             format.

    Parameters:
        instrument_object (object) - Instance of an instrument object.

        my_command (string) - The command issued to the instrument to make it 
                      perform some action or service. 
    Returns:
        <<<reply>>> (string) - The requested information returned from the 
                    target instrument. Obtained by way of a caller
                    to instrument_read().

    Revisions:
        2019-08-21    JJB    Initial revision.
*********************************************************************************"""


def instrument_query(instrument_object, my_command):
    if echo_commands == 1:
        print(my_command)
    return instrument_object.query(my_command)


"""*********************************************************************************
    Function: instrument_disconnect(instrument_object)

    Purpose: Break the VISA connection between the controlling computer
             and the target instrument.

    Parameters:
        instrument_object (object) - Instance of an instrument object.

    Returns:
        None

    Revisions:
        2019-08-21    JJB    Initial revision.
*********************************************************************************"""


def instrument_disconnect(instrument_object):
    instrument_object.close()
    return


def check_system_error(instrument_object):
    err_chk = instrument_query(instrument_object, "SYST:ERR?")
    if err_chk.find("NO ERROR") == -1:
        print(err_chk)
        time.sleep(0.5)
    return

# ================================================================================
#
#    MAIN CODE STARTS HERE
#
# ================================================================================
t1 = time.time()  # Start the timer...
resource_manager = visa.ResourceManager()  # Opens the resource manager

# connect to and configure the load
dmm2015 = None

inst_resource_string = "GPIB0::16::INSTR"
#resource_manager, dmm2015 = instrument_connect(resource_manager, dmm2015, inst_resource_string, 20000, 1, 1, 0,
#                                               stop_bits=pyconst.StopBits.one,
#                                               parity=pyconst.Parity.none,
#                                               flow_control=0,
#                                               read_terminator="\n")
resource_manager, dmm2015 = instrument_connect(resource_manager, dmm2015, inst_resource_string, 20000, 1, 1, 0)
print(instrument_query(dmm2015, "*IDN?"))  # query is the same as write + read

instrument_write(dmm2015, "*RST")
instrument_write(dmm2015, "*CLS")
freq = 1000
fmag = 1
instrument_write(dmm2015, ":SENS:FUNC \'DIST\'")            # select distortion
instrument_write(dmm2015, ":SENS:DIST:TYPE THD")            # select SINAD type
instrument_write(dmm2015, ":SENS:DIST:HARM 64")             # set the highest harmonic to 64
instrument_write(dmm2015, ":UNIT:DIST DB")                  # specify units in decibels
instrument_write(dmm2015, ":SENS:DIST:SFIL NONE")           # no shaping filter
instrument_write(dmm2015, ":SENS:DIST:RANG:AUTO ON")        # turn on auto-ranging
instrument_write(dmm2015, ":OUTP:FREQ {0}".format(freq))    # set frequency
instrument_write(dmm2015, ":OUTP:IMP HIZ")                  # set high impedance source
instrument_write(dmm2015, ":OUTP:AMPL {0}".format(fmag))    # set the output signal to 1 volt
instrument_write(dmm2015, ":OUTP:CHAN2 ISINE")              # select inverted sine
instrument_write(dmm2015, ":OUTP ON")                       # turn on the source
result = instrument_query(dmm2015, ":READ?").strip('\n')    # trigger one reading;

print("READ? reports {0} for selected distortion type...".format(float(result)))
thd = float(instrument_query(dmm2015, ":SENS:DIST:THD?").strip('\n'))   # return the THD corresponding to the measurement
thdn = float(instrument_query(dmm2015, ":SENS:DIST:THDN?").strip('\n')) # return the THD+n corresponding to the measurement
sinad = 1/thdn  # For a given input frequency and amplitude, THD+N is the reciprocal to SINAD provided that both measurements
                # are made over the same bandwidth: https://en.wikipedia.org/wiki/Total_harmonic_distortion#
rms = float(instrument_query(dmm2015, ":SENS:DIST:RMS?").strip('\n'))   # return the RMS corresponding to the measurement
harm_mag = instrument_query(dmm2015, ":SENS:DIST:HARM:MAGN? 2,64").strip('\n') # extract the array of harmonics
harm_mag_list = harm_mag.split(',')

print("THD = {0}".format(thd))
print("THD+N = {0}".format(thdn))
print("RMS = {0}".format(rms))
print("SINAD = {0}".format(sinad))
check_system_error(dmm2015)

instrument_disconnect(dmm2015)
resource_manager.close()

t2 = time.time()  # Stop the timer...

# Notify the user of completion and the data streaming rate achieved.
print("done")
print("Elapsed Time: {0:0.3f}s".format(t2 - t1))

input("Press Enter to continue...")
exit()

