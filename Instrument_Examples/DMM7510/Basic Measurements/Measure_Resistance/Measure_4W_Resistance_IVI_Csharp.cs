using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using KeithleyInstruments.KeithleyDMM7510.Interop;

namespace Measure_4W_Resistance
{
    class Measure_4W_Resistance
    {
        static void Main(string[] args)
        {
            KeithleyDMM7510 system_dmm = new KeithleyDMM7510();

            system_dmm.Initialize("USB0::0x05E6::0x7510::04345311::INSTR", true, true, "Simulate=false");
            system_dmm.System.IOTimeout = 60000;

            // Set the measure function to 4-wire resistance; set to auto range; apply a 1 PLC aperture
            system_dmm.Function = KeithleyDMM7510FunctionEnum.KeithleyDMM7510Function4WireResistance;
            system_dmm.Measurement.Configuration.AutoRange[KeithleyDMM7510FunctionsWithRangeEnum.KeithleyDMM7510FunctionsWithRange4WireResistance] = true;
            system_dmm.Measurement.Configuration.NPLC[KeithleyDMM7510NPLCFunctionsEnum.KeithleyDMM7510NPLCFunctions4WireResistance] = 1.0;

            system_dmm.Measurement.Configuration.OffsetCompensationEnabled[KeithleyDMM7510Function5Enum.KeithleyDMM7510Function54WireResistance] = false;
            system_dmm.Measurement.Configuration.OpenDetector[KeithleyDMM7510OpenDetectorFunctionsEnum.KeithleyDMM7510OpenDetectorFunctions4WireResistance] = true;
            system_dmm.Measurement.Configuration.FourWireDryCircuitState = false;


            // Capture the reading which depends on the timeout value being elevated to 60s to work without actually timing out
            string mymeas = system_dmm.Measurement.Read("defbuffer1", "READ");


            // Now dial back the timeout interval and monitor the trigger model to determine when the reading can be polled.
            // Build a simple trigger model
            system_dmm.Trigger.Model.Block.BufferClear(1, "defbuffer1");
            system_dmm.Trigger.Model.Block.Measure(2, "defbuffer1");

            // Trigger the acquisition
            system_dmm.Trigger.Initiate();

            // Loop until the model is no longer running, indicating that the reading is in the buffer
            String model_state = system_dmm.Trigger.Model.State.ToUpper();
            while (model_state.Contains("RUNNING"))
            {
                System.Threading.Thread.Sleep(250);
                model_state = system_dmm.Trigger.Model.State.ToUpper();
            }

            // Extract the reading
            mymeas = system_dmm.Buffer.Fetch("defbuffer1", "READ");

            // Close the driver session
            system_dmm.Close();
        }
    }
}
