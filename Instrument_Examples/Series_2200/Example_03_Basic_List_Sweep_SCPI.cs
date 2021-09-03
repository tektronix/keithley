//This example shows how to set and measure voltage and current outputs using IVI, as well when using more than one channel for a series and parallel connection
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Ivi.Driver.Interop;
using KeithleyInstruments.Keithley2230.Interop;


namespace Example02_Basic_List_Sweep_IVI
{
    class Basic_List_Sweep_IVI
    {
        static void Main(string[] args)
        {

            Keithley2230 driver = new Keithley2230Class();  
            driver.Initialize("USB0::0x05E6::0x2230::9010101::INSTR", false, true, "");
            driver.System.ControlMode = Keithley2230ControlModeEnum.Keithley2230ControlModeRemote;
            driver.OutputChannels.Item["OutputChannel1"].VoltageLevel = 0.5;
            driver.OutputChannels.Item["OutputChannel1"].CurrentLimit = 1.0;
           
            
            //driver.System.SCPIVersion.AsParallel(); //Use this line if connection is parallel
            
            
            driver.OutputChannels.Item["OutputChannel1"].State = true; //Turns on
           

      
            for (int i = 0; i < 10; i++)
            {

                Console.WriteLine("Voltage: " + driver.OutputChannels.Item["OutputChannel1"].VoltageLevel);
                Console.WriteLine("Current: " + driver.OutputChannels.Item["OutputChannel1"].CurrentLimit);
                Console.WriteLine("Measured Voltage: " + (driver.OutputChannels.get_Item("OutputChannel1").Measure(Keithley2230MeasurementTypeEnum.Keithley2230MeasurementTypeVoltage).ToString()));
                Console.WriteLine("Measured Current: " + (driver.OutputChannels.get_Item("OutputChannel1").Measure(Keithley2230MeasurementTypeEnum.Keithley2230MeasurementTypeCurrent).ToString()));
                driver.OutputChannels.Item["OutputChannel1"].VoltageLevel += 0.5;
            }


            driver.OutputChannels.Item["OutputChannel1"].State = false; //Turns off 

            driver.Close();


        }
    }
}
