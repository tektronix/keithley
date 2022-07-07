--[[
################################################################################
    Script: DiodeTestFunctions_12Jun2019.tsp
Written by: Keithley Applications Engineering

Copyright Tektronix, Inc.
See www.tek.com/sample-license for licensing terms.

Revision History:
    * Initial release 06/12/2019

This script is example code which creates functions that can be used to test 
diodes.  It includes functions that perform spot measurements of forward 
voltage (Vf), reverse voltage (Vr) and reverse leakage current (Ir).  It also 
includes sweep functions to perform basic V vs I and I vs V characterization 
of a diode.

Required equipment:  The script and functions that are created will run on any 
                     2600A, 2600B or 2650A Series SourceMeter instrument.

Note:  The functions do not perform any error checking.  It is the user's 
       responsibility to specify settings that are compatible with the 
       instrument model being used, and with its power envelope.
       
Note:  It is the user's responsibility to follow all safety guidelines given in 
       the instrument's Reference Manual.  This is especially critical if 
       voltages in excess of 42VDC will be present in the test circuits.  Such 
       voltage levels are hazardous. 

Functions created by this script:

    * initialize_smu(...)
    * display_vmeas(...)
    * display_imeas(...)
    * spotv_measiv(...)
    * spoti_measiv(...)
    * sweepv_measiv(...)
    * sweepi_measiv(...)
    * measure_vf(...)
    * measure_vr(...)
    * measure_ir(...)

    See detailed information listed in individual functions
################################################################################
--]]

-- *****************************************************************************
function initialize_smu(smux)

    --[[
    This function sets the specified SMU to an initial state suitable for use
    with the other functions created by this script.
    
    Prerequisite:  None
    
    Pass parameters:
        * smux is the SMU to be initialized, either smua or smub.  smux 
          defaults to smua if no SMU is specified.
            
    Returned values:  None
    --]]
            
    -- Default to smua if smux is not specified.
    if smux == nil then
        smux = smua
    end --if
    
    smux.reset()    -- Reset smux to default conditions
    
    -- Set SourceMeter display to single-channel view so source limit setting is visible
    if smux == smua then
        display.screen = display.SMUA
    elseif smux == smub then
        display.screen = display.SMUB
    end --if
    
    -- Configure nonvolatile reading buffers.  Each SMU channel has 2 such buffers,
    --   smux.nvbuffer1 and smux.nvbuffer2.
    -- Note:  User must execute smuX.savebuffer(smuX.nvbufferY) command to 
    --        actually store the buffer into nonvolatile memory.
    smux.nvbuffer1.clear()                 -- Clear any existing readings from the buffer
    smux.nvbuffer1.appendmode = 1          -- Enable append mode so new readings 
                                           --   are appended to the end of the buffer.
    smux.nvbuffer1.collecttimestamps = 1   -- Collect reading timestamps
    
    smux.nvbuffer2.clear()                 -- Clear any existing readings
    smux.nvbuffer2.appendmode = 1          -- Enable append mode
    smux.nvbuffer2.collecttimestamps = 1   -- Collect reading timestamps

end --function initialize_smu()
-- *****************************************************************************
function display_vmeas(smux)

    --[[
    This function sets the displayed measure function to voltage.
    
    Prerequisite:  The initialize_smu() function must be called prior to calling 
                   this function.
    
    Pass parameters:
        * smux is the SMU being used, either smua or smub.  smux defaults to 
          smua if no SMU is specified.
          
    Returned values:  None
    --]]
            
    -- Default to smua if smux is not specified.
    if smux == nil then
        smux = smua
    end --if

    -- Set the displayed measure function to voltage
    if smux == smua then
        display.smua.measure.func = display.MEASURE_DCVOLTS
    elseif smux == smub then
        display.smub.measure.func = display.MEASURE_DCVOLTS
    end --if
    
end --function display_vmeas()
-- *****************************************************************************
function display_imeas(smux)

    --[[
    This function sets the displayed measure function to current.
    
    Prerequisite:  The initialize_smu() function must be called prior to calling 
                   this function.
    
    Pass parameters:
        * smux is the SMU being used for the test, either smua or smub.  
          smux defaults to smua if no SMU is specified.
          
    Returned values:  None
    --]]
            
    -- Default to smua if smux is not specified.
    if smux == nil then
        smux = smua
    end --if
    
    -- Set displayed measure function to current
    if smux == smua then
        display.smua.measure.func = display.MEASURE_DCAMPS
    elseif smux == smub then
        display.smub.measure.func = display.MEASURE_DCAMPS
    end --if
    
