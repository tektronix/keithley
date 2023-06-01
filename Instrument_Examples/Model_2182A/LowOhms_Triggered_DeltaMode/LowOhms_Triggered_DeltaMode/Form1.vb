Public Class Form1

    ' example using 2450 in SCPI mode and 2182A for triggered delta mode
    '
    ' 2450 firmware was 1.3.0s
    ' 2182A firmware was C04.3

    '2450-TLINK cable that connects pin1 to pin1 and pin2 to pin2 on the DB9 of 2450 and TLINK of 2182A


    Private Sub cmdRun_Click(sender As Object, e As EventArgs) Handles cmdRun.Click
        ' simple commands to control 2182A and 2450 for triggered delta mode measurement
        ' 2450 is in SCPI mode

        Dim ioMgr As Ivi.Visa.Interop.ResourceManager
        Dim Instr2450 As Ivi.Visa.Interop.FormattedIO488
        Dim Instr2182A As Ivi.Visa.Interop.FormattedIO488

        Dim ResourceStr2182A As String = "GPIB0::" & txt2181A_addr.Text & "::INSTR"        '"GPIB0::07::INSTR"
        Dim ResourceStr2450 As String = "GPIB0::" & txt2450_addr.Text & "::INSTR"        '"GPIB0::18::INSTR"

        lstResults.Items.Clear()


        ioMgr = New Ivi.Visa.Interop.ResourceManager
        Instr2450 = New Ivi.Visa.Interop.FormattedIO488
        Instr2182A = New Ivi.Visa.Interop.FormattedIO488

        Try
            Instr2450.IO = ioMgr.Open(ResourceStr2450)
        Catch ex As Exception
            MsgBox("Could Not Connect to 2450!", vbOKOnly, "Error Opening Connection")
        End Try

        Try
            Instr2182A.IO = ioMgr.Open(ResourceStr2182A)
        Catch ex As Exception
            MsgBox("Could Not Connect to 2182A!", vbOKOnly, "Error Opening Connection")
        End Try


        'setup 2182A
        'Instr2182A.WriteString("")
        Instr2182A.WriteString("*CLS")
        Instr2182A.WriteString(":SYSTEM:PRESET")
        Instr2182A.WriteString(":STATUS:PRESET")  ' status registers to default state
        Instr2182A.WriteString(":TRACE:CLEAR")
        Instr2182A.WriteString(":SENSE:FUNC 'VOLT'")
        Instr2182A.WriteString(":SYST:FAZ OFF")  ' front autozero disable - increase delta speed
        Instr2182A.WriteString(":SYST:AZERO:STATE OFF")
        Instr2182A.WriteString(":SYST:LSYNC OFF")
        Instr2182A.WriteString(":SENSE:VOLT:CHAN1:DFIL:STATE OFF")
        Instr2182A.WriteString(":SENSE:VOLT:DC:NPLC " & txtNPLC.Text)
        Instr2182A.WriteString(":SENSE:VOLT:DC:RANG:AUTO ON")
        Instr2182A.WriteString(":TRIGGER:DELAY 0")
        Instr2182A.WriteString(":TRIGGER:SOURCE EXTERNAL") ' output triggers stop when this issued
        Instr2182A.WriteString(":TRIG:COUN 3")
        Instr2182A.WriteString(":SAMP:COUN 1")
        Instr2182A.WriteString(":TRACE:POINTS 3")
        Instr2182A.WriteString(":TRACE:FEED SENS")
        Instr2182A.WriteString(":TRACE:FEED:CONT NEXT")
        Instr2182A.WriteString(":STAT:MEAS:ENAB 512")
        Instr2182A.WriteString("*SRE 1")

        System.Threading.Thread.Sleep(1000) ' give 2182A some time to complete the setup

        ' ******************************************
        '
        '   setup 2450
        '
        ' *****************************************
        'Instr2450.WriteString("")
        Instr2450.WriteString("*RST")
        Instr2450.WriteString(":SYST:CLE")   'clear event log

        'source current with fixed range
        Instr2450.WriteString(":SOUR:CURR:READ:BACK ON")
        Instr2450.WriteString(":SOUR:FUNC CURR")
        Instr2450.WriteString(":SOUR:CURR:RANG:AUTO OFF")
        Instr2450.WriteString(":SOUR:CURR:RANG " & txtCurrent.Text)  ' will coerce to proper source range
        Instr2450.WriteString(":SOUR:CURR:VLIM " & txtVLimit.Text)  ' compliance limit

        'measure voltage with fixed range
        Instr2450.WriteString(":SENS:FUNC 'VOLT'")
        Instr2450.WriteString(":SENS:VOLT:RANG:AUTO OFF")
        Instr2450.WriteString(":SENS:VOLT:RANG " & txtVLimit.Text)
        Instr2450.WriteString(":SENS:VOLT:NPLC 0.01")  ' 0.01 to 10

        'build a 4 point config list of positive current, neg current, positive current, zero current
        Instr2450.WriteString(":SOUR:CONF:LIST:CREATE 'delta'")

        Instr2450.WriteString(":SOUR:CURR:LEV " & txtCurrent.Text)
        Instr2450.WriteString(":SOUR:CONF:LIST:STOR 'delta'")

        Instr2450.WriteString(":SOUR:CURR:LEV -" & txtCurrent.Text)
        Instr2450.WriteString(":SOUR:CONF:LIST:STOR 'delta'")

        Instr2450.WriteString(":SOUR:CURR:LEV " & txtCurrent.Text)
        Instr2450.WriteString(":SOUR:CONF:LIST:STOR 'delta'")

        ' last point in list is 0 amps
        Instr2450.WriteString(":SOUR:CURR:LEV 0.0")
        Instr2450.WriteString(":SOUR:CONF:LIST:STOR 'delta'")



        'digital IO config
        Instr2450.WriteString(":DIG:LINE1:MODE TRIG, IN")
        Instr2450.WriteString(":DIG:LINE2:MODE TRIG, OUT")
        Instr2450.WriteString(":TRIG:DIG2:OUT:STIM NOTIFY1")
        'Instr2450.WriteString(":TRIG:DIG2:OUT:PULSEWIDTH 1e-3")  ' for the scope


        Instr2450.WriteString(":TRIGger:BLOCk:BUFFer:CLEar 1")
        Instr2450.WriteString(":TRIGger:BLOCk:SOURce:STATe 2, ON")
        Instr2450.WriteString(":TRIGger:BLOCk:CONFig:RECall 3, 'delta', 1")

        Instr2450.WriteString(":TRIG:BLOC:DEL:CONS 4, 0.01")  ' constant delay
        Instr2450.WriteString(":TRIGger:BLOCk:MEASure 5")
        Instr2450.WriteString(":TRIG:BLOC:NOP 6")  ' no operation...just a place holder

        Instr2450.WriteString(":TRIG:BLOC:NOT 7, 1")   ' output trigger to 2182A...time to measure
        Instr2450.WriteString(":TRIG:BLOC:WAIT 8, DIG1, OR, DISP")   ' wait for meter complete from 2182A
        Instr2450.WriteString(":TRIG:BLOC:CONF:NEXT 9, 'delta'")
        Instr2450.WriteString(":TRIG:BLOC:DEL:CONS 10, 0.001")  ' 1msec delay
        Instr2450.WriteString(":TRIGger:BLOCk:MEASure 11")
        Instr2450.WriteString(":TRIG:BLOC:BRAN:COUNTER 12, 3, 7")  ' repeat 3 times, go to block number 7

        Instr2450.WriteString(":TRIGger:BLOCk:CONFig:RECall 13, 'delta', 4")   ' recall 0 Amps value from config list
        Instr2450.WriteString(":TRIG:BLOC:DEL:CONS 14, 0.05")  ' seeing glitch as output turns off...due to high Z state
        Instr2450.WriteString(":TRIGger:BLOCk:SOURce:STATe 15, OFF")
        Instr2450.WriteString(":TRIG:BLOC:BRAN:ALWAYS 16, 0")


        System.Threading.Thread.Sleep(1000)  ' delay....allow the 2450 time to process the commands and get ready
        ' if issue :INIT command too soon, we have a problem
        Application.DoEvents()


        'wait for SRQ on 2182A
        Dim loopCnt As Integer = 0
        Dim status As Short = 0
        status = Instr2182A.IO.ReadSTB()
        Debug.Print("initial status: " & status)
        'start the 2450
        Instr2450.WriteString(":INIT")


        ' polling loop for SRQ AND loopCnt too big
        ' loopCnt too big = expected SRQ did not happen within N loops and some problem maybe exists
        ' test for bit6 in STB set to logic 1 (SRQ has occurred)
        Do While ((status And 64) <> 64) And (loopCnt <= 500)
            status = Instr2182A.IO.ReadSTB()
            System.Threading.Thread.Sleep(200)
            Application.DoEvents()
            Debug.Print("status: " & status & " loopCnt: " & loopCnt)
            loopCnt = loopCnt + 1
        Loop

        'System.Threading.Thread.Sleep(1000)
        'Beep()


        'read 2182A data
        Dim data_2182A As String
        Instr2182A.WriteString(":TRACE:DATA?")
        data_2182A = Instr2182A.ReadString()
        Debug.Print(data_2182A)

        Dim data_2182A_single As String() = data_2182A.Split(",")
        Dim each_2182A(2) As Single  '3 element array of singles
        Dim i As Integer = 0
        For Each data_2182A In data_2182A_single
            Debug.Print(data_2182A)
            each_2182A(i) = CSng(data_2182A)
            i = i + 1
        Next

        'get the source read back (measured) current values from 2450
        Dim measured_current_all As String

        Instr2450.WriteString(":TRAC:DATA? 1,3, 'defbuffer1', SOUR")
        measured_current_all = Instr2450.ReadString()
        Debug.Print(measured_current_all)
        Dim measured_current_each As String() = measured_current_all.Split(",")
        Dim each_measured_current(2) As Single

        i = 0
        For Each measured_current In measured_current_each
            each_measured_current(i) = CSng(measured_current)
            i = i + 1
        Next

        Dim Res(2) As Single
        For i = 0 To 2
            Res(i) = each_2182A(i) / each_measured_current(i)
            lstResults.Items.Add(Res(i))
        Next


        ' close the session
        Instr2450.IO.Clear()
        Instr2450.IO.Close()

        Instr2182A.IO.Clear()
        Instr2182A.IO.Close()
    End Sub
End Class
