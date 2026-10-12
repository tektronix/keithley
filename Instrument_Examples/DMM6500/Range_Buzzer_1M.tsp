--[[
Range Buzzer v2

Purpose: Set upper and lower limits, and the meter will buzz within that resistance range.

Make sure upper is higher than lower, and lower is lower than higher.

Tested from 0 to 1MΩ.

Written by: EEVBlog user KungfuJosh (https://www.eevblog.com/forum/profile/?u=241412)
Source thread: https://www.eevblog.com/forum/testgear/tsp-and-lua-scripts-for-modern-keithley-dmms-smus-etc/
Reproduced with Permission.

]]

local function trigger_model_active()
    local state = trigger.model.state()
    return state == trigger.STATE_RUNNING or state == trigger.STATE_WAITING or state == trigger.STATE_BUILDING
end

local function stop_trigger_model()
    pcall(function() trigger.timer[1].enable = trigger.ON end)
    local timeout = 0.5
    while trigger_model_active() and timeout > 0 do
        delay(0.01)
        timeout = timeout - 0.01
    end

    if trigger_model_active() then
        trigger.model.abort()
    end
end

local function autoexec_exists()
    for name in script.catalog() do
        if name == "autoexec" then
            return true
        end
    end
    return false
end

local function end_app()
    stop_trigger_model()

    pcall(display.delete, ui.swipe1.root)
    ui = nil

    reset()
    if autoexec_exists() then
        autoexec.run()
    end
end

local function create_display()
    display.clear(display.SCREEN_HOME)
    ui = {}
    ui.swipe1 = {}
    ui.swipe1.root = display.create(display.SCREEN_HOME, display.OBJ_SWIPE, "Range Buzzer")
    ui.swipe1.lower_limit = display.create(ui.swipe1.root, display.OBJ_EDIT_NUMBER, 200, 10, "Lower Limit", "0 \18 ...1 M\18", display.NFORMAT_USER, 0, 0, 1000001, "\18")
    ui.swipe1.upper_limit = display.create(ui.swipe1.root, display.OBJ_EDIT_NUMBER, 620, 10, "Upper Limit", "1 \18 ...1 M\18", display.NFORMAT_USER, 1, 1, 1000001, "\18")
    ui.swipe1.duration = display.create(ui.swipe1.root, display.OBJ_EDIT_NUMBER, 200, 70, "Beep Duration", "10 ms...1 s", display.NFORMAT_USER, 0.01, 0.01, 1, "s")
    ui.swipe1.frequency = display.create(ui.swipe1.root, display.OBJ_EDIT_NUMBER, 620, 70, "Beep Frequency", "100 Hz...10 kHz", display.NFORMAT_INTEGER, 1000, 100, 10000, "Hz")
    ui.swipe1.exit = display.create(ui.swipe1.root, display.OBJ_BUTTON, 620, 130, "Exit", 150)
end

local function main()
    reset()

    create_display()
    dmm.measure.func = dmm.FUNC_RESISTANCE
    dmm.measure.range = 1000000
    dmm.measure.nplc = 0.0005
    trigger.timer[1].reset()
    trigger.timer[1].delay = 0.001
    trigger.timer[1].count = 1
    trigger.timer[1].start.stimulus = trigger.EVENT_NONE
    trigger.timer[1].start.generate = trigger.ON
    trigger.model.setblock(1, trigger.BLOCK_MEASURE, defbuffer1)
    trigger.model.setblock(2, trigger.BLOCK_BRANCH_ON_EVENT, trigger.EVENT_TIMER1, 4)
    trigger.model.setblock(3, trigger.BLOCK_BRANCH_ALWAYS, 1)
    trigger.model.setblock(4, trigger.BLOCK_NOP)
    trigger.model.initiate()

    while display.waitevent(0.001) ~= ui.swipe1.exit do
        if defbuffer1.n > 0 then
            local reading = defbuffer1.readings[defbuffer1.endindex]
            local upper = display.getvalue(ui.swipe1.upper_limit)
            local lower = display.getvalue(ui.swipe1.lower_limit)

            -- Beep only when reading is within the specified range
            if reading >= lower and reading <= upper then
                beeper.beep(display.getvalue(ui.swipe1.duration), display.getvalue(ui.swipe1.frequency))
            end
        end
    end

    end_app()
end

main()