end --function display_imeas()
-- *****************************************************************************
function spotv_measiv(smux, src_vlevel, settle_time)
    --[[
    This function configures the specified SMU to output the specified voltage  
    level, waits the specified amount of time to allow the voltage source and
    device-under-test to settle, and then performs single simultaneous 
    measurements of voltage and current.  This function leaves the SMU 
    output turned on after the measurements are complete.  
    
    Prerequisites:
        (1) The initialize_smu() function must be called prior to calling this 
            function.
        
    Pass parameters:
        * smux is the SMU being used for the test, either smua or smub.  
          smux defaults to smua if no SMU is specified, i.e. if smux is nil.
        * src_vlevel is the output voltage level in volts.
        * settle_time is the time in seconds to wait between setting the output 
          voltage level and performing the current and voltage measurements.
          
    Returned values:
        * imeas is the measured current
        * vmeas is the measured voltage
    --]]
    
    -- Default to smua if smux is not specified.
    if smux == nil then
        smux = smua
    end --if

    smux.source.levelv = src_vlevel         -- Set the voltage source level

    smux.source.output = smux.OUTPUT_ON     -- Turn SMU output ON
    
    delay(settle_time)                      -- Wait for source and DUT to settle
    
    local imeas, vmeas = smux.measure.iv()  -- Simultaneously measure current and voltage
    
    return imeas, vmeas
    
end --function spotv_measiv()
-- *****************************************************************************
function spoti_measiv(smux, src_ilevel, settle_time)

    --[[
    This function configures the specified SMU to output the specified current  
    level, waits the specified amount of time to allow the current source and
    device-under-test to settle, and then performs single simultaneous 
    measurements of voltage and current.  This function leaves the SMU 
    output turned on after the measurements are complete.  
    
    Prerequisites:
        (1) The initialize_smu() function must be called prior to calling this 
            function.
        
    Pass parameters:
        * smux is the SMU being used for the test, either smua or smub.  
          smux defaults to smua if no SMU is specified, i.e. if smux is nil.
        * src_ilevel is the output current level in amps.
        * settle_time is the time in seconds to wait between setting the output 
          current level and performing the current and voltage measurements.
          
    Returned values:
        * imeas is the measured current
        * vmeas is the measured voltage
    --]]

    -- Default to smua if smux is not specified.
    if smux == nil then
        smux = smua
    end --if

    smux.source.leveli = src_ilevel         -- Set the current source level

    smux.source.output = smux.OUTPUT_ON     -- Turn SMU output ON
    
    delay(settle_time)                      -- Wait for source to settle; delay time is in seconds
    
    local imeas, vmeas = smux.measure.iv()  -- Simultaneously measure current and voltage
    
    return imeas, vmeas
    
