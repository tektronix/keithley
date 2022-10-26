"""
    Copyright Tektronix, Inc.
    See www.tek.com/sample-license for licensing terms.
"""
import time

import pyvisa as visa
import pyvisa.constants as pyconst

ECHO_COMMANDS = 0


def instrument_connect(resource_mgr: visa.ResourceManager,
                       instrument_object: object,
                       instrument_resource_string: str,
                       timeout: int,
                       do_id_query: int,
                       do_reset: int,
                       do_clear: int,
                       reset_str: str = None,
                       baud_rate: int = 9600,
                       data_bits: int = 8,
                       parity: visa.constants = pyconst.Parity.none,
                       stop_bits: visa.constants = pyconst.StopBits.one,
                       flow_control: int = 0,
                       read_terminator: str = "\n"):
    """_summary_
    Args:
        resource_mgr (visa.ResourceManager): Instance of a resource manager
        object.
        instrument_object (object): Instance of an instrument object to be
        initialized within this function.
        instrument_resource_string (str): The VISA resource string associated
        with a specific instrument defining its connection characteristics
        (communications type, model, serial number, etc.)
        timeout (int): Time in milliseconds to wait before the communication
        transaction with the target instrument is considered failed (timed out)
        do_id_query (int): A flag that determines whether or not to query and
        print the instrument ID string.
        do_reset (int): A flag that determines whether or not to issue a reset
        command to the instrument during this connection.
        do_clear (int): A flag that determines whether or not to issue a clear
        command to the instrument during this connection.
        baud_rate (int, optional): The communication speed in baud. Only to be
        used with ASRL resources. Defaults to 9600.
        data_bits (int, optional): Number of data bits contained in each frame.
        Its value must be from 5 to 8. Only to be used with ASRL resources.
        Defaults to 8.
        parity (visa.constants, optional): The parity used with every frame
        transmitted and received. Possible values are: no_parity, odd_parity,
        even_parity, mark_parity, and space_parity. Only to be used with ASRL
        resources. Defaults to pyconst.Parity.none.
        stop_bits (visa.constants, optional): Number of stop bits contained in
        each frame. Possible values are 1, 1.5, and 2. Only to be used with
        ASRL resources. Defaults to pyconst.StopBits.one.
        flow_control (int, optional): The flow control option to be used with
        serial commmunications. Can be 0 for 'None', 1 for 'XON/XOFF', 2 for
        'RTS/CTS', or 3 for 'DTR/DSR'. Only to be used with ASRL resources.
        Defaults to 0.
        read_terminator (str, optional): _description_. Defaults to "\n".

    Returns:
        visa.ResourceManager: An updated copy of the resource manager object.
        object: An updated copy of the instrument resource object.
    """

    instrument_object = resource_mgr.open_resource(instrument_resource_string)

    if "SOCKET" in instrument_resource_string:
        instrument_object.write_termination = "\n"
        instrument_object.read_termination = "\n"
        instrument_object.send_end = True
    elif "ASRL" in instrument_resource_string:
        instrument_object.baud_rate = baud_rate
        instrument_object.data_bits = data_bits
        instrument_object.parity = parity  # pyconst.Parity.odd
        instrument_object.stop_bits = stop_bits  # pyconst.StopBits.one
        instrument_object.flow_control = flow_control
        instrument_object.write_termination = "\n"
        instrument_object.read_termination = read_terminator
        instrument_object.send_end = True
    elif "GPIB" in instrument_resource_string:
        # do nothing
        PURE_SOCKETS = 0
    elif "USB" in instrument_resource_string:
        # do nothing
        PURE_SOCKETS = 0
    else:
        # Assume a sockets connection; set the flag
        PURE_SOCKETS = 1

    if do_id_query == 1:
        print(instrument_query(instrument_object, "*IDN?"))
    if do_reset == 1:
        if reset_str is None:
            instrument_write(instrument_object, "*RST")
        else:
            instrument_write(instrument_object, f"{reset_str}")
    if do_clear == 1:
        instrument_object.clear()
    instrument_object.timeout = timeout
    return resource_mgr, instrument_object


def instrument_write(instrument_object: object, my_command: str):
    """
    Issue controlling commands to the target instrument.

    Args:
    instrument_object (object): Instance of an instrument object.
    my_command (string) - The command issued to the instrument to make it
                              perform some action or service.
    Returns:
        None

    """
    if ECHO_COMMANDS == 1:
        print(my_command + "\n")
    instrument_object.write(my_command)


