using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using KeithleyInstruments.KeithleyDMM7510.Interop;

namespace Sampling_Temperature_TC_at_Set_Time_Interval
{
    class Sampling_Temperature_TC_at_Set_Time_Interval
    {
        static void Main(string[] args)
        {
            KeithleyDMM7510 system_dmm = new KeithleyDMM7510();

            system_dmm.Initialize("USB0::0x05E6::0x7510::04345311::INSTR", true, true, "Simulate=false");
            system_dmm.System.IOTimeout = 60000;

            // Set the measure function to temperature; configure for TC measurements, type K, simulated reference junction, and open lead detection enabled
            system_dmm.Function = KeithleyDMM7510FunctionEnum.KeithleyDMM7510FunctionTemperature;
            system_dmm.Measurement.Configuration.Temperature.TransducerType = KeithleyDMM7510TransducerTypeEnum.KeithleyDMM7510TransducerTypeThermocouple;
            system_dmm.Measurement.Configuration.Temperature.ThermocoupleType = KeithleyDMM7510ThermocoupleTypeEnum.KeithleyDMM7510ThermocoupleTypeK;
            system_dmm.Measurement.Configuration.Temperature.ThermocoupleSimulatedRefJunction = 23.0;
            system_dmm.Measurement.Configuration.Temperature.Unit = KeithleyDMM7510TemperatureUnitEnum.KeithleyDMM7510TemperatureUnitCelsius;
            system_dmm.Measurement.Configuration.OpenDetector[KeithleyDMM7510OpenDetectorFunctionsEnum.KeithleyDMM7510OpenDetectorFunctionsTemperature] = true;

            system_dmm.Measurement.Configuration.NPLC[KeithleyDMM7510NPLCFunctionsEnum.KeithleyDMM7510NPLCFunctionsTemperature] = 1.0;

            // Duration Loop... sample for 60s at 1s intervals
            system_dmm.Trigger.Model.LoadDurationLoop(60.0, 1.0, "defbuffer1", KeithleyDMM7510TriggerReadingBlockEnum.KeithleyDMM7510TriggerReadingBlockActive);

            // Trigger the acquisition
            system_dmm.Trigger.Initiate();

            // Loop until the model is no longer running, indicating that the reading is in the buffer
            String model_state = system_dmm.Trigger.Model.State.ToUpper();
            int buffer_actual_count = 0;
            int extracted_count = 0;
            double [] reading_data = new double[1];
            double[] time_data = new double[1];
            while (model_state.Contains("RUNNING"))
            {
                System.Threading.Thread.Sleep(1000);
                model_state = system_dmm.Trigger.Model.State.ToUpper();
                buffer_actual_count = system_dmm.Buffer.Actual["defbuffer1"];
                while (buffer_actual_count > extracted_count)
                {
                    extracted_count += 1;
                    reading_data = system_dmm.Buffer.GetDoubleData(extracted_count, extracted_count, "defbuffer1", KeithleyDMM7510BufferFormatElementEnum.KeithleyDMM7510BufferFormatElementReading);
                    time_data = system_dmm.Buffer.GetDoubleData(extracted_count, extracted_count, "defbuffer1", KeithleyDMM7510BufferFormatElementEnum.KeithleyDMM7510BufferFormatElementRelative);
                    Console.WriteLine("Reading {0}: {1}\tTime: {2}", extracted_count, reading_data[0], time_data[0]);
                }
            }


            // Build the trgger model.... sample for 60s at 1s intervals
            system_dmm.Trigger.Model.Reset();
            system_dmm.Trigger.Model.Block.BufferClear(1, "defbuffer1");
            system_dmm.Trigger.Model.Block.ConstantDelay(2, 1.0);
            system_dmm.Trigger.Model.Block.Measure(3, "defbuffer1");
            system_dmm.Trigger.Model.Block.BranchCounter(4, 60, 2.0);

            // Trigger the acquisition
            system_dmm.Trigger.Initiate();

            // Loop until the model is no longer running, indicating that the reading is in the buffer
            model_state = system_dmm.Trigger.Model.State.ToUpper();
            extracted_count = 0;
            while (model_state.Contains("RUNNING"))
            {
                System.Threading.Thread.Sleep(1000);
                model_state = system_dmm.Trigger.Model.State.ToUpper();
                buffer_actual_count = system_dmm.Buffer.Actual["defbuffer1"];
                while (buffer_actual_count > extracted_count)
                {
                    extracted_count += 1;
                    reading_data = system_dmm.Buffer.GetDoubleData(extracted_count, extracted_count, "defbuffer1", KeithleyDMM7510BufferFormatElementEnum.KeithleyDMM7510BufferFormatElementReading);
                    time_data = system_dmm.Buffer.GetDoubleData(extracted_count, extracted_count, "defbuffer1", KeithleyDMM7510BufferFormatElementEnum.KeithleyDMM7510BufferFormatElementRelative);
                    Console.WriteLine("Reading {0}: {1}\tTime: {2}", extracted_count, reading_data[0], time_data[0]);
                }
            }

            // Close the driver session
            system_dmm.Close();
        }
    }
}
