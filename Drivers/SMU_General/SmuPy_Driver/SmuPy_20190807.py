"""***********************************************************
*** Copyright Tektronix, Inc.                           ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************"""

import visa
import struct
import math
import time
from enum import Enum


class SmuPy:
    def __init__(self):
        self.echo_command = 0
        self.my_instrument = 0
    # ======================================================================
    #      DEFINE INSTRUMENT CONNECTION AND COMMUNICATIONS FUNCTIONS HERE
    # ======================================================================

    """*********************************************************************************
        Function: instrument_connect(resource_manager, instrument_resource_string, timeout,
                                     do_id_query, do_reset, do_clear) 

        Purpose: Open an instance of an instrument object for remote communication.

        Parameters:
            resource_manager (object) - Instance of a resource manager object.
            
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

    def instrument_connect(self, resource_manager, instrument_resource_string, timeout,
                           do_id_query, do_reset, do_clear):
        self.my_instrument = resource_manager.open_resource(instrument_resource_string)
        if do_id_query == 1:
            print(self.instrument_query("*IDN?"))
        if do_reset == 1:
            self.instrument_write("reset()")
        if do_clear == 1:
            self.my_instrument.clear()
        # self.my_instrument.read_termination = '\n'
        # self.my_instrument.write_termination = '\n'

        self.my_instrument.timeout = timeout
        return

    """*********************************************************************************
        Function: instrument_disconnect()
        
        Purpose: Break the VISA connection between the controlling computer
                 and the target instrument.
        
        Parameters:
            None
        
        Returns:
            None
        
        Revisions:
            2019-08-07    JJB    Initial revision.
    *********************************************************************************"""
    def instrument_disconnect(self):
        self.my_instrument.close()
        return

    """*********************************************************************************
        Function: instrument_write(my_command)
        
        Purpose: Issue controlling commands to the target instrument.
        
        Parameters:
            my_command (string) - The command issued to the instrument to make it 
                                  perform some action or service. 
        Returns:
            None
        
        Revisions:
            2019-08-07    JJB    Initial revision.
    *********************************************************************************"""
    def instrument_write(self, my_command):
        if self.echo_command == 1:
            print(my_command)
        self.my_instrument.write(my_command)
        return

    """*********************************************************************************
        Function: instrument_query(my_socket, my_command, receive_size)
        
        Purpose: Break the LAN/Ethernet connection between the controlling computer
             and the target instrument.
        
        Parameters:
            my_command (string) - The command issued to the instrument to make it 
                          perform some action or service. 
        Returns:
            <<<reply>>> (string) - The requested information returned from the 
                        target instrument. Obtained by way of a caller
                        to instrument_read().
        
        Revisions:
            2019-08-07    JJB    Initial revision.
    *********************************************************************************"""

    def instrument_query(self, my_command):
        if self.echo_command == 1:
            print(my_command)
        return self.my_instrument.query(my_command)

    """*********************************************************************************
        Function: load_script_file(filePathAndName)
        
        Purpose: Copy the contents of a specific script file off of the computer 
                 and upload onto the target instrument. 
        
        Parameters:
            my_script_file (string) - The script file/path (ASCII text format) that 
                          will be read from the computer and sent to the
                          instrument. 
            my_socket - The TCP instrument connection object used for 
                          sending and receiving data. 
        Returns:
            None
        
        Revisions:
            2019-07-30    JJB    Initial revision.
    *********************************************************************************"""

    def load_script_file(self, file_path_and_name):
        # This function opens the functions.lua file in the same directory as
        # the Python script and transfers its contents to the instrument internal
        # memory. All the functions defined in the file are callable by the
        # controlling program.
        cmd = "loadandrunscript loadfuncs\n"
        self.instrument_write(cmd)

        with open(file_path_and_name) as fp:
            line = fp.readline()
            while line:
                self.instrument_write(line)
                line = fp.readline()

        cmd = "\nendscript"
        self.instrument_write(cmd)
        return

    """*********************************************************************************
        Function: diode_test_measure_forward_voltage(smu_channel, source_i_range, bias_i, source_v_limit, settle_time,
                                                     nplc, measure_v_range, end_of_test_output_state)
        
        Purpose: This function performs a forward voltage measurement at the specified 
                 bias current.  It configures the specified SMU using the given
                 source and measure parameters.  The SMU applies the specified bias current  
                 level, waits the specified amount of time to allow the current source and
                 diode-under-test to settle, and then performs single simultaneous 
                 measurements of voltage and current.  The SMU output is left on after 
                 the measurements are complete. 
        
        Parameters:
            smu_channel (string) - The SMU being used for the test, either smua or smub.  
            
            source_i_range (number) - Is the value in amps used to set the current source range.  If nil is passed 
                                      to the function, then current source 
                                      autoranging is enabled.
            bias_i (number) - Is the current level in amps at which the forward voltage is to be measured.  If SMU 
                             Force HI is connected to the anode of the diode, then to properly forward bias the 
                             diode, the current bias must be entered as a positive value.
            source_v_limit (number) - Is the voltage limit in volts for the current source.
            
            settle_time (number) - Is the time in seconds to wait between applying the bias current to the diode 
                                   and performing the current and voltage measurements.
            nplc (number) - Is the integration time for the analog-to-digital converter, and is specified in terms
                            of the number of powerline cycles.  The allowed range of values is 0.001 to 25.  An 
                            "autozero once" is performed after setting the NPLC value.
            measure_v_range (number) - Is the value in volts used to set the current measure range.  If no value 
                                       or nil is passed to the function, then current  measure autoranging is enabled.
        Returns:
            None
        
        Revisions:
            2019-08-22    JJB    Initial revision.
    *********************************************************************************"""

    def diode_test_measure_forward_voltage(self, smu_channel, source_i_range, bias_i, source_v_limit, settle_time, nplc,
                                           measure_v_range, end_of_test_output_state):
        # Initialize the smu...
        self.instrument_write("initialize_smu({0})".format(smu_channel))

        # Call meas_vf()
        measurement = self.instrument_query("print(measure_vf({0}, {1}, {2}, {3}, {4}, {5}, {6}))".format(smu_channel,
                                                                                                          source_i_range,
                                                                                                          bias_i,
                                                                                                          source_v_limit,
                                                                                                          settle_time,
                                                                                                          nplc,
                                                                                                          measure_v_range))
        measurement = measurement.rstrip()
        measured_i_bias, measured_vfwd = measurement.split('\t')
        if end_of_test_output_state == self.SmuOutputState.OFF:
            self.instrument_write("{0}.source.output = {1}.OUTPUT_OFF".format(smu_channel, smu_channel))
        return float(measured_i_bias), float(measured_vfwd)

    """*********************************************************************************
         Function: diode_test_measure_reverse_voltage(smu_channel, source_i_range, bias_i, source_v_limit, settle_time,
                                                      nplc, measure_v_range, end_of_test_output_state)

         Purpose: This function performs a reverse voltage measurement at the specified bias current.  It configures 
                  the specified SMU using the given source and measure parameters.  The SMU applies the specified 
                  bias current level, waits the specified amount of time to allow the current source and diode-
                  under-test to settle, and then performs single simultaneous measurements of voltage and current.  
                  The SMU output is left after the measurements are complete.

         Parameters:
             smu_channel (string) - The SMU being used for the test, either smua or smub.  

             source_i_range (number) - Is the value in amps used to set the current source range.  If nil is passed 
                                       to the function, then current source 
                                       autoranging is enabled.
             bias_i (number) - Is the current level in amps at which the forward voltage is to be measured.  If SMU 
                              Force HI is connected to the anode of the diode, then to properly forward bias the 
                              diode, the current bias must be entered as a positive value.
             source_v_limit (number) - Is the voltage limit in volts for the current source.

             settle_time (number) - Is the time in seconds to wait between applying the bias current to the diode 
                                    and performing the current and voltage measurements.
             nplc (number) - Is the integration time for the analog-to-digital converter, and is specified in terms
                             of the number of powerline cycles.  The allowed range of values is 0.001 to 25.  An 
                             "autozero once" is performed after setting the NPLC value.
             measure_v_range (number) - Is the value in volts used to set the current measure range.  If no value 
                                        or nil is passed to the function, then current  measure autoranging is enabled.
         Returns:
             None

         Revisions:
             2019-08-22    JJB    Initial revision.
     *********************************************************************************"""

    def diode_test_measure_reverse_voltage(self, smu_channel, source_i_range, bias_i, source_v_limit, settle_time, nplc,
                                           measure_v_range, end_of_test_output_state):
        # Initialize the smu...
        self.instrument_write("initialize_smu({0})".format(smu_channel))

        # Call the meas_vr()
        measurement = self.instrument_query("print(measure_vr({0}, {1}, {2}, {3}, {4}, {5}, {6}))".format(smu_channel,
                                                                                                          source_i_range,
                                                                                                          bias_i,
                                                                                                          source_v_limit,
                                                                                                          settle_time,
                                                                                                          nplc,
                                                                                                          measure_v_range))
        measurement = measurement.rstrip()
        measured_i_bias, measured_vrev = measurement.split('\t')
        if end_of_test_output_state == self.SmuOutputState.OFF:
            self.instrument_write("{0}.source.output = {1}.OUTPUT_OFF".format(smu_channel, smu_channel))
        return float(measured_i_bias), float(measured_vrev)

    class SmuOutputState(Enum):
        OFF = 0
        ON = 1
