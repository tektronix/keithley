using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using KeithleyInstruments.KeithleyDMM7510.Interop;

namespace Measure_DCV_with_High_Accuracy
{
    class Measure_DCV_with_High_Accuracy
    {
        static void Main(string[] args)
        {
            KeithleyDMM7510 system_dmm = new KeithleyDMM7510();

            system_dmm.Initialize("USB0::0x05E6::0x7510::04345311::INSTR", true, true, "Simulate=false");
            system_dmm.System.IOTimeout = 60000;

            // Set the measure function to DCV; fix the range to 10V; apply a 10 PLC aperture
            system_dmm.Function = KeithleyDMM7510FunctionEnum.KeithleyDMM7510FunctionVoltageDC;
            system_dmm.Measurement.Configuration.Range[KeithleyDMM7510FunctionsWithRangeEnum.KeithleyDMM7510FunctionsWithRangeVoltageDC] = 10.0;
            system_dmm.Measurement.Configuration.NPLC[KeithleyDMM7510NPLCFunctionsEnum.KeithleyDMM7510NPLCFunctionsVoltageDC] = 10.0;

            // Ensure the output impedance is set to Auto (> 10GΩ) and auto zero is enabled
            system_dmm.Measurement.Configuration.DCVoltInputImpedance = KeithleyDMM7510InputImpedanceEnum.KeithleyDMM7510InputImpedanceAuto;
            system_dmm.Measurement.Configuration.AutoZeroEnabled[KeithleyDMM7510FunctionEnum.KeithleyDMM7510FunctionVoltageDC] = true;

            // Configure and enabele the filter
            system_dmm.Measurement.Configuration.Filter.Type[KeithleyDMM7510Function2Enum.KeithleyDMM7510Function2VoltageDC] = KeithleyDMM7510MeasurementFilterTypeEnum.KeithleyDMM7510MeasurementFilterTypeRepeat;
            system_dmm.Measurement.Configuration.Filter.Count[KeithleyDMM7510Function2Enum.KeithleyDMM7510Function2VoltageDC] = 100;
            system_dmm.Measurement.Configuration.Filter.State[KeithleyDMM7510Function2Enum.KeithleyDMM7510Function2VoltageDC] = true;

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
