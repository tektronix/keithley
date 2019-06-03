""" ================================================================================

*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***

================================================================================ """

"""
====================================================================================================

    EXAMPLE DETAILS
    ===============
        The program example performs a multi-channel, mixed function scan using the Keithley DAQ6510
        Data Acquisition and Multimeter System. The example specifically targets the use of RS232
        in order to assist the large existing base of users who sill appreciate the value of this
        reliable communications tool. Further details of the program are as follows:
        
        A. Connects to the serial instrument with the DAQ6510 default serial settings, while also 
           leaving in place some "extras".
        B. Establishes the multi-channel, mixed function measurement attributes.
        C. Configures the scan attributes. 
        D. Initiates the scanning.
        E. Monitors the measurement reading buffer and outputs readings to the console window. 
        F. Beeps to notify user of completion.
        G. Disconnects from the DAQ6510. 
        
    REQUIREMENTS
    ============
        A. Python 3.5 or higher
        B. PyVISA 1.9
        C. VISA - recommended is NI-VISA, but Keysight VISA is also acceptable. 
====================================================================================================
"""
import visa
import time


def kei_instrument_connect(resource_string, instrument_object, get_id_string, timeout, do_reset):
    """
        Purpose: Open an instance of an instrument object for remote communication and
                 establish the communication attributes. In this instance, RS232 is
                 specifically established.

        Parameters:
            resource_string - The instrument VISA resource string used to identify the
                              equipment at the underlying driver level. This string can
                              be obtained per making a call to Find_Resources() VISA
                              function and extracted from the reported list.
            instrument_object - This is the instrument object variable that is used to
                                hold the reference to the instrument connection. Note that
                                it is expected to be uninitialized when entering this
                                function (nil) and will be updated and returned to the
                                caller at the end of the function.
            get_id_string - If set to a value of 1, this will promote the querying and
                            printing of the instrument ID string.
            timeout - This is used to define the duration of wait time that will transpire
                      with respect to VISA read/query calls prior to an error being reported.
            do_reset - If set to a value of 1, this will promote a call for the instrumet
                       to perform a reset.

        Returns:
            instrument_object - The initialized object variable that is used to pass to
                                other instrument communications functions.

        Revisions:
            2019-06-03    JJB    Quick cleanup and documentation preparation for sharing.
    """
    instrument_object = rm.open_resource(resource_string, baud_rate=9600, data_bits=8)
    instrument_object.write_termination = '\n'
    instrument_object.read_termination = '\n'
    instrument_object.send_end = True
    instrument_object.StopBits = 1
    # instrument_object.flow_control =      # only available in PyVisa 1.9
    # instrument_object.baud_rate = 9600
    if get_id_string == 1:
        print(instrument_object.query("*IDN?"))
    instrument_object.timeout = timeout
    if do_reset == 1:
        instrument_object.write('reset()')
    instrument_object.write('*CLS')
    return instrument_object


def kei_instrument_disconnect(instrument_object):
    """
        Purpose: Closes an instance of and instrument object previously opended for
                 remote communication.

        Parameters:
            instrument_object - This is the instrument object variable that is used to
                                hold the reference to the instrument connection.

        Returns:
            None

        Revisions:
            2019-06-03    JJB    Quick cleanup and documentation preparation for sharing.
    """
    instrument_object.close()
    return


def kei_instrument_send(instrument_object, command_to_send):
    """
        Purpose: Used to send commands to the instrument referenced via instrument_object.

        Parameters:
            instrument_object - The instrument object variable that is used for instrument connection.

            command_to_send - The command string issued to the instrument in order to perform
                              an action.

        Revisions:
            2019-06-03    JJB    Quick cleanup and documentation preparation for sharing.
    """
    instrument_object.write(command_to_send)
    return


def kei_instrument_query(instrument_object, command_to_send):
    """
        Purpose: Used to send commands to the instrument referenced via instrument_object and
                 obtain an information string from the instrument. Note that the information
                 received will depend on the command sent.

        Parameters:
            instrument_object - The instrument object variable that is used for instrument connection.

            command_to_send - The command string issued to the instrument in order to perform
                              an action.

        Returns:
            The string obtained from the instrument.

        Revisions:
            2019-06-03    JJB    Quick cleanup and documentation preparation for sharing.
    """
    received_string = instrument_object.query(command_to_send)
    return received_string


