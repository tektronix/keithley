'================================================================================
'
'       Copyright 2019 Tektronix, Inc.
'       See www.tek.com/sample-license for licensing terms. 
'
'================================================================================

'================================================================================
'
'       This program is a brief example of how a user can send a TSP/Lua script
'       file to a Keithley TSP-enabled instrument.
'
'================================================================================

Imports Ivi.Visa.Interop

Module KEI_Touchscreen_Instrument_Send_Script_VB

    Dim echo_cmd As Boolean = True

    Sub Main()
        Dim resrc_mgr As ResourceManager = New ResourceManager()
        Dim resources As String() = resrc_mgr.FindRsrc("?*")
        Dim rcv_buffer As String = ""

        For Each n In resources
            Console.WriteLine("{0}", n)
        Next

        Dim my_resource_name As String = "TCPIP0::134.63.74.20::inst0::INSTR"
        Dim my_instr As FormattedIO488 = New Ivi.Visa.Interop.FormattedIO488()
        my_instr.IO = resrc_mgr.Open(my_resource_name, AccessMode.NO_LOCK, 2000)
        ' Instrument ID String examples...
        '       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
        '       USB -> USB0::0x05E6::0x2450::01419962::INSTR
        '       GPIB -> GPIB0::16::INSTR
        '       Serial -> ASRL4::INSTR
        my_instr.IO.Clear()
        Dim myTO As Int16 = my_instr.IO.Timeout
        my_instr.IO.Timeout = 20000
        myTO = my_instr.IO.Timeout
        my_instr.IO.TerminationCharacterEnabled = True
        my_instr.IO.TerminationCharacter = &HA

        Dim my_stopwatch As Stopwatch = New Stopwatch()
        my_stopwatch.Start()

        instrument_write(my_instr, "if loadfuncs ~= nil then script.delete('loadfuncs') end")

        instrument_write(my_instr, "loadscript loadfuncs")
        Dim line As String = ""
        Dim file As System.IO.StreamReader = New System.IO.StreamReader("..\..\Functions.lua")

        Do
            line = file.ReadLine()
            instrument_write(my_instr, line)
        Loop Until line Is vbNullString

        'While ((line = file.ReadLine()) <> vbNull)
        'instrument_write(my_instr, line)
        'End While

        file.Close()
        instrument_write(my_instr, "endscript")
        Console.WriteLine(instrument_query(my_instr, "loadfuncs()"))

        instrument_write(my_instr, "do_beep(0.250, 1000)")
        Threading.Thread.Sleep(0.5)
        instrument_write(my_instr, "do_beep(0.250, 1000)")
        Threading.Thread.Sleep(0.5)
        instrument_write(my_instr, "do_beep(0.250, 1000)")

        my_stopwatch.Stop()
        Dim ts As TimeSpan = my_stopwatch.Elapsed

        ' Format and display the elapsed test time
        Dim elapsed_time As String = String.Format("{0:00}:{1:00}:{2:00}:{3:00}.{4:000}", ts.Days, ts.Hours, ts.Minutes, ts.Seconds, ts.Milliseconds)
        Console.WriteLine("Run Time: " + elapsed_time)

        Console.WriteLine("Press any key to continue...")
        Dim k As Char = Console.ReadKey().KeyChar
        my_instr.IO.Close()
    End Sub

    Public Sub instrument_write(instr As FormattedIO488, command As String)
        If (echo_cmd = True) Then
            Console.WriteLine("{0}", command)
        End If

        instr.WriteString(command + vbLf)
    End Sub

    Public Function instrument_query(ByVal instr As FormattedIO488, ByVal command As String) As String
        instrument_write(instr, command)
        Return instr.ReadString()
    End Function

End Module
