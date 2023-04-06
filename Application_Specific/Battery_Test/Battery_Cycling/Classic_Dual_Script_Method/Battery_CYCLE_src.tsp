function main()
    local TCOND={batt={},CHG={},LD={}}
    local TRSLT={}
    local flg_exec
    
    flg_exec = util_SET_PARAM(TCOND)
    if flg_exec==true then
        util_SET_DC(TCOND)
        display.changescreen(display.SCREEN_HOME)
        
        if TCOND.batt.flg_start==1 then -- start from charge
            for k=1,TCOND.batt.iNcycle do
                util_SET_BUFF()
                util_DISP(k,'CHG', TCOND)
                TRSLT = util_BATT_CHG(TCOND)
                if TRSLT.flg_CCexit==true then break end
                util_SAVE(k,'CHG',TRSLT, TCOND)
                
                util_SET_BUFF()
                util_DISP(k,'LOAD', TCOND)
                TRSLT = util_BATT_LOAD(TCOND)
                util_SAVE(k,'LOAD',TRSLT, TCOND)
            end
        elseif TCOND.batt.flg_start==2 then -- start from load
            for k=1,TCOND.batt.iNcycle do
                util_SET_BUFF()
                util_DISP(k,'LOAD', TCOND)
                TRSLT = util_BATT_LOAD(TCOND)
                util_SAVE(k,'LOAD',TRSLT, TCOND)
                
                util_SET_BUFF()
                util_DISP(k,'CHG', TCOND)
                TRSLT = util_BATT_CHG(TCOND)
                if TRSLT.flg_CCexit==true then break end
                util_SAVE(k,'CHG',TRSLT, TCOND)
            end
        end
        
        chime()
    end
end

function util_SET_PARAM(TCOND)
    local flg_exec = false
    local TINPUT = {}
    
    -- INPUT GUI
    flg_exec, TINPUT = util_PARAM_INPUT()
    
    -- Mapping
    TCOND.batt.cap       = TINPUT.dCap -- mAh
    TCOND.batt.dVnomi    = TINPUT.dVnomi -- V
    TCOND.batt.flg_start = TINPUT.istart -- 1: from charge, 2:from discharge
    TCOND.batt.iNcycle   = TINPUT.iNcycle
    
    TCOND.CHG.dCcc       = TINPUT.dCcc -- C
    TCOND.CHG.dIchg      = TCOND.batt.cap*TCOND.CHG.dCcc*0.001 -- A
    TCOND.CHG.dVcv       = TINPUT.dVcv -- V
    TCOND.CHG.dIstop     = TINPUT.dIstop *0.001 -- mA-->A
    TCOND.CHG.dTccmax    = TINPUT.dTccmax * 3600.0 -- h-->sec
    TCOND.CHG.dTcvmax    = TINPUT.dTcvmax * 3600.0 -- h-->sec
    TCOND.CHG.iNchg      = 1000 -- pt
    TCOND.CHG.dTival_chg = 1/TCOND.CHG.dCcc * 3600.0/TCOND.CHG.iNchg -- sec
    if TCOND.CHG.dTival_chg<1.0 then TCOND.CHG.dTival_chg=1.0 end
    TCOND.CHG.dTwait     = 0.01 -- sec
    
    TCOND.LD.dCload      = TINPUT.dCload -- C
    TCOND.LD.dIload      = TCOND.batt.cap*TCOND.LD.dCload*0.001 -- A
    TCOND.LD.dVempty     = TINPUT.dVempty -- V
    TCOND.LD.iNpt_load   = 1000 -- pt
    TCOND.LD.iNpt_esr    = 100 -- pt
    TCOND.LD.dTival_load = 1/TCOND.LD.dCload * 3600.0/TCOND.LD.iNpt_load -- sec
    TCOND.LD.dTival_esr  = 1/TCOND.LD.dCload * 3600.0/TCOND.LD.iNpt_esr  -- sec
    TCOND.LD.dTdelay_esr = 0.1 -- sec
    TCOND.LD.dTwait      = 0.01 -- sec
    
    -- check USB drive
    if file.usbdriveexists()==0 then
        for i=1,4 do beeper.beep(0.05,2000) delay(0.05) end
        flg_exec=false
        display.prompt(display.BUTTONS_OK, "ERROR : No_USB_Drive")
        display.waitevent()
    end
    return flg_exec
