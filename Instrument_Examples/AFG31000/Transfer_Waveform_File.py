"""

    ***********************************************************
    *** Copyright 2025 Tektronix, Inc.                      ***
    *** See www.tek.com/sample-license for licensing terms. ***
    ***********************************************************

    Transfer_Waveform_File.py
    
    Transfer an AFG31k waveform file (.tfwx) over a remote communication to an AFG31k (requires AFG31k firmware 1.6.5 or above). Note waveform file to transfer must be in the same directory as this Python script.
"""

import pyvisa
import sys
from pathlib import Path

def read_waveform_file(file_path):
    """
        read_waveform_file reads the waveform file contents that is specified at file_path

        :param file_path: file path of waveform file
        :return: contents of waveform file
    """ 
    try:
        with open(file_path, 'rb') as file: # read waveform file
            return file.read()
    except FileNotFoundError: # error if waveform file not found
        print(f"Error: File not found at {file_path}")
        sys.exit(1)
    except Exception as e: # error if issue reading waveform file
        print(f"Error reading the waveform file: {e}")
        sys.exit(1)
        

def transfer_waveform_file(instrument, filename, file_contents):
    """
        transfer_waveform_file transfers a waveform file (.tfwx) to an AFG31k

        :param instrument: PyVISA resource object
        :param filename: filename of waveform file
        :param file_contents: contents of waveform file
        :return: none
    """ 
    
    chunk_size = 1048575 # size of each binary data chunk in bytes (max allowed is 1048575 bytes)
    total_size = len(file_contents) # get number of bytes in file
    num_chunks = (total_size // chunk_size) + (1 if total_size % chunk_size != 0 else 0) # get number of chunks required to send entire file
    command = f"DATA:FILE \"{filename}\",{total_size}," # SCPI command to transfer file
    
    # send wavefrom file
    for i in range(num_chunks):
        
        # get binary chunk from file contents
        start = i * chunk_size
        end = start + chunk_size
        chunk = file_contents[start:end]
        
        print(f"Sending chunk {i+1}/{num_chunks}, size: {len(chunk)} bytes")
        instrument.write_binary_values(command, chunk, datatype='b') # transfer waveform
        
        if(i == 0 or i ==1): # check for errors with DATA:FILE command
            error = instrument.query("SYST:ERROR?")
            if(error[0] != "0"):
                raise Exception(f"DATA:FILE command error, {error}")
      
    # check if waveform file was saved succesfully
    savedFiles = instrument.query("MMEMory:CATalog?")
    if f"{filename}" not in savedFiles:
        print(f"All Saved Files:\n{savedFiles}")
        raise Exception("Waveform file transfer failed") 
    
    print("File sent successfully.")
        
        
def main():
    try:
        # configure and connect to an AFG31k
        rm = pyvisa.ResourceManager()
        instrument_address = "" # instrument resource string
        instrument = None # instrument connection session
        instrument = rm.open_resource(instrument_address, write_termination='\n')
        instrument.timeout = 25000
        if "SOCKET" in instrument_address:
            instrument.write_termination = "\n"
            instrument.read_termination = "\n"
            instrument.send_end = True
            
        instrument.write("*RST") # reset AFG to default state
        instrument.write("*CLS") # clear error queue
        
        filename = "example.tfwx" # name waveform file to send to AFG31k
        waveform_file_path = str(Path(__file__).parent) + "\\" + filename # complete file path to waveform file (waveform file must be in same directroy as Python script)
        waveform_file_contents = read_waveform_file(waveform_file_path) # get file contents
        transfer_waveform_file(instrument, filename, waveform_file_contents) # transfer waveform file
        
    except pyvisa.VisaIOError as e: # errors for instrument communcation
        print(f"VISA communication error: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        if(instrument != None): # check if connection was ever successfully established
            try:
                # print errors from error queue
                errors = instrument.query("SYST:ERROR?")
                while(errors[0] != "0"):
                    print(errors)
                    errors = instrument.query("SYST:ERROR?")
                    
                instrument.clear() # clear connection
            except Exception as e:
                print(f"An error occurred: {e}")    
            finally:
                instrument.close() # close VISA session
                rm.close() # close resource manager session

if __name__ == "__main__":
    main()
