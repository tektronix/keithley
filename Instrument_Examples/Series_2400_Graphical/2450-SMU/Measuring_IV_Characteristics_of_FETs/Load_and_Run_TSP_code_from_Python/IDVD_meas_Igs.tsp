
--[[

     Keithley 2450 TSP Lua script for FET ID–VD curves using two SMUs.
    - Gate: node[1] (alias 'smu' on local instrument)
    - Drain: node[2]
    - Measures gate current (Igs) at every Vds point for each Vgs step.

    Tested originally with 2450 @ FW 1.7.16a
	
	TSPLINK node 1 = Gate
	TSPLINK node 2 = Drain
	
	Front Terminals, 2-Wire connections
    

]]

-----------------------------
-- User-adjustable settings --
-----------------------------
local VGS_STEPS = {2, 3, 4, 5}     -- Vgs values to step
local VDS_START = 0                -- Vds sweep start (V)
local VDS_STEP  = 0.1              -- Vds step (V)
local VDS_POINTS = 51              -- number of points (e.g., 0..5 V in 0.1 V -> 51 points)
local VDS_DELAY_S = 0.01           -- optional settle time per Vds point (s), e.g. 10 ms

-- Gate SMU (node 1 / local 'smu') measure autorange low threshold
local GATE_AUTORANGE_LOW = 100e-9  -- A
local GATE_ILIMIT_A = 100e-6   -- also affects resting range if rebound turned on.

-- Drain SMU current limit and range
local DRAIN_ILIMIT_A  = 100e-3
local DRAIN_MEAS_RANGE_A = 100e-3

-------------------------
-- Utility / Core funcs --
-------------------------

function ensure_tsplink_online_or_quit()
    
    reset()
    eventlog.clear()
    status.clear()
	
	tsplink.initialize()

    local state = tsplink.state
    if state ~= "online" then
        print("Error:\n- Check that all SMUs have different node numbers\n- Check that all SMUs are connected correctly\n")
        return false
    end
    return true
end

function setup_gate_smu()
    -- Model 2450 #1 (gate) setup
    smu.source.func = smu.FUNC_DC_VOLTAGE
    smu.source.range = 20
    smu.source.ilimit.level = GATE_ILIMIT_A
    smu.measure.func = smu.FUNC_DC_CURRENT
    smu.measure.autorange = smu.ON
    smu.measure.terminals = smu.TERMINALS_FRONT
    smu.measure.autorangelow = GATE_AUTORANGE_LOW
    --smu.measure.autorangerebound = smu.ON  -- to avoid range compliance 
end

function setup_drain_smu()
    -- Model 2450 #2 (drain) setup
    local dsmu = node[2].smu
    dsmu.source.func  = dsmu.FUNC_DC_VOLTAGE
    dsmu.source.range = 20
    dsmu.source.ilimit.level = DRAIN_ILIMIT_A

    dsmu.measure.func = dsmu.FUNC_DC_CURRENT
    dsmu.measure.autorange = dsmu.OFF
    dsmu.measure.terminals = dsmu.TERMINALS_FRONT
    dsmu.measure.range = DRAIN_MEAS_RANGE_A
end


function build_vds_sweep(start_v, step_v, points)
    local t = {}
    for i = 1, points do
        t[i] = start_v + step_v * (i - 1)
    end
    return t
end


function clear_all_buffers()
    defbuffer1.clear()             -- gate node (node[1])
    node[2].defbuffer1.clear()     -- drain node (node[2])
end

function set_outputs(enable)
    local on = enable and smu.ON or smu.OFF
    smu.source.output = on
    node[2].smu.source.output = enable and node[2].smu.ON or node[2].smu.OFF
end

function measure_idvd(vgs_list, vds_sweep, delay_s)
    local count = 0
    --for each Vgs level
    for i = 1, table.getn(vgs_list) do
        smu.source.level = tonumber(vgs_list[i])

        --Do the Vds Sweep and measure Ids and Igs
        for j = 1, table.getn(vds_sweep) do    
            node[2].smu.source.level = tonumber(vds_sweep[j])

            if delay_s and delay_s > 0 then
                delay(delay_s) -- settle / emulate trigger model delay
            end

            node[2].smu.measure.read() -- drain current (Ids)
            smu.measure.read()         -- gate current (Igs)
            count = count + 1
        end

        -- Return drain to 0 V between Vgs steps
        node[2].smu.source.level = 0
    end

    -- Force gate back to 0 V at end (drain already returned to 0 V in loop)
    smu.source.level = 0

    return count
end


function print_results()
    local gate_buf  = node[1].defbuffer1
    local drain_buf = node[2].defbuffer1

    if gate_buf.n == 0 or drain_buf.n == 0 then
        print("\nNo readings in buffer\n")
        return
    end

    -- Header: Vds    Ids    Vgs    Igs
    --print("Vds\tIds\t\tVgs\tIgs")
    --print("Vds..','..Ids..','..Vgs..','..Igs")

    -- We assume both buffers advanced in lockstep: one pair per Vds point per Vgs step
    --local n = math.min(gate_buf.n, drain_buf.n, expected_points)
    
    printbuffer(1, drain_buf.n,
                   drain_buf.sourcevalues, drain_buf,
                   gate_buf.sourcevalues,  gate_buf)
   
end

--local function run_test()
function run_test(vgs_steps, vds_start, vds_step, vds_pts, vds_delay)

    if not ensure_tsplink_online_or_quit() then
        return
    end

    --TODO:  make some setup parameters for range, limits, etc.
    -- hard coding 20V source range, Ids with fixed 100mA range and limit
    -- Igs with 100nA and higher auto ranges and 10mA limit
    setup_gate_smu()
    setup_drain_smu()

    --local vds_sweep = build_vds_sweep(vds_start, vds_step, vds_pts)
    local vds_sweep = build_vds_sweep(tonumber(vds_start), tonumber(vds_step), tonumber(vds_pts))
    clear_all_buffers()

    -- config status subsystem to raise SRQ when opc() runs
    status.request_enable = 32  -- enable Evebt Summary Bit (ESB)
    status.standard.enable = 1  -- enable OPC bit to feed ESB

    timer.cleartime()
    local t0 = timer.gettime()

    set_outputs(true)  -- blue lights on 
    --local expected_total_points = table.getn(vgs_steps) * table.getn(vds_sweep)
    local acquired = measure_idvd(vgs_steps, vds_sweep, vds_delay)
    set_outputs(false)  -- blue lights off

    local test_time = timer.gettime() - t0  -- store our benchmark time

      --assert SRQ
    opc()

    return test_time
  
end



-- to run the code from TSP Toolkit or TSB, uncomment these lines 

--ensure_tsplink_online_or_quit()

--benchmark = run_test(VGS_STEPS, VDS_START, VDS_STEP, VDS_POINTS, VDS_DELAY_S)
--print(benchmark)

--print_results()
--print_results()