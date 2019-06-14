'================================================================================
'
'       Copyright 2019 Tektronix, Inc.
'       See www.tek.com/sample-license for licensing terms. 
'
'================================================================================

'================================================================================
'
'       This program is a brief example of how a DAQ6510 user might add
'       a frequency measurement to their programmed scan. Only one channel
'       is defined and we provide two different means for triggering, monitoring
'       and extracting the scan measurement data. 
'
'       This example will work any of the following multiplexer card
'       models: 7700, 7701, 7702, 7703, 7706, 7707, 7708, 7710
'
'================================================================================

Imports KeithleyInstruments.KeithleyDMM6500.Interop

Module Module1

    Sub Main()
        Dim my_stopwatch As Stopwatch = New Stopwatch()
        my_stopwatch.Start()

        Dim resourceName As String = "USB0::0x05E6::0x6510::04340543::INSTR"
        ' Instrument ID String examples...
        '       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
        '       USB -> USB0::0x05E6::0x2450::01419962::INSTR
        '       GPIB -> GPIB0::16::INSTR
        '       Serial -> ASRL4::INSTR
        Dim daq6510 As IKeithleyDMM6500 = New KeithleyDMM6500
        'Initialize and Reset the instrument to the default settings
        daq6510.Initialize(resourceName, True, True, "")

        'Set up channel settings for Slot 1
        daq6510.ChannelFunction("201:204") = KeithleyDMM6500FunctionEnum.KeithleyDMM6500FunctionFrequency

        ' Define a supplemental scan object And configure to iterate 10 times with a 1s interval between
        ' each scan. 
        Dim my_scan As IKeithleyDMM6500RouteScan = daq6510.Route.Scan
        my_scan.Create("201:204")
        my_scan.Interval = 3.0
        my_scan.Count = 1

        ' Start the scanning And the hold until complete. Typical trigger model transitions during
        ' the scan are either "WAITING" Or "RUNNING", so we will key off of those returns. Also 
        ' note that the Trigger Model State value Is updated (at the instrument level) only once
        ' every 100ms, so you could save your computer the comms traffic by delaying by at least
        ' that much; perhaps, in this case, as much as 1s since that Is what the scan interval Is
        ' assigned to. 

        ' First scan for setup...
        daq6510.Trigger.Initiate()
        Dim trigState As String = ""

        Do
            System.Threading.Thread.Sleep(500)  'delay defined In milliseconds
            trigState = daq6510.Trigger.Model.State
            'Console.WriteLine("{0}", daq6510.Buffer.Actual["defbuffer1"])
        Loop While (trigState.IndexOf("WAITING") <> -1 Or trigState.IndexOf("RUNNING") <> -1)

        my_scan.Count = 10
        daq6510.Trigger.Initiate()


        Do
            System.Threading.Thread.Sleep(500)  'delay defined In milliseconds
            trigState = daq6510.Trigger.Model.State
            'Console.WriteLine("{0}", daq6510.Buffer.Actual["defbuffer1"])
        Loop While (trigState.IndexOf("WAITING") <> -1 Or trigState.IndexOf("RUNNING") <> -1)

        Dim receieved_data As String = daq6510.Buffer.FetchData(1, 40, "defbuffer1", "READ, UNIT, CHAN, REL")
        Dim data_array_str As String() = receieved_data.Split(",")
        Dim k as Int32 = 1
        For j As Int32 = 0 To (my_scan.Count * my_scan.StepCount * 4 - 1) Step 4     ' note the step size is 4 because we are requesting four data items per measurement
            Console.WriteLine("Reading {0}, {1} {2}, {3}, {4}", k, data_array_str(j), data_array_str(j + 1), data_array_str(j + 2), data_array_str(j + 3))
            k += 1
        Next

        Console.WriteLine(vbLf + "Triggering second loop..." + vbLf)

        ' Do it again And get the data as the scan progresses...
        daq6510.Trigger.Initiate()
        trigState = ""
        Dim g As Int32 = 0
        Dim start_index As Int32 = 1
        Dim end_index As Int32 = my_scan.StepCount
        Dim readings_count As Int32 = 0
        ' The total number of measurements will be the scan count multiplied by the number of measurement steps
        ' (or channels) defined in the scan, as defined with scan.Create() and/or scan.Add()
        Dim target_count = my_scan.Count * my_scan.StepCount
        Dim h As Int32 = 0
        Dim m As Int32 = 0
        Do
            System.Threading.Thread.Sleep(100) ' delay defined In milliseconds
            g = daq6510.Buffer.Actual("defbuffer1")
            'Console.WriteLine("{0}", g)
            If ((g - readings_count) >= my_scan.StepCount) Then
                receieved_data = daq6510.Buffer.FetchData(start_index, end_index, "defbuffer1", "READ, UNIT, CHAN, REL")
                ReDim data_array_str(receieved_data.Split(",").Count)
                data_array_str = receieved_data.Split(",")
                For k = 0 To (data_array_str.Count / 4) - 1
                    Console.WriteLine("Reading {0}, {1} {2}, {3}, {4}", m + 1, data_array_str(h), data_array_str(h + 1), data_array_str(h + 2), data_array_str(h + 3))
                    h += 4
                    m += 1
                Next
                start_index += my_scan.StepCount
                end_index += my_scan.StepCount
                readings_count += my_scan.StepCount
                h = 0
            End If
        Loop While (readings_count < target_count)

        daq6510.Close()

        ' Capture the program stop time from the system.
        my_stopwatch.Stop()

        ' Get the elapsed time as a TimeSpan value.
        Dim ts As TimeSpan = my_stopwatch.Elapsed

        ' Format And display the TimeSpan value.
        Dim elapsedTime As String = String.Format("{0:00}:{1:00}:{2:00}:{3:00}.{4:000}",
                ts.Days, ts.Hours, ts.Minutes, ts.Seconds,
                ts.Milliseconds / 10)
        Console.WriteLine("RunTime " + elapsedTime)

        ' Implement a keypress capture so that the user can see the output of their program.
        Console.WriteLine("Press any key to continue...")
        Dim i As Char = Console.ReadKey().KeyChar
    End Sub

End Module
