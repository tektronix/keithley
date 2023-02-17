"""
    Copyright 2023 Tektronix, Inc.                      
    See www.tek.com/sample-license for licensing terms. 
"""

import pyvisa as visa
import pyvisa.constants as pyconst


class Communications:
    """
    This class offers the consumer a collection of wrapper menthods that
    leverage PyVisa calls and attempts to condense collections of methods
    therein while also adding in a means for echoing command calls to the
    terminal if the appropriate internal attribute is set to True. 

    Note that this is a work in progress and by no means a work of 
    perfection. Please feel free to copy, reuse, or enhance to your own
    liking and feel free to leave suggestions for improvement. Thanks!
    """

    def __init__(self, instrument_resource_string=None):
        self._instrument_resource_string = instrument_resource_string
        self._resource_manager = None
        self._instrument_object = None
        self._timeout = 20000
        self._echo_cmds = False

        try:
            if self._resource_manager is None:
                self._resource_manager = visa.ResourceManager()
        except visa.VisaIOError as visaerror:
            print(f"{visaerror}")
        except visa.VisaIOWarning as visawarning:
            print(f"{visawarning}")

    def connect(self, instrument_resource_string=None, timeout=None):
        """
        Open an instance of an instrument object for remote communication.

        Args:
            timeout (int): Time in milliseconds to wait before the \
                communication transaction with the target instrument\
                    is considered failed (timed out).
            
        Returns:
            None
        """
        try:
            if instrument_resource_string != None:
                self._instrument_resource_string = instrument_resource_string
                
            self._instrument_object = self._resource_manager.open_resource(
                self._instrument_resource_string
            )

            if timeout is None:
                self._instrument_object.timeout = timeout
            else:
                self._instrument_object.timeout = self._timeout

            # Check for the SOCKET as part of the instrument ID string and set
            # the following accordingly...
            if "SOCKET" in self._instrument_resource_string:
                self._instrument_object.write_termination = "\n"
                self._instrument_object.read_termination = "\n"
                self._instrument_object.send_end = True

        except visa.VisaIOError as visaerr:
            print(f"{visaerr}")
        return

    def configure_rs232_settings(
        self,
        baudrate=9600,
        databits=8,
        parity=0,
        stopbits=1,
        flowcontrol=0,
        writetermination="\n",
        readtermination="\n",
        sendend=True,
    ):
        """
            This method pulls the collection of RS-232 settings together in 
            one location. For applicable PyVisa-specific constants that best
            align with this method's use, refer to documentation on
            pyvisa.constants. 

        Args:
            baudrate (int): Defines the baud rate to be used for data \
                transmission. Options are typically 2400, 4800, 9600, and \
                    others up to 115200. Refer to your instrument documentation \
                        for what is truly applicable. 
            databits (int): Typically 8, sometimes 7.
            parity (pyconst.Parity): Options include none, odd, and even.
            stopbits (pyconst.StopBits): Options include one and two.
            flowcontrol (pyconst.ControlFlow): Options include none, xon/xoff, \
                rts/cts, and dtr/dsr.
            read_terminator (str): Character options include "\\n" and "\\r".
            sendend (bool): Specifies whether or not the end character is to be \
                sent. 

        Returns:
            None
        """
        # First verify that the instrument resource string has "ASRL" so
        #   we know it connected as a serial instrument.
        if "ASRL" in self._instrument_resource_string:
            self._instrument_object.baud_rate = baudrate
            self._instrument_object.data_bits = databits
            if parity == 0:
                self._instrument_object.parity = pyconst.Parity.none
            elif parity == 1:
                self._instrument_object.parity = pyconst.Parity.odd
            elif parity == 2:
                self._instrument_object.parity = pyconst.Parity.even

            if stopbits == 0:
                self._instrument_object.stop_bits = pyconst.StopBits.one_and_a_half
            elif stopbits == 1:
                self._instrument_object.stop_bits = pyconst.StopBits.one
            elif stopbits == 2:
                self._instrument_object.stop_bits = pyconst.StopBits.two

            if flowcontrol == 0:
                self._instrument_object.flow_control = pyconst.ControlFlow.none
            elif flowcontrol == 1:
                self._instrument_object.flow_control = pyconst.ControlFlow.xon_xoff
            elif flowcontrol == 1:
                self._instrument_object.flow_control = pyconst.ControlFlow.rts_cts
            elif flowcontrol == 1:
                self._instrument_object.flow_control = pyconst.ControlFlow.dtr_dsr

            self._instrument_object.write_termination = writetermination
            self._instrument_object.read_termination = readtermination
            self._instrument_object.send_end = sendend

        else:
            print("raise an exception")

    def disconnect(self):
        """
        Close an instance of an instrument object.

        Args:
            None

        Returns:
            None
        """
        try:
            self._instrument_object.close()
        except visa.VisaIOError as visaerr:
            print(f"{visaerr}")
        return

    def write(self, command: str):
        """
        Issue controlling commands to the target instrument.

        Args:
            command (str): The command issued to the instrument to make it\
                perform some action or service.

        Returns:
            None
        """
        try:
            if self._echo_cmds is True:
                print(command)
            self._instrument_object.write(command)
        except visa.VisaIOError as visaerr:
            print(f"{visaerr}")
        return

    def read(self):
        """
        Used to read commands from the instrument.

        Args:
            None

        Returns:
            (str): The requested information returned from the target
            instrument.
        """
        return self._instrument_object.read()

    def query(self, command: str):
        """
        Used to send commands to the instrument  and obtain an information
        string from the instrument. Note that the information received will
        depend on the command sent and will be in string format.

        Args:
            command (str): The command issued to the instrument to make it
            perform some action or service.

        Returns:
            (str): The requested information returned from the target
            instrument.
        """
        response = ""
        try:
            if self._echo_cmds is True:
                print(command)
            response = self._instrument_object.query(command).rstrip()
        except visa.VisaIOError as visaerr:
            print(f"{visaerr}")

        return response
