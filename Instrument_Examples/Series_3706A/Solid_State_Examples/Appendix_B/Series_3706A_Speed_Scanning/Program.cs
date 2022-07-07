using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net.Sockets;
using System.Diagnostics;
using System.IO;
using System.Threading;

namespace Series_3706A_Speed_Scanning
{
    class Program
    {
        static public bool echoCommands = true;

        static void Main(string[] args)
        {
            string ipAddress = "192.168.1.37";
            int portNum = 5025;
            TcpClient myClient = null;
            NetworkStream netStream = null;
            string rcvBuffer = "";
            Stopwatch myStpWtch = new Stopwatch();

            myStpWtch.Start();

            // Get the elapsed time as a TimeSpan value.
            TimeSpan ts = myStpWtch.Elapsed;
            string elapsedTime = "";
            int cardSlot = 1;
            String sndBuffer = "";

            InstConnect(ref myClient, ref netStream, ipAddress, portNum, true, false, ref rcvBuffer);

            // Reset the instrument to the default settings and clear existing system errors...
            InstSend(netStream, "*rst");
            InstSend(netStream, "errorqueue.clear()");

            // Check the interlock state and reset any existing scan attributes...
            InstQuery(netStream, "print(slot[1].interlock.state)", 32, ref rcvBuffer);
            InstSend(netStream, "*cls");
            InstSend(netStream, "scan.reset()");

            // Build the script that will...
            //  a. Configure the measurment channel attributes optimized for speed
            //      i. Setting a fixed range
            //      ii. Disabling auto zero
            //      iii. Disabling auto delay
            //      iv. Turn line sync off
            //      v. Disable filtering and limits
            //      vi. Decreasing the power line cycles (PLC) to the minimum
            //  b. Clear and size the scan buffer, 
            //  c. Establish the scan configuration
            //  d. Execute the scan
            //  e. Provide timers that allow us to monitor 
            //      i. Scan setup time
            //      ii. Scan execution time
            InstSend(netStream, "loadscript SCAN_3724");
            InstSend(netStream, "timer.reset()");
            sndBuffer = String.Format("if slot[{0}].interlock.override == 0 then slot[{1}].interlock.override = 1 end", cardSlot, cardSlot);
            InstSend(netStream, sndBuffer);
            InstSend(netStream, "channel.open(\"allslots\")");
            InstSend(netStream, "dmm.reset('all')");
            InstSend(netStream, "dmm.func = dmm.DC_VOLTS");
            InstSend(netStream, "dmm.nplc = 0.0005");
            InstSend(netStream, "dmm.displaydigits = dmm.DIGITS_7_5");
            InstSend(netStream, "dmm.autorange = dmm.OFF");
            InstSend(netStream, "dmm.autodelay = dmm.OFF");
            InstSend(netStream, "dmm.autozero = dmm.OFF");
            InstSend(netStream, "dmm.limit[1].enable = dmm.OFF");
            InstSend(netStream, "dmm.limit[2].enable = dmm.OFF");
            InstSend(netStream, "format.data = format.SREAL");  // Use binary data transfer for readings...
            InstSend(netStream, "dmm.range = 10");
            InstSend(netStream, "dmm.measurecount = 1");
            InstSend(netStream, "scan.scancount = 100");          // used to be measurecount
            InstSend(netStream, "dmm.linesync = dmm.OFF");
            InstSend(netStream, "dmm.configure.set('dcv')");
            InstSend(netStream, "scan_buf = dmm.makebuffer(1000)");
            InstSend(netStream, "channel.connectrule = channel.BREAK_BEFORE_MAKE");
            //InstSend(netStream, "dmm.measure()");

            sndBuffer = String.Format("dmm.setconfig('1001:1010','dcv') scan.create('1001:1010')");
            InstSend(netStream, sndBuffer);
            InstSend(netStream, "timeLapseSetup = timer.measure.t()");

            InstSend(netStream, "timer.reset()");
            InstSend(netStream, "scan.execute(scan_buf)");
            InstSend(netStream, "timeLapse = timer.measure.t()");
            InstSend(netStream, "endscript");

            // Call the script (on the instrument) that executes the scanning...
            InstSend(netStream, "SCAN_3724()");

            //Extract all data...
            float[] fltData = new float[100];
            int start_index = 1;
            int end_index = 100;
            int chunk_size = 100;
            int mm = 0;
            for (int n = 0; n < 10; n++)
            {
                sndBuffer = String.Format("printbuffer({0}, {1}, scan_buf.readings)", start_index, end_index);
                InstQuery_FloatData(netStream, sndBuffer, chunk_size, ref fltData);  // scan_buf.readings,
                start_index += chunk_size;
                end_index += chunk_size;
                for (int m = 0; m < fltData.Length; m++)
                {
                    Console.Write("Rdg {0} = {1},\n", (mm++) + 1, fltData[m]);
                }
            }

            // To get channels per sec scan speed, must divide 30 (the # of chans in a scan) by elapsed time
            InstSend(netStream, "format.data = format.ASCII");
            InstQuery(netStream, "print(timeLapseSetup)", 128, ref rcvBuffer);
            Console.WriteLine("Time Lapse for scan script configuration: {0:E}", rcvBuffer);

            InstQuery(netStream, "print(timeLapse)", 128, ref rcvBuffer);
            Console.WriteLine("Time Lapse for internal scan execution: {0:E}", rcvBuffer);

            Double testResults = 1000 / Convert.ToDouble(rcvBuffer);
            Console.WriteLine("Calculated Channels/Sec: {0:E}", testResults);

            InstDisconnect(ref myClient, ref netStream);

            myStpWtch.Stop();

            // Get the elapsed time as a TimeSpan value.
            ts = myStpWtch.Elapsed;

            // Format and display the TimeSpan value.
            elapsedTime = String.Format("{0:00}:{1:00}:{2:00}:{3:00}.{4:000}",
                ts.Days, ts.Hours, ts.Minutes, ts.Seconds,
                ts.Milliseconds / 10);
            Console.WriteLine("Total Program Run Time " + elapsedTime + "\n");

            Console.WriteLine("Press any key to continue...");
            char k = Console.ReadKey().KeyChar;
        }

