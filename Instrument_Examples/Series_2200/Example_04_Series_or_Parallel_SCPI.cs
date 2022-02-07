/*================================================================================

    Copyright 2019 Tektronix, Inc.                      
    See www.tek.com/sample-license for licensing terms. 

================================================================================*/

/* ================================================================================

       This example shows how to place the channels of the 2230 in series
       or parallel configuration to achieve higher voltage or higher
       current ouput, respectively.

================================================================================ */

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using NationalInstruments.Visa;

namespace Example03_Series_Parallel_SCPI
{
    class Series_Parallel_SCPI
    {
        static void Main(string[] args)
        {
            ResourceManager rmSession = new ResourceManager();
            MessageBasedSession mbSession = null; //Used to pass am empty object for mbsession(18)
            String instrument_id_string = "USB0::0x05E6::0x2230::9010101::INSTR"; // GPIB0::26::INSTR    USB0::0x05E6::0x2602::4403417::INSTR , model 
            mbSession = (MessageBasedSession)rmSession.Open(instrument_id_string, Ivi.Visa.AccessModes.None, 2000);//Opens
            // Do instrument ID query
            mbSession.RawIO.Write("*IDN?");//Writes to 2230G
            string my_id = "";
            my_id = mbSession.RawIO.ReadString().Trim();//Reads from 2230G/ Takes the instrument id
            Console.WriteLine("Instrument ID: {0}", my_id);

            mbSession.RawIO.Write("*RST"); //Reset
            mbSession.RawIO.Write("SYST:REM"); //Switches instrument to remote control mode 

            ////////////////Uncomment One of These Lines////////////////////////////////
            //mbSession.RawIO.Write("INST:NSEL 1"); //Use this line for Channel 1 connection
           mbSession.RawIO.Write("INST:COM:SER"); //Use this line for Series Connection
            //mbSession.RawIO.Write("INST:COM:PARA"); //Use this line for Parallel Connection

            /////////////////////////////////////////////////////////////////////////////////
            mbSession.RawIO.Write("VOLT 0.0");//Output level
            mbSession.RawIO.Write("CURR 1.0"); //Current limit
            mbSession.RawIO.Write("OUTP 1");//Turns on output

            double current = 0.35; //Constant variable, no change 
            double set_voltage = .5;
            for (int i = 0; i < 10; i++)
            {
                mbSession.RawIO.Write("VOLT " + set_voltage.ToString());  //Add space after 'T' to avoid errors 
                Console.WriteLine("Set Voltage: {0}", set_voltage);
                mbSession.RawIO.Write("MEAS:VOLT?");//Reads voltage
                double measured_voltage = Convert.ToDouble(mbSession.RawIO.ReadString());//Converts & sets variable
                Console.WriteLine("Measured Voltage: {0}", measured_voltage);
                mbSession.RawIO.Write("MEAS:CURR?");//Reads current
                double measured_current = Convert.ToDouble(mbSession.RawIO.ReadString());//Converts & sets variable
                Console.WriteLine("Set Current: {0}", current);
                Console.WriteLine("Measured Current: {0}", measured_current.ToString());
                set_voltage += .5;

            }


            mbSession.RawIO.Write("OUTP 0");//Turns off output
            mbSession.Dispose();//Cleans object




        }
    }
}