end

function util_SET_BUFF()
    defbuffer1.clear()
    defbuffer1.fillmode=buffer.FILL_ONCE
    defbuffer2.clear()
    defbuffer2.fillmode=buffer.FILL_ONCE
end

function util_SET_DC(TCOND)
    reset() eventlog.clear()
    
    smu.source.func         = smu.FUNC_DC_VOLTAGE  -- preparation for CV mode
    smu.measure.func        = smu.FUNC_DC_CURRENT  -- preparation for CV mode
    smu.source.offmode      = smu.OFFMODE_HIGHZ    -- preparation for CV mode
    smu.measure.sense       = smu.SENSE_4WIRE      -- preparation for CV mode
    
    smu.source.func         = smu.FUNC_DC_CURRENT
    smu.measure.func        = smu.FUNC_DC_VOLTAGE
    smu.source.offmode      = smu.OFFMODE_HIGHZ
    smu.measure.sense       = smu.SENSE_4WIRE
    smu.source.level        = 0.0
    
    smu.source.autorange    = smu.OFF
    if TCOND.batt.flg_start==1 then -- start from charge
        smu.source.range = math.abs(TCOND.CHG.dIchg) -- A
    elseif TCOND.batt.flg_start==2 then -- start from load
        smu.source.range = math.abs(TCOND.LD.dIload) -- A
    end
    local dVal = math.abs(TCOND.batt.dVnomi*2.0)  if dVal>20.0 then dVal=20.0 end
    smu.source.vlimit.level = dVal
    smu.source.autodelay    = smu.OFF
    smu.source.delay        = 0.0
    smu.source.readback     = smu.ON
    smu.source.highc        = smu.OFF
    smu.measure.autorange   = smu.ON
    smu.measure.nplc        = 1.0
    smu.measure.terminals   = smu.TERMINALS_FRONT
end

function util_BATT_CHG(TCOND)
    local TRSLT={tload={}, topen={}, tchg={}, flg_CCexit=false}
    local dTlap=0.0  local dTlap_cvsta=0.0
    local dIchg=0.0
    local meas_flg=2  -- 2:before first meas, 1:after first meas, 0:exit
    
    -- CV mode
    util_SET_DC_CV(TCOND)
    smu.source.output=smu.ON  timer.cleartime()
    meas_flg=2
    dTlap_cvsta = timer.gettime()
    while meas_flg>0 do
        -- measure
        if ( timer.gettime()-dTlap>TCOND.CHG.dTival_chg or meas_flg==2 ) then
            smu.measure.readwithtime(defbuffer1)  dTlap=timer.gettime()
            table.insert(TRSLT.tchg, {time=dTlap, curr=defbuffer1.readings[defbuffer1.n], vout=defbuffer1.sourcevalues[defbuffer1.n]} )
            dIchg = defbuffer1.readings[defbuffer1.n]
            meas_flg = 1
        end
        -- judge exit
        if (dIchg<TCOND.CHG.dIstop or dTlap-dTlap_cvsta>TCOND.CHG.dTcvmax) then
            meas_flg = 0        
        elseif (dIchg>TCOND.CHG.dIchg*0.98 and dTlap-dTlap_cvsta>TCOND.CHG.dTccmax) then -- too long CC mode
            meas_flg = 0
            TRSLT.flg_CCexit=true  -- short mode failure
        end
    end
    
    smu.source.output=smu.OFF
    return TRSLT
end