def instrument_read(instrument_object: object):
    """
    Used to read commands from the instrument.

    Args:
    instrument_object (object): Instance of an instrument object.

    Returns:
    string: The requested information returned from the target instrument.
    Obtained by way of a caller to instrument_read().
    """
    return instrument_object.read()


def instrument_query(instrument_object: object, my_command: str):
    """
    Used to send commands to the instrument  and obtain an information string
    from the instrument. Note that the information received will depend on the
    command sent and will be in string format.

    Args:
    instrument_object (object): Instance of an instrument object.
    my_command (string) - The command issued to the instrument to make it
    perform some action or service.

    Returns:
    string: The requested information returned from the target instrument.
    Obtained by way of a caller to instrument_read().
    """
    if ECHO_COMMANDS == 1:
        print(my_command)
    return instrument_object.query(my_command)


def instrument_query_binary_to_single_float(instrument_object: object,
                                            my_command: str,
                                            number_of_data_points: int):
    """
    Used to send commands to the instrument  and obtain a list of floating
    point (single) data items from the instrument. Note that the information
    received will depend on the command sent.

    Args:
    instrument_object (object): Instance of an instrument object.
    my_command (string) - The command issued to the instrument to make it
    perform some action or service.

    Returns:
    float[]: The requested information returned from the target instrument.
    Obtained by way of a caller to instrument_query_binary_data.
    """
    if ECHO_COMMANDS == 1:
        print(my_command)
    return instrument_object.query_binary_values(
        my_command, datatype='f',
        is_big_endian=False,
        data_points=number_of_data_points)


def instrument_disconnect(instrument_object: object):
    """
    Break the VISA connection between the controlling computer and the target
    instrument.

    Args:
    instrument_object (object): Instance of an instrument object.

    Returns:
    None
    """
    instrument_object.close()


def kei2231a_disconnect(instrument_object: object):
    instrument_write((instrument_object, "SYST:LOC"))
    instrument_disconnect(instrument_object)
    return


def kei2231a_selectchannel(instrument_object: object, myChan: int):
    instrument_write(instrument_object, f"INST:NSEL {myChan}")
    return

def kei2231a_setvoltage(instrument_object: object, myV: float):
    instrument_write(instrument_object, f"VOLT {myV}")
    return

def kei2231a_setcurrent(instrument_object: object, myI: float):
    instrument_write(instrument_object, f"CURR {myI}")
    return

def kei2231a_outputstate(instrument_object: object, myState):
    if myState == 0:
        instrument_write(instrument_object, f"OUTP {myState}")
    else:
        instrument_write(instrument_object, f"OUTP {myState}")
    return

def kei2231a_measurecurrent(instrument_object: object):
    return float(instrument_query(instrument_object, "MEAS:CURR?").rstrip())


# ================================================================================
#
#    MAIN CODE STARTS HERE
#
# ================================================================================
t1 = time.time()  # Start the timer...
resource_manager = visa.ResourceManager()  # Opens the resource manager
# print(resource_manager.list_resources())
KEI2231A = None

inst_resource_string = "ASRL3::INSTR"
resource_manager, KEI2231A = instrument_connect(resource_manager,
                                               KEI2231A,
                                               inst_resource_string,
                                               20000,
                                               0, 1, 0,
                                               reset_str="*RST; SYST:REM",
                                               baud_rate=9600,
                                               parity=pyconst.Parity.none,
                                               data_bits=8,
                                               flow_control=0,
                                               stop_bits=pyconst.StopBits.one)
print(KEI2231A.query("*IDN?"))
kei2231a_selectchannel(KEI2231A, 1)
kei2231a_setvoltage(KEI2231A, 1.0)
kei2231a_setcurrent(KEI2231A, 1.0)
kei2231a_outputstate(KEI2231A, 1)

time.sleep(0.25)
print(kei2231a_measurecurrent(KEI2231A))

kei2231a_outputstate(KEI2231A, 0)

instrument_disconnect(KEI2231A)

resource_manager.close

t2 = time.time()  # Stop the timer...

# Notify the user of completion and the data streaming rate achieved.
print("done")
print(f"Elapsed Time: {t2-t1:0.3f}s")

input("Press Enter to continue...")
exit()