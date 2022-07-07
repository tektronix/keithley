/*================================================================================

    Copyright 2019 Tektronix, Inc.                      
    See www.tek.com/sample-license for licensing terms. 

================================================================================*/
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Ivi.Visa.Interop;
using System.Diagnostics;       // needed for stopwatch usage

namespace My_First_C_Sharp_Project_2
{
    class My_First_C_Sharp_Project
    {
        static Boolean echo_command = true;

        static void Main(string[] args)
        {
            // Create a Stopwatch object and capture the program start time from the system.
            Stopwatch myStpWtch = new Stopwatch();
            myStpWtch.Start();

            /*
             *  First step: Open the resource manager and assigns it to an object variable
             */
            ResourceManager resource_manager = new ResourceManager();

            /*
             *  Second step: Create a FormattedIO488 object to represent the instrument 
             *  you intend to communicate with, and connect to it.
             */
            FormattedIO488 my_instrument = new Ivi.Visa.Interop.FormattedIO488();

            string instrument_id_string = "GPIB0::18::INSTR";
            Int16 timeout = 20000;  // define the timeout in terms of milliseconds
            // Instrument ID String examples...
            //       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
            //       USB -> USB0::0x05E6::0x2450::01419962::INSTR
            //       GPIB -> GPIB0::16::INSTR
            //       Serial -> ASRL4::INSTR
            Connect_To_Instrument(ref resource_manager, ref my_instrument, instrument_id_string, timeout);

            /*
             *  Third step: Issue commands to the instrument and receive responses to 
             *  be printed to the program console window.
             */
            for (int i = 0; i < 10; i++)
            {
                Console.WriteLine(Instrument_Query(my_instrument, "*IDN?"));
            }

            /*
             *  Fourth step: Close the instrument object and release it for use
             *  by other programs.
             */
            Disconnect_From_Instrument(ref my_instrument);
            
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
            char k = Console.ReadKey().KeyChar;
        }

        static void Connect_To_Instrument(ref ResourceManager resource_manager, ref FormattedIO488 instrument_control_object, string instrument_id_string, Int16 timeout)
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
            instrument_control_object.IO = (IMessage)resource_manager.Open(instrument_id_string, AccessMode.NO_LOCK, 20000);
            // Instrument ID String examples...
            //       LAN -> TCPIP0::134.63.71.209::inst0::INSTR
            //       USB -> USB0::0x05E6::0x2450::01419962::INSTR
            //       GPIB -> GPIB0::16::INSTR
            //       Serial -> ASRL4::INSTR
            instrument_control_object.IO.Clear();
            int myTO = instrument_control_object.IO.Timeout;
            instrument_control_object.IO.Timeout = timeout;
            myTO = instrument_control_object.IO.Timeout;
            instrument_control_object.IO.TerminationCharacterEnabled = true;
            instrument_control_object.IO.TerminationCharacter = 0x0A;
            return;
        }

        static void Disconnect_From_Instrument(ref FormattedIO488 instrument_control_object)
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
            instrument_control_object.IO.Close();
            return;
        }

        static void Instrument_Write(FormattedIO488 instrument_control_object, string command)
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
            instrument_control_object.WriteString(command + "\n");
            return;
        }

        static string Instrument_Read(FormattedIO488 instrument_control_object)
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
            return instrument_control_object.ReadString();
        }

        static string Instrument_Query(FormattedIO488 instrument_control_object, string command)
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
            Instrument_Write(instrument_control_object, command);
            return Instrument_Read(instrument_control_object);
        }
    }
}
