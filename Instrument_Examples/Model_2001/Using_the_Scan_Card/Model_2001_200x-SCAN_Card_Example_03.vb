'================================================================================

'   Copyright 2019 Tektronix, Inc.
'   See www.tek.com/sample-license for licensing terms. 

'================================================================================

Imports Ivi.Visa.Interop

Module Module1

    Private ReadOnly echo_command As Boolean = True

    Sub Main()
        ' Create a Stopwatch object And capture the program start time from the system.
        Dim myStpWtch As Stopwatch = New Stopwatch()
        myStpWtch.Start()

        '
        ' Open the resource manager And assigns it to an object variable
        '
        Dim resource_manager As Ivi.Visa.Interop.ResourceManager = New Ivi.Visa.Interop.ResourceManager

        '
        '  Create a FormattedIO488 object to represent the instrument 
        '  you intend to communicate with, And connect to it.
        '
        'Dim USB As Ivi.Visa.Interop.IUsb = MSG

        Dim my_instrument As FormattedIO488 = New Ivi.Visa.Interop.FormattedIO488()
        Dim instrument_id_string As String = "GPIB0::17::INSTR"
        Dim timeout As Int16 = 20000  ' define the timeout in terms of milliseconds
        ' Instrument ID String examples...
        '       LAN -> TCPIP0:134.63.71.209:inst0 : InStr()
        '       USB -> USB0:0x05E6:0x2450:01419962:InStr()
        '       GPIB -> GPIB0:16:InStr()
        '       Serial -> ASRL4:InStr()
        Connect_To_Instrument(resource_manager, my_instrument, instrument_id_string, timeout)

        Instrument_Write(my_instrument, "*RST")                                 ' Set to a known state
        Instrument_Write(my_instrument, "INIT:CONT OFF")                        ' Disable continuous trigger
        Instrument_Write(my_instrument, "ROUT:SCAN:LSEL NONE")                  ' Temporarily disable scanning
        Instrument_Write(my_instrument, "ROUT:SCAN:FUNC (@1:10), 'VOLT:DC'")    ' Define the channel function
        Instrument_Write(my_instrument, "ROUT:SCAN (@1:10)")                    ' Define which channels are to be included within the scan
        Instrument_Write(my_instrument, "TRIG:COUN 10")                         ' Number of channel measurements that are triggered in each scan, in this case 3 channels = 3 triggers
        Instrument_Write(my_instrument, "TRIG:SOUR IMM")                        ' Apply immediate triggering of each channel measurement
        Dim scan_count = 60
        Instrument_Write(my_instrument, String.Format("ARM:LAY2:COUN {0}", scan_count)) ' Number of scans to execute; since we want once per minute for an hour we set to 60
        Instrument_Write(my_instrument, "ARM:LAY2:SOUR TIM")                    ' Set the scan trigger to be dependent on the timer event
        Instrument_Write(my_instrument, "ARM:LAY2:TIM 60.0")                    ' Set the scan trigger timer to initiate a trigger event every 60 seconds
        Instrument_Write(my_instrument, "TRAC:CLE")                             ' Clear the buffer
        Instrument_Write(my_instrument, "TRAC:POIN 10")                         ' Size the buffer for a single scan; extract the full buffer per scan
        Instrument_Write(my_instrument, "TRAC:FEED SENS")                       ' Measurements stored to data buffer
        Instrument_Write(my_instrument, "TRAC:FEED:CONT NEXT")                  ' Configure the buffer for a single-fill-and-stop operation
        Instrument_Write(my_instrument, "ROUT:SCAN:LSEL INT")                   ' Enable scanning
        Instrument_Write(my_instrument, "FORM:ELEM READ, CHAN, UNIT")           ' Return readings, channel numbers, and units
        Instrument_Write(my_instrument, "STAT:PRES; *CLS")                      ' Clear register 
        Instrument_Write(my_instrument, "STAT:MEAS:ENAB 512")                   ' Check for a buffer full status
        Instrument_Write(my_instrument, "*SRE 1")                               ' Status register events enabled
        Instrument_Write(my_instrument, "INIT")                                 ' Start the scanning process

        Dim counter = 0
        Dim mask_val = 512
        Dim rcvBuffer As String = ""
        Dim status_mon As Int16 = 0
        status_mon = status_mon And mask_val
        Do While counter <> scan_count
            Do While status_mon <> mask_val
                Threading.Thread.Sleep(5000)                                    ' Delay for n milliseconds to allow for scanning and delay between scans
                status_mon = CInt(Instrument_Query(my_instrument, "STAT:MEAS?")) ' Check the measurement status register
                Console.WriteLine(status_mon)
                status_mon = status_mon And mask_val                            ' Mask to look for the buffer full condition
            Loop

            status_mon = 0
            rcvBuffer = Instrument_Query(my_instrument, "TRAC:DATA?")           ' Extract the data
            Console.WriteLine(rcvBuffer)
            Instrument_Write(my_instrument, "TRAC:CLE")                         ' Clear the buffer
            Instrument_Write(my_instrument, "TRAC:FEED:CONT NEXT")              ' ...then re-establish the fill mode
            counter += 1
        Loop

        '  Close the instrument object And release it for use
        '  by other programs.
        '
        Disconnect_From_Instrument(my_instrument)

        ' Capture the program stop time from the system.
        myStpWtch.Stop()

        ' Get the elapsed time as a TimeSpan value.
        Dim ts As TimeSpan = myStpWtch.Elapsed

        ' Format And display the TimeSpan value.
        Dim elapsedTime As String = $"{ts.Days:00}:{ts.Hours:00}:{ts.Minutes:00}:{ts.Seconds:00}.{ts.Milliseconds _
            / 10:000}"
        Console.WriteLine("RunTime " + elapsedTime)

        ' Implement a keypress capture so that the user can see the output of their program.
        Console.WriteLine("Press any key to continue...")
        Dim k As Char = Console.ReadKey().KeyChar
    End Sub

    Sub Connect_To_Instrument(ByRef resource_manager As ResourceManager, ByRef instrument_control_object As FormattedIO488, instrument_id_string As String, timeout As Int16)
        '
        '  Purpose: Open an instance Of an instrument Object For remote communication And establish the communication attributes.
        '  
        '  Parameters:
        '      resource_manager - The reference to the resource manager object created external to this function. It Is passed in 
        '                         by reference so that any internal attributes that are updated when using to connect to the 
        '                         instrument are updated to the caller. 
        '                         
        '      instrument_control_object - The reference to the instrument object created external to this function. It Is passed
        '                                  in by reference so that it retains all values upon exiting this function, making it
        '                                  consumable to all other calling functions. 
        '                                  
        '      instrument_id_string - The instrument VISA resource string used to identify the equipment at the underlying driver 
        '                             level. This string can be obtained per making a call to Find_Resources() VISA function And 
        '                             extracted from the reported list.
        '                             
        '      timeout - This Is used to define the duration of wait time that will transpire with respect to VISA read/query calls 
        '                prior to an error being reported.
        '                
        '  Returns:
        '      None
        '      
        '  Revisions: 
        '      2019-06-14      JJB     Initial revision.
        '
        instrument_control_object.IO = resource_manager.Open(instrument_id_string, Ivi.Visa.Interop.AccessMode.NO_LOCK, 20000)
        ' Instrument ID String examples...
        '       LAN -> TCPIP0:134.63.71.209:inst0:INSTR
        '       USB -> USB0:0x05E6:0x2450:01419962:INSTR
        '       GPIB -> GPIB0:16:INSTR
        '       Serial -> ASRL4:INSTR
        instrument_control_object.IO.Clear()
        Dim myTO As Int16 = instrument_control_object.IO.Timeout
        instrument_control_object.IO.Timeout = timeout
        myTO = instrument_control_object.IO.Timeout
        instrument_control_object.IO.TerminationCharacterEnabled = True
        instrument_control_object.IO.TerminationCharacter = Convert.ToByte(10)
        Return
    End Sub

    Sub Disconnect_From_Instrument(ByRef instrument_control_object As FormattedIO488)
        '
        '  Purpose: Closes an instance Of And instrument Object previously opened For remote communication.
        ' 
        '  Parameters:
        '      instrument_control_object - The reference to the instrument object created external to this function. It Is passed
        '                                  in by reference so that it retains all values upon exiting this function, making it
        '                                  consumable to all other calling functions. 
        '                
        '  Returns:
        '      None
        '      
        '  Revisions: 
        '      2019-06-14      JJB     Initial revision.
        '
        instrument_control_object.IO.Close()
        Return
    End Sub

    Sub Instrument_Write(instrument_control_object As FormattedIO488, command As String)
        '
        '  Purpose: Used to send commands to the instrument.
        '  
        '  Parameters:
        '      instrument_control_object - The reference to the instrument object created external to this function. It Is passed
        '                                  in by reference so that it retains all values upon exiting this function, making it
        '                                  consumable to all other calling functions. 
        '                                  
        '      command - The command string issued to the instrument in order to perform an action.
        '      
        '  Returns
        '      None
        '      
        '  Revisions 
        '      2019-06-04      JJB     Initial revision.
        '
        If (echo_command = True) Then
            Console.WriteLine("{0}", command)
        End If
        instrument_control_object.WriteString(command)
        Return
    End Sub

    Function Instrument_Read(instrument_control_object As FormattedIO488) As String
        '
        '  Purpose: Used to read commands from the instrument.
        '  
        '  Parameters:
        '      instrument_control_object - The reference to the instrument object created external to this function. It Is passed
        '                                  in by reference so that it retains all values upon exiting this function, making it
        '                                  consumable to all other calling functions. 
        '      
        '  Returns:
        '      The string obtained from the instrument.
        '      
        '  Revisions: 
        '      2019-06-04      JJB     Initial revision.
        '
        Return instrument_control_object.ReadString()
    End Function

    Function Instrument_Query(instrument_control_object As FormattedIO488, command As String) As String
        '
        '  Purpose: Used to send commands to the instrument  And obtain an information string from the instrument.
        '           Note that the information received will depend on the command sent And will be in string
        '           format.
        '  
        '  Parameters:
        '      instrument_control_object - The reference to the instrument object created external to this function. It Is passed
        '                                  in by reference so that it retains all values upon exiting this function, making it
        '                                  consumable to all other calling functions. 
        '                                  
        '      command - The command string issued to the instrument in order to perform an action.
        '      
        '  Returns:
        '      The string obtained from the instrument.
        '      
        '  Revisions: 
        '      2019-06-04      JJB     Initial revision.
        '
        Instrument_Write(instrument_control_object, command)
        Return Instrument_Read(instrument_control_object)
    End Function

End Module
