/*================================================================================

    Copyright 2019 Tektronix, Inc.                      
    See www.tek.com/sample-license for licensing terms. 

================================================================================*/

/* ================================================================================

       This program is an example used to help show the low level current
       measuremente performance through use of the preamp paired with the
       Keithley 6430. 

================================================================================ */

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using NationalInstruments.Visa; // Added references to 
                                //  1. NationalInstruments.Common
                                //  2. NationalInstruments.MStudioCLM
                                //  3. NationalInstruments.NiLmClientDLL
                                //  4. NationalInstruments.Visa
                                // If further errors persist, you may need to add a reference to Ivi.Visa 
                                // and can do so through VS fix options presented via drop-down in the editor. 
using System.Diagnostics;       // needed for stopwatch usage

namespace Mode_6430_Low_Current_Sensitivity_Example
{
    class Program
    {
        static Boolean echo_command = false;

        static void Main(string[] args)
        {
            ResourceManager rmSession = new ResourceManager();
            MessageBasedSession mbSession = null;
            String instrument_id_string = "GPIB0::15::INSTR"; // GPIB0::26::INSTR    USB0::0x05E6::0x2602::4403417::INSTR
            Boolean isUsing6430 = false; 

            Stopwatch myStpWtch = new Stopwatch();
            myStpWtch.Start();

            instrument_connect(ref rmSession, ref mbSession, instrument_id_string, 20000);

            Console.WriteLine(instrument_query(mbSession, "*IDN?"));

            instrument_write(mbSession, "*RST");
            instrument_write(mbSession, "SOUR:FUNC VOLT");
            instrument_write(mbSession, "SOUR:VOLT:LEV 0");
            instrument_write(mbSession, "SOUR:VOLT:RANG 0.2");
            if (isUsing6430)
            {
                instrument_write(mbSession, "AVER:AUTO ON");        // for use w/ the 6430
                instrument_write(mbSession, "AVER:REP ON");         // for use w/ the 6430
                instrument_write(mbSession, "AVER:ADV:NTOL 0.1");   // for use w/ the 6430
            }
            else
            {
                instrument_write(mbSession, "AVER:TCON REP");       // for use w/ the 2400
            }
            instrument_write(mbSession, "AVER:STAT ON"); 
            instrument_write(mbSession, "SENS:CURR:PROT 1E-6");
            instrument_write(mbSession, "SENS:FUNC 'CURR'");
            instrument_write(mbSession, "SENS:CURR:RANG 1E-12");
            instrument_write(mbSession, "CURR:NPLC 10");
            instrument_write(mbSession, "FORM:ELEM CURR, TIME");
            instrument_write(mbSession, "SYST:TIME:RES");
            instrument_write(mbSession, "*OPC");
            instrument_write(mbSession, "OUTP ON");

            for(int j = 0; j < 10; j++)
            {
                Console.WriteLine(instrument_query(mbSession, "READ?"));
            }

            instrument_write(mbSession, "OUTP OFF");

            instrument_disconnect(ref mbSession);

            // Capture the program stop time from the system.
            myStpWtch.Stop();

            // Get the elapsed time as a TimeSpan value.
            TimeSpan ts = myStpWtch.Elapsed;

            // Format and display the TimeSpan value.
            string elapsedTime = String.Format("{0:00}:{1:00}:{2:00}:{3:00}.{4:000}",
                ts.Days, ts.Hours, ts.Minutes, ts.Seconds,
                ts.Milliseconds / 10);
            Console.WriteLine("RunTime: " + elapsedTime);

            // Implement a keypress capture so that the user can see the output of their program.
            Console.WriteLine("Press any key to continue...");
            char k = Console.ReadKey().KeyChar;

            rmSession.Dispose();

        }