function util_SET_DC_CV(TCOND)
    smu.source.func         = smu.FUNC_DC_VOLTAGE -- smu turned off
    smu.measure.func        = smu.FUNC_DC_CURRENT
    smu.source.range        = math.abs(TCOND.CHG.dVcv)
    smu.source.level        = math.abs(TCOND.CHG.dVcv)
    smu.source.ilimit.level = math.abs(TCOND.CHG.dIchg)
    smu.measure.autorange   = smu.ON
end

function util_BATT_LOAD(TCOND)
    local TRSLT={tload={}, topen={}, tchg={}, flg_CCexit=false}
    local dTlap=0.0  local dTlap_esr=0.0
    local dVload=0.0  local dVopen=0.0  local dResr=0.0
    local meas_flg=2  -- 2:before first meas, 1:after first meas, 0:exit
    
    util_SET_DC_LOAD(TCOND)
    smu.source.output=smu.ON  timer.cleartime()
    while meas_flg>0 do
        -- measure
        if ( timer.gettime()-dTlap_esr>TCOND.LD.dTival_esr or meas_flg==2 ) then
            smu.source.level = 0.0  delay(dTdelay_esr)  -- no load
            smu.measure.readwithtime(defbuffer2)  dTlap_esr=timer.gettime()
            smu.source.level = -1.0*math.abs(TCOND.LD.dIload)  -- restore load
            table.insert(TRSLT.topen, {time=dTlap_esr, vout=defbuffer2.readings[defbuffer2.n], curr=defbuffer2.sourcevalues[defbuffer2.n]} )
            dVopen = defbuffer2.readings[defbuffer2.n]
            if meas_flg==1 then
                dResr = (dVopen-dVload)/TCOND.LD.dIload  -- temporary ESR
            end
        end
        if ( timer.gettime()-dTlap>TCOND.LD.dTival_load or meas_flg==2 ) then
            smu.measure.readwithtime(defbuffer1)  dTlap=timer.gettime()
            table.insert(TRSLT.tload, {time=dTlap, vout=defbuffer1.readings[defbuffer1.n], curr=defbuffer1.sourcevalues[defbuffer1.n]} )
            dVload = defbuffer1.readings[defbuffer1.n]
            meas_flg=1  -- 2:before first meas, 1:after first meas
        end
        
        -- judge exit
        if (dVload+dResr*TCOND.LD.dIload)<TCOND.LD.dVempty and meas_flg==1 then
            smu.source.level = 0.0  delay(dTdelay_esr)  -- no load
            smu.measure.readwithtime(defbuffer2)  dTlap_esr=timer.gettime()
            table.insert(TRSLT.topen, {time=dTlap_esr, vout=defbuffer2.readings[defbuffer2.n], curr=defbuffer2.sourcevalues[defbuffer2.n]} )
            meas_flg=0
        end
        
        -- wait in loop
        if meas_flg>0 then delay(TCOND.LD.dTwait) end
    end
    smu.source.output=smu.OFF
    
    return TRSLT
end

function util_SET_DC_LOAD(TCOND)
    smu.source.func         = smu.FUNC_DC_CURRENT -- smu turned off
    smu.measure.func        = smu.FUNC_DC_VOLTAGE
    smu.source.range        = TCOND.LD.dIload
    smu.source.level        = 0.0
    local dVal = TCOND.batt.dVnomi*2.0  if dVal>20.0 then dVal=20.0 end
    smu.source.vlimit.level = dVal
    smu.measure.autorange   = smu.ON
end

