' ***********************************************************
' *** Copyright Tektronix, Inc.                           ***
' *** See www.tek.com/sample-license for licensing terms. ***
' ***********************************************************

Imports NationalInstruments.Visa
' Make sure to include the following assemblies...
'   NationalInstruments.Common
'   NationalInstruments.MStudio.CLM
'   NationalInstruments.Visa
'   Ivi.Visa

' ====================================================================================================
' EXAMPLE DESCRIPTION
' This example application demonstrates how to use the DAQ6510 to perform complex multi-channel,
' mixed function scanning in a production test environment.
'
' The DAQ6510 can perform more than one function In a multichannel scan, providing a range of
' data-acquisition options in a single test.
'
' In this production environment, the DAQ6510 is:
' • Integrated into a test stand.
' • Wired to a fixture that Is connected to an active device under test (DUT).
' • Quickly capturing DC volts And current; temperature; AC volts And current, and 2- and 4-wire resistance.
'
' Before the start Of the scan, you can Step through each of the configured channels on the DAQ6510,
' which allows you to troubleshoot the test configuration. This allows you to view the readings of
' individually closed channels to ensure that connections to the DUT are secure.
' ====================================================================================================

Module Mixed_Channel_Multifunction_Scan

    Dim echo_cmd As Boolean = False

    Sub Main()

        Dim rmSession As ResourceManager = New ResourceManager()
        Dim mbSession As MessageBasedSession

        instrument_connect(rmSession, mbSession, "TCPIP0::192.168.1.65::5025::SOCKET", 5000)
        '       LAN -> TCPIP0:134.63.71.209:inst0 : INSTR
        '       USB -> USB0:0x05E6:0x2450:01419962:INSTR
        '       GPIB -> GPIB0:16:INSTR
        '       Serial -> ASRL4:INSTR
        Dim my_stopwatch As Stopwatch = New Stopwatch()
        my_stopwatch.Start()

        mbSession.Clear()
        Console.WriteLine(instrument_query(mbSession, "*IDN?"))
        Dim feedback As String = instrument_query(mbSession, "*OPC?")

        instrument_write(mbSession, "*RST")
        instrument_write(mbSession, "SENS:FUNC 'VOLT:AC',(@116)")
        instrument_write(mbSession, "SENS:VOLT:AC:DET:BAND 30, (@116)")
        instrument_write(mbSession, "SENS:FUNC 'VOLT:DC', (@111:114)")
        instrument_write(mbSession, "SENS:FUNCtion 'TEMPerature', (@101,110,115,120)")
        instrument_write(mbSession, "SENS:TEMP:TRAN TC, (@101,110,115,120)")
        instrument_write(mbSession, "SENS:TEMP:TC:TYPE K, (@101,110,115,120)")
        instrument_write(mbSession, "SENS:TEMP:TC:RJUN:RSEL SIM, (@101,110,115,120)")
        instrument_write(mbSession, "SENS:TEMP:TC:RJUN:SIM 23, (@101,110,115,120)")
        instrument_write(mbSession, "SENS:FUNC 'CURR:AC', (@121)")
        instrument_write(mbSession, "SENS:FUNC 'CURR:DC', (@122)")
        instrument_write(mbSession, "SENS:FUNC 'RES', (@102:106)")
        instrument_write(mbSession, "SENS:FUNC 'FRES', (@107:109)")
        instrument_write(mbSession, "FRES:OCOM ON, (@107:109)")
        instrument_write(mbSession, "FRES:RANG 100, (@107)")
        instrument_write(mbSession, "FRES:RANG 10, (@108)")
        instrument_write(mbSession, "FRES:RANG 1, (@109)")

        ' establish the channels that will be included in the scan
        instrument_write(mbSession, "ROUT:SCAN:CRE (@101:116,120)")
        ' apply the interval between each scan start or init
        instrument_write(mbSession, "ROUTe:SCAN:INTerval 10.0")

        ' get the step count, or number of channels that will acquire measurements in a single scan 
        Dim step_count As Int32 = Convert.ToInt32(instrument_query(mbSession, "ROUTe:SCAN:COUNt:STEP?"))
        Dim scan_count As Int32 = 10

        instrument_write(mbSession, String.Format("ROUT:SCAN:COUN:SCAN {0}", scan_count))

        'Dim accumulated_readings As Int32 = 0
        Dim target_reading_count As Int32 = step_count * scan_count
        Dim start_index As Int32 = 1
        Dim end_index As Int32 = step_count
        Dim temp_count As Int32 = 0

        instrument_write(mbSession, "INIT")

        ' loop until done
        While (end_index <= target_reading_count)
            temp_count = Convert.ToInt32(instrument_query(mbSession, "TRACe:ACTual?"))
            If (temp_count >= end_index) Then
                ' get readings from the buffer,,,
                feedback = instrument_query(mbSession, String.Format("TRACe:DATA? {0}, {1}, ""defbuffer1"", READ", start_index, end_index))
                Console.WriteLine("{0}", feedback)
                start_index += step_count
                end_index += step_count

            End If
        End While

        instrument_write(mbSession, "*RST")

        my_stopwatch.Stop()
        Dim ts As TimeSpan = my_stopwatch.Elapsed

        ' Format and display the elapsed test time
        Dim elapsed_time As String = String.Format("{0:00}:{1:00}:{2:00}:{3:00}.{4:000}", ts.Days, ts.Hours, ts.Minutes, ts.Seconds, ts.Milliseconds)
        Console.WriteLine("Run Time: " + elapsed_time)

        Console.WriteLine("Press any key to continue...")
        Dim k As Char = Console.ReadKey().KeyChar

        mbSession.Dispose()
        rmSession.Dispose()
    End Sub

    Public Sub instrument_connect(ByRef resource_manager As ResourceManager, ByRef instrument_control_object As MessageBasedSession, instrument_id_string As String, timeout As Int16)

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
        '      2019-06-04      JJB     Initial revision.
        '

        instrument_control_object = resource_manager.Open(instrument_id_string, Ivi.Visa.AccessModes.None, 2000) ' (MessageBasedSession)
        ' Instrument ID String examples...
        '       LAN -> TCPIP0:134.63.71.209:inst0 : INSTR
        '       USB -> USB0:0x05E6:0x2450:01419962:INSTR
        '       GPIB -> GPIB0:16:INSTR
        '       Serial -> ASRL4:INSTR
        instrument_control_object.Clear()
        instrument_control_object.TimeoutMilliseconds = timeout

        If (instrument_id_string.Contains("ASRL")) Then
            Dim srlSession As SerialSession = instrument_control_object
            With srlSession
                .BaudRate = 9600
                .FlowControl = Ivi.Visa.SerialFlowControlModes.None
                .Parity = Ivi.Visa.SerialParity.None
                .StopBits = Ivi.Visa.SerialStopBitsMode.One
                .ReadTermination = Ivi.Visa.SerialTerminationMethod.TerminationCharacter
                .TerminationCharacter = &HA
                .TerminationCharacterEnabled = True
            End With
        ElseIf (instrument_id_string.Contains("SOCKET")) Then
            instrument_control_object.TerminationCharacterEnabled = True
            instrument_control_object.TerminationCharacter = &HA
        End If

    End Sub

    Public Sub instrument_disconnect(ByRef instrument_control_object As MessageBasedSession)
        '
        '   Purpose: Closes an instance Of And instrument Object previously opened For remote communication.
        '   
        '   Parameters:
        '       instrument_control_object - The reference to the instrument object created external to this function. It Is passed
        '                                    in by reference so that it retains all values upon exiting this function, making it
        '                                     consumable to all other calling functions. 
        '                   
        '   Returns:
        '       None
        '          
        '   Revisions: 
        '       2019-06-04      JJB     Initial revision.
        '    
        instrument_control_object.Dispose()
    End Sub

    Public Sub instrument_write(instr As MessageBasedSession, command As String)
        If (echo_cmd = True) Then
            Console.WriteLine("{0}", command)
        End If
        instr.RawIO.Write(command + vbLf)
    End Sub

    Public Function instrument_query(ByVal instr As MessageBasedSession, ByVal command As String) As String
        instrument_write(instr, command)
        Return instr.RawIO.ReadString()
    End Function
End Module
