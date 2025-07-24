Option Explicit On

Imports Ivi.Visa
Imports NationalInstruments.Visa
Imports System.Text

Public Class Form1

    'Go to Project > Add Reference > Browse
    'Locate And add NationalInstruments.Visa.dll
    '(usually found in C:\Program Files\IVI Foundation\VISA\Visa.NET Shared Components)
    '
    'Also include Ivi.Visa.Interop.dll and Ivi.Visa.dll

    'Microsoft Visual Studio Community 2022 (64-bit) - Current Version 17.11.4
    'NI VISA 2025
    'Win11
    'Any 2600A or 2600B model but used 2636B, firmware 4.0.5
    '



    Private rm As ResourceManager
    Private mbSession As MessageBasedSession
    Dim response As String

    Dim Resource As String = "TCPIP0::192.168.0.52::INSTR"

    Dim eventOccured As Boolean = False
    Dim statusByte As Short

    Dim commandList As New List(Of String) From {"reset()",
                                                 "errorqueue.clear()",
                                                 "status.reset()",
                                                 "status.operation.enable = status.operation.SWEEPING",
                                                 "status.operation.sweeping.enable = status.operation.sweeping.SMUA",
                                                 "status.operation.sweeping.ptr = 0",
                                                 "status.operation.sweeping.ntr = status.operation.sweeping.SMUA",
                                                 "status.node_enable = status.OSB",
                                                 "status.request_enable = status.OSB",
                                                 "smua.nvbuffer1.clear()",
                                                 "smua.nvbuffer1.appendmode = 1",
                                                 "smua.nvbuffer1.collectsourcevalues = 1",
                                                 "smua.nvbuffer2.clear()",
                                                 "smua.nvbuffer2.appendmode = 1",
                                                 "smua.nvbuffer2.collectsourcevalues = 1",
                                                 "smua.measure.delay = 0.1",    'slow down the sweep
                                                 "smua.trigger.source.action = smua.ENABLE",
                                                 "smua.trigger.source.linearv(-1.0, 1.0, 21)",
                                                 "smua.trigger.count = 21",   ' make tthis same and number of source values
                                                 "smua.trigger.measure.action = smua.ENABLE",
                                                 "smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)",
                                                 "smua.source.output = 1",
                                                 "smua.trigger.initiate()"}


    Private Sub Button1_Click(sender As Object, e As EventArgs) Handles Button1.Click

        rm = New ResourceManager()

        mbSession = rm.Open(Resource)
        mbSession.TerminationCharacter = &H10 ' line feed in hex for Byte data type
        mbSession.TerminationCharacterEnabled = True  ' add LF terminator to each write

        mbSession.RawIO.Write("*idn?")
        TextBox1.Text = mbSession.RawIO.ReadString()


        For Each cmd As String In commandList
            mbSession.RawIO.Write(cmd)
        Next

        ' poll until the SRQ is asserted at Sweep completion
        statusByte = mbSession.ReadStatusByte()
        Debug.Print(statusByte)
        Do While ((statusByte And 64) <> 64)   ' 64 = 2^6 = MSS bit in status.conditon register = 1
            statusByte = mbSession.ReadStatusByte()
            Application.DoEvents()
            Debug.Print(statusByte)
            Threading.Thread.Sleep(100)
        Loop


        mbSession.RawIO.Write("smua.source.output = 0")
        mbSession.RawIO.Write("status.reset()")

        mbSession.RawIO.Write("beeper.beep(0.5, 1200)")  ' duration and freq of beep
        Threading.Thread.Sleep(500)


        mbSession.RawIO.Write("printbuffer(1, smua.nvbuffer1.n, smua.nvbuffer1.readings, smua.nvbuffer1.sourcevalues)")
        Dim rawData As String = mbSession.RawIO.ReadString()
        Debug.Print(rawData)

        mbSession.Clear()

        mbSession.Dispose()
        rm.Dispose()

        TextBox1.Text = "All Done"


    End Sub
End Class