function util_SAVE(idx, smode, TRSLT, TCOND)
    --IN  : idx   loop index
    --IN  : smode 'LOAD' or 'CHG'
    --IN  : result table
    --OUT : file  'BattLOAD_n.csv' 'BattCHG_n.csv'
    local fname  local fout
    local TMODL = util_GEN_MODEL(TCOND, TRSLT, smode)
    
    fname = string.format('Batt%s_%d.csv', smode, idx)
    fout  = file.open(string.format('/usb1/%s', fname), file.MODE_WRITE)
        if smode=='LOAD' then
            file.write( fout, "mAh,Open Voltage(V),ESR(ohm)\n" )
        elseif smode=='CHG' then
            file.write( fout, "time(sec),Voltage(V),Current(A)\n" )
        end
        for i=1,table.getn(TMODL.data) do
            file.write( fout, string.format("%f,%f,%f\n",  TMODL.data[i].x, TMODL.data[i].y1, TMODL.data[i].y2) )
        end
    file.close(fout)
end

function util_GEN_MODEL(TCOND, TRSLT, smode)
    local idxmax = 101 -- data number
    local TMODL={data={}}
    for i=1,idxmax do
        table.insert(TMODL.data, {idx=i, x=-999.9, y1=-999.9, y2=-999.9})
    end
    
    if smode=='LOAD' then
        local iNmax   = table.getn(TRSLT.tload)
        local dsecmax = TRSLT.tload[iNmax].time
        for i=1,idxmax do
            -- x  : mAh
            -- y1 : open voltage
            -- y2 : esr
            local dXtgt = dsecmax/idxmax * (i-1)  -- sec
            local dVload_tgt = util_BATT_FINDU(TRSLT.tload, dXtgt)
            local dVopen_tgt = util_BATT_FINDU(TRSLT.topen, dXtgt)
            local dESR_tgt   = (dVopen_tgt - dVload_tgt)/(0.0-(-TCOND.LD.dIload))
            TMODL.data[i].x  = TCOND.LD.dIload*1000.0 * dXtgt/3600.0  -- mAh
            TMODL.data[i].y1 = dVopen_tgt  -- open voltage
            TMODL.data[i].y2 = dESR_tgt    -- ESR ohm
        end
    elseif smode=='CHG' then
        local iNmax   = table.getn(TRSLT.tchg)
        local dsecmax = TRSLT.tchg[iNmax].time
        for i=1,idxmax do
            -- x  : time
            -- y1 : volt
            -- y2 : curr
            local dXtgt = dsecmax/idxmax * (i-1)  -- sec
            TMODL.data[i].x = dXtgt
            TMODL.data[i].y1, TMODL.data[i].y2 = util_CHG_FINDU(TRSLT.tchg, dXtgt)
        end
    end
    return TMODL
end

function util_BATT_FINDU(t1, dXtgt)
    --IN  : t1[i].time  xvalue
    --IN  : t1[i].vout  yvalue
    --IN  : dXtgt
    --OUT : dYtgt
    local dYtgt  local iNpt=table.getn(t1)
    local idx1   local idx2
    if iNpt>1 then
        if dXtgt<=t1[1].time then
            idx1=1  idx2=2
        elseif t1[iNpt].time<dXtgt then
            idx1=iNpt-1  idx2=iNpt
        else
            for i=1,iNpt-1 do
                if t1[i].time<dXtgt and dXtgt<=t1[i+1].time then
                    idx1=i  idx2=i+1
                    break
                end
            end
        end
        dYtgt=(t1[idx2].vout-t1[idx1].vout)/(t1[idx2].time-t1[idx1].time)*(dXtgt-t1[idx1].time)+t1[idx1].vout
    elseif iNpt==1 then
        dYtgt=t1[1].vout
    else
        dYtgt=-999.9
    end
    return dYtgt
end

