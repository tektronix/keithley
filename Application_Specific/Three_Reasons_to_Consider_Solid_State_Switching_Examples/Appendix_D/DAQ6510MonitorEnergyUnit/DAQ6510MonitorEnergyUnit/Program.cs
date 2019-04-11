using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;
using System.Diagnostics;       // needed for stopwatch usage
using Ivi.Visa.Interop;         // Add the VISA COM Type Library to use this

namespace DAQ6510MonitorEnergyUnit
{
    class Program
    {
        static Boolean echoCmd = true;

        static void Main(string[] args)
        {
            ResourceManager ioMgr = new ResourceManager();
            string[] resources = ioMgr.FindRsrc("?*");

            foreach (string n in resources)
            {
                Console.Write("{0}\n", n);

            }

            FormattedIO488 myInstr = new Ivi.Visa.Interop.FormattedIO488();
            /////////////////////////////////////////////////////////////////////////////////////////////////
            myInstr.IO = (IMessage)ioMgr.Open("TCPIP0::192.168.1.165::inst0::INSTR", AccessMode.NO_LOCK, 20000);
            // Instrument ID String examples...
            //       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
            //       USB -> USB0::0x05E6::0x2450::01419962::INSTR
            //       GPIB -> GPIB0::16::INSTR
            //       Serial -> ASRL4::INSTR
            /////////////////////////////////////////////////////////////////////////////////////////////////
            myInstr.IO.Clear();
            int myTO = myInstr.IO.Timeout;
            myInstr.IO.Timeout = 20000;
            myTO = myInstr.IO.Timeout;
            myInstr.IO.TerminationCharacterEnabled = true;
            myInstr.IO.TerminationCharacter = 0x0A;

            Stopwatch myStpWtch = new Stopwatch();
            Stopwatch CHANTIME = new Stopwatch();

            myStpWtch.Start();

            // Clear any script local to the DAQ6510 which has the name "loadfuncs"
            instrWrite(myInstr, "if loadfuncs ~= nil then script.delete('loadfuncs') end\n");
            // Build the new "loadfuncs" script by defining it then extractin all the functions defined
            // within the test script file local to this program executable.
            instrWrite(myInstr, "loadscript loadfuncs\n");
            string line;
            // Load the script file from the path where the Program.cs file resides
            System.IO.StreamReader file = new System.IO.StreamReader("..\\..\\myTestFunctions.tsp");
            while ((line = file.ReadLine()) != null)
            {
                instrWrite(myInstr, line);
            }
            file.Close();
            instrWrite(myInstr, "endscript\n");
            //  To ensure all the functions written to the instrument become active, we
            //  call the "loadfuncs" script which holds the definitions.
            Console.WriteLine(instrQuery(myInstr, "loadfuncs()\n"));

            // Configure the DAQ6510 channel measure attributes DCV and Temperature. Note that we will  
            // calculate current after the scan is complete. 
            String sndBuffer = String.Format("DAQ_ChanConfig(\"{0}\", \"{1}\", \"{2}\")", "101:103", "104:106", "110");
            instrWrite(myInstr, sndBuffer);

            // Configure the DAQ6510 scan attributes. 
            Int16 scanCount = 1300;
            sndBuffer = String.Format("DAQ_ScanConfig(\"{0}\", {1})", "101:106,110", scanCount);
            instrWrite(myInstr, sndBuffer);

            // Tell the DAQ6510 to make a LAN connection to the power supply and configure
            // it to set the output on and supplying 9V at 1.5A.
            sndBuffer = String.Format("PSU_Configure(\'{0}\', {1}, {2}, {3})", "192.168.1.28", 9.0, 1.5, 1);
            instrWrite(myInstr, sndBuffer);

            //start timer for scan time
            CHANTIME.Start();

            // Trigger the scanning to start.
            instrWrite(myInstr, "DAQ_Trig()");

            // Turn the power supply output off.
            instrWrite(myInstr, "PSU_Off()");

            // Loop until the scan has successfully completed. 
            CheckScanProgress(myInstr);

            // Scanning timer ending
            CHANTIME.Stop();

            // Ensure that the supply is turned off and the socket connection
            // is closed. 
            instrWrite(myInstr, "PSU_Disable()");

            // Split the main buffer (defbufer1) into separate buffer items where the
            // individual channel measurments are warehoused. 
            sndBuffer = String.Format("DAQ_ParseReadingBuffer({0})", scanCount);
            instrWrite(myInstr, sndBuffer);

            // Extract each buffer's contents and make them local to the controlling PC. Note
            // that the values for the current channels will hold the current values calculated
            // local to the DAQ6510. 
            Console.WriteLine(instrQuery(myInstr, "printbuffer(1, voltBuff1.n, voltBuff1)"));
            Console.WriteLine(instrQuery(myInstr, "printbuffer(1, voltBuff2.n, voltBuff2)"));
            Console.WriteLine(instrQuery(myInstr, "printbuffer(1, voltBuff3.n, voltBuff3)"));
            Console.WriteLine(instrQuery(myInstr, "printbuffer(1, currBuff1.n, currBuff1)"));
            Console.WriteLine(instrQuery(myInstr, "printbuffer(1, currBuff2.n, currBuff2)"));
            Console.WriteLine(instrQuery(myInstr, "printbuffer(1, currBuff3.n, currBuff3)"));
            Console.WriteLine(instrQuery(myInstr, "printbuffer(1, tempBuff.n, tempBuff)"));

            // Output block for the time it took to run just the scan (not including the 
            // output of the buffer)
            TimeSpan dt = CHANTIME.Elapsed;
            double dts = dt.Seconds;
            double dtms = dt.Milliseconds;
            dtms = dtms / 1000;
            double totalt = dts + dtms;
            Console.WriteLine("Scan time elapsed: " + totalt + " Second");

            double chanpersec = (7 * 1300) / totalt;  // number of channels times number of scans, 
                                                      //   then divide by scan time
            Console.WriteLine("Channels scanned per second: " + chanpersec);

            myInstr.IO.Close();

            myStpWtch.Stop();

            // Get the elapsed time as a TimeSpan value.
            TimeSpan ts = myStpWtch.Elapsed;

            // Format and display the TimeSpan value.
            string elapsedTime = String.Format("{0:00}:{1:00}:{2:00}:{3:00}.{4:000}",
                ts.Days, ts.Hours, ts.Minutes, ts.Seconds,
                ts.Milliseconds / 10);
            Console.WriteLine("Total Test Run Time " + elapsedTime);




            Console.WriteLine("Press any key to continue...");
            char k = Console.ReadKey().KeyChar;
        }

        static void instrWrite(FormattedIO488 instr, string cmd)
        {
            if (echoCmd == true)
            {
                Console.WriteLine("{0}", cmd);
            }
            instr.WriteString(cmd + "\n");
            return;
        }

        static string instrQuery(FormattedIO488 instr, string cmd)
        {
            instr.WriteString(cmd);
            return instr.ReadString();
        }


        static void CheckScanProgress(FormattedIO488 instr)
        {
            string trgrcheck = "";
            bool triggercheck = false;
            do
            {
                trgrcheck = instrQuery(instr, "print(scan.state())");
                //Console.WriteLine(trgrcheck);  //uncomment to see the current trigger state
                if (trgrcheck.Contains("SUCCESS"))
                {
                    triggercheck = true;
                }
            } while (triggercheck == false);
            return;
        }
    }
}
