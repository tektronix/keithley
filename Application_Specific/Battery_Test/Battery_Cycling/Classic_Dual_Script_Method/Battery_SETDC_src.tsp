function main()
    util_SET_DC()
end

function util_SET_BUFF()
    defbuffer1.clear()
    defbuffer1.fillmode=buffer.FILL_ONCE
    defbuffer2.clear()
    defbuffer2.fillmode=buffer.FILL_ONCE
end

function util_SET_DC()
    reset()
    smu.source.func  = smu.FUNC_DC_CURRENT
    smu.measure.func = smu.FUNC_DC_VOLTAGE
    
    smu.source.offmode      = smu.OFFMODE_HIGHZ
    smu.source.autorange    = smu.OFF
    smu.source.range        = 1.0 -- A
    smu.source.vlimit.level = 20.0
    smu.source.autodelay    = smu.OFF
    smu.source.delay        = 0.0
    smu.source.readback     = smu.ON
    smu.source.highc        = smu.OFF
    
    smu.measure.autorange   = smu.ON
    smu.measure.nplc        = 1.0
    smu.measure.sense       = smu.SENSE_4WIRE
    smu.measure.terminals   = smu.TERMINALS_FRONT
    
    smu.source.level = 0.0
end

main()