function util_CHG_FINDU(t1, dXtgt)
    --IN  : t1[i].time  xvalue
    --IN  : t1[i].vout  y1value
    --IN  : t1[i].curr  y2value
    --IN  : dXtgt
    --OUT : dY1tgt
    --OUT : dY2tgt
    local dY1tgt local dY2tgt  local iNpt=table.getn(t1)
    local idx1   local idx2
    if iNpt>1 then
        if dXtgt<=t1[1].time then
            idx1=1  idx2=2
        elseif t1[iNpt].time<dXtgt then
            idx1=iNpt-1  idx2=iNpt
        else
            for i=1,iNpt-1 do
                if t1[i].time<dXtgt and dXtgt<=t1[i+1].time then
                    idx1=i  idx2=i+1
                    break
                end
            end
        end
        dY1tgt=(t1[idx2].vout-t1[idx1].vout)/(t1[idx2].time-t1[idx1].time)*(dXtgt-t1[idx1].time)+t1[idx1].vout
        dY2tgt=(t1[idx2].curr-t1[idx1].curr)/(t1[idx2].time-t1[idx1].time)*(dXtgt-t1[idx1].time)+t1[idx1].curr
    elseif iNpt==1 then
        dY1tgt=t1[1].vout
        dY2tgt=t1[1].curr
    else
        dY1tgt=-999.9
        dY2tgt=-999.9
    end
    return dY1tgt, dY2tgt
end

function util_PARAM_INPUT()
    local flg_exec    = true
    local flg_SET_BATT= false
    local flg_SET_CHG = false
    local flg_SET_LOAD= false    
    local TINPUT={}
    
    -- FIRST INPUT LOOP
    while (flg_SET_BATT==false or flg_SET_CHG==false or flg_SET_LOAD==false) do
        optionID=display.input.option( "INPUT ALL PARAMETERS",
                                       "Set BATTERY    ",
                                       "Set CHARGE     ",
                                       "Set LOAD       " )
        if optionID==nil then
            flg_exec = false  break
        elseif optionID==display.BUTTON_OPTION1 then
            flg_SET_BATT=util_PARAM_BATT(TINPUT)
        elseif optionID==display.BUTTON_OPTION2 then
            flg_SET_CHG =util_PARAM_CHG(TINPUT)
        elseif optionID==display.BUTTON_OPTION3 then
            flg_SET_LOAD=util_PARAM_LOAD(TINPUT)
        end
    end
    
    -- CONFIRMATION LOOP
    while flg_exec do
        optionID=display.input.option( "CONFIRMATION",
                                       "Set BATTERY    ",
                                       "Set CHARGE     ",
                                       "Set LOAD       ",
                                       ">>>>> EXECUTE  " )
        if optionID==nil then
            flg_exec = false  break
        elseif optionID==display.BUTTON_OPTION1 then
            util_PARAM_BATT(TINPUT)
        elseif optionID==display.BUTTON_OPTION2 then
            util_PARAM_CHG(TINPUT)
        elseif optionID==display.BUTTON_OPTION3 then
            util_PARAM_LOAD(TINPUT)
        elseif optionID==display.BUTTON_OPTION4 then
            flg_exec = true  break
        end
    end
    
    -- debug
    --print (flg_exec)
    --for key,val in TINPUT do
    --    print (key, tostring(val))
    --end
    
    return flg_exec, TINPUT
end