        static void instrument_connect(ref ResourceManager resource_manager, ref MessageBasedSession instrument_control_object, string instrument_id_string, Int16 timeout)
        {
            /*
             *  Purpose: Open an instance of an instrument object for remote communication and establish the communication attributes.
             *  
             *  Parameters:
             *      resource_manager - The reference to the resource manager object created external to this function. It is passed in 
             *                         by reference so that any internal attributes that are updated when using to connect to the 
             *                         instrument are updated to the caller. 
             *                         
             *      instrument_control_object - The reference to the instrument object created external to this function. It is passed
             *                                  in by reference so that it retains all values upon exiting this function, making it
             *                                  consumable to all other calling functions. 
             *                                  
             *      instrument_id_string - The instrument VISA resource string used to identify the equipment at the underlying driver 
             *                             level. This string can be obtained per making a call to Find_Resources() VISA function and 
             *                             extracted from the reported list.
             *                             
             *      timeout - This is used to define the duration of wait time that will transpire with respect to VISA read/query calls 
             *                prior to an error being reported.
             *                
             *  Returns:
             *      None
             *      
             *  Revisions: 
             *      2019-06-04      JJB     Initial revision.
             */

            instrument_control_object = (MessageBasedSession)(resource_manager.Open(instrument_id_string, Ivi.Visa.AccessModes.None, 2000));
            // Instrument ID String examples...
            //       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
            //       USB -> USB0::0x05E6::0x2450::01419962::INSTR
            //       GPIB -> GPIB0::16::INSTR
            //       Serial -> ASRL4::INSTR
            instrument_control_object.Clear();
            instrument_control_object.TimeoutMilliseconds = timeout;
            if (instrument_id_string.Contains("ASRL"))
            {
                instrument_control_object.TerminationCharacterEnabled = true;
                instrument_control_object.TerminationCharacter = 0x0A;
            }
            else if (instrument_id_string.Contains("SOCKET"))
            {
                instrument_control_object.TerminationCharacterEnabled = true;
                instrument_control_object.TerminationCharacter = 0x0A;
            }

            return;
        }

        static void instrument_disconnect(ref MessageBasedSession instrument_control_object)
        {
            /*
             *  Purpose: Closes an instance of and instrument object previously opened for remote communication.
             * 
             *  Parameters:
             *      instrument_control_object - The reference to the instrument object created external to this function. It is passed
             *                                  in by reference so that it retains all values upon exiting this function, making it
             *                                  consumable to all other calling functions. 
             *                
             *  Returns:
             *      None
             *      
             *  Revisions: 
             *      2019-06-04      JJB     Initial revision.
             */
            instrument_control_object.Dispose();
            return;
        }

        static void instrument_write(MessageBasedSession instrument_control_object, string command)
        {
            /*
             *  Purpose: Used to send commands to the instrument.
             *  
             *  Parameters:
             *      instrument_control_object - The reference to the instrument object created external to this function. It is passed
             *                                  in by reference so that it retains all values upon exiting this function, making it
             *                                  consumable to all other calling functions. 
             *                                  
             *      command - The command string issued to the instrument in order to perform an action.
             *      
             *  Returns:
             *      None
             *      
             *  Revisions: 
             *      2019-06-04      JJB     Initial revision.
             */
            if (echo_command == true)
            {
                Console.WriteLine("{0}", command);
            }
            instrument_control_object.RawIO.Write(command);
            //instrument_control_object.WriteString(command + "\n");
            return;
        }

        static string instrument_read(MessageBasedSession instrument_control_object)
        {
            /*
             *  Purpose: Used to read commands from the instrument.
             *  
             *  Parameters:
             *      instrument_control_object - The reference to the instrument object created external to this function. It is passed
             *                                  in by reference so that it retains all values upon exiting this function, making it
             *                                  consumable to all other calling functions. 
             *      
             *  Returns:
             *      The string obtained from the instrument.
             *      
             *  Revisions: 
             *      2019-06-04      JJB     Initial revision.
             */
            return instrument_control_object.RawIO.ReadString();
        }

