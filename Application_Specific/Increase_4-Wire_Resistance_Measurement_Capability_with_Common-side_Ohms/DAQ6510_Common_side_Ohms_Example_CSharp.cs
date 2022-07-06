using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Threading;
using System.Diagnostics;       
using Ivi.Visa.Interop;

namespace DAQ6510_CommonSideOhms_Scanning_CSharp
{
    class Program
    {
        static Boolean echoCmd = false; // Set to "true" to echo commands send to the 
                                        // instrument(s)
                            
        static void Main(string[] args)
        {
            ResourceManager ioMgr = new ResourceManager();

            // To list all connected instrument resources, uncomment 
            // the following four lines
            /*string[] resources = ioMgr.FindRsrc("?*");
            foreach (string n in resources)
            {
                Console.Write("{0}\n", n);

            }*/

            FormattedIO488 myInstr = new Ivi.Visa.Interop.FormattedIO488();
            myInstr.IO = (IMessage)ioMgr.Open("TCPIP0::192.168.1.165::inst0::INSTR", 
                                               AccessMode.NO_LOCK, 20000);
            // Instrument ID String examples...
            //       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
            //       USB -> USB0::0x05E6::0x2450::01419962::INSTR
            //       GPIB -> GPIB0::16::INSTR
            //       Serial -> ASRL4::INSTR
            myInstr.IO.Clear();
            int myTO = myInstr.IO.Timeout;
            myInstr.IO.Timeout = 20000;
            myTO = myInstr.IO.Timeout;
            myInstr.IO.TerminationCharacterEnabled = true;
            myInstr.IO.TerminationCharacter = 0x0A;

            Stopwatch myStpWtch = new Stopwatch();

            myStpWtch.Start();

            instrWrite(myInstr, "reset()"); // Set to defaults
            // Enable common-side ohms
            instrWrite(myInstr, "channel.setcommonside(\"slot1\", channel.ON)");
            // Set for 4-wire resistance
            instrWrite(myInstr, "channel.setdmm(\"101:105\", dmm.ATTR_MEAS_FUNCTION," +
                                " dmm.FUNC_4W_RESISTANCE)");
            // Enable offset compensation
            instrWrite(myInstr, "channel.setdmm(\"101:105\", " +
                                "dmm.ATTR_MEAS_OFFCOMP_ENABLE, dmm.OCOMP_ON)");
            // Set a fixed range
            instrWrite(myInstr, "channel.setdmm(\"101:105\", " +
                                "dmm.ATTR_MEAS_RANGE, 10)");
            // Enable averaging 
            instrWrite(myInstr, "channel.setdmm(\"101:105\", " +
                                "dmm.ATTR_MEAS_FILTER_ENABLE, dmm.ON)");
            // Set the average count
            instrWrite(myInstr, "channel.setdmm(\"101:105\", " +
                                "dmm.ATTR_MEAS_FILTER_COUNT, 20)");
            // Create the scan
            instrWrite(myInstr, "scan.add(\"101:105\")");
            // Define the scan iterations
            instrWrite(myInstr, "scan.scancount = 10");
            // Define which channels are shown on the instrument front panel
            instrWrite(myInstr, "display.watchchannels = \"101:105\"");
            // Start the scan                                                           
            instrWrite(myInstr, "trigger.model.initiate()");            

            // The following loop determines if a scan iteration has completed
            // then outputs the readings and channel numbers.
            Int16 rdgsCnt = 0, extractSize = 5;
            String sndBuffer = "", rcvBuffer = "";
            Int16 startIndex = 1, endIndex = extractSize;
            do
            {
                rdgsCnt = Convert.ToInt16(instrQuery(myInstr, "print(defbuffer1.n)"));
                if (rdgsCnt >= endIndex)
                {
                    sndBuffer = String.Format("printbuffer({0}, {1}, defbuffer1, " +
                    "defbuffer1.readings, defbuffer1.channels)", startIndex, endIndex);
                    rcvBuffer = instrQuery(myInstr, sndBuffer);
                    Console.Write("{0}", rcvBuffer);
                    startIndex += extractSize;
                    endIndex += extractSize;
                }
               else
                {
                    Thread.Sleep(500);
                }
            
            } while (endIndex <= 50);

            // Upon scan completion, report the average and pk-to-pk information
            // for each channel. 
            Int32 tmpInt = 0;
            String rcvBuffer2 = "";
            for(Int32 j = 1; j <= 5; j++)
            {
                tmpInt = j + 100;
                instrWrite(myInstr, String.Format("myStats = buffer.getstats(defbuffer1, " +
                                                  "\"{0}\")", tmpInt));
                sndBuffer = String.Format("print(myStats.mean)");
                rcvBuffer = instrQuery(myInstr, sndBuffer);
                sndBuffer = String.Format("print(myStats.max.reading - myStats.min.reading)");
                rcvBuffer2 = instrQuery(myInstr, sndBuffer);
                Console.WriteLine("Channel {0} Avg = {1}, Pk2Pk = {2}", tmpInt, 
                                  rcvBuffer.TrimEnd('\n'), rcvBuffer2.TrimEnd('\n'));
            }

            myInstr.IO.Close();

            myStpWtch.Stop();

            // Get the elapsed time as a TimeSpan value.
            TimeSpan ts = myStpWtch.Elapsed;

            // Format and display the TimeSpan value.
            string elapsedTime = String.Format("{0:00}:{1:00}:{2:00}:{3:00}.{4:000}",
                ts.Days, ts.Hours, ts.Minutes, ts.Seconds,
                ts.Milliseconds / 10);
            Console.WriteLine("RunTime " + elapsedTime);

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
    }
}