end --function spoti_measiv()
-- *****************************************************************************
function sweepv_measiv(smux, vstart, vstop, vstep, src_vrange, src_ilimit, settle_time, nplc, meas_irange)

    --[[
    This function performs a DC linear staircase voltage sweep and measures the 
    voltage and current at each point of the sweep.  The timestamped readings 
    are accumulated in the nonvolatile reading buffers of the specified SMU.  
    Current readings are stored in smux.nvbuffer1 and voltage readings are 
    stored in smux.nvbuffer2.  The sweep is general in nature, but in this 
    context, it is intended to be used for IV characterization of a diode.
    
    This function configures the specified SMU using the given source and 
    measure parameters.  It sets the output voltage level for each point in the 
    sweep, waits the specified amount of time to allow the voltage source and
    device-under-test to settle, and then performs simultaneous measurements 
    of voltage and current.  It leaves the SMU output turned on after the sweep
    is completed.
    
    Prerequisites:
        (1) The initialize_smu() function must be called prior to calling this 
            function.
        
    Pass parameters:
        * smux is the SMU being used for the test, either smua or smub.  
          smux defaults to smua if no SMU is specified, i.e. if smux is nil.
        * vstart is the beginning voltage level in volts for the sweep .
        * vstop is the target end voltage level in volts for the sweep.
        * vstep is the increment in volts by which the voltage level is changed 
          for each step of the sweep.
        * src_vrange is the value in volts used to set the voltage source 
          range.  If nil is passed to the function, then voltage source 
          autoranging is enabled.
        * src_ilimit is the current limit in amps for the voltage source.
        * settle_time is the time in seconds to wait between setting the output 
          voltage level and performing the current and voltage measurements.
        * nplc is the integration time for the analog-to-digital converter, and 
          is specified in terms of the number of powerline cycles.  The 
          allowed range of values is 0.001 to 25.  This function performs an 
          "autozero once" after setting the NPLC value.
        * meas_irange is the value in amps used to set the current measure
          range.  If no value or nil is passed to the function, then current 
          measure autoranging is enabled.
          
    Note:  If vstep does not divide evenly into the difference between vstop 
           and vstart, then the number of points in the sweep is adjusted to 
           insure that the actual end voltage for the sweep is greater than or 
           equal to vstop.
                      
    Returned values:
        * smux.nvbuffer1 - Buffer where current measurements are stored 
        * smux.nvbuffer2 - Buffer where voltage measurements are stored
    --]]
    
    -- Default to smua if smux is not specified.
    if smux == nil then
        smux = smua
    end --if
    
    local npoints = math.ceil(math.abs((vstop-vstart) / vstep) + 1)
    
    local stepv
    if vstop >= vstart then
        stepv = math.abs(vstep)
    else
        stepv = -math.abs(vstep)
    end --if

    display_imeas(smux) -- Set displayed measure function to current
    
    if src_vrange == nil then  -- If no range is specified, then enable voltage source autorange
        smux.source.autorangev = smux.AUTORANGE_ON
    else                        -- Otherwise set a fixed voltage source range
        smux.source.rangev = src_vrange
    end --if
    
    smux.source.levelv = 0                  -- Set initial voltage source level to zero
    smux.source.limiti = src_ilimit         -- Set the current limit for the voltage source
    smux.source.func = smux.OUTPUT_DCVOLTS  -- Set the source function to voltage
    
    if meas_irange == nil then  -- If no range is specified, then enable current measure autorange
        smux.measure.autorangei = smux.AUTORANGE_ON
    else                        -- Otherwise set a fixed current measure range
        smux.measure.rangei = meas_irange
    end --if
    
    smux.measure.nplc = nplc                    -- Set integration time for analog-to-digital converter
    smux.measure.autozero = smux.AUTOZERO_ONCE  -- Perform autozero once, and then disable autozero
    
    smux.source.output = smux.OUTPUT_ON         -- Turn SMU output ON
    
    -- Delete any existing readings from the nonvolatile buffers
    smux.nvbuffer1.clear()
    smux.nvbuffer2.clear()
    
    -- Perform the voltage sweep
    for i = 1, npoints do
        smux.source.levelv = vstart + (i - 1) * stepv   -- Set the voltage level
        delay(settle_time)                              -- Wait for source and DUT to settle
        
        smux.measure.iv(smux.nvbuffer1, smux.nvbuffer2) -- Simultaneously measure current and voltage;
                                                        --   accumulate readings in nonvolatile buffers
    end --for
    
    return smux.nvbuffer1, smux.nvbuffer2
     
