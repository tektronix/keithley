/*================================================================================

    Copyright 2019 Tektronix, Inc.                      
    See www.tek.com/sample-license for licensing terms. 

================================================================================*/

/* ================================================================================

       This program is a brief example of how a DAQ6510 user might add
       a frequency measurement to their programmed scan. Only one channel
       is defined and we provide two different means for triggering, monitoring
       and extracting the scan measurement data. 

       This example will work any of the following multiplexer card
       models: 7700, 7701, 7702, 7703, 7706, 7707, 7708, 7710

================================================================================ */
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using KeithleyInstruments.KeithleyDMM6500.Interop;
using System.Diagnostics;       // needed for stopwatch usage

namespace DAQ6510_IVI_COM_Scan_with_Frequency_CSharp
{
    class Program
    {
        static void Main(string[] args)
        {
            // Create a Stopwatch object and capture the program start time from the system.
            Stopwatch myStpWtch = new Stopwatch();
            myStpWtch.Start();

            // Start by instantiating a DAQ6510 control object and printing the model info to the console.
            String resource_name = "USB0::0x05E6::0x6510::04340543::INSTR";
            KeithleyDMM6500 daq6510 = new KeithleyDMM6500();
            daq6510.Initialize(resource_name, true, false, "");
            // Instrument ID String examples...
            //       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
            //       USB -> USB0::0x05E6::0x2450::01419962::INSTR
            //       GPIB -> GPIB0::16::INSTR
            //       Serial -> ASRL4::INSTR
            string id = daq6510.Identity.InstrumentModel;
            Console.WriteLine("ID is {0}", id);

            // Ensure the channel of interest is selected and that it is assigned to use the frequency function.
            daq6510.ChannelFunction["101"] = KeithleyDMM6500FunctionEnum.KeithleyDMM6500FunctionFrequency;

            // Define a supplemental scan object and configure to iterate 10 times with a 1s interval between
            // each scan. 
            IKeithleyDMM6500RouteScan my_scan = daq6510.Route.Scan;
            my_scan.Create("201");
            my_scan.Interval = 1.0;
            my_scan.Count = 10;

            // Start the scanning and the hold until complete. Typical trigger model transitions during
            // the scan are either "WAITING" or "RUNNING", so we will key off of those returns. Also 
            // note that the Trigger Model State value is updated (at the instrument level) only once
            // every 100ms, so you could save your computer the comms traffic by delaying by at least
            // that much; perhaps, in this case, as much as 1s since that is what the scan interval is
            // assigned to. 
            daq6510.Trigger.Initiate();
            string trigState = "";
            do
            {
                System.Threading.Thread.Sleep(1000); // delay defined in milliseconds
                trigState = daq6510.Trigger.Model.State;
                //Console.WriteLine("{0}", daq6510.Buffer.Actual["defbuffer1"]);
            } while ((trigState.IndexOf("WAITING")) != -1 || (trigState.IndexOf("RUNNING") != -1));

            String receieved_data = daq6510.Buffer.FetchData(1, 10, "defbuffer1", "READ, UNIT, CHAN, REL");
            String[] data_array_str = receieved_data.Split(',');
            int k = 1;
            for(int j = 0; j < 40; j+=4)
            {
                Console.WriteLine("Reading {0}, {1} {2}, {3}, {4}", k++, data_array_str[j], data_array_str[j + 1], data_array_str[j + 2], data_array_str[j + 3]);
            }

            Console.WriteLine("\nTriggering second loop...\n");

            // Do it again and get the data as the scan progresses...
            daq6510.Trigger.Initiate();
            trigState = "";
            Int32 g = 0;
            Int32 start_index = 1;
            Int32 end_index = 2;
            Int32 extract_size = 1;
            Int32 readings_count = 0;
            k = 0;
            Int32 h = 1;
            do
            {
                System.Threading.Thread.Sleep(100); // delay defined in milliseconds
                trigState = daq6510.Trigger.Model.State;
                g = daq6510.Buffer.Actual["defbuffer1"];
                if (g >= end_index)
                {
                    receieved_data = daq6510.Buffer.FetchData(start_index, end_index, "defbuffer1", "READ, UNIT, CHAN, REL");
                    data_array_str = receieved_data.Split(',');
                    for (k = 0; k < extract_size; k++)
                    {
                        Console.WriteLine("Reading {0}, {1} {2}, {3}, {4}", h++, data_array_str[0], data_array_str[1], data_array_str[2], data_array_str[3]);
                        start_index += extract_size;
                        end_index += extract_size;
                        readings_count += extract_size;
                    }
                    
                    
                }
                    
            } while (trigState.IndexOf("WAITING") != -1 || trigState.IndexOf("RUNNING") != -1 && readings_count <= 10);

            daq6510.Close();

            // Capture the program stop time from the system.
            myStpWtch.Stop();

            // Get the elapsed time as a TimeSpan value.
            TimeSpan ts = myStpWtch.Elapsed;

            // Format and display the TimeSpan value.
            string elapsedTime = String.Format("{0:00}:{1:00}:{2:00}:{3:00}.{4:000}",
                ts.Days, ts.Hours, ts.Minutes, ts.Seconds,
                ts.Milliseconds / 10);
            Console.WriteLine("RunTime " + elapsedTime);

            // Implement a keypress capture so that the user can see the output of their program.
            Console.WriteLine("Press any key to continue...");
            char i = Console.ReadKey().KeyChar;
        }
    }
}
