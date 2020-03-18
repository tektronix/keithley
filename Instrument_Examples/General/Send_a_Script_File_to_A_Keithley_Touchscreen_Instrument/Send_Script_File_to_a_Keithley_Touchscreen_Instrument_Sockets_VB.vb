Imports System.IO
Imports System.Net.Sockets      
Imports System.Text

Module Module1

    Public echoCommands As Boolean = True

    Public client1 As Net.Sockets.TcpClient
    Public stream1 As Net.Sockets.NetworkStream

    Sub Main()
        Dim ipAddress As String = "192.168.1.147"
        Dim portNum As Int32 = 5025
        Dim myClient As TcpClient
        Dim netStream As NetworkStream
        Dim rcvBuffer As String = ""
        Dim myStpWtch As Stopwatch = New Stopwatch()

        myStpWtch.Start()

        instrument_connect(myClient, netStream, ipAddress, portNum, True, False, rcvBuffer)

        ' Reset the instrument to the default settings.
        instrument_write(netStream, "reset()")

        ' Ready the instrument to receive the target file contents
        instrument_write(netStream, "if loadfuncs ~= nil then script.delete('loadfuncs') end")
        instrument_write(netStream, "loadscript loadfuncs")

        ' Load the script file line by line
        Dim line As String = ""
        Dim file As System.IO.StreamReader = New System.IO.StreamReader("..\..\functions2.tsp")
        Do
            line = file.ReadLine()
            instrument_write(netStream, line)
        Loop Until line Is vbNullString
        file.Close()

        ' Close out the loadfuncs wrapper script then call it as a function to load the 
        ' contents of the script file into active memory. 
        instrument_write(netStream, "endscript")
        Dim tmpStr As String = ""
        instrument_query(netStream, "loadfuncs()", 32, tmpStr)
        Console.WriteLine(tmpStr)       ' Note that we are echoing a queried function here. 
        ' You will note that the final line in the functions.tsp
        ' script file is a print() command that will push its contents
        ' to the output data queue. 

        instrument_write(netStream, "do_beep(0.250, 1000, 3)")

        instrument_disconnect(myClient, netStream)

        myStpWtch.Stop()

        ' Get the elapsed time as a TimeSpan value.
        Dim ts As TimeSpan = myStpWtch.Elapsed

        ' Format And display the TimeSpan value.
        Dim elapsedTime As String = String.Format("{0:00}:{1:00}:{2:00}:{3:00}.{4:000}", ts.Days, ts.Hours, ts.Minutes, ts.Seconds, ts.Milliseconds / 10)
        Console.WriteLine("RunTime " + elapsedTime)

        Console.WriteLine("Press any key to continue...")
        Dim k As Char = Console.ReadKey().KeyChar
    End Sub

    Public Function instrument_connect(ByRef myClient As TcpClient, ByRef netStream As NetworkStream, ByVal ipAddress As String, ByVal portNum As Int16, ByVal echoIdString As Boolean, ByVal doReset As Boolean, ByRef strId As String) As Integer
        Dim status As Int16 = 0
        Try
            myClient = New TcpClient(ipAddress, portNum)
            myClient.NoDelay = True
            netStream = myClient.GetStream()
            Console.WriteLine("Connected to instrument......")
            myClient.ReceiveTimeout = 20000
            myClient.ReceiveBufferSize = 35565
            'netStream = myClient.GetStream()
            If (echoIdString) Then
                instrument_query(netStream, "*IDN?", 128, strId)
                Console.WriteLine("{0}", strId)
            End If

            If (doReset) Then
                instrument_write(netStream, "reset()")
            End If

        Catch ex As Exception
            status = -1
            Console.WriteLine(ex.Message)

        Finally
            ' Nothing to close
        End Try

        Return status
    End Function

    Public Sub instrument_disconnect(ByRef myClient As TcpClient, ByRef netStream As NetworkStream)
        netStream.Close()
        myClient.Close()
    End Sub

    Public Function instrument_write(ByVal netstream As NetworkStream, ByVal cmdStr As String) As Int16
        Dim byteBuffer As Byte()
        If (echoCommands = True) Then
            Console.WriteLine("{0}", cmdStr)
        End If
        byteBuffer = Encoding.[Default].GetBytes(cmdStr + vbLf + vbLf)
        netstream.Write(byteBuffer, 0, byteBuffer.Length)
        Array.Clear(byteBuffer, 0, byteBuffer.Length)
        Return 0
    End Function

    Public Function instrument_read(ByVal netStream As NetworkStream, ByVal byteCount As Int16, ByRef rcvStr As String) As Int16
        Dim rcvBytes(byteCount) As Byte
        Dim bytesRcvd As Int16 = netStream.Read(rcvBytes, 0, byteCount)
        rcvStr = Encoding.[Default].GetString(rcvBytes, 0, bytesRcvd)
        Array.Clear(rcvBytes, 0, byteCount)
        Return 0
    End Function

    Public Function instrument_read_float_data(ByVal netStream As NetworkStream, ByVal chunkSize As Int16, ByRef fltData() As Single)
        Dim rcvBytes(chunkSize * 4 + 3) As Byte
        Dim bytesRcvd = netStream.Read(rcvBytes, 0, rcvBytes.Length)
        ' Need to convert to the byte array into single or do
        Buffer.BlockCopy(rcvBytes, 2, fltData, 0, fltData.Length * 4)
        Array.Clear(rcvBytes, 0, rcvBytes.Length)
        Return 0
    End Function

    Public Sub instrument_query(ByVal netStream As NetworkStream, ByVal cmdStr As String, ByVal byteCount As Int16, ByRef rcvStr As String)
        Dim status As Int16 = 0

        status = instrument_write(netStream, cmdStr)
        status = instrument_read(netStream, byteCount, rcvStr)

    End Sub

    Public Sub instrument_query_float_data(ByVal netStream As NetworkStream, ByVal cmdStr As String, ByVal byteCount As Int16, ByRef fltData() As Single)
        Dim status As Int16 = 0

        status = instrument_write(netStream, cmdStr)
        status = instrument_read_float_data(netStream, byteCount, fltData)

    End Sub

End Module
