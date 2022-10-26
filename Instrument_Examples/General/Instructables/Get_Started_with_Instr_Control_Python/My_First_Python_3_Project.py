import visa
import time

echo_commands = 0

"""*********************************************************************************
    Function: instrument_connect(resource_mgr, instrument_resource_string, timeout,
                                 do_id_query, do_reset, do_clear) 

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


def instrument_connect(resource_mgr, instrument_object, instrument_resource_string, timeout, do_id_query, do_reset, do_clear): 
    instrument_object = resource_mgr.open_resource(instrument_resource_string)
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
        print(my_command)
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


#================================================================================
#
#    MAIN CODE STARTS HERE
#
#================================================================================
t1 = time.time()                    # Start the timer...
instrument_resource_string = "USB0::0x05E6::0x2602::4132104::INSTR"
resource_manager = visa.ResourceManager()	# Opens the resource manager
my_instr = None 
resource_manager, my_instr = instrument_connect(resource_manager, my_instr, instrument_resource_string, 20000, 1, 1, 1)

instrument_write(my_instr, "*RST")
for j in range(1, 10):
    instrument_write(my_instr, "*IDN?")
    print(instrument_read(my_instr))
    print(instrument_query(my_instr, "*IDN?")) # query is the same as write + read

instrument_disconnect(my_instr)
resource_manager.close

t2 = time.time()                    # Stop the timer...

# Notify the user of completion and the data streaming rate achieved. 
print("done")
print("Elapsed Time: {0:0.3f}s".format(t2-t1))

input("Press Enter to continue...")
exit()