end --function sweepv_measiv()
-- *****************************************************************************
function sweepi_measiv(smux, istart, istop, istep, src_irange, src_vlimit, settle_time, nplc, meas_vrange)

    --[[
    This function performs a DC linear staircase current sweep and measures the 
    voltage and current at each point of the sweep.  The timestamped readings 
    are accumulated in the nonvolatile reading buffers of the specified SMU.  
    Current readings are stored in smux,nvbuffer1 and voltage readings are 
    stored in smux.nvbuffer2.  The sweep is general in nature, but in this 
    context, it is intended to be used for IV characterization of a diode.
    
    This function configures the specified SMU using the given source and 
    measure parameters.  It sets the output current level for each point in the 
    sweep, waits the specified amount of time to allow the current source and
    device-under-test to settle, and then performs simultaneous measurements 
    of voltage and current.  It leaves the SMU output turned on after the sweep
    is completed.
    
    Prerequisites:
        (1) The initialize_smu() function must be called prior to calling this 
            function.
        
    Pass parameters:
        * smux is the SMU being used for the test, either smua or smub.  
          smux defaults to smua if no SMU is specified.
        * istart is the beginning current level in amps for the sweep .
        * istop is the target end current level in amps for the sweep.
        * istep is the increment in amps by which the current level is changed 
          for each step of the sweep.
        * src_irange is the value in amps used to set the current source 
          range.  If nil is passed to the function, then current source 
          autoranging is enabled.
        * src_vlimit is the voltage limit in volts for the current source.
        * settle_time is the time in seconds to wait between setting the output 
          current level and performing the current and voltage measurements.
        * nplc is the integration time for the analog-to-digital converter, and 
          is specified in terms of the number of powerline cycles.  The 
          allowed range of values is 0.001 to 25.  This function performs an 
          "autozero once" after setting the NPLC value.
        * meas_vrange is the value in volts used to set the current measure
          range.  If no value or nil is passed to the function, then voltage 
          measure autoranging is enabled.
          
    Note:  If istep does not divide evenly into the difference between istop 
           and istart, then the number of points in the sweep is adjusted to 
           insure that the actual end current for the sweep is greater than or 
           equal to istop.
                      
    Returned values:
        * smux.nvbuffer1 - Buffer where current measurements are stored 
        * smux.nvbuffer2 - Buffer where voltage measurements are stored
    --]]
    
    -- Default to smua if smux is not specified.
    if smux == nil then
        smux = smua
    end --if
    
    local npoints = math.ceil(math.abs((istop-istart) / istep) + 1)
    
    local stepi
    if istop >= istart then
        stepi = math.abs(istep)
    else
        stepi = -math.abs(istep)
    end --if

    display_vmeas(smux) -- Set displayed measure function to voltage
    
    if src_irange == nil then  -- If no range is specified, then enable current source autorange
        smux.source.autorangei = smux.AUTORANGE_ON
    else                        -- Otherwise set a fixed current source range
        smux.source.rangei = src_irange
    end --if
    
    smux.source.leveli = 0                  -- Set initial current source level to zero
    smux.source.limitv = src_vlimit         -- Set the voltage limit for the current source
    smux.source.func = smux.OUTPUT_DCAMPS   -- Set the source function to current
    
    if meas_vrange == nil then  -- If no range is specified, then enable voltage measure autorange
        smux.measure.autorangev = smux.AUTORANGE_ON
    else                        -- Otherwise set a fixed voltage measure range
        smux.measure.rangev = meas_vrange
    end --if
    
    smux.measure.nplc = nplc                    -- Set integration time for analog-to-digital converter
    smux.measure.autozero = smux.AUTOZERO_ONCE  -- Perform autozero once, and then disable autozero
    
    smux.source.output = smux.OUTPUT_ON         -- Turn SMU output ON
    
    -- Delete any existing readings from the nonvolatile buffers
    smux.nvbuffer1.clear()
    smux.nvbuffer2.clear()
    
    -- Perform the current sweep
    for i = 1, npoints do
        smux.source.leveli = istart + (i - 1) * stepi   -- Set the current level
        delay(settle_time)                              -- Wait for source and DUT to settle
        
        smux.measure.iv(smux.nvbuffer1, smux.nvbuffer2) -- Simultaneously measure current and voltage;
                                                        --   accumulate readings in nonvolatile buffers
    end --for
    
    return smux.nvbuffer1, smux.nvbuffer2
    
end --function sweepi_measiv()
-- *****************************************************************************
function measure_vf(smux, src_irange, bias_current, src_vlimit, settle_time, nplc, meas_vrange)

