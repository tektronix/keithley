"""
    Double_Pulse_2Ch.py
    
    Example for 2 channel double pulse on the AFG31k using remote commands. Creates a double pulse waveform, sends it to each channel's edit memory, and outputs it from two channels.
"""

import pyvisa
import sys
import time

def generateDoublePulse(instrument, channel, pulse1OnTime, pulse1OffTime, pulse2OnTime, pulse2OffTime, highV, lowV, invert=0):
    """
        generateDoublePulse configures a double pulse arbitrary waveform to the AFG31k's basic mode. Configures AFG31k's basic mode to be in burst mode where it waits for a *TRG before outputting
        the double when the selected channel is on. Before turning on the selected channel send a *TRG the AFG31k to ensure the selected waveform idle state is correct.

        :param instrument: PyVISA resource object
        :param channel: AFG31k channel to configure to double pulse
        :param pulse1OnTime: duration (pulse width) of first pulse in seconds. Max: 10ms Min: 20ns
        :param pulse1OffTime: duration of gap between pulse 1 and pulse 2 in seconds. Max: 10ms Min: 20ns
        :param pulse2OnTime: duration (pulse width) of second pulse in seconds. Max: 10ms Min: 20ns
        :param pulse2OffTime: duration of gap after pulse 2 in seconds. Max: 10ms Min: 20ns
        :param highV: voltage of pulse during on time in volts
        :param lowV: voltage of pulse during off time in volts
        :param invert: Invert double pulse waveform. 0 for normal, 1 for inverted
        :return: None
    """ 
    debug = 0 # to print debug statements. 0 = no, 1 = yes
    
    MAX_VALUE = 0x3FFE # Value of highest point (high peak) in hexidecimal
    MIN_VALUE = 0x0000 # Value of lowest point (low peak) in hexidecimal
    minPulseTime = 20e-9 # minimum timing allowed for a single pulse
    maxPulseTime = 10e-3 # maximum timing allowed for a single pulse
    numberPoints = 130000 # Number of points used for arbitrary double pulse waveform
    maxTimingError = 1 # maximum timing error allowed as a percentage

    # Get settable double pulse timing
    totalTime = pulse1OnTime + pulse1OffTime + pulse2OnTime + pulse2OffTime
    frequency = 1/totalTime
    pulse1OnPoints = round((pulse1OnTime/totalTime)*numberPoints)
    pulse1OffPoints = round((pulse1OffTime/totalTime)*numberPoints)
    pulse2OnPoints = round((pulse2OnTime/totalTime)*numberPoints)
    pulse2OffPoints = round((pulse2OffTime/totalTime)*numberPoints)

    # Check if object passed is a PyVISA object
    if(not(hasattr(instrument, 'session'))):
        raise Exception(f"{generateDoublePulse.__name__}- A valid PyVISA object must be passed")
    
    # Calculate pulse timing representation errors
    setPulse1OnTime = pulse1OnPoints/numberPoints*totalTime
    pulse1OnError = (abs(setPulse1OnTime-pulse1OnTime)/pulse1OnTime)*100
    setPulse1OffTime = pulse1OffPoints/numberPoints*totalTime
    pulse1OffError = (abs(setPulse1OffTime-pulse1OffTime)/pulse1OffTime)*100
    setPulse2OnTime = pulse2OnPoints/numberPoints*totalTime
    pulse2OnError = (abs(setPulse2OnTime-pulse2OnTime)/pulse2OnTime)*100
    setPulse2OffTime = pulse2OffPoints/numberPoints*totalTime
    pulse2OffError = (abs(setPulse2OffTime-pulse2OffTime)/pulse2OffTime)*100
    
    # Print pulse timing representation errors
    if(debug):  
        print(f"\nAFG31k Double pulse ch{channel} timing and frequency representation errors\ndue to rounding and finite number of arbitrary points")
        print("------------------------------------------------------------------------------")
        print(f"Requested Pulse 1 On Time: {pulse1OnTime}")
        print(f"Set Pulse 1 On Time: {setPulse1OnTime}")
        print(f"Pulse 1 On Time Percent error: {pulse1OnError} %")
        print(f"\nRequested Pulse 2 Off Time: {pulse1OffTime}")
        print(f"Set Pulse 1 Off Time: {setPulse1OffTime}")
        print(f"Pulse 1 On Time Percent error: {pulse1OffError} %")
        print(f"\nRequested Pulse 2 On Time: {pulse2OnTime}")
        print(f"Set Pulse 2 On Time: {setPulse2OnTime}")
        print(f"Pulse 2 On Time Percent error: {pulse2OnError} %")
        print(f"\nRequested Pulse 2 Off Time: {pulse2OffTime}")
        print(f"Set Pulse 2 Off Time: {setPulse2OffTime}")
        print(f"Pulse 2 Off Time Percent error: {pulse2OffError} %")
        
    # Check pulse timings
    idn = instrument.query("*IDN?").split(",") # Get model info
    if(pulse1OnTime < minPulseTime or pulse1OffTime < minPulseTime or pulse2OnTime < minPulseTime or pulse2OffTime < minPulseTime):
        raise Exception(f"{generateDoublePulse.__name__}- All pulse segment must be longer than {minPulseTime} seconds ")
    if(idn[1][:-1] == "AFG3102" and totalTime < 160e-6):
        raise Exception(f"{generateDoublePulse.__name__}- AFG312X models must have a total double pulse time of at least 160ns")
    if(pulse1OnTime > maxPulseTime or pulse1OffTime > maxPulseTime or pulse2OnTime > maxPulseTime or pulse2OffTime > maxPulseTime):
        raise Exception(f"{generateDoublePulse.__name__}- All pulse segment must be shorter than {maxPulseTime} seconds")
    if((pulse1OnError > maxTimingError) or (pulse1OffError > maxTimingError) or (pulse2OnError > maxTimingError) or (pulse2OffError > maxTimingError)):
        if(pulse1OnError > maxTimingError):
            raise Exception(f"{generateDoublePulse.__name__}- pulse 1 on time timing error exceeds max timing error. {pulse1OnError}% > {maxTimingError}%")
        elif(pulse1OffError > maxTimingError):
            raise Exception(f"{generateDoublePulse.__name__}- pulse 1 off time timing error exceeds max timing error. {pulse1OffError}% > {maxTimingError}%")
        elif(pulse2OnError > maxTimingError):
            raise Exception(f"{generateDoublePulse.__name__}- pulse 2 on time timing error exceeds max timing error. {pulse2OnError}% > {maxTimingError}%")
        else:
            raise Exception(f"{generateDoublePulse.__name__}- pulse 2 off time timing error exceeds max timing error. {pulse2OffError}% > {maxTimingError}%")
    
    # Check channel number
    if(channel != 1 and channel!=2):
        raise Exception(f"{generateDoublePulse.__name__} Channel must be either 1 or 2")
    
    # check amplitude values
    amplitude = highV + abs(lowV)
    offset = (highV+lowV)/2
    outputImpedance = float(instrument.query(f"OUTPut{channel}:IMPedance?"))
    if(highV <= lowV):
        raise Exception(f"{generateDoublePulse.__name__}- High voltage ({highV}) must be greater than low voltage ({lowV})")
    if(outputImpedance == 50):
        if(idn[1][:-1] == "AFG3102" or idn[1][:-1] == "AFG3105" or idn[1][:-1] == "AFG3110"):
            if(5 < (amplitude/2.0)+abs(offset)):
                raise Exception(f"{generateDoublePulse.__name__}- Invalid HighV and LowV setting combination for 50 Ohm load. Must follow: ((highV + |lowV|)/2 + |(highV+lowV)/2|) < 5 (Set: {(amplitude/2.0)+abs(offset)}  < 5)")
        else:
            if(2.5 < (amplitude/2.0)+abs(offset)):
                raise Exception(f"{generateDoublePulse.__name__}- Invalid HighV and LowV setting combination for 50 Ohm load. Must follow: ((highV + |lowV|)/2 + |(highV+lowV)/2|) < 2.5 (Set: {(amplitude/2.0)+abs(offset)}  < 2.5)")
    elif(outputImpedance > 10000):
        if(idn[1][:-1] == "AFG3102" or idn[1][:-1] == "AFG3105" or idn[1][:-1] == "AFG3110"):
            if(10 < (amplitude/2.0)+abs(offset)):
                raise Exception(f"{generateDoublePulse.__name__}- Invalid HighV and LowV setting combination for High Z load. Must follow: ((highV + |lowV|)/2 + |(highV+lowV)/2|) < 10 (Set: {(amplitude/2.0)+abs(offset)}  < 10)")
        else:
            if(5 < (amplitude/2.0)+abs(offset)):
                raise Exception(f"{generateDoublePulse.__name__}- Invalid HighV and LowV setting combination for High Z load. Must follow: ((highV + |lowV|)/2 + |(highV+lowV)/2|) < 5 (Set: {(amplitude/2.0)+abs(offset)}  < 5)")

    # Construct double pulse waveform in hexadecimal
    byteString = "" # Hold double pulse waveform data as hexidecimal
    for x in range(pulse1OnPoints):
        hexValue = format(MAX_VALUE, '04X') # Convert MAX_VALUE to Hex
        byteString = byteString + hexValue # Store hexValue in Byte String
    for x in range(pulse1OffPoints):
        hexValue = format(MIN_VALUE, '04X') # Convert MIN_VALUE to Hex
        byteString = byteString + hexValue # Store hexValue in Byte String 
    for x in range(pulse2OnPoints):
        hexValue = format(MAX_VALUE, '04X') # Convert MAX_VALUE to Hex
        byteString = byteString + hexValue # Store hexValue in Byte String 
    for x in range(pulse2OffPoints):
        hexValue = format(MIN_VALUE, '04X') # Convert MIN_VALUE to Hex
        byteString = byteString + hexValue # Store hexValue in Byte String
    
    # Send double pulse waveform to AFG31k's edit memory
    instrument.write(f"SOUR{channel}:FUNC:SHAP EMEM{channel}") # Configure channel to EMEM
    command = f"DATA:DATA EMEM{channel}," # SCPI command for transfering waveform
    data = bytes.fromhex(byteString) # Convert hex string to bytes
    instrument.write_binary_values(command, data, datatype='b') # Transfer waveform

    # Configure AFG31k's basic mode
    instrument.write(f"SOUR{channel}:BURST:STATE ON")# Burst waveform
    instrument.write(f"SOURce{channel}:BURSt:MODE TRIGgered") # Trigger Mode
    instrument.write(f"TRIG:SOUR EXT") # External trigger
    instrument.write(f"SOURce{channel}:BURSt:NCYCles 1") # 1 cycle
    instrument.write(f"SOURce{channel}:VOLTage:LEVel:IMMediate:HIGH {highV}V") # Set high V
    instrument.write(f"SOURce{channel}:VOLTage:LEVel:IMMediate:LOW {lowV}V") # Set low V
    instrument.write(f"SOUR{channel}:FREQ {frequency}") # Set frequency
    
    # invert waveform
    if invert:
        instrument.write(f"SOURce{channel}:BURSt:IDLE START") # idle state start point
        instrument.write(f"OUTPut{channel}:POLarity INVerted") # invert waveform polarity
    else:
        instrument.write(f"SOURce{channel}:BURSt:IDLE END") # idle state end point
        instrument.write(f"OUTPut{channel}:POLarity NORMal") # normal waveform polarity
    
    # Print frequency representation errors
    if(debug):
        setFrequency = float(instrument.query(f"SOUR{channel}:FREQ?"))
        print(f"\nRequested Frequency: {frequency}")
        print(f"Set frequency: {setFrequency}")
        print(f"Frequency Percent error: {(abs(setFrequency-frequency)/frequency)*100} %")
        print("------------------------------------------------------------------------------")
    