        static public int InstConnect(ref TcpClient myClient, ref NetworkStream netStream, string ipAddress, int portNum, bool echoIdString, bool doReset, ref string strId)
        {
            int status = 0;
            try
            {
                myClient = new TcpClient(ipAddress, portNum);
                Console.WriteLine("Connected to instrument......");
                myClient.ReceiveTimeout = 20000;
                myClient.ReceiveBufferSize = 35565;
                netStream = myClient.GetStream();
                if (echoIdString)
                {
                    InstQuery(netStream, "*IDN?", 128, ref strId);
                }
                if (doReset)
                {
                    InstSend(netStream, "reset()");
                }
            }
            catch (Exception e)
            {
                status = -1;
                Console.WriteLine(e.Message);
            }
            finally
            {
                // Nothing to close
            }
            return status;
        }

        static public void InstDisconnect(ref TcpClient myClient, ref NetworkStream netStream)
        {
            netStream.Close();
            myClient.Close();
        }

        static public int InstSend(NetworkStream netStream, string cmdStr)
        {
            try
            {
                byte[] byteBuffer;
                if (echoCommands == true)
                {
                    Console.WriteLine("{0}", cmdStr);
                }
                byteBuffer = Encoding.ASCII.GetBytes(cmdStr + "\r\n");
                netStream.Write(byteBuffer, 0, byteBuffer.Length);
                Array.Clear(byteBuffer, 0, byteBuffer.Length);
                return 0;
            }
            catch (Exception e)
            {
                Console.WriteLine("{0}", e.Message);
                Console.WriteLine("{0}", e.ToString());
                return -9999;
            }
        }

        static public int InstRcv(NetworkStream netStream, int byteCount, ref string rcvStr)
        {
            try
            {
                byte[] rcvBytes;
                rcvBytes = new byte[byteCount];
                int bytesRcvd = netStream.Read(rcvBytes, 0, byteCount);
                rcvStr = Encoding.ASCII.GetString(rcvBytes, 0, bytesRcvd);
                Array.Clear(rcvBytes, 0, byteCount);
                return 0;
            }
            catch (Exception e)
            {
                Console.WriteLine("{0}", e.Message);
                return -9999;
            }
        }

        static public int InstRcv_FloatData(NetworkStream netStream, int chunkSize, ref float[] fltData)
        {
            byte[] rcvBytes;
            rcvBytes = new byte[chunkSize * 4 + 3];
            int bytesRcvd = netStream.Read(rcvBytes, 0, rcvBytes.Length);
            // Need to convert to the byte array into single or do
            Buffer.BlockCopy(rcvBytes, 2, fltData, 0, fltData.Length * 4);
            Array.Clear(rcvBytes, 0, rcvBytes.Length);
            return 0;
        }

        static public int InstQuery(NetworkStream netStream, string cmdStr, int byteCount, ref string rcvStr)
        {
            int status = 0;
            status = InstSend(netStream, cmdStr);
            if (status == 0)
                status = InstRcv(netStream, byteCount, ref rcvStr);
            return status;
        }

        static public int InstQuery_FloatData(NetworkStream netStream, string cmdStr, int byteCount, ref float[] fltData)
        {
            int status = 0;
            status = InstSend(netStream, cmdStr);
            status = InstRcv_FloatData(netStream, byteCount, ref fltData);
            return 0;
        }
    }
}