function util_PARAM_BATT(TINPUT)
    local flg_return = false
    if TINPUT.dCap==nil then TINPUT.dCap = 110.0 end    local flg_dCap    = false
    if TINPUT.dVnomi==nil then TINPUT.dVnomi = 3.7 end  local flg_dVnomi  = false
    if TINPUT.iNcycle==nil then TINPUT.iNcycle = 10 end local flg_iNcycle = false
    if TINPUT.istart==nil then TINPUT.istart = 1 end    local flg_start   = false
    
    while(flg_dCap==false or flg_dVnomi==false or flg_iNcycle==false or flg_start==false) do
        if flg_dCap==false then
            local val = display.input.number("Battery Capacitance (mAh)", display.NFORMAT_DECIMAL, TINPUT.dCap, 0.0, 5000) flg_dCap=true
            if val~=nil then TINPUT.dCap = val end
        end
        if flg_dVnomi==false then
            local val = display.input.number("Battery nominal voltage (V)", display.NFORMAT_DECIMAL, TINPUT.dVnomi, 0.0, 20.0) flg_dVnomi=true
            if val~=nil then TINPUT.dVnomi=val end
        end
        if flg_iNcycle==false then
            local val = display.input.number("Number of Test Cycle", display.NFORMAT_INTEGER, TINPUT.iNcycle, 0.0, 100.0) flg_iNcycle=true
            if val~=nil then TINPUT.iNcycle=val end
        end
        if flg_start==false then
            optionID = display.input.option("Test Start from...", "from Charge", "from Discharge" )
            if     optionID==nil                    then TINPUT.istart=1 -- from charge
            elseif optionID==display.BUTTON_OPTION1 then TINPUT.istart=1 -- from charge
            elseif optionID==display.BUTTON_OPTION2 then TINPUT.istart=2 -- from discharge
            end
            flg_start=true
        end
        optionID=display.input.option( "confirmation",
                                       "Batt Cap  (mAh)",
                                       "Batt Nominal(V)",
                                       "Test Cycle     ",
                                       "Test Start from",
                                       ">>>>> OK       " )
        if     optionID==nil                    then flg_return  =false  break
        elseif optionID==display.BUTTON_OPTION1 then flg_dCap    =false
        elseif optionID==display.BUTTON_OPTION2 then flg_dVnomi  =false
        elseif optionID==display.BUTTON_OPTION3 then flg_iNcycle =false
        elseif optionID==display.BUTTON_OPTION4 then flg_start   =false
        elseif optionID==display.BUTTON_OPTION5 then flg_return  =true   break
        end
    end
    return flg_return
end

function util_PARAM_CHG(TINPUT)
    local flg_return = false
    if TINPUT.dCcc==nil then TINPUT.dCcc = 1.0 end          local flg_dCcc = false
    if TINPUT.dVcv==nil then TINPUT.dVcv = 4.2 end          local flg_dVcv = false
    if TINPUT.dIstop==nil then TINPUT.dIstop = 10.0 end     local flg_dIstop = false
    if TINPUT.dTccmax==nil then TINPUT.dTccmax = 2.0 end    local flg_dTccmax = false
    if TINPUT.dTcvmax==nil then TINPUT.dTcvmax = 4.0 end    local flg_dTcvmax = false
    
    while(flg_dCcc==false or flg_dTccmax==false or flg_dVcv==false or flg_dIstop==false or flg_dTcvmax==false) do
        if flg_dCcc==false then
            local val = display.input.number("CC Charging Rate (C)", display.NFORMAT_DECIMAL, TINPUT.dCcc, 0.0, 5.0) flg_dCcc=true
            if val~=nil then TINPUT.dCcc=val end
        end
        if flg_dTccmax==false then
            local val = display.input.number("CC max time (h)", display.NFORMAT_DECIMAL, TINPUT.dTccmax, 0.0, 100.0) flg_dTccmax=true
            if val~=nil then TINPUT.dTccmax=val end
        end
        if flg_dVcv==false then
            local val = display.input.number("CV voltage (V)", display.NFORMAT_DECIMAL, TINPUT.dVcv, 0.0, 20.0) flg_dVcv=true
            if val~=nil then TINPUT.dVcv=val end
        end
        if flg_dIstop ==false then
            local val = display.input.number("CV stop current (mA)", display.NFORMAT_DECIMAL, TINPUT.dIstop, 0.0, 1000.0) flg_dIstop=true
            if val~=nil then TINPUT.dIstop=val end
        end
        if flg_dTcvmax==false then
            local val = display.input.number("CV max time (h)", display.NFORMAT_DECIMAL, TINPUT.dTcvmax, 0.0, 100.0) flg_dTcvmax=true
            if val~=nil then TINPUT.dTcvmax=val end
        end
        optionID=display.input.option( "confirmation",
                                       "ChargingRate(C)",
                                       "CC max time (h)",
                                       "CV Voltage  (V)",
                                       "CV Stop I  (mA)",
                                       "CV max time (h)",
                                       ">>>>> OK       " )
        if     optionID==nil                    then flg_return  =false  break
        elseif optionID==display.BUTTON_OPTION1 then flg_dCcc    =false
        elseif optionID==display.BUTTON_OPTION2 then flg_dTccmax =false
        elseif optionID==display.BUTTON_OPTION3 then flg_dVcv    =false
        elseif optionID==display.BUTTON_OPTION4 then flg_dIstop  =false
        elseif optionID==display.BUTTON_OPTION5 then flg_dTcvmax =false
        elseif optionID==display.BUTTON_OPTION6 then flg_return  =true   break
        end
    end
    return flg_return
