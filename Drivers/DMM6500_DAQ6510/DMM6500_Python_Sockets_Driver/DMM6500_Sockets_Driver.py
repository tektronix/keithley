import socket
import struct
import math
import time
from enum import Enum

# ======================================================================
#      DEFINE THE DMM CLASS INSTANCE HERE
# ======================================================================
class DMM6500:
    def __init__(self):
        self.echoCmd = 1
        self.my_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.stub_comms = 0

        self.measurement_functions = ["dmm.FUNC_DC_VOLTAGE",
                             "dmm.FUNC_DC_CURRENT",
                             "dmm.FUNC_AC_VOLTAGE",
                             "dmm.FUNC_AC_CURRENT",
                             "dmm.FUNC_RESISTANCE",
                             "dmm.FUNC_4W_RESISTANCE",
                             "dmm.FUNC_DIODE",
                             "dmm.FUNC_CAPACITANCE",
                             "dmm.FUNC_TEMPERATURE",
                             "dmm.FUNC_CONTINUITY",
                             "dmm.FUNC_ACV_FREQUENCY",
                             "dmm.FUNC_ACV_PERIOD",
                             "dmm.FUNC_DCV_RATIO",
                             "dmm.FUNC_DIGITIZE_VOLTAGE",
                             "dmm.FUNC_DIGITIZE_CURRENT"]
        
    # ======================================================================
    #      DEFINE INSTRUMENT CONNECTION AND COMMUNICATIONS FUNCTIONS HERE
    # ======================================================================
    def Connect(self, my_address, my_port, timeout, do_reset, do_id_query):
        if self.stub_comms == 0:
            self.my_socket.connect((my_address, my_port)) # input to connect must be a tuple
            self.my_socket.settimeout(timeout)
        if do_reset == 1:
            self.Reset()
            self.SendCmd("waitcomplete()")
        if do_id_query == 1:
            tmpId = self.IDQuery()
            return tmpId
        else:
            return

    def Disconnect(self):
        if self.stub_comms == 0:
            self.my_socket.close()
        return

    def SendCmd(self, cmd):
        if self.echoCmd == 1:
            print(cmd)
        cmd = "{0}\n".format(cmd)
        if self.stub_comms == 0:
            self.my_socket.send(cmd.encode())
        return

    def QueryCmd(self, cmd, rcv_size):
        self.SendCmd(cmd)
        time.sleep(0.1)
        rcv_string = ""
        if self.stub_comms == 0:
            rcv_string = self.my_socket.recv(rcv_size).decode()
        return rcv_string

    # ======================================================================
    #      DEFINE BASIC FUNCTIONS HERE
    # ======================================================================        
    def Reset(self):
        snd_buffer = "reset()"
        self.SendCmd(snd_buffer)
        
    def IDQuery(self):
        snd_buffer = "*IDN?"
        return self.QueryCmd(snd_buffer, 64)

    def LoadScriptFile(self, file_path_and_name):
        # This function opens the functions.lua file in the same directory as
        # the Python script and trasfers its contents to the DMM's internal
        # memory. All the functions defined in the file are callable by the
        # controlling program. 
        func_file = open(file_path_and_name, "r")
        contents = func_file.read()
        func_file.close()

        cmd = "if loadfuncs ~= nil then script.delete('loadfuncs') end"
        self.SendCmd(cmd)

        cmd = "loadscript loadfuncs\n{0}\nendscript".format(contents)
        self.SendCmd(cmd)
        cmd = "loadfuncs()"
        print(self.QueryCmd(cmd, 32))
        return

    # ======================================================================
    #      DEFINE MEASUREMENT FUNCTIONS HERE
    # ======================================================================
    def configure_measurement(self, measure_function=None, measure_range=None, use_nplc=None, integration_time=None, channel_list=None):
        if channel_list is None:
            # Configure as front terminal, non-scanning
            # Set the measure function
            cmd = "dmm.measure.func = {0}".format(self.measurement_functions[measure_function.value])
            self.SendCmd(cmd)
            
            # Set the range or auto
            if measure_range is not None:
                if measure_range == 0:
                    # Apply auto ranging
                    self.SendCmd("dmm.measure.autorange = dmm.ON")
                else:
                    # Set the fixed range
                    self.SendCmd("dmm.measure.autorange = dmm.OFF")
                    self.SendCmd("dmm.measure.range = {}".format(measure_range))
                    
            # Apply the aperture or NPLC
            if use_nplc is not None:
                if use_nplc == 1:
                    # Program integration time with NPLC
                    self.SendCmd("dmm.measure.nplc = {}".format(integration_time))
                else:
                    # Program integration time with Aperture
                    self.SendCmd("dmm.measure.aperture = {}".format(integration_time))
        else:
            # Configure for rear terminal scanning
            # Set the measure function
            cmd = "channel.setdmm(\"{0}\", dmm.ATTR_MEAS_FUNCTION, {1})".format(channel_list, self.measurement_functions[measure_function.value])
            self.SendCmd(cmd)
            
            # Set the range or auto
            if measure_range is not None:
                if measure_range == 0:
                    # Apply auto ranging
                    self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_MEAS_RANGE_AUTO, dmm.ON)".format(channel_list))
                else:
                    # Set the fixed range
                    self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_MEAS_RANGE_AUTO, dmm.OFF)".format(channel_list))
                    self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_MEAS_RANGE, {1})".format(channel_list, measure_range))
                    
            # Apply the aperture or NPLC
            if use_nplc is not None:
                if use_nplc == 1:
                    # Program integration time with NPLC
                    self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_MEAS_NPLC, {1})".format(channel_list, integration_time))
                else:
                    # Program integration time with Aperture
                    self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_MEAS_APERTURE, {1})".format(channel_list, integration_time))
        return

    def configure_digitize(self, digitize_function=None, digitize_range=None, sample_rate=None, sample_count=None, channel_list=None):
        if channel_list is None:
            # Configure as front terminal, non-scanning
            # Set the measure function
            cmd = "dmm.digitize.func = {0}".format(self.measurement_functions[digitize_function.value])
            self.SendCmd(cmd)
            
            # Set the range or auto
            if digitize_range is not None:
                # Set the fixed range
                self.SendCmd("dmm.digitize.range = {}".format(digitize_range))
                    
            # Set the sample rate
            if sample_rate is not None:
                self.SendCmd("dmm.digitize.samplerate = {}".format(sample_rate))

            # Set the sample count
            if sample_rate is not None:
                self.SendCmd("dmm.digitize.count = {}".format(sample_count))
        else:
            # Configure for rear terminal scanning
            # Set the measure function
            cmd = "channel.setdmm(\"{0}\", dmm.ATTR_DIGI_FUNCTION, {1})".format(channel_list,
                                                                                self.measurement_functions[digitize_function.value])
            self.SendCmd(cmd)
            
            # Set the range or auto
            if digitize_range is not None:
                # Set the fixed range
                self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_DIGI_RANGE, {1})".format(channel_list, digitize_range))
                    
            # Set the sample rate
            if sample_rate is not None:
                # Program integration time with Aperture
                self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_DIGI_SAMPLE_RATE, {1})".format(channel_list, sample_rate))

            # Set the sample count
            if sample_rate is not None:
                self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_DIGI_COUNT, {1})".format(channel_list, sample_count))
        return

    def configure_measurement_additional(self, auto_delay=None, auto_zero=None, line_sync=None, measure_unit=None, channel_list=None):
        
        return

    def configure_filter(self, filter_enable=None, filter_type=None, filter_count=None, filter_window=None, channel_list=None):
        if channel_list is None:
            # Configure as front terminal, non-scanning
            # Set the filter state
            if filter_enable is not None:
                self.SendCmd("dmm.measure.filter.enable = {0}".format(filter_enable))
            
            # Set the filter type
            if filter_type is not None:
                if filter_type == FilterType.REPEAT:
                    self.SendCmd("dmm.measure.filter.type = dmm.FILTER_REPEAT_AVG")
                elif filter_type == FilterType.MOVE:
                    self.SendCmd("dmm.measure.filter.type = dmm.FILTER_MOVING_AVG")
                    
            # Set the filter count
            if filter_count is not None:
                self.SendCmd("dmm.measure.filter.count = {0}".format(filter_count))

            # Set the filter window
            if filter_window is not None:
                self.SendCmd("dmm.measure.filter.window = {0}".format(filter_window))
        else:
            # Configure for rear terminal scanning
            # Set the filter state
            if filter_enable is not None:
                self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_MEAS_FILTER_ENABLE, {1})".format(channel_list, filter_enable))
            
            # Set the filter type
            if filter_type is not None:
                if filter_type == FilterType.REPEAT:
                    self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_MEAS_FILTER_TYPE, dmm.FILTER_REPEAT_AVG)")
                elif filter_type == FilterType.MOVE:
                    self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_MEAS_FILTER_TYPE, dmm.FILTER_MOVING_AVG)")
                    
            # Set the filter count
            if filter_count is not None:
                self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_MEAS_FILTER_COUNT, {1})".format(channel_list, filter_count))

            # Set the filter window
            if filter_window is not None:
                self.SendCmd("channel.setdmm(\"{0}\", dmm.ATTR_MEAS_FILTER_WINDOW, {1})".format(channel_list, filter_window))
        return

    def configure_dc_voltage(self, input_impedance=None, relative_offset=None, db_reference=None, channel_list=None):
        return

    def configure_dc_current(self, channel_list=None):  # do we even bother with this???
        return

    def configure_ac_voltage(self, detector_bandwidth=None, db_reference=None, channel_list=None):
        return

    def configure_ac_current(self, detector_bandwidth=None, channel_list=None):
        return

    def configure_2w_resistance(self, channel_list=None):  # do we even bother with this???
        return

    def configure_4w_resistance(self, enable_offset_compensation=None, enable_open_lead_detection=None, channel_list=None):
        return

    def configure_diode(self, bias_level=None, limit_audible=None, limit_high=None, limit_low=None, channel_list=None):
        return
    
    def configure_capacitance(self, channel_list=None):  # do we even bother with this???
        return

    def configure_temperature(self, transducer_type=None, measure_unit=None, channel_list=None):
        return
    
    def configure_thermocouple(self, thermocouple_type=None, reference_junction=None, simulated_junction_value=None, channel_list=None):
        return

    def configure_temperature_thermistor(self, thermistor_type=None, measure_unit=None, channel_list=None):
        return

    def configure_temperature_rtd(self, rtd_type=None, enable_offset_compensation=None, enable_open_lead_detection=None, alpha=None, beta=None, delta=None, zero=None, channel_list=None):
        return
    
    def configure_continuity(self, limit_audible=None, limit_high=None, line_sync=None, channel_list=None):
        return
    
    def configure_frequency(self, threshold_autorange=None, threshold_range=None, channel_list=None):
        return
    
    def configure_period(self, threshold_autorange=None, threshold_range=None, channel_list=None):
        return
    
    def convigure_dcv_ratio(self, sense_range=None, relative_offset=None, channel_list=None):
        return
    
    def configure_digitize(self, relative_offset, relative_enable, channel_list=None):
        return

    def configure_math(self, math_enable=None, math_format=None, m_scale=None, b_offset=None, math_percent=None, channel_list=None):
        return

    def configure_limits(self, limits_enable=None, limits_audible=None, high_1=None, low_1=None, high_2=None, low_2=None, auto_clear_enable=None, channel_list=None):
        return

    def channel_label(self, label=None, channel_list=None):
        return

    def configure_channel_digital_io(self, set_mode=None, width=None, set_match=None, match_type=None, channel_list=None):
        return

    def configure_channel_totalizer(self, set_mode=None, set_match=None, match_type=None, channel_list=None):
        return

    def configure_digital_io_line_mode(self, dio_line=None, mode=None):
        if mode is None:
            mode = self.DIOMode.DIO_OPEN_DRAIN
            self.SendCmd("digio.line[{0}].mode = digio.{}".format(dio_line, self.dig_io_mode[dio_line.value]))
        return

    def configure_trigger_input(self, input_type=None, line=None, edge_type=None, do_clear=None, do_wait=None):
        if input_type is None:
            input_type = TriggerLineType.TSPLINK
            if line is None:
                line = 1

        if edge_type is not None:
            # Build input trigger string
            if line is not None:
                send_buffer = "{0}in[{1}].edge = trigger.{2}".format(self.trigger_line_type[input_type.value], line, self.trigger_edge_type[edge_type.value])
            else:
                send_buffer = "{0}in.edge = trigger.{2}".format(self.trigger_line_type[input_type.value], line, self.trigger_edge_type[edge_type.value])
            self.SendCmd(send_buffer)       # trigger.digin[N].edge trigger.extin.edge trigger.tsplinkin[N].edge
            
        if do_clear is not None:
            # Build clear string
            if line is not None:
                send_buffer = "{0}in[{1}].clear()".format(self.trigger_line_type[input_type.value], line)
            else:
                send_buffer = "{0}in.clear()".format(self.trigger_line_type[input_type.value])
            self.SendCmd(send_buffer)      # trigger.digin[N].clear() trigger.extin.clear() trigger.tsplinkin[N].clear()

        if do_wait is not None:
            # Build wait string
            if line is not None:
                send_buffer = "{0}in[{1}].wait()".format(self.trigger_line_type[input_type.value], line)
            else:
                send_buffer = "{0}in.wait()".format(self.trigger_line_type[input_type.value])
            self.SendCmd(send_buffer)       # trigger.digin[N].wait() trigger.extin.wait() trigger.tsplinkin[N].wait()

        """if overrun is not None:
            # Build overrun string
            if line is not None:
                send_buffer = "{0}in[{1}].wait()".format(self.trigger_line_type[input_type.value], line)
            else:
                send_buffer = "{0}in.wait()".format(self.trigger_line_type[input_type.value])
            self.SendCmd(send_buffer)"""
            
        # trigger.digin[N].overrun trigger.extin.overrun trigger.tsplinkin[N].overrun        
        return

    class TriggerPolarity(Enum):
        FALLING = 0
        RISING = 1
        EITHER = 2

    self.trigger_edge_type = ["EDGE_FALLING",
                              "EDGE_RISING",
                              "EDGE_EITHER"]
    
    class TriggerLineType(Enum):
        DIGITAL = 0
        EXTERNAL = 1
        TSPLINK = 2
        
    self.trigger_line_type = ["trigger.dig",
                              "trigger.ext",
                              "trigger.tsplink"]

    def configure_trigger_output(self, output_type=None, logic_type=None, line=None, stimulus_type=None, pulse_width=None, do_assert=None, do_release=None):
        if output_type is None:
            output_type = TriggerLineType.TSPLINK
            if line is None:
                line = 1

        if logic_type is not None:
            # Build input trigger string
            if line is not None:
                send_buffer = "{0}out[{1}].logic = trigger.{2}".format(self.trigger_line_type[logic_type.value], line, self.trigger_logic[logic_type.value])
            else:
                send_buffer = "{0}out.logic = trigger.{2}".format(self.trigger_line_type[input_type.value], line, self.trigger_logic[logic_type.value])
            self.SendCmd(send_buffer)       # trigger.tsplinkout[N].logic = trigger.LOGIC_POSITIVE trigger.extout.logic trigger.tsplinkout[N].logic

        if do_release is not None:
            if line is not None:
                send_buffer = "{0}out[{1}].release()".format(self.trigger_line_type[logic_type.value], line)
            else:
                send_buffer = "{0}out.release()".format(self.trigger_line_type[logic_type.value])
            self.SendCmd(send_buffer)       # trigger.tsplinkout[N].release() trigger.digout[N].release() trigger.tsplinkout[N].release()

        if do_assert is not None:
            if line is not None:
                send_buffer = "{0}out[{1}].assert()".format(self.trigger_line_type[logic_type.value], line)
            else:
                send_buffer = "{0}out.assert()".format(self.trigger_line_type[logic_type.value])
            self.SendCmd(send_buffer)       # trigger.tsplinkout[N].assert() trigger.digout[N].assert() trigger.extout.assert()

        if stimulus_type is not None:
            if line is not None:
                send_buffer = "{0}out[{1}].stimulus = trigger.{2}".format(self.trigger_line_type[logic_type.value], line, self.stimulus[stimulus_type])
            else:
                send_buffer = "{0}out.stimulus = trigger.{1}".format(self.trigger_line_type[logic_type.value], self.stimulus[stimulus_type])
            self.SendCmd(send_buffer)       # trigger.tsplinkout[N].stimulus = trigger.EVENT_NONE trigger.digout[N].stimulus trigger.extout.stimulus

        if pulse_width is not None:
            if line is not None:
                send_buffer = "{0}out[{1}].pulsewidth = {2}".format(self.trigger_line_type[logic_type.value], line, self.stimulus[stimulus_type])
            else:
                send_buffer = "{0}out.pulsewidth = {1}".format(self.trigger_line_type[logic_type.value], self.stimulus[stimulus_type])
            self.SendCmd(send_buffer)       # trigger.tsplinkout[N].pulsewidth = width trigger.digout[N].pulsewidth
        return

    class TriggerLogic(Enum):
        NEGATIVE = 0
        POSITIVE = 1

    self.trigger_logic = ["LOGIC_NEGATIVE",
                          "LOGIC_POSITIVE"]

    class Stimulus(Enum):
        NONE = 0
        DISPLAY = 1
        NOTIFY = 2
        COMMAND = 3
        DIGIO = 4
        TSPLINK = 5
        LAN = 6
        ANALOGTRIGGER = 7
        TIMER = 8
        EXTERNAL = 9
        SCAN_ALARM_LIMIT = 10
        SCAN_CHANNEL_READY = 11
        SCAN_COMPLETE = 12
        SCAN_MEASURE_COMPLETE = 13
        SCAN_ALARM_LIMIT_2 = 14

    self.stimulus = ["EVENT_NONE",
                     "EVENT_DISPLAY",
                     "EVENT_NOTIFYn",
                     "EVENT_COMMAND",
                     "EVENT_DIGIOn",
                     "EVENT_TSPLINKn",
                     "EVENT_LANn",
                     "EVENT_ANALOGTRIGGER",
                     "EVENT_TIMERn",
                     "EVENT_EXTERNAL",
                     "EVENT_SCAN_ALARM_LIMIT",
                     "EVENT_SCAN_CHANNEL_READY",
                     "EVENT_SCAN_COMPLETE",
                     "EVENT_SCAN_MEASURE_COMPLETE",
                     "EVENT_SCAN_ALARM_LIMIT"]
    
    def trigger_reset(self):
        trigger.ext.reset()
        return

    def SetMeasure_Function(self, myFunc):
        funcStr = ""
        if myFunc == self.MeasFunc.DCV:
            funcStr = "dmm.FUNC_DC_VOLTAGE"
        elif myFunc == self.MeasFunc.DCI:
            funcStr = "dmm.FUNC_DC_CURRENT"
        sndBuffer = "dmm.measure.func =  {}".format(funcStr)
        self.SendCmd(sndBuffer)
        return

    def SetMeasure_Range(self, *args):
        if (type(args[0]) != str):
            if (type(args[0]) == self.DmmState):
                if(args[0] == self.AutoRange.OFF):
                    arState = "dmm.OFF"
                else:
                    arState = "dmm.ON"
                funcStr = "dmm.measure.autorange = {}".format(arState)
            else:
                funcStr = "dmm.measure.range = {}".format(args[0])
            self.SendCmd("{}".format(funcStr))
        else:
            setStr = "channel.setdmm(\"{}\", ".format(args[0])
            if (type(args[1]) == self.AutoRange):
                if(args[1] == self.AutoRange.OFF):
                    arState = "dmm.OFF"
                else:
                    arState = "dmm.ON"
                self.SendCmd("{}dmm.ATTR_MEAS_RANGE_AUTO, {})".format(setStr, arState))
            else:
                self.SendCmd("{}dmm.ATTR_MEAS_RANGE, {})".format(setStr, args[1]))
        return

    def SetMeasure_NPLC(self, *args):
        if type(args[0]) != str:
            self.SendCmd("dmm.measure.nplc = {}".format(args[0]))
        else:
            setStr = "channel.setdmm(\"{}\", ".format(args[0])
            self.SendCmd("{}dmm.ATTR_MEAS_NPLC, {})".format(setStr, args[1]))
        return

    def SeMeasure_LineSync(self, *args):
        # define me...
        return
    
    def SetMeasure_InputImpedance(self, *args):
        if type(args[0]) != str:
            if myZ == self.InputZ.Z_AUTO:
                funcStr = "dmm.IMPEDANCE_AUTO"
            elif myZ == self.InputZ.Z_10M:
                funcStr = "dmm.IMPEDANCE_10M"
            self.SendCmd("dmm.measure.inputimpedance = {}".format(funcStr))
        else:
            setStr = "channel.setdmm(\"{}\", ".format(args[0])
            if myZ == self.InputZ.Z_AUTO:
                funcStr = "dmm.IMPEDANCE_AUTO"
            elif myZ == self.InputZ.Z_10M:
                funcStr = "dmm.IMPEDANCE_10M"
            self.SendCmd("{}dmm.ATTR_MEAS_INPUT_IMPEDANCE, {})".format(setStr, funcStr))
        return

    def SetMeasure_AutoDelay(self, *args):
        if type(args[0]) != str:
            if args[0] == self.DmmState.OFF:
                funcStr = "dmm.DELAY_OFF"
            elif args[0] == self.DmmState.ON:
                funcStr = "dmm.DELAY_ON"
            self.SendCmd("dmm.measure.autodelay = {}".format(args[0]))
        else:
            setStr = "channel.setdmm(\"{}\", ".format(args[0])
            if args[1] == self.DmmState.OFF:
                funcStr = "dmm.DELAY_OFF"
            elif args[1] == self.DmmState.ON:
                funcStr = "dmm.DELAY_ON"
            self.SendCmd("{}dmm.ATTR_MEAS_AUTO_DELAY, {})".format(setStr, funcStr))
        return
    
    def SetMeasure_AutoZero(self, *args):
        if type(args[0]) != str:
            if args[0] == self.DmmState.OFF:
                funcStr = "dmm.OFF"
            elif args[0] == self.DmmState.ON:
                funcStr = "dmm.ON"
            self.SendCmd("dmm.measure.autozero.enable = {}".format(args[0]))
        else:
            setStr = "channel.setdmm(\"{}\", ".format(args[0])
            if args[1] == self.DmmState.OFF:
                funcStr = "dmm.OFF"
            elif args[1] == self.DmmState.ON:
                funcStr = "dmm.ON"
            self.SendCmd("{}dmm.ATTR_MEAS_AUTO_ZERO, {})".format(setStr, funcStr))
        return

    def SetMeasure_Count(self, *args):
        if type(args[0]) != str:
            self.SendCmd("dmm.measure.count = {}".format(args[0]))
        else:
            setStr = "channel.setdmm(\"{}\", ".format(args[0])
            self.SendCmd("{}dmm.ATTR_MEAS_COUNT, {})".format(setStr, args[1]))
        return

    def SetMeasure_Filter(self, *args):   # THIS NEEDS FIXED - DOES NOT ACCOUNT FOR CHANNEL USAGE
        # Default call to this function implies no less than
        # turning the filter on/off.
        self.SetMeasure_FilterState(args[0])
        if len(args) > 1:
            self.SetMeasure_FilterType(args[1])
        if len(args) > 2:
            self.SetMeasure_FilterCount(args[2])
        return
    
    def SetMeasure_FilterType(self, my_filter):
        if my_filter == self.FilterType.REP:
            func_str = "dmm.FILTER_REPEAT_AVG"
        elif myFilter == self.FilterType.MOV:
            func_str = "dmm.FILTER_MOVING_AVG"
        send_buffer = "dmm.measure.filter.type = {}".format(func_str)
        self.SendCmd(send_buffer)
        return

    def SetMeasure_FilterCount(self, count):
        send_buffer = "dmm.measure.filter.count = {}".format(count)
        self.SendCmd(send_buffer)
        return

    def SetMeasure_FilterState(self, myState):
        if myState == self.DmmState.OFF:
            func_str = "dmm.OFF"
        elif myState == self.DmmState.ON:
            func_str = "dmm.ON"
            send_buffer = "dmm.measure.filter.enable = {}".format(func_str)
        self.SendCmd(send_buffer)
        return

    def SetMeasure_OffsetCompensation(self, *args):
        if type(args[0]) != str:
            xStr = "dmm.measure.offsetcompensation.enable"
            if args[0] == self.OCOMP.ON:
               xStr2 = "dmm.OCOMP_ON"
            elif args[0] == self.OCOMP.OFF:
               xStr2 = "dmm.OCOMP_OFF" 
            self.SendCmd("{} = {}".format(xStr, xStr2))
        else:
            setStr = "channel.setdmm(\"{}\", ".format(args[0])
            if args[1] == self.OCOMP.ON:
               xStr2 = "dmm.OCOMP_ON"
            elif args[1] == self.OCOMP.OFF:
               xStr2 = "dmm.OCOMP_OFF"
            self.SendCmd("{}dmm.ATTR_MEAS_OFFCOMP_ENABLE, {})".format(setStr, xStr))
        return
    
    def Measure(self, count):
        return self.QueryCmd("print(dmm.measure.read())", 32)

    def SetFunction_DC_Voltage(self, *args):
        # This function can be used to set up different measurement
        # function attributes, but they are expected to be in a certain
        # order....
        #   For simple front/rear terminal measurements:
        #       1. Input impedance
        #   For channel scan measurements:
        #       1. Channel string
        #       2. Input impedance
        if len(args) == 0:
            self.SendCmd("dmm.measure.func = dmm.FUNC_DC_VOLTAGE")
        else:
            if type(args[0]) != str:
                self.SendCmd("dmm.measure.func = dmm.FUNC_DC_VOLTAGE")
                if len(args) > 0:
                    xStr = "dmm.measure.inputimpedance"
                    if args[0] == self.InputZ.Z_10M:
                       xStr2 = "dmm.IMPEDANCE_10M"
                    elif args[0] == self.InputZ.Z_AUTO:
                       xStr2 = "dmm.IMPEDANCE_AUTO"
                    sndBuffer = "{} = {}".format(xStr, xStr2)
                    self.SendCmd(sndBuffer)
            else:
                setStr = "channel.setdmm(\"{}\", ".format(args[0])
                self.SendCmd("{}dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_VOLTAGE)".format(setStr))
                if len(args) > 1:
                    if args[1] == self.InputZ.Z_10M:
                       xStr = "dmm.IMPEDANCE_10M"
                    elif args[1] == self.InputZ.Z_AUTO:
                       xStr = "dmm.IMPEDANCE_AUTO"
                    
                    sndBuffer = "{}dmm.ATTR_MEAS_INPUT_IMPEDANCE, {})".format(setStr, xStr)
                    self.SendCmd(sndBuffer)
        return
    
    def SetFunction_2W_Resistance(self, *args):
        if len(args) == 0:
            self.SendCmd("dmm.measure.func = dmm.FUNC_RESISTANCE")  #FUNC_4W_RESISTANCE
        else:
            if type(args[0]) != str:
                self.SendCmd("dmm.measure.func = dmm.FUNC_RESISTANCE")
            else:
                setStr = "channel.setdmm(\"{}\", ".format(args[0])
                self.SendCmd("{}dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_RESISTANCE)".format(setStr))
        return

    def SetFunction_4W_Resistance(self, *args):
        if len(args) == 0:
            self.SendCmd("dmm.measure.func = dmm.FUNC_4W_RESISTANCE")  
        else:
            if type(args[0]) != str:
                self.SendCmd("dmm.measure.func = dmm.FUNC_4W_RESISTANCE")
                if len(args) > 0:
                    # The first argument will set OCOMP...
                    xStr = "dmm.measure.offsetcompensation.enable"
                    if args[0] == self.OCOMP.ON:
                       xStr2 = "dmm.OCOMP_ON"
                    elif args[0] == self.OCOMP.OFF:
                       xStr2 = "dmm.OCOMP_OFF"
                    sndBuffer = "{} = {}".format(xStr, xStr2)
                    self.SendCmd(sndBuffer)
                if len(args) > 1:
                    # The second argument will set open lead detection...
                    xStr = "dmm.measure.opendetector"
                    if args[1] == self.DmmState.OFF:
                       xStr2 = "dmm.OFF"
                    elif args[1] == self.DmmState.ON:
                       xStr2 = "dmm.ON"
                    sndBuffer = "{} = {}".format(xStr, xStr2)
                    self.SendCmd(sndBuffer)
            else:
                setStr = "channel.setdmm(\"{}\", ".format(args[0])
                self.SendCmd("{}dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_4W_RESISTANCE)".format(setStr))
                if len(args) > 1:
                    if args[1] == self.OCOMP.ON:
                       xStr = "dmm.OCOMP_ON"
                    elif args[1] == self.OCOMP.OFF:
                       xStr = "dmm.OCOMP_OFF"
                    sndBuffer = "{}dmm.ATTR_MEAS_OFFCOMP_ENABLE, {})".format(setStr, xStr)
                    self.SendCmd(sndBuffer)
                if len(args) > 2:
                    if args[2] == self.OLeadDetect.ON:
                       xStr = "dmm.ON"
                    elif args[2] == self.OLeadDetect.OFF:
                       xStr = "dmm.OFF"
                    sndBuffer = "{}dmm.ATTR_MEAS_OPEN_DETECTOR, {})".format(setStr, xStr)
                    self.SendCmd(sndBuffer)
        return
    
    def SetFunction_Temperature(self, *args):
        # This function can be used to set up to three different measurement
        # function attributes, but they are expected to be in a certain
        # order....
        #   For simple front/rear terminal measurements:
        #       1. Transducer (TC/RTD/Thermistor)
        #       2. Transducer type
        #   For channel scan measurements:
        #       1. Channel string
        #       2. Transducer
        #       3. Transducer type
        if (len(args) == 0):
            self.SendCmd("dmm.measure.func = dmm.FUNC_TEMPERATURE")
        else:
            if (type(args[0]) != str):
                self.SendCmd("dmm.measure.func = dmm.FUNC_TEMPERATURE")
                if len(args) > 0:
                    xStr = "dmm.measure.transducer"
                    if args[0] == self.Transducer.TC:
                       xStr2 = "dmm.TRANS_THERMOCOUPLE"
                    elif args[0] == self.Transducer.RTD4:
                       xStr2 = "dmm.TRANS_FOURRTD"
                    elif args[0] == self.Transducer.RTD3:
                       xStr2 = "dmm.TRANS_THREERTD"
                    elif args[0] == self.Transducer.THERM:
                       xStr2 = "dmm.TRANS_THERMISTOR"
                    sndBuffer = "{} = {}".format(xStr, xStr2)
                    self.SendCmd(sndBuffer)
                if len(args) > 1:
                    if args[0] == self.Transducer.TC:
                        xStr = "dmm.measure.thermocouple"
                        if args[1] == self.TCType.K:
                           xType = "dmm.THERMOCOUPLE_K"
                        elif args[1] == self.TCType.J:
                           xType = "dmm.THERMOCOUPLE_J"
                        elif args[1] == self.TCType.N:
                           xType = "dmm.THERMOCOUPLE_N" 
                        sndBuffer = "{} = {}".format(xStr, xType)
                        self.SendCmd(sndBuffer)
                    elif (args[0] == self.Transducer.RTD4) or (args[1] == self.Transducer.RTD3):
                        if args[0] == self.Transducer.RTD4:
                            xStr = "dmm.measure.fourrtd"
                        if args[0] == self.Transducer.RTD3:
                            xStr = "dmm.measure.threertd"

                        if args[1] == self.RTDType.PT100:
                           rtdType = "dmm.RTD_PT100"
                        elif args[1] == self.RTDType.PT385 :
                           rtdType = "dmm.RTD_PT385"
                        elif args[1] == self.RTDType.PT3916:
                           rtdType = "dmm.RTD_PT3916"
                        elif args[1] == self.RTDType.D100:
                           rtdType = "dmm.RTD_D100"
                        elif args[1] == self.RTDType.F100:
                           rtdType = "dmm.RTD_F100"
                        elif args[1] == self.RTDType.USER:
                           rtdType = "dmm.RTD_USER"
                           
                        sndBuffer = "{} = {}".format(xStr, rtdType)
                        self.SendCmd(sndBuffer)
                    elif args[0] == self.Transducer.THERM:
                        xStr = "dmm.measure.thermistor"
                        if args[1] == self.ThermType.TH2252:
                           thrmType = "dmm.THERM_2252"
                        elif args[1] == self.ThermType.TH5K:
                           thrmType = "dmm.THERM_5000"
                        elif args[1] == self.ThermType.TH10K:
                           thrmType = "dmm.THERM_10000"
                        sndBuffer = "{} = {}".format(xStr, thrmType)
                        self.SendCmd(sndBuffer)
            else:
                setStr = "channel.setdmm(\"{}\", ".format(args[0])
                self.SendCmd("{}dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_TEMPERATURE)".format(setStr))
                if len(args) > 1:
                    if args[1] == self.Transducer.TC:
                       xStr = "dmm.TRANS_THERMOCOUPLE"
                       xStr2 = "dmm.ATTR_MEAS_THERMOCOUPLE"
                    elif args[1] == self.Transducer.RTD4:
                       xStr = "dmm.TRANS_FOURRTD"
                       xStr2 = "dmm.ATTR_MEAS_FOUR_RTD"
                    elif args[1] == self.Transducer.RTD3:
                       xStr = "dmm.TRANS_THREERTD"
                       xStr2 = "dmm.ATTR_MEAS_THREE_RTD"
                    elif args[1] == self.Transducer.THERM:
                       xStr = "dmm.TRANS_THERMISTOR"
                       xStr2 = "dmm.ATTR_MEAS_THERMISTOR"
                    sndBuffer = "{}dmm.ATTR_MEAS_TRANSDUCER, {})".format(setStr, xStr)
                    self.SendCmd(sndBuffer)
                if len(args) > 2:
                    if args[1] == self.Transducer.TC:
                        if args[2] == self.TCType.K:
                           xType = "dmm.THERMOCOUPLE_K"
                        elif args[2] == self.TCType.J:
                           xType = "dmm.THERMOCOUPLE_J"
                        elif args[2] == self.TCType.N:
                           xType = "dmm.THERMOCOUPLE_N" 
                        # print("{}dmm.ATTR_MEAS_THERMOCOUPLE, {})".format(setStr, xType))
                        sndBuffer = "{}dmm.ATTR_MEAS_THERMOCOUPLE, {})".format(setStr, xType)
                        self.SendCmd(sndBuffer)
                    elif (args[1] == self.Transducer.RTD4) or (args[1] == self.Transducer.RTD3):
                        if args[2] == self.RTDType.PT100:
                           rtdType = "dmm.RTD_PT100"
                        elif args[2] == self.RTDType.PT385:
                           rtdType = "dmm.RTD_PT385"
                        elif args[2] == self.RTDType.PT3916:
                           rtdType = "dmm.RTD_PT3916"
                        elif args[2] == self.RTDType.D100:
                           rtdType = "dmm.RTD_F100"
                        elif args[2] == self.RTDType.F100:
                           rtdType = "dmm.RTD_D100"
                        elif args[2] == self.RTDType.USER:
                           rtdType = "dmm.RTD_USER"
                        sndBuffer = "{}{}, {})".format(setStr, xStr2, rtdType)
                        self.SendCmd(sndBuffer)
                    if args[1] == self.Transducer.THERM:
                        if args[2] == self.ThermType.TH2252:
                           thrmType = "dmm.THERM_2252"
                        elif args[2] == self.ThermType.TH5K:
                           thrmType = "dmm.THERM_5000"
                        elif args[2] == self.ThermType.TH10K:
                           thrmType = "dmm.THERM_10000"
                        sndBuffer = "{}{}, {})".format(setStr, xStr2, thrmType)
                        self.SendCmd(sndBuffer)
        return
    
    class MeasFunc(Enum):
        DCV = 0
        DCI = 1
        ACV = 2
        ACI = 3
        RES2W = 4
        RES4W = 5
        DIODE = 6
        CAP = 7
        TEMP = 8
        CONT = 9
        FREQ = 10
        PER = 11
        RATIO = 12
        DIGI_V = 13
        DIGI_I = 14
    
    class InputZ(Enum):
        Z_AUTO = 0
        Z_10M = 1

    class DmmState(Enum):
        OFF = 0
        ON = 1
        
    class AutoRange(Enum):
        OFF = 0
        ON = 1

    class Transducer(Enum):
        TC = 0
        RTD4 = 1
        RTD3 = 2
        THERM = 3

    class TCType(Enum):
        K = 0
        J = 1
        N = 2

    class RTDType(Enum):
        PT100 = 0
        PT385 = 1
        PT3916 = 2
        D100 = 3
        F100 = 4
        USER = 5

    class ThermType(Enum):
        TH2252 = 0
        TH5K = 1
        TH10K = 2

    class OCOMP(Enum):
        OFF = 0
        ON = 1

    class OLeadDetect(Enum):
        OFF = 0
        ON = 1

    class FilterType(Enum):
        REPEAT = 0
        MOVE = 1

    class DIOMode(Enum):
        DIO_IN = 0
        DIO_OUT = 1
        DIO_OPEN_DRAIN = 2
        TRIG_IN = 3
        TRIG_OUT = 4
        TRIG_OPEN_DRAIN = 5
        TRIG_SYNC_MASTER = 6
        TRIG_SYNC_ACCEPTOR = 7
        
    self.dig_io_mode = ["digio.MODE_DIGITAL_IN",
                        "digio.MODE_DIGITAL_OUT",
                        "digio.MODE_DIGITAL_OPEN_DRAIN",
                        "digio.MODE_TRIGGER_IN",
                        "digio.MODE_TRIGGER_OUT",
                        "digio.MODE_TRIGGER_OPEN_DRAIN",
                        "digio.MODE_SYNCHRONOUS_MASTER",
                        "digio.MODE_SYNCHRONOUS_ACCEPTOR"]

    def SetScan_BasicAttributes(self, *args):
        self.SendCmd("scan.create(\"{}\")".format(args[0]))

        # Set the scan count
        if len(args) > 1:
            self.SendCmd("scan.scancount = {}".format(args[1]))

        # Set the time between scans
        if len(args) > 2:
            self.SendCmd("scan.scaninterval = {}".format(args[2]))
        return

    def Init(self):
        self.SendCmd("waitcomplete()")
        self.SendCmd("trigger.model.initiate()")
        return

    def GetScan_Status(self):
        return self.QueryCmd("print(trigger.model.state())", 45)

    def GetScan_Data(self, dataCount, startIndex, endIndex):
        charCnt = 24 * dataCount
        accumCnt = int(self.QueryCmd("print(defbuffer1.n)", 16)[0:-1])
        while accumCnt < endIndex:
            accumCnt = int(self.QueryCmd("print(defbuffer1.n)", 16)[0:-1])
        rcvBuffer = self.QueryCmd("printbuffer({}, {}, defbuffer1)".format(startIndex, endIndex), charCnt)[0:-1]
        return rcvBuffer