--[[
    This function performs a forward voltage measurement at the specified 
    bias current.  It configures the specified SMU using the given
    source and measure parameters.  The SMU applies the specified bias current  
    level, waits the specified amount of time to allow the current source and
    diode-under-test to settle, and then performs single simultaneous 
    measurements of voltage and current.  The SMU output is left on after 
    the measurements are complete.
    
    Prerequisites:
        (1) The initialize_smu() function must be called prior to calling this 
            function.
        
    Pass parameters:
        * smux is the SMU being used for the test, either smua or smub.  
          smux defaults to smua if no SMU is specified, i.e. if smux is nil.
        * src_irange is the value in amps used to set the current source 
          range.  If nil is passed to the function, then current source 
          autoranging is enabled.
        * bias_current is the current level in amps at which the forward
          voltage is to be measured.  If SMU Force HI is connected to 
          the anode of the diode, then to properly forward bias the diode, the 
          current bias must be entered as a positive value.
        * src_vlimit is the voltage limit in volts for the current source.
        * settle_time is the time in seconds to wait between applying the 
          bias current to the diode and performing the current and voltage 
          measurements.
        * nplc is the integration time for the analog-to-digital converter, and 
          is specified in terms of the number of powerline cycles.  The 
          allowed range of values is 0.001 to 25.  An "autozero once" is 
          performed after setting the NPLC value.
        * meas_vrange is the value in volts used to set the current measure
          range.  If no value or nil is passed to the function, then current 
          measure autoranging is enabled.
          
    Returned values:  None
        * vf is the measured forward voltage
        * ibias is the measured value of the bias current
    --]]
    
    -- Default to smua if smux is not specified.
    if smux == nil then
        smux = smua
    end --if

    display_vmeas(smux) -- Set displayed measure function to voltage
    
    if src_irange == nil then  -- If no range is specified, then enable current source autorange
        smux.source.autorangei = smux.AUTORANGE_ON
    else                        -- Otherwise set a fixed current source range
        smux.source.rangei = src_irange
    end --if

    smux.source.limitv = src_vlimit         -- Set the voltage limit for the current source
    smux.source.func = smux.OUTPUT_DCAMPS   -- Set the source function to current

    if meas_vrange == nil then  -- If no range is specified, then enable voltage measure autorange
        smux.measure.autorangev = smux.AUTORANGE_ON
    else                        -- Otherwise set a fixed voltage measure range
        smux.measure.rangev = meas_vrange
    end --if
    
    smux.measure.nplc = nplc    -- Set integration time for integrating analog-to-digital converter
    smux.measure.autozero = smux.AUTOZERO_ONCE  -- Perform autozero once, and then disable autozero
    
    local ibias, vf = spoti_measiv(smux, bias_current, settle_time)
    
    return ibias, vf
      
end --function measure_vf()
-- *****************************************************************************
function measure_vr(smux, src_irange, bias_current, src_vlimit, settle_time, nplc, meas_vrange)

--[[
    This function performs a reverse voltage measurement at the specified 
    bias current.  It configures the specified SMU using the given
    source and measure parameters.  The SMU applies the specified bias current  
    level, waits the specified amount of time to allow the current source and
    diode-under-test to settle, and then performs single simultaneous 
    measurements of voltage and current.  The SMU output is left after 
    the measurements are complete.
    
    Prerequisites:
        (1) The initialize_smu() function must be called prior to calling this 
            function.
        
    Pass parameters:
        * smux is the SMU being used for the test, either smua or smub.  
          smux defaults to smua if no SMU is specified.
        * src_irange is the value in amps used to set the current source 
          range.  If nil is passed to the function, then current source 
          autoranging is enabled.
        * bias_current is the current level in amps at which the forward
          voltage is to be measured.  If SMU Force HI is connected to 
          the anode of the diode, then to properly forward bias the diode, the 
          current bias must be entered as a positive value.
        * src_vlimit is the voltage limit in volts for the current source.
        * settle_time is the time in seconds to wait between applying the 
          bias current to the diode and performing the current and voltage 
          measurements.
        * nplc is the integration time for the analog-to-digital converter, and 
          is specified in terms of the number of powerline cycles.  The 
          allowed range of values is 0.001 to 25.  An "autozero once" is 
          performed after setting the NPLC value.
        * meas_vrange is the value in volts used to set the current measure
          range.  If no value or nil is passed to the function, then current 
          measure autoranging is enabled.
          
    Returned values:  None
        * vr is the measured reverse voltage
        * ibias is the measured value of the bias current
    --]]
    
    -- Default to smua if smux is not specified.
    if smux == nil then
        smux = smua
    end --if

    display_vmeas(smux) -- Set displayed measure function to voltage
    
    if src_irange == nil then  -- If no range is specified, then enable current source autorange
        smux.source.autorangei = smux.AUTORANGE_ON
    else                        -- Otherwise set a fixed current source range
        smux.source.rangei = src_irange
    end --if

    smux.source.limitv = src_vlimit         -- Set the voltage limit for the current source
    smux.source.func = smux.OUTPUT_DCAMPS   -- Set the source function to current

    if meas_vrange == nil then  -- If no range is specified, then enable voltage measure autorange
        smux.measure.autorangev = smux.AUTORANGE_ON
    else                        -- Otherwise set a fixed voltage measure range
        smux.measure.rangev = meas_vrange
    end --if
    
    smux.measure.nplc = nplc    -- Set integration time for integrating analog-to-digital converter
    smux.measure.autozero = smux.AUTOZERO_ONCE  -- Perform autozero once, and then disable autozero
    
    local ibias, vr = spoti_measiv(smux, bias_current, settle_time)
    
    return ibias, vr
    