        static string instrument_query(MessageBasedSession instrument_control_object, string command)
        {
            /*
             *  Purpose: Used to send commands to the instrument  and obtain an information string from the instrument.
             *           Note that the information received will depend on the command sent and will be in string
             *           format.
             *  
             *  Parameters:
             *      instrument_control_object - The reference to the instrument object created external to this function. It is passed
             *                                  in by reference so that it retains all values upon exiting this function, making it
             *                                  consumable to all other calling functions. 
             *                                  
             *      command - The command string issued to the instrument in order to perform an action.
             *      
             *  Returns:
             *      The string obtained from the instrument.
             *      
             *  Revisions: 
             *      2019-06-04      JJB     Initial revision.
             */
            instrument_write(instrument_control_object, command);
            return instrument_read(instrument_control_object);
        }

        /*static Single[] instrument_query_float_data_array(MessageBasedSession instr, String command, Int32 count, ref Single[] fltData)
        {
            // This function is designed to work with single floating point data only
            // First send the query command....
            instrument_write(instr, command);

            // Extract the readings in raw byte format
            //int tmp_nm = sizeof(Single);
            byte[] tmp_bytes = instr.RawIO.Read(sizeof(Single) * count + 3);        // addition of 3 accounts for the preamble chars, #0, and the terminator

            // Need to convert to the byte array into single. Need account for the '#0' that begins the binary response
            // and apply the offset in the second argument to the BlockCopy() method. Also, we'll define the count of
            // readings to copy into float data assuming it has been appropriately sized for the number of readings
            // that the measurement operation is to yield. Note that in VB the declaration of an array of size n will 
            // result in the allocation of n+1 indices in the resulting array. This is why we subtract 1 from the 
            // length in argument 4 prior to multiplying by the Single data type byte size (4). 
            Buffer.BlockCopy(tmp_bytes, 2, fltData, 0, (fltData.Length) * 4);
            return fltData;
        }*/

        static Single[] instrument_query_float_data_array(MessageBasedSession instr, String command, ref Single[] fltData)
        {
            // This function is designed to work with single floating point data only
            // First send the query command....
            instrument_write(instr, command);

            // Extract the readings in raw byte format
            fltData = instr.FormattedIO.ReadBinaryBlockOfSingle();
            //byte[] myBytes = instr.RawIO.Read();
            Int64 mycnt = fltData.Length;

            // Need to convert to the byte array into single. Need account for the '#0' that begins the binary response
            // and apply the offset in the second argument to the BlockCopy() method. Also, we'll define the count of
            // readings to copy into float data assuming it has been appropriately sized for the number of readings
            // that the measurement operation is to yield. Note that in VB the declaration of an array of size n will 
            // result in the allocation of n+1 indices in the resulting array. This is why we subtract 1 from the 
            // lenght in argument 4 prior to multiplying by the Single data type byte size (4). 
            //Buffer.BlockCopy(myBytes, 2, fltData, 0, (fltData.Length - 1) * 4);

            return fltData;
        }

        static Single instrument_query_float_single_point(MessageBasedSession instr, String command)
        {
            // This function is designed to work with single floating point data only
            // First send the query command....
            instrument_write(instr, command);

            // Extract the readings in raw byte format
            byte[] myBytes = instr.RawIO.Read();

            /* Need to convert to the byte array into single. Need account for the '#0' that begins the binary response
            ' and apply the offset in the second argument to the BlockCopy() method. Also, we'll define the count of
            ' readings to copy into float data assuming it has been appropriately sized for the number of readings
            ' that the measurement operation is to yield. Note that in VB the declaration of an array of size n will 
            ' result in the allocation of n+1 indices in the resulting array. This is why we subtract 1 from the 
            ' lenght in argument 4 prior to multiplying by the Single data type byte size (4). */
            Single[] fltData = new Single[1];   // size for the number of readings
            Buffer.BlockCopy(myBytes, 2, fltData, 0, (fltData.Length - 1) * 4);

            return fltData[0];
        }
    }
}