def main():
    
    resourceString = "" # Instrument resource string
    
    # Configure Visa Connection
    rm = pyvisa.ResourceManager()
    instrument = rm.open_resource(resourceString)
    instrument.timeout = 10000
    if "SOCKET" in resourceString:
        instrument.write_termination = "\n"
        instrument.read_termination = "\n"
        instrument.send_end = True
    
    instrument.write("*RST") # reset instrument

    # Configure double pulse
    pulse1OnTime = 20e-6
    pulse1OffTime = 10e-6
    pulse2OnTime = 10e-6
    pulse2OffTime = 10e-6
    totalPulseTiming = pulse1OnTime + pulse1OffTime + pulse2OnTime + pulse2OffTime
    voltageHigh = 2.5
    voltageLow = 0
    try:
        generateDoublePulse(instrument, 1, pulse1OnTime, pulse1OffTime, pulse2OnTime, pulse2OffTime, voltageHigh, voltageLow)
        generateDoublePulse(instrument, 2, pulse1OnTime, pulse1OffTime, pulse2OnTime, pulse2OffTime, voltageHigh, voltageLow)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit()
        
    # Output double pulses
    instrument.write("*TRG")
    instrument.write(":OUTPut1:STATe ON;:OUTPut2:STATe ON")
    time.sleep(1) # wait for channels outputs to both be on and ready
    instrument.write("*TRG")
    time.sleep(totalPulseTiming) # wait for total time of double pulse before turning channels off
    instrument.write(":OUTPut1:STATe OFF")
    instrument.write(":OUTPut2:STATe OFF")

    instrument.clear() # Clear connection
    instrument.close() # Close VISA session
    rm.close() # Close resource manager session
    
main() # Run main program
