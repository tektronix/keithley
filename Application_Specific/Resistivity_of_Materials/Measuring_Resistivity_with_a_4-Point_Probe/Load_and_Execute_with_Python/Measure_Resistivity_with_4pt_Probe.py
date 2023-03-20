"""
    ***********************************************************
    *** Copyright 2023 Tektronix, Inc.                      ***
    *** See www.tek.com/sample-license for licensing terms. ***
    ***********************************************************
    
    This example is used to show how a resistivity measurement with a 4-point probe
    can be conducted using a 2400 Interactive Source Measure Unit.

    This code does the following:
        A. Establishes a communication connection between the PC and the TSP-enabled
           instrumentation. 
        B. Loads a TSP script file onto the master node. The script is executed upon
           load, activating the functions defined within the script file into instrument
           memory. 
        C. Execution of the resistivity test and a change of the instrument front panel
           to reflect the calculated outcome. 
        D. Return of the reading to the controlling program.
"""
from instrcomms import Communications
import time
import pathlib


class SourceMeasureUnit(Communications):
    """
    Placeholder docstring
    """
    def __init__(self, instrument_resource_string):
        Communications.__init__(self, instrument_resource_string)
        self._model_number = None
        self._manufacturer = None
        self._serial_number = None
        self._firmware = None
        
    def initialize(self, do_reset=False):
        """
        Opens the I/O session to the instrument. Driver methods and properties
        that access the instrument are only accessible after initialize() is
        called. The initialize optionally performs an instrument reset. The
        instrument ID is queried by default and the returned information is
        populated in and accessible through member variables.
        """
        self.connect(self._instrument_resource_string)
        time.sleep(0.01)
        if do_reset is True:
            self.write("reset()")

        # Query the ID then parse the return string to obain the associated
        #   information
        details = self.query("*IDN?").split(',')
        self._manufacturer = details[0].strip()
        self._model_number = details[1].strip()
        self._serial_number = details[2].strip()
        self._firmware = details[3].strip()
    
    def close(self):
        """
        Closes the I/O session to the instrument. Driver methods and properties
        that access the instrument are not accessible after Close is called.
        """
        self.disconnect()
    
    
    def get_readings(self):
        """placeholder for docstring"""
        return self.query("printbuffer(1, defbuffer1.n, defbuffer1)")

    def load_script_file(self, my_script_file):
        """
        This function opens the functions.lua file in the same directory as
        the Python script and trasfers its contents to the DMM7510's internal
        memory. All the functions defined in the file are callable by the
        controlling program.
        """
        func_file = open(my_script_file, "r")

        send_buffer = "if loadfuncs ~= nil then script.delete('loadfuncs') end"
        self.write(send_buffer)

        send_buffer = f"loadscript loadfuncs\n"
        self.write(send_buffer)

        for line in func_file:
            self.write(line)

        send_buffer = f"endscript"
        self.write(send_buffer)

        func_file.close()

        send_buffer = "loadfuncs()"
        print(self.query(send_buffer))  # Note that the query here presumes the script file
                                        #   ends with some sort of print statement. This can
                                        #   be confirmed in the script referenced in this 
                                        #   example. (See simple_resistivity_measure.tsp)
        return

# --------------------------------------------------------------------------------
#               MAIN CODE STARTS HERE
# --------------------------------------------------------------------------------
print(pathlib.Path.cwd())
fileandpath = f"{pathlib.Path.cwd()}\\Model_2450\\003_Measure_Resistivity\\simple_resistivity_measure.tsp"
print(fileandpath)

smu2450 = SourceMeasureUnit("TCPIP0::192.168.0.50::inst0::INSTR")
smu2450.initialize(do_reset=False)

# Upload a script file to the instrument
smu2450.load_script_file(fileandpath)

print(smu2450.query("print(resistivity_4point(100e-3))"))

smu2450.close()