end --function measure_vr()
-- *****************************************************************************
function measure_ir(smux, src_vrange, bias_voltage, src_ilimit, settle_time, nplc, meas_irange)

--[[
    This function performs a reverse leakage current measurement at the 
    specified bias voltage.  It configures the specified SMU using the given
    source and measure parameters.  The SMU applies the specified bias voltage  
    level, waits the specified amount of time to allow the voltage source and
    diode-under-test to settle, and then performs single simultaneous 
    measurements of voltage and current.  The SMU output is left on after 
    the measurements are complete.
    
    Prerequisites:
        (1) The initialize_smu() function must be called prior to calling this 
            function.
        
    Pass parameters:
        * smux is the SMU being used for the test, either smua or smub.  
          smux defaults to smua if no SMU is specified, i.e. if smux is nil.
        * src_vrange is the value in volts used to set the voltage source 
          range.  If nil is passed to the function, then voltage source 
          autoranging is enabled.
        * bias_voltage is the voltage level in volts at which the reverse 
          leakage current is to be measured.  If SMU Force HI is connected to 
          the anode of the diode, then to properly reverse bias the diode, the 
          voltage bias must be entered as a negative value.
        * src_ilimit is the current limit in amps for the voltage source.
        * settle_time is the time in seconds to wait between applying the 
          bias voltage to the diode and performing the current and voltage 
          measurements.
        * nplc is the integration time for the analog-to-digital converter, and 
          is specified in terms of the number of powerline cycles.  The 
          allowed range of values is 0.001 to 25.  An "autozero once" is 
          performed after setting the NPLC value.
        * meas_irange is the value in amps used to set the current measure
          range.  If no value or nil is passed to the function, then current 
          measure autoranging is enabled.

    Returned values:
        * ir is the measured leakage current
        * vbias is the measured value of the bias voltage
    --]]
    
    -- Default to smua if smux is not specified.
    if smux == nil then
        smux = smua
    end --if

    display_imeas(smux)    -- Set displayed measure function to current
    
    if src_vrange == nil then   -- If no range is specified, then enable voltage source autorange
        smux.source.autorangev = smux.AUTORANGE_ON
    else                        -- Otherwise set a fixed voltage source range
        smux.source.rangev = src_vrange
    end --if
 
    smux.source.limiti = src_ilimit         -- Set the current limit for the voltage source
    smux.source.func = smux.OUTPUT_DCVOLTS  -- Set the source function to voltage
    
    if meas_irange == nil then  -- If no range is specified, then enable current measure autorange
        smux.measure.autorangei = smux.AUTORANGE_ON
    else                        -- Otherwise set a fixed current measure range
        smux.measure.rangei = meas_irange
    end --if
    
    smux.measure.nplc = nplc    -- Set integration time for analog-to-digital converter
    smux.measure.autozero = smux.AUTOZERO_ONCE  -- Perform autozero once, and then disable autozero
    
    local ir, vbias = spotv_measiv(smux, bias_voltage, settle_time)
    
    return ir, vbias
      
end --function measure_ir()
-- *****************************************************************************
function do_beep(duration, frequency, count)
	for i = 1, count, 1 do
		beeper.beep(duration, frequency)
		delay(0.1)
	end
end

-- print("Functions Loaded")
