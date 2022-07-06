Imports System.IO
Imports System.Net.Sockets
Imports System.Text
Imports System.Threading.Tasks
Imports System.Diagnostics       ' needed for stopwatch usage

Module Module1
    Dim echo_command As Boolean = False

    Sub Main()
        Dim myStpWtch As Stopwatch = New Stopwatch()
        myStpWtch.Start()

        Dim TcpClient As TcpClient = New TcpClient()
        ' Uses the GetStream public method to return the NetworkStream.
        'Dim netStream As NetworkStream = Nothing
        Dim netStream As Stream = Nothing

        Instrument_Connect(TcpClient, netStream, "192.168.1.65", 5025, 10000)

        'Instrument_Write(netStream, "SYST:BEEP 1000,2")              ' This command isn't in the 2701 manual; where is the customer getting his from?
        Dim response As String = Instrument_Query(TcpClient, netStream, "*IDN?")
        Console.WriteLine(response)

        Instrument_Write(netStream, "*RST")
        Instrument_Write(netStream, "SENS:FUNC ""TEMP"", (@101,110,115,120)")
        Instrument_Write(netStream, "SENS:TEMP:TRAN TC, (@101,110,115,120)")
        Instrument_Write(netStream, "SENS:TEMP:TC:TYPE K, (@101,110,115,120)")
        Instrument_Write(netStream, "SENS:TEMP:TC:RJUN:RSEL INT, (@101,110,115,120)")
        Instrument_Write(netStream, "SENS:TEMP:NPLC 1.0, (@101,110,115,120)")
        Instrument_Write(netStream, "SENS:TEMP:AZER:STAT OFF, (@101,110,115,120)")
        Instrument_Write(netStream, "SENS:TEMP:LINE:SYNC OFF, (@101,110,115,120)")
        Instrument_Write(netStream, "SENS:TEMP:DEL:AUTO OFF, (@101,110,115,120)")


        Instrument_Write(netStream, "SENS:TEMP:ODET ON, (@101,110,115,120)")
        Instrument_Write(netStream, "ROUT:SCAN:CRE (@101,110,115,120)")
        Dim scan_count As Int32 = 100
        Instrument_Write(netStream, String.Format("ROUT:SCAN:COUN:SCAN {0}", scan_count))
        Instrument_Write(netStream, "ROUT:SCAN:INTerval 0")
        Instrument_Write(netStream, "FORM:DATA SRE")

        Dim channels_per_scan As Int32 = Instrument_Query(TcpClient, netStream, "ROUT:SCAN:COUN:STEP?")

        Instrument_Write(netStream, "INIT")

        Dim scan_array(channels_per_scan) As Single
        Dim start_index = 1
        Dim end_index = channels_per_scan
        Dim expected_count = channels_per_scan * scan_count
        Dim temp_count = 0
        While end_index <= expected_count
            temp_count = Convert.ToInt32(Instrument_Query(TcpClient, netStream, "TRACe:ACTual?"))
            While temp_count < end_index
                temp_count = Convert.ToInt32(Instrument_Query(TcpClient, netStream, "TRACe:ACTual?"))
            End While
            Instrument_Query_Binary(TcpClient, netStream, String.Format("TRACe:DATA? {0}, {1}, ""defbuffer1"", READ", start_index, end_index), 4, scan_array)
            Console.WriteLine("{0}, {1}, {2}, {3}", scan_array(0), scan_array(1), scan_array(2), scan_array(3))
            start_index += channels_per_scan
            end_index += channels_per_scan
        End While

        Instrument_Disconnect(TcpClient, netStream)

        ' Capture the program stop time from the system.
        myStpWtch.Stop()

        ' Get the elapsed time as a TimeSpan value.
        Dim ts As TimeSpan = myStpWtch.Elapsed

        ' Format And display the TimeSpan value.
        Dim elapsedTime As String = String.Format("{0:00}:{1:00}:{2:00}:{3:00}.{4:000}",
        ts.Days, ts.Hours, ts.Minutes, ts.Seconds,
        ts.Milliseconds / 10)
        Console.WriteLine("RunTime: " + elapsedTime)

        ' Implement a keypress capture so that the user can see the output of their program.
        Console.WriteLine("Press any key to continue...")
        Dim k As Char = Console.ReadKey().KeyChar
    End Sub

    Public Sub Instrument_Connect(ByRef my_client As TcpClient, ByRef my_netstrem As Stream, ByVal ip_address As String, ByVal port_number As Int16, ByVal timeout As Int16)
        '
        '  Purpose: Open an instance of an TCP client and stream Objects for remote communication and establish the communication attributes.
        '  
        '  Parameters:
        '      my_client - The reference to the TCPClient object created external to this function. It Is passed in 
        '                  by reference so that any internal attributes that are updated when using to connect to the 
        '                  instrument are updated to the caller. 
        '
        '      my_netstream - The reference to the Stream object created external to this function. It Is passed in 
        '                     by reference so that any internal attributes that are updated when using to connect to the 
        '                     instrument are updated to the caller.
        '                         
        '      ip_address - The string that defines the IP address assigned to the target instrument. 
        '                                  
        '      port_number - An integer value that defines the port to be used for the socket connection.
        '                             
        '      timeout - This Is used to define the duration of wait time that will transpire with respect to read/query calls 
        '                prior to an error being reported.
        '                
        '  Returns:
        '      None
        '      
        '  Revisions: 
        '      2020-09-11      JJB     Initial revision.
        '
        Try
            my_client.Connect(ip_address, port_number)
            my_netstrem = my_client.GetStream()
            my_client.NoDelay = True
            my_client.ReceiveBufferSize = 1024
            my_client.ReceiveTimeout = timeout
        Catch ex As Exception
            ' do something here....
        End Try
    End Sub

    Public Sub Instrument_Disconnect(ByRef my_client As TcpClient, ByRef my_netstream As Stream)
        '
        '  Purpose: Closes an instance Of And instrument Object previously opened For remote communication.
        ' 
        '  Parameters:
        '      my_client - The reference to the TCP client object created external to this function. It Is passed
        '                  in by reference so that it retains all values upon exiting this function, making it
        '                  consumable to all other calling functions. 
        '
        '      my_netstream - The reference to the Stream object created external to this function. It Is passed in 
        '                     by reference so that any internal attributes that are updated when using to connect to the 
        '                     instrument are updated to the caller.
        '                         
        '  Returns:
        '      None
        '      
        '  Revisions: 
        '      2020-09-11      JJB     Initial revision.
        '
        my_client.Close()

        ' Closing the tcpClient instance does Not close the network stream.
        my_netstream.Close()
    End Sub


    Public Sub Instrument_Write(ByVal netStream As NetworkStream, ByVal command As String)
        '
        '  Purpose: Used to send commands to the instrument.
        '  
        '  Parameters:
        '      my_netstream - A copy of the Stream object created external to this function. 
        '                                  
        '      command - The command string issued to the instrument in order to perform an action.
        '      
        '  Returns
        '      None
        '      
        '  Revisions 
        '      2020-09-11      JJB     Initial revision.
        '
        Dim attempt_counter As Int16 = 0

        While (netStream.CanWrite <> True)
            ' apply delay....
            System.Threading.Thread.Sleep(100)
            attempt_counter += 1
            If (attempt_counter > 10) Then
                Exit While
            End If
        End While

        If (netStream.CanWrite) Then
            If (echo_command = True) Then
                Console.WriteLine(command)
            End If
            Dim sendBytes() As Byte = Encoding.Default.GetBytes(command + vbLf)
            netStream.Write(sendBytes, 0, sendBytes.Length)
        End If
    End Sub

    Public Function Instrument_Read(ByVal my_client As TcpClient, ByVal my_netstream As NetworkStream) As String
        '
        '  Purpose: Used to read commands from the instrument.
        '  
        '  Parameters:
        '      my_client - A copy of the TCP Client object created external to this function. 
        '
        '      my_netstream - A copy of the Stream object created external to this function. 
        '      
        '  Returns:
        '      The string obtained from the instrument.
        '      
        '  Revisions: 
        '      2020-09-11      JJB     Initial revision.
        '
        ' Reads NetworkStream into a byte buffer.
        Dim bytes() As Byte = New Byte(my_client.ReceiveBufferSize) {}

        ' Read can return anything from 0 to numBytesToRead.
        ' This method blocks until at least one byte Is read.
        Dim status As Int64 = my_netstream.Read(bytes, 0, my_client.ReceiveBufferSize)

        ' Returns the data received from the host to the console.
        Dim charsToTrim() As Char = {vbNullChar, vbLf}
        'Dim returndata As String = Encoding.Default.GetString(bytes).Trim(charsToTrim)

        Return Encoding.Default.GetString(bytes).Trim(charsToTrim)
    End Function

    Public Sub Instrument_Read_Binary(ByVal my_client As TcpClient, ByVal my_netstream As NetworkStream, ByVal readings_count As Int32, ByRef single_array() As Single)
        '
        '  Purpose: Used to read commands from the instrument.
        '  
        '  Parameters:
        '      my_client - A copy of the TCP Client object created external to this function. 
        '
        '      my_netstream - A copy of the Stream object created external to this function. 
        '
        '      readings_count - The number of readings/values from the buffer to extract.
        '
        '      single_array() - The array that will hold the floating point values that are extracted. 
        '      
        '  Returns:
        '      The string obtained from the instrument.
        '      
        '  Revisions: 
        '      2020-09-11      JJB     Initial revision.
        '
        Dim receive_bytes(readings_count * 4 + 3) As Byte

        Dim bytes_received As Int32 = my_netstream.Read(receive_bytes, 0, receive_bytes.Length)

        ' Convert the bytes array into single
        Buffer.BlockCopy(receive_bytes, 2, single_array, 0, (single_array.Length - 1) * 4)  ' VB pads an array with an extra index, so remove this first then multiply

        Array.Clear(receive_bytes, 0, receive_bytes.Length)
    End Sub


    Public Function Instrument_Query(ByVal my_client As TcpClient, ByVal my_netstream As NetworkStream, ByVal command As String) As String
        '
        '  Purpose: Used to send commands to the instrument and obtain an information string from the instrument.
        '           Note that the information received will depend on the command sent And will be in string
        '           format.
        '  
        '  Parameters:
        '      my_client - A copy of the TCP Client object created external to this function. 
        '
        '      my_netstream - A copy of the Stream object created external to this function. 
        '                                  
        '      command - The command string issued to the instrument in order to perform an action.
        '      
        '  Returns:
        '      The string obtained from the instrument.
        '      
        '  Revisions: 
        '      2020-09-11      JJB     Initial revision.
        '
        Instrument_Write(my_netstream, command)
        Return Instrument_Read(my_client, my_netstream)
    End Function

    Public Function Instrument_Query_Binary(ByRef my_client As TcpClient, ByVal my_netstream As NetworkStream, ByVal command As String, ByVal readings_count As Int32, ByRef single_array As Single()) As Single
        '
        '  Purpose: Used to send commands to the instrument and obtain an information string from the instrument.
        '           Note that the information received will depend on the command sent And will be in string
        '           format.
        '  
        '  Parameters:
        '      my_client - A copy of the TCP Client object created external to this function. 
        '
        '      my_netstream - A copy of the Stream object created external to this function. 
        '                                  
        '      command - The command string issued to the instrument in order to perform an action.
        '       
        '      readings_count - The number of readings/values from the buffer to extract.
        '
        '      single_array() - The array that will hold the floating point values that are extracted.
        '      
        '  Returns:
        '      The string obtained from the instrument.
        '      
        '  Revisions: 
        '      2020-10-20      JJB     Initial revision.
        Instrument_Write(my_netstream, command)
        Instrument_Read_Binary(my_client, my_netstream, readings_count, single_array)
    End Function

End Module
