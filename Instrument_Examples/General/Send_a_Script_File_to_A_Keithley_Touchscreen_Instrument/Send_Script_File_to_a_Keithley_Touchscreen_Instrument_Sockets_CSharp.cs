using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net.Sockets;
using System.Diagnostics;   // for timing tools
using System.IO;
using System.Text;
using System.Threading;     // for delays

namespace Send_TSP_Script_File_to_DAQ6510_Sockets_CSharp
{
    class Program
    {
        static public bool echoCommands = true;

        static void Main(string[] args)
        {
            string ipAddress = "192.168.1.147";
            int portNum = 5025;
            TcpClient myClient = null;
            NetworkStream netStream = null;
            string rcvBuffer = "";
            Stopwatch myStpWtch = new Stopwatch();

            myStpWtch.Start();

            // Get the elapsed time as a TimeSpan value.
            TimeSpan ts = myStpWtch.Elapsed;
            string elapsedTime = "";

            instrument_connect(ref myClient, ref netStream, ipAddress, portNum, true, false, ref rcvBuffer);

            // Reset the instrument to the default settings.
            instrument_write(netStream, "reset()");

            // Ready the instrument to receive the target file contents
            instrument_write(netStream, "if loadfuncs ~= nil then script.delete('loadfuncs') end");
            instrument_write(netStream, "loadscript loadfuncs");

            // Load the script file line by line
            String line = "";
            System.IO.StreamReader file = new System.IO.StreamReader("..\\..\\functions2.tsp");
            do
            {
                line = file.ReadLine();
                instrument_write(netStream, line);
            } while (line != null);

            file.Close();

            // Close out the loadfuncs wrapper script then call it as a function to load the 
            // contents of the script file into active memory. 
            instrument_write(netStream, "endscript");
            String tmpStr = "";
            instrument_query(netStream, "loadfuncs()", 32, ref tmpStr);
            Console.WriteLine(tmpStr);       // Note that we are echoing a queried function here. 
                                             // You will note that the final line in the functions.tsp
                                             // script file is a print() command that will push its contents
                                             // to the output data queue. 

            instrument_write(netStream, "do_beep(0.250, 1000, 3)");

            InstDisconnect(ref myClient, ref netStream);

            myStpWtch.Stop();

            // Get the elapsed time as a TimeSpan value.
            ts = myStpWtch.Elapsed;

            // Format and display the TimeSpan value.
            elapsedTime = String.Format("{0:00}:{1:00}:{2:00}:{3:00}.{4:000}",
                ts.Days, ts.Hours, ts.Minutes, ts.Seconds,
                ts.Milliseconds / 10);
            Console.WriteLine("RunTime " + elapsedTime + "\n");

            Console.WriteLine("Press any key to continue...");
            char k = Console.ReadKey().KeyChar;
        }

        static public int instrument_connect(ref TcpClient myClient, ref NetworkStream netStream, string ipAddress, int portNum, bool echoIdString, bool doReset, ref string strId)
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
                    instrument_query(netStream, "*IDN?", 128, ref strId);
                }
                if (doReset)
                {
                    instrument_write(netStream, "reset()");
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

        static public int instrument_write(NetworkStream netStream, string cmdStr)
        {
            try
            {
                byte[] byteBuffer;
                if (echoCommands == true)
                {
                    Console.WriteLine("{0}", cmdStr);
                }
                byteBuffer = Encoding.ASCII.GetBytes(cmdStr + "\n\n");
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

        static public int instrument_read(NetworkStream netStream, int byteCount, ref string rcvStr)
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

        static public int instrument_read_float_data(NetworkStream netStream, int chunkSize, ref float[] fltData)
        {
            byte[] rcvBytes;
            rcvBytes = new byte[chunkSize * 4 + 3];
            int bytesRcvd = netStream.Read(rcvBytes, 0, rcvBytes.Length);
            // Need to convert to the byte array into single or do
            Buffer.BlockCopy(rcvBytes, 2, fltData, 0, fltData.Length * 4);
            Array.Clear(rcvBytes, 0, rcvBytes.Length);
            return 0;
        }

        static public int instrument_query(NetworkStream netStream, string cmdStr, int byteCount, ref string rcvStr)
        {
            int status = 0;
            status = instrument_write(netStream, cmdStr);
            if (status == 0)
                status = instrument_read(netStream, byteCount, ref rcvStr);
            return status;
        }

        static public int instrument_query_float_data(NetworkStream netStream, string cmdStr, int byteCount, ref float[] fltData)
        {
            int status = 0;
            status = instrument_write(netStream, cmdStr);
            status = instrument_read_float_data(netStream, byteCount, ref fltData);
            return 0;
        }
    }
}