def daq6510_configure_multifunction_scan_channels(instrument_object):
    """
        Purpose: Used to configure the desired scan channels with the functions and attributes
                 needed to monitor the signals of interest.

        Parameters:
            instrument_object - The instrument object variable that is used for instrument connection.

        Returns:
            None

        Revisions:
            2019-06-03    JJB    Quick cleanup and documentation preparation for sharing.
    """
    #  Assume channels 101, 110, 115, and 120 are using thermocouples to monitor temperature and we use the internal
    #  reference junction for cold-junction compensation.
    kei_instrument_send(instrument_object, 'channel.setdmm("101,110,115,120", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE)')
    kei_instrument_send(instrument_object, 'channel.setdmm("101,110,115,120", dmm.ATTR_MEAS_REF_JUNCTION, dmm.REFJUNCT_INTERNAL)')

    # Assume we are using channels 102 through 106 and 116 to measure 2-wire resistance; applying auto-ranging to each.
    kei_instrument_send(instrument_object, 'channel.setdmm("102:106,116", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_RESISTANCE)')
    kei_instrument_send(instrument_object, 'channel.setdmm("102:106,116", dmm.ATTR_MEAS_RANGE_AUTO, dmm.ON)')

    # Assume we are using channels 107 through 109 to measure 4-wire resistance; applying auto-ranging to each.
    kei_instrument_send(instrument_object, 'channel.setdmm("107:109", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_4W_RESISTANCE)')
    kei_instrument_send(instrument_object, 'channel.setdmm("107:109", dmm.ATTR_MEAS_RANGE_AUTO, dmm.ON)')

    # Assume we are using channels 111 through 114 to measure DC voltage; applying auto-ranging to each.
    kei_instrument_send(instrument_object, 'channel.setdmm("111:114", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_VOLTAGE)')
    kei_instrument_send(instrument_object, 'channel.setdmm("111:114", dmm.ATTR_MEAS_RANGE_AUTO, dmm.ON)')
    return


def daq6510_configure_scan_attributes(instrument_object, scan_count, scan_interval):
    """
        Purpose: Used to configure the desired scan channels with the functions and attributes
                 needed to monitor the signals of interest.

        Parameters:
            instrument_object - The instrument object variable that is used for instrument connection.

            scan_count - The number of times the series of defined channels will be measured.

            scan_interval - The delay between the start of one scan to the start of the next scan.

        Returns:
            None

        Revisions:
            2019-06-03    JJB    Quick cleanup and documentation preparation for sharing.
    """
    kei_instrument_send(instrument_object, 'scan.create("101:120")')
    kei_instrument_send(instrument_object, 'scan.scancount = {0}'.format(scan_count))
    kei_instrument_send(instrument_object, 'scan.scaninterval = {0}'.format(scan_interval))
    kei_instrument_send(instrument_object, 'scan.monitor.channel = "101"')
    return


def daq6510_trigger(instrument_object):
    """
        Purpose: Used to initiate the scan.

        Parameters:
            instrument_object - The instrument object variable that is used for instrument connection.

        Returns:
            None

        Revisions:
            2019-06-03    JJB    Quick cleanup and documentation preparation for sharing.
    """
    kei_instrument_send(instrument_object, 'trigger.model.initiate()')
    return


def daq6510_get_scan_measurements(instrument_object, scan_count):
    """
        Purpose: Used to monitor the reading buffer, extract readings, and print to the console window.

        Parameters:
            instrument_object - The instrument object variable that is used for instrument connection.

            scan_count - The number of times the series of defined channels will be measured.

        Returns:
            None

        Revisions:
            2019-06-03    JJB    Quick cleanup and documentation preparation for sharing.
    """
    channel_count = 17  # There are 20 channels, but 3 are configured for 4W measurements, so 20-3 = 17
    start_index = 1
    end_index = channel_count
    target_count = scan_count * channel_count
    readings_captured = 0
    looper = 1

    #  Loop until we have extracted all data from the buffer and printed to the console.
    while end_index <= target_count:
        kei_instrument_send(instrument_object, 'statsVar = buffer.getstats(defbuffer1)')
        stats_var = int(kei_instrument_query(instrument_object, 'print(statsVar.n)'))

        while (stats_var - readings_captured) < channel_count:
            time.sleep(0.5)
            kei_instrument_send(instrument_object, 'statsVar = buffer.getstats(defbuffer1)')
            stats_var = int(kei_instrument_query(instrument_object, 'print(statsVar.n)'))

        looper = looper + 1

        #  Extract the data...
        print("{0}\n".format(kei_instrument_query(instrument_object, 'printbuffer({0}, {1}, defbuffer1.readings)'.format(start_index, end_index))))

        #  Update all variables that help us index through the reading buffer and provide program control.
        start_index = start_index + channel_count
        end_index = end_index + channel_count
        readings_captured = readings_captured + channel_count

    #  Provide an audible alert to let the operator know the test is complete.
    kei_instrument_send(instrument_object, 'beeper.beep(1.0, 3500)')
    return


""" ================================================================================

    MAIN CODE GOES HERE
    
================================================================================"""
my_daq = 0
rm = 0
scan_count = 100
scan_interval = 5.0

rm = visa.ResourceManager()  # Opens the resource manager and sets it to variable rm

t1 = time.time()  # Capture start time....

my_daq = kei_instrument_connect("ASRL5::INSTR", my_daq, 1, 20000, 1)

time.sleep(0.25)

daq6510_configure_multifunction_scan_channels(my_daq)
daq6510_configure_scan_attributes(my_daq, scan_count, scan_interval)
daq6510_trigger(my_daq)

daq6510_get_scan_measurements(my_daq, scan_count)

kei_instrument_disconnect(my_daq)

rm.close()

t2 = time.time()  # Capture stop time...
print("{0:.3f} s".format((t2 - t1)))