end

function util_PARAM_LOAD(TINPUT)
    local flg_return = false
    if TINPUT.dCload==nil then TINPUT.dCload = 1.0 end      local flg_dCload = false
    if TINPUT.dVempty==nil then TINPUT.dVempty = 3.0 end    local flg_dVempty = false
    
    while(flg_dCload==false or flg_dVempty==false) do
        if flg_dCload==false then
            local val = display.input.number("DisCharging Rate (C)", display.NFORMAT_DECIMAL, TINPUT.dCload, 0.0, 5.0) flg_dCload=true
            if val~=nil then TINPUT.dCload=val end
        end
        if flg_dVempty==false then
            local val = display.input.number("Empty Level (V)", display.NFORMAT_DECIMAL, TINPUT.dVempty, 0.0, 20.0) flg_dVempty=true
            if val~=nil then TINPUT.dVempty=val end
        end
        optionID=display.input.option( "confirmation",
                                       "DisCHG Rate (C)",
                                       "Batt Empty  (V)",
                                       ">>>>> OK       " )
        if     optionID==nil                    then flg_return  =false  break
        elseif optionID==display.BUTTON_OPTION1 then flg_dCload  =false
        elseif optionID==display.BUTTON_OPTION2 then flg_dVempty =false
        elseif optionID==display.BUTTON_OPTION3 then flg_return  =true   break
        end
    end
    return flg_return
end

function chime()
    t=0.2
    beeper.beep(t,1318)
    beeper.beep(t,1046)
    beeper.beep(t,1174)
    beeper.beep(t*1.5,784)
    delay(t*0.5)
    beeper.beep(t,784)
    beeper.beep(t,1174)
    beeper.beep(t,1318)
    beeper.beep(t*1.5,1046)
    delay(t*0.5)
    beeper.beep(t,1046)
    beeper.beep(t,1318)
    beeper.beep(t,1174)
    beeper.beep(t*1.5,784)
    delay(t*0.5)
    beeper.beep(t,784)
    beeper.beep(t,1174)
    beeper.beep(t,1318)
    beeper.beep(t*1.5,1046)
end

function util_DISP(idx, smode, TCOND)
    --IN  : idx   loop index
    --IN  : smode 'LOAD' or 'CHG'
    local sout1  local sout2
    if smode=='LOAD' then
        if     TCOND.batt.flg_start==1 then iseq=2
        elseif TCOND.batt.flg_start==2 then iseq=1
        end
        sout1 = string.format("LOAD")
        sout2 = string.format("Cycle : %03d/%03d - %d", idx, TCOND.batt.iNcycle, iseq)
    elseif smode=='CHG'  then
        if     TCOND.batt.flg_start==1 then iseq=1
        elseif TCOND.batt.flg_start==2 then iseq=2
        end
        sout1 = string.format("CHARGE")
        sout2 = string.format("Cycle : %03d/%03d - %d", idx, TCOND.batt.iNcycle, iseq)
    end
    --display.changescreen(display.SCREEN_USER_SWIPE)
    display.clear()
    display.settext(display.TEXT1,sout1)
    display.settext(display.TEXT2,sout2)
end

main()