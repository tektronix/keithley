"""
Keithley PyVisa example code that connects to 6221 + 2182/2182A instrument
stack and runs differential conductance measurements with user parameters from GUI.

Set INSTRUMENT_RESOURCE_STRING equal to your instrument's resource string, found using the
    VISA Interactive Control program.

    Copyright 2023 Tektronix, Inc.                      
    See www.tek.com/sample-license for licensing terms.

"""
import time
import datetime
import textwrap
import math
from instrcomms import Communications
from instrgui import InstrumentOption, open_gui_return_input

DEBUG_PRINT_COMMANDS = False

SAVED_PARAMETERS_FILENAME = "differential_conductance_parameters.txt"

INSTRUMET_RESROUCE_STRING = "GPIB0::15::INSTR"


def experiment_setup(instrument, parameters, start_time):
    """Set up instrument parameters for differential conductance"""
    # Differential Conductance Settings
    delta = float(parameters["delta"])
    filter_on = parameters["filter_on"]
    filter_count = int(parameters["filter_count"])
    voltage_range = float(parameters["voltage_range"])
    delay = float(parameters["delay"])
    integration_nplcs = float(parameters["integration_NPLCs"])
    volt_compliance = float(parameters["volt_compliance"])
    guarding_on = parameters["guarding_on"]
    low_to_earth_on = parameters["lowToEarth_on"]
    start_current = float(parameters["start_current"])
    stop_current = float(parameters["stop_current"])
    step = float(parameters["step"])

    # Check that we have valid parameters
    invalid_parameters = False
    if delta < 0 or delta > 105e-3:
        print("Delta must be in range [0, 105e-3]")
        invalid_parameters = True
    if (filter_count < 2 or filter_count > 300) and filter_on:
        print("If filter is enabled, filter count must be in range [2, 300]")
        invalid_parameters = True
    if voltage_range not in [0.01, 0.1, 1, 10 or 100]:
        print("Voltage range must be in 0.01, 0.1, 1, 10, or 100")
        invalid_parameters = True
    if delay < 1e-3 or delay > 9999.999:
        print("Delay must be in range [1e-3, 9999.999]")
        invalid_parameters = True
    if integration_nplcs < 0.01 or integration_nplcs > 60:
        print("Integration NPLCs must be in range [0.01, 60] (60Hz system)")
        invalid_parameters = True
    if volt_compliance < 0.1 or volt_compliance > 105:
        print("Voltage compliance must be in range [0.1, 105]")
        invalid_parameters = True
    if start_current < -105e-3 or start_current > 105e-3:
        print("Start current must be in range [-105e-3, 105e-3]")
        invalid_parameters = True
    if stop_current < -105e-3 or stop_current > 105e-3:
        print("Stop current must be in range [-105e-3, 105e-3]")
        invalid_parameters = True
    if start_current == stop_current:
        print("Stop and start current cannot be the same")
        invalid_parameters = True
    if step < 0 or step > 105e-3:
        print("Step must be in range [0, 105e-3]")
        invalid_parameters = True

    if invalid_parameters:
        instrument.disconnect()
        stop_time = time.time()  # Stop the timer...
        print(f"Elapsed Time: {(stop_time - start_time):0.3f}s")

        exit()

    # Abort tests in the other modes
    instrument.write("SOUR:SWE:ABOR")
    instrument.write("SOUR:WAVE:ABOR")

    instrument.write("*RST")  # Reset the 6221
    time.sleep(2)  # Wait 2 seconds

    # Use Guard?
    if guarding_on:
        instrument.write("OUTP:ISH GUARD")
    else:
        instrument.write("OUTP:ISH OLOW")

    # Low to Earth?
    if low_to_earth_on:
        instrument.write("OUTP:LTE ON")
    else:
        instrument.write("OUTP:LTE OFF")

    time.sleep(0.5)

    instrument.write("FORM:ELEM READ,SOUR,AVOL,TST")  # Set readings to be returned
    instrument.write(f"SOUR:DCON:STAR {start_current}")  # Set start current
    time.sleep(0.1)
    instrument.write(f"SOUR:DCON:STOP {stop_current}")  # Set stop current
    instrument.write(f"SOUR:DCON:STEP {step}")  # Set current step size
    instrument.write(f"SOUR:DCON:DEL {delay}")  # Set step delay
    instrument.write(f"SOUR:DCON:DELT {abs(delta)}")  # Set delta value
    instrument.write(f"SOUR:CURR:COMP {volt_compliance}")  # Set voltage compliance
    instrument.write("SYST:COMM:SERIAL:SEND \042*RST\042")  # Reset the 2182A
    time.sleep(3)
    instrument.write(
        f"SYST:COMM:SERIAL:SEND \042:SENS:VOLT:NPLC {integration_nplcs}\042"
    )  # Set NPLC for 2182A
    time.sleep(2)
    instrument.write(
        f"SYST:COMM:SERIAL:SEND \042:SENS:VOLT:RANG {voltage_range}\042"
    )  # Set voltage measure range
    instrument.write("SENS:AVER:WIND 0")  # Set averaging window
    time.sleep(0.5)
    if filter_on:  # Set filter
        instrument.write("SENS:AVER:STAT 1")  # Turn on filtering
        instrument.write(
            "SENS:AVER:TCON REP"
        )  # Repeating filter (No other filter is valid in diffcond)
        cmd = f"SENS:AVER:COUN {filter_count}"  # Set filter count
        instrument.write(cmd)
    else:
        instrument.write("SENS:AVER:STAT 0")  # No filter
    time.sleep(2)
    instrument.write("UNIT SIEM")  # Set units


def read_data(instrument, num_readings: int):
    """Wait for instruments to finish measuring and read data"""
    # Wait for sweep to finish
    sweep_done = False
    data = []
    while not sweep_done:
        time.sleep(1)
        oper_byte_status = instrument.query(
            "STAT:OPER:EVEN?"
        )  # Check the event register
        oper_byte_status = int(oper_byte_status)  # Convert decimal string to int
        sweep_done = oper_byte_status & (1 << 1)  # bit mask to check if sweep done

    # Get the measurements 1000 at a time
    for i in range((num_readings - 1) // 1000 + 1):
        if num_readings - i * 1000 > 1000:  # if more than 1000 readings left
            data_sel_count = 1000
        else:
            data_sel_count = num_readings - i * 1000

        # Transfer readings over GPIB
        raw_data = instrument.query(f"TRAC:DATA:SEL? {i * 1000},{data_sel_count}")
        raw_data = raw_data.split(",")
        data.extend(raw_data)

    return data


def write_csv(data, csv_path: str):
    """Write data to csv file"""
    # Create and open file
    with open(csv_path, "a+", encoding="utf-8") as csv_file:
        # Write the measurements to the CSV file
        csv_file.write("Reading, Timestamp, Source Current, Average Voltage\n")

        # We queried 4 values per reading, so iterate over groups of 4 elements
        for i in range(0, len(data), 4):
            v_reading = data[i]
            time_stamp = data[i + 1]
            source_current = data[i + 2]
            reading_number = data[i + 3]
            csv_file.write(
                f"{v_reading}, {time_stamp}, {source_current}, {reading_number}\n"
            )
            csv_file.flush()


def main():
    """Main function. Connect to instrument, get test params through GUI, run test, save data."""
    start_time = time.time()  # Start the timer...
    inst_6221 = Communications("GPIB0::15::INSTR")
    inst_6221.connect()

    instrument_options = [
        InstrumentOption(
            "Start Current",
            "start_current",
            tooltip="Must be in range [-105e-3, 105e-3]",
        ),
        InstrumentOption(
            "Stop Current",
            "stop_current",
            "0.001",
            tooltip="Must be in range [-105e-3, 105e-3]",
        ),
        InstrumentOption(
            "Step", "step", "1e-5", tooltip="Must be in range [0, 105e-3]"
        ),
        InstrumentOption(
            "Delta", "delta", "1e-5", tooltip="Must be in range [0, 105e-3]"
        ),
        InstrumentOption("Use Filter", "filter_on", False, True),
        InstrumentOption(
            "Filter Count",
            "filter_count",
            "2",
            tooltip="If filter is enabled, filter count must be in range [2, 300]",
        ),
        InstrumentOption(
            "Voltage Measure Range",
            "voltage_range",
            "0.1",
            tooltip="Must be 0.01, 0.1, 1, 10, or 100",
        ),
        InstrumentOption(
            "Delay", "delay", "0.5", tooltip="Must be in range [1e-3, 9999.999]"
        ),
        InstrumentOption(
            "NPLCs",
            "integration_NPLCs",
            "5",
            tooltip="Integration NPLCs must be in range [0.01, 60] or [0.01, 50], \n"
            "depending respectively on if instrument is connected to 60 or 50 Hz mains",
        ),
        InstrumentOption(
            "Voltage Compliance",
            "volt_compliance",
            "10",
            tooltip="Must be in range [0.1, 105]",
        ),
        InstrumentOption("Use Guard", "guarding_on", False, True),
        InstrumentOption("Use Low to Earth", "lowToEarth_on", False, True),
    ]

    messages = (
        "Test Setup: Connect the 6221 Current Source and 2182 Nanovoltmeter "
        "through their RS-232 ports and connect the 6221 to this PC via GPIB adapter."
    )

    # Wrap messages so each line is no more than 40 characters.
    messages = "\n".join(textwrap.wrap(messages, 40))

    parameters = open_gui_return_input(
        instrument_options, messages, SAVED_PARAMETERS_FILENAME
    )

    # If user clicks close button on app window without clicking run params are invalid
    if list(parameters.values())[0] is None:
        print("Application window closed without starting test; aborting")
        inst_6221.disconnect()
        stop_time = time.time()  # Stop the timer...

        print(f"Elapsed Time: {(stop_time - start_time):0.3f}s")

        exit()

    start_current = float(parameters["start_current"])
    stop_current = float(parameters["stop_current"])
    step = float(parameters["step"])
    num_readings = math.ceil((stop_current - start_current) / step)

    experiment_setup(inst_6221, parameters, start_time)

    inst_6221.write("SOUR:DCON:ARM")  # Arm the test
    time.sleep(3)
    inst_6221.write("INIT:IMM")  # Start the test

    data = read_data(inst_6221, num_readings)

    date = datetime.datetime.now().strftime("%Y-%m-%d %H-%M-%S")
    csv_path = f".\\Differential_Conductance {date}.csv"
    write_csv(data, csv_path)

    inst_6221.write(
        ":SOUR:SWE:ABORT"
    )  # Abort the test to prevent the output being left on

    inst_6221.disconnect()

    stop_time = time.time()  # Stop the timer...

    # Notify the user of completion and the data streaming rate achieved.
    print("done")
    print(f"Elapsed Time: {(stop_time - start_time):0.3f}s")

    exit()


if __name__ == "__main__":
    main()
