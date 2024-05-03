
--[[

This example requires a Model 2612A (or similar)and 2 Model 2651A.  One channel (SMU A) of the 2612A is used to drive the gate 
of a transistor with a linear staircase voltage sweep. The two outputs of the 2651As are connected and operated in 
parallel to drive the drain with one fixed amplitude voltage pulse for each step of the gate sweep. One 2651A is configured as 
a V-source, and the other 2561A is configured as an I-source.  The I-source is used to effectively increase the current 
compliance of the V-source.

Written By: Keithley Facotry Applications (Al Ivons)

Requirements (TBD):

	- Sweep the gate from X to Y in Z steps; compliance = TBD.
	- Must turn on gate BEFORE pulsing the drain (Check if necessary for Fairchild FCH35N60
	- Pulse the drain with up to 40V max; compliance of both SMUs set to TBD for a total of TBD. Max pulse width is region-dependent.
	- Measure Ig and Id
	- All SMUs should have their high-C mode enabled (Don't believe this is required, but leave high-C stuff in from original function)
	
Some hardware driven requirements:

	- 2651A SMUs will be be used in an Extended Operating Area (EOA).  Pulse width and duty cycle are 
	  limited as follows:
	  	- Max pulse width = region-dependent
	  	- Max duty cycle = region-dependent
]]

--[[

The basic approach used is as follows:
	1. Specify the 2651A operating region to be used for test (Ivons renumbered regions for this test);
	   Region = 0 will automatically pick the region based on Drain Voltage and corresponding I-limit
	2. Specify drain pulse width (PW).  If PW is too large for the specified region, it will automatically 
	   be reduced to 98% of the maximum pulse width allowed for the selected operating region (allow 2% timing
	   margin).  Note: Program DOES NOT force margin if user specifies max PW allowed for region.
	3. Specify the duty cycle (DC) for the drain pulse.  If DC is too large for the specified region, it 
	   will automatically be reduced to the 98% maximum duty cycle allowed for the selected operating region 
	   (allow 2% timing margin).  Note: Program DOES NOT force margin if user specifies max DC allowed for region. 
	4. Calculate drain pulse period (PERIOD = PW/DC).
	5. Use PERIOD as the time interval per step for Gate staircase sweep.
	6. Initiate the drain voltage pulse "sweep," which will sit waiting to be synchronized with gate sweep.
	7. Initiate the gate voltage sweep.  Note: Gate sweep waits for confirmation that drain pulse completed.
	8. Assert a Dig I/O line to generate digio.trigger[N].EVENT_ID to start the PERIOD timer with passthrough enabled.
	9. Use the PERIOD timer EVENT_ID to start the GATE MEASURE timer with interval set to PULSE DELAY + PW/2, and
	   also to drive TSP-Link trigger line #1.
	10. Use TSP-Link trigger line #1 to start the PULSE DELAY timer on the drain 2602A with interval set to PERIOD/2.
	11. Use PULSE DELAY timer EVENT_ID to trigger the source actions on both drain SMUs and to start the PW timer with
	   interval set to PW, and also to start DRAIN MEASURE timer with interval set (at least initially) to PW/2.
	12. Use DRAIN MEASURE timer and GATE MEASURE timer EVENT_IDs to start measure actions on drain and gate SMUs,
	    respectively.  Use NPLC=0.001 to start.
	13. Use PW timer to trigger the endpulse action for drain SMUs.
]]

--[[

This demo is set up to work with Keithley's ACS Basic software.  It requires 1 Model 2612A (or similar) set as Node 01, and
2 Model 2651A, one set as Node 02 and the other set as Node 3. 
]]
--  It is assumed that TSP Link is reset by ACS Basic prior to running this script
--	tsplink.reset()
--	tsplink_status = tsplink.state
--	print(tsplink_status)

--	ACS Basic should automatically set up the following global aliases: (NOW DOES NOT APPEAR TO BE TRUE 02/11/2009)
--  Note added by Ivons on 12/16/2010: SMUX is a table; SMUX[1] is node[N].smuY, e.g. SMU1[1] is node[1].smua
--	SMU1 = node[1].smua
--	SMU2 = node[1].smub
--	SMU3 = node[2].smua

	--============================================================================
	-- 
	-- Pulse Region definitions - From KIPulse Factory Script
	-- Ivons added 2651A info on 12/16/2010
	-- Ivons modified 2651A region numbers to be consistent with other models
	-- Ivons corrected limit errors for other models based on his table of values
	--
	--============================================================================
	
	local PULSE_REGIONS =				-- These regions are local to the script
	{
    	-- ilimit = max DC and/or PULSE current
    	-- vlimit = max DC and/or PULSE voltage
    	-- mbi  = max bias (DC) level i
    	-- mblv = max bias (DC) limit v
    	-- mbv  = max bias (DC) level v
    	-- mbli = max bias (DC) limit i
    	
    	["2601A"] = 
    	{
        	[1] = { ilimit= 1.0,  vlimit=40,   mpw=4200,      dc=1.00,   mbi=1.,   mblv=40,  mbv=40,   mbli=1  },      -- SOA
        	[2] = { ilimit= 3.0,  vlimit= 6,   mpw=4200,      dc=1.00,   mbi=3.,   mblv= 6,  mbv= 6,   mbli=3  },      -- SOA
        	[3] = { ilimit= 1.5,  vlimit=40,   mpw=100.0e-3,  dc=0.25,   mbi=3,    mblv= 6,  mbv=40,   mbli=1  },      -- EOA
        	[4] = { ilimit= 5.0,  vlimit=35,   mpw=  4.0e-3,  dc=0.04,   mbi=3,    mblv= 6,  mbv=40,   mbli=1  },      -- EOA
        	[5] = { ilimit=10.0,  vlimit=20,   mpw=  1.8e-3,  dc=0.01,   mbi=3,    mblv= 6,  mbv=40,   mbli=1  }       -- EOA
    	},
    	["2611A"] = 
    	{
        	[1] = { ilimit= 0.1,  vlimit=200,  mpw=4200,      dc=1.000,  mbi=0.1,  mblv=200, mbv=200,  mbli=0.1 },      -- SOA
        	[2] = { ilimit= 1.5,  vlimit= 20,  mpw=4200,      dc=1.000,  mbi=1.5,  mblv=20,  mbv= 20,  mbli=1.5 },      -- SOA
        	[3] = { ilimit= 1.0,  vlimit=180,  mpw=8.5e-3,    dc=0.010,  mbi=1.0,  mblv=20,  mbv=200,  mbli=0.1 },      -- EOA
        	[4] = { ilimit= 1.0,  vlimit=200,  mpw=2.2e-3,    dc=0.010,  mbi=0.0,  mblv=0,   mbv=200,  mbli=0.1 },      -- EOA
        	[5] = { ilimit=10.0,  vlimit=  5,  mpw=1.0e-3,    dc=0.022,  mbi=1.5,  mblv=20,  mbv= 20,  mbli=1.5 }       -- EOA
    	},
    	["2651A"] = 
    	{
        	[1] = { ilimit= 5,    vlimit=40,   mpw=4200,      dc=1.00,  mbi=5,     mblv=40,  mbv=40,   mbli=5   },      -- SOA
        	[2] = { ilimit=10,    vlimit=20,   mpw=4200,      dc=1.00,  mbi=10,    mblv=20,  mbv=20,   mbli=10  },      -- SOA
        	[3] = { ilimit=20,    vlimit=10,   mpw=4200,      dc=1.00,  mbi=20,    mblv=10,  mbv=10,   mbli=20  },      -- SOA
        	[4] = { ilimit=10,    vlimit=40,   mpw=1.5e-3,    dc=0.40,  mbi=10,    mblv=20,  mbv=40,   mbli=5   },      -- EOA
        	[5] = { ilimit=20,    vlimit=20,   mpw=1.5e-3,    dc=0.40,  mbi=20,    mblv=10,  mbv=20,   mbli=10  },      -- EOA
        	[6] = { ilimit=50,    vlimit=10,   mpw=1.0e-3,    dc=0.35,  mbi=20,    mblv=10,  mbv=10,   mbli=20  },      -- EOA
        	[7] = { ilimit=50,    vlimit=20,   mpw=330e-6,    dc=0.10,  mbi=20,    mblv=10,  mbv=20,   mbli=10  },      -- EOA
        	[8] = { ilimit=50,    vlimit=40,   mpw=300e-6,    dc=0.01,  mbi=20,    mblv=10,  mbv=40,   mbli=5   }       -- EOA; was mpw=165e-6; changed on 01/05/2011
    	},
	}
	
	PULSE_REGIONS["2602A"] = PULSE_REGIONS["2601A"]	-- Cannot use PULSE_REGIONS.2601A because 2601A is not a proper
	PULSE_REGIONS["2612A"] = PULSE_REGIONS["2611A"]	--   Lua identifier; must start with a letter;
	PULSE_REGIONS["2635A"] = PULSE_REGIONS["2611A"]	--   e.g PULSE_REGIONS.A2601 is OK
	PULSE_REGIONS["2636A"] = PULSE_REGIONS["2611A"]

	--============================================================================
	-- HELPER FUNCTIONS
	--============================================================================
	
function ResetTspLink(Print_TsplinkState)
	
	local status
	local msg
		
	tsplink.reset()
	
	if tsplink.state == "online" then
		status = true
	else
		status = false
	end --if
		
	msg = "TSP-Link is "..tsplink.state
		
	if Print_TsplinkState == true then
			print(msg)
	end --if
		
	return status, msg
		
end --function ResetTspLink
	
function PrintUnitInfo()
	
	if tsplink.state == "online" then 
			
		for i = 1, 64 do
			if node[i] ~= nil then
				print()
				print("Node Number:|".."node["..i.."]")
				print("Model Number:|"..node[i].model)
				print("S/N:|"..node[i].serialno)
				print("FW Rev:|"..node[i].revision)
			end --if
		end --for
			
	else
		
		print()
		print("Node Number:|".."Localnode Only")
		print("Model Number:|"..localnode.model)
		print("S/N:|"..localnode.serialno)
		print("FW Rev:|"..localnode.revision)
			
	end --if
		
	print()
	
end --function CheckUnitInfo

	------------------------------------------------------------------------------
	--
	-- CheckPulseRegionI - Borrowed from KIPulse Factory Script (20 Dec 2010)
	-- 
	-- Check pulse region for a current pulse.  The bias and level are in Amps,
	-- the limit in Volts.
	--
	------------------------------------------------------------------------------

function CheckPulseRegionI(bias, level, limit, rg)       
    local b = math.abs(bias)
	local lv = math.abs(level)
    local lm = math.abs(limit)
    local l = math.max(b, lv)
    local r, region
    local ret = nil
    for r, region in ipairs(rg) do
        if (l <= region.ilimit) and (lm <= region.vlimit) then
            ret = r
            break
        end --if
    end --for
    return ret
end --function CheckPulseRegionI

	------------------------------------------------------------------------------
	--
	-- CheckPulseRegionV - Borrowed from KIPulse Factory Script (20 Dec 2010)
	--
	-- Check pulse region for a voltage pulse.  The bias and level are in Volts,
	-- the limit in Amps.
	--
	------------------------------------------------------------------------------

function CheckPulseRegionV(bias, level, limit, rg)
    local b = math.abs(bias)
    local lv = math.abs(level)
    local lm = math.abs(limit)
    local l = math.max(b, lv)
    local r, region
    local ret = nil
    for r, region in ipairs(rg) do
        if (l <= region.vlimit) and (lm <= region.ilimit) then
            ret = r
            break
        end --if
    end --for
    return ret
end --function CheckPulseRegionV

	------------------------------------------------------------------------------
	--
	-- CheckBiasRegionI - Borrowed from KIPulse Factory Script (20 Dec 2010)
	--
	-- Check bias region for a current pulse.  Check bias level and limit
	-- during bias conditions.  Determine the voltage limit to set during bias.
	-- The bias is in Amps, the limit in Volts.  r is a region.
	--
	------------------------------------------------------------------------------

function CheckBiasRegionI(bias, limit, r)
    local b = math.abs(bias)
    local lm = math.abs(limit)

    if (b > r.mbi) then
        return nil
    end --if
    lm = math.min(lm, r.mblv)
    return lm
end --function CheckBiasRegionI

	------------------------------------------------------------------------------
	--
	-- CheckBiasRegionV - Borrowed from KIPulse Factory Script (20 Dec 2010)
	--
	-- Check bias region for voltage pulse.  Check bias level and limit
	-- during bias conditions.  Determine the voltage limit to set during bias.
	-- The bias is in Volts, the limit in Amps.  r is a region.
	------------------------------------------------------------------------------

function CheckBiasRegionV(bias, limit, r)
    local b = math.abs(bias)
    local lm = math.abs(limit)

    if (b > r.mbv) then
        return nil
    end --if
    lm = math.min(lm, r.mbli)
    return lm
end --function CheckBiasRegionV

	------------------------------------------------------------------------------
	--
	-- CheckRegionLimits - Borrowed from KIPulse Factory Script (20 Dec 2010)
	--
	-- Check the pulse region against the specified ON and OFF times to 
	-- verify pulse width and duty cycle limits.
	------------------------------------------------------------------------------
--[[
	function CheckRegionLimits(region, ton, tofftable)
    	local dc
    	local p = table.getn(tofftable)
    	local i
    
    	if (ton < 200e-6) then
        	return false, "Pulse too short"
    	end --if
    
    	if (ton > region.mpw) then
        	return false, "Pulse too long"
    	end --if
    
    	for i=1,p do
        	if (tofftable[i] < 0) then
            	return false, "Invalid off time"
        	end --if
        
        	dc = ton / (ton + tofftable[i])
        	if (dc > region.dc) then
            	return false, "Duty cycle exceeded"
        	end --if
    	end --for
    
    	return true, ""
	end --function CheckRegionLimits
]]	
function CheckRegionLimits_IvonsMod(region, pulse_width, duty_cycle)
    --local dc
    --local p = table.getn(tofftable)
    --local i
    
    if (pulse_width < 100e-6) then
        return false, "Pulse too short"
    end --if
    
    if (pulse_width > region.mpw) then
        return false, "Pulse too long"
    end --if
    
    if (duty_cycle > region.dc) then
        return false, "Duty cycle exceeded"
    end --if
    
    return true, ""
end --function CheckRegionLimits_IvonsMod

function TurnOffAll()
	node[3].smua.source.output = 0
	node[2].smua.source.output = 0
	node[1].smua.source.output = 0
end --function TurnOffAll

function SweepGate_PulseDrain(GateStartV, GateStopV, GateStepV, GateIlimit, DrainSmuMode, DrainSmuRegionIndex, DrainVpulseLevel, DrainIlimit, DrainIsrc_ZeroAmpMode, DrainPulseWidth, DrainDutyCycle, Nplc, EnableHighC, 
								Digitize, DigInterval, DigCount, PreTrigPercent, CheckParamOnly, VsrcCmplOff, VsrcLagDelay, IsrcPulseWidth, Use2wire)

	-- DrainSmuMode = 1 or 2
	--   1:  Always split current between Drain V-source and I-source
	--   2:  Only use Drain I-source if V-source can't supply enough current
	--   "else" condition will select mode 1

	-- DrainSmuRegionIndex = 0, 1, 2, 3, 4, 5, 6, 7, or 8
	--   0:  Will automatically select appropriate SMU operating region based on DrainVpulseLevel and DrainIlimit
	--   1:  Region 1: 40V @  5A or  5A @ 40V (SOA, i.e Safe Operating Area)
	--   2:  Region 2: 20V @ 10A or 10A @ 20V (SOA)
	--   3:  Region 3: 10V @ 20A or 20A @ 10V (SOA)
	--   4:  Region 4: 40V @ 10A or 10A @ 40V (EOA, i.e. Extended Operating Area, Pulsed Operation Only)
	--   5:  Region 5: 20V @ 20A or 20A @ 20V (EOA)
	--   6:  Region 6: 10V @ 50A or 50A @ 10V (EOA)
	--   7:  Region 7: 20V @ 50A or 50A @ 20V (EOA)
	--   8:  Region 8: 40V @ 50A or 50A @ 40V (EOA)
	--   Entries less than zero are set to zero
	--   Entries greater than 8 are set to 8
	--   Other entries set rounded down to closest integer (math.floor)
	--   For Index = 0, the function will exit if an appropriate operating region is not found
	--   For Index ~= 0, the function will exit if either DrainVpulseLevel or DrainIlimit is outside the specified region
	--   Once specified, the same operating region will be used for both the Drain V-source and I-source
	--   NOTE:  IT IS STILL TO BE DETERMINED IF I CAN FORCE THE SMUS TO OPERATE IN A SPECIFIED OPERATING REGION
	
	-- DrainIsrc_ZeroAmpMode = "ZeroAmp" or "HighZ"
	--   Comes into play if DrainSmuMode = 2, and the required Drain I-source level is zero amps
	--     "ZeroAmp": Set I-source I-level = 0 if not required, and turn output on.
	--     "HighZ": If Drain I-source is not required, set its off-state impedance = High-Z, and leave its output turned off
	--   "else" condition will select "ZeroAmp" mode

	print()
	print("GateStartV:|"..GateStartV)
	print("GateStopV:|"..GateStopV)
	print("GateStepV:|"..GateStepV)
	print("GateIlimit:|"..GateIlimit)
	print("DrainSmuMode:|"..DrainSmuMode)
	print("DrainSmuRegionIndex:|"..DrainSmuRegionIndex)
	print("DrainVpulseLevel:|"..DrainVpulseLevel)
	print("DrainIlimit:|"..DrainIlimit)
	print("DrainIsrc_ZeroAmpMode:|"..DrainIsrc_ZeroAmpMode)
	print("DrainPulseWidth:|"..DrainPulseWidth)
	print("DrainDutyCycle:|"..DrainDutyCycle)
	print("Nplc:|"..Nplc)
	print("EnableHighC:|"..tostring(EnableHighC))
	print("Digitize:|"..tostring(Digitize))
	print("DigInterval:|"..tostring(DigInterval))
	print("DigCount:|"..tostring(DigCount))
	print("PreTrigPercent:|"..tostring(PreTrigPercent))
	print("VsrcCmplOff:|"..tostring(VsrcCmplOff))	-- Ivons added on 21 Jan 2011
	print("VsrcLagDelay:|"..VsrcLagDelay)			-- Ivons added on 21 Jan 2011
	print("IsrcPulseWidth:|"..IsrcPulseWidth)		-- Ivons added on 21 Jan 2011
	print("Use2wire:|"..tostring(Use2wire))			-- Ivons added on 21 Jan 2011

	if tsplink.state ~= "online" then
		if not(ResetTspLink(true)) then
			return
		end --if
	end --if		 
	
	-- Create local aliases for NODEs and SMUs
	
	-- Create aliases for nodes
	local N1 = node[1]
	local N2 = node[2]
	local N3 = node[3]
		
	-- The following SMUX aliases are equivalent, but not identical, to ACS's SMUX aliases.
	-- That is, node[1].smua is the same physical SMU as referenced by ACS SMU1, but ACS SMU1<>node[1].smua
	local GATE = N1.smua
	local DRAIN_V = N2.smua
	local DRAIN_I = N3.smua
	
	-- Assign the Pulse or Operating Region based on the model number
	local GATE_PULSE_REGIONS = PULSE_REGIONS[N1.model]	-- Set up for now, but probably won't need because low power only
	local DRAIN_PULSE_REGIONS = PULSE_REGIONS[N2.model]	-- The same region will be used for both the V-source and the I-source
	
	-- Specify/check SMU source levels (including passed values) and select operating region(s)
	
	local drain_smu_mode
	local drain_pulse_ilimit
	
	if DrainSmuMode == 1 then
		drain_smu_mode = 1
		drain_pulse_ilimit = DrainIlimit / 2	-- Drain SMUs will each supply maximum of half of necessary current
	elseif DrainSmuMode == 2 then
		drain_smu_mode = 2
		drain_pulse_ilimit = DrainIlimit		-- DRAIN_I SMU will only supply excess current required by DRAIN_V SMU
	else
		drain_smu_mode = 1
		drain_pulse_ilimit = DrainIlimit / 2	-- Drain SMUs will each supply maximum of half of necessary current
	end --if
	
	print()
	print("drain_smu_mode:|"..drain_smu_mode)
	print("Max current per Drain SMU:|"..drain_pulse_ilimit)
	
	local max_index = table.getn(DRAIN_PULSE_REGIONS)
	local drain_smu_region_index = math.floor(DrainSmuRegionIndex)
	
	drain_smu_region_index = math.max(drain_smu_region_index, 0)
	drain_smu_region_index = math.min(drain_smu_region_index, max_index)	-- was math.min(drain_smu_region_index, 8)

--	local region_index
	if drain_smu_region_index == 0 then	-- Automatically select operating region
		-- 	function CheckPulseRegionV(bias, level, limit, rg)
		drain_smu_region_index = CheckPulseRegionV(0, DrainVpulseLevel, drain_pulse_ilimit, DRAIN_PULSE_REGIONS)
		if (drain_smu_region_index == nil) then
			if drain_smu_mode == 1 then
				print()
        		print("Levels incompatible with available pulse regions")
        		return
        	else
        		drain_smu_region_index = CheckPulseRegionV(0, DrainVpulseLevel, drain_pulse_ilimit/2, DRAIN_PULSE_REGIONS)
        		if (drain_smu_region_index == nil) then
        			print()
        			print("Levels incompatible with available pulse regions")
        			return
        		end --if
        	end --if
    	end --if
    end --if
    
    local DRAIN_SMU_REGION = DRAIN_PULSE_REGIONS[drain_smu_region_index]
    print()
    print("max_index:|"..max_index)
    print("drain_smu_region_index:|"..drain_smu_region_index)
    
	-- Note:  The following inspection does NOT consider any margin for I-src V-limit or V-src I-limit
	if drain_smu_mode == 1 then
    	if (DrainVpulseLevel > DRAIN_SMU_REGION.vlimit) or (drain_pulse_ilimit > DRAIN_SMU_REGION.ilimit) then
    		print()
        	print("Voltage and/or current level incompatible with selected operating region")
        	return
    	end --if
    else
    	if (DrainVpulseLevel > DRAIN_SMU_REGION.vlimit) then
    		print()
        	print("Voltage level incompatible with selected operating region")
        	return
    	end --if
    	if (drain_pulse_ilimit > DRAIN_SMU_REGION.ilimit) and ((drain_pulse_ilimit / 2) > DRAIN_SMU_REGION.ilimit) then
    		print()
        	print("Current level incompatible with selected operating region")
        	return
    	end --if
    end --if
	
	local DRAIN_V_PULSE_VLIMIT = DRAIN_SMU_REGION.vlimit
    local DRAIN_V_PULSE_ILIMIT = DRAIN_SMU_REGION.ilimit
    local DRAIN_V_IDLE_VLIMIT = DRAIN_SMU_REGION.mbv
    local DRAIN_V_IDLE_ILIMIT = DRAIN_SMU_REGION.mbli
    
    local DRAIN_I_PULSE_ILIMIT = DRAIN_SMU_REGION.ilimit
    local DRAIN_I_PULSE_VLIMIT = DRAIN_SMU_REGION.vlimit
    local DRAIN_I_IDLE_ILIMIT = DRAIN_SMU_REGION.mbi
    local DRAIN_I_IDLE_VLIMIT = DRAIN_SMU_REGION.mblv
    
    print()
    print("DRAIN_V_PULSE_VLIMIT:|"..DRAIN_V_PULSE_VLIMIT)
    print("DRAIN_V_PULSE_ILIMIT:|"..DRAIN_V_PULSE_ILIMIT)
    print("DRAIN_V_IDLE_VLIMIT:|"..DRAIN_V_IDLE_VLIMIT)
    print("DRAIN_V_IDLE_ILIMIT:|"..DRAIN_V_IDLE_ILIMIT)
    print()
    print("DRAIN_I_PULSE_ILIMIT:|"..DRAIN_I_PULSE_ILIMIT)
    print("DRAIN_I_PULSE_VLIMIT:|"..DRAIN_I_PULSE_VLIMIT)
    print("DRAIN_I_IDLE_ILIMIT:|"..DRAIN_I_IDLE_ILIMIT)
    print("DRAIN_I_IDLE_VLIMIT:|"..DRAIN_I_IDLE_VLIMIT)
    
    local drain_v_idle_vlevel = 0
    local drain_v_pulse_vlevel = DrainVpulseLevel

    local drain_i_idle_ilevel = 0
    local drain_i_pulse_ilevel
    
	if drain_smu_mode == 1 then
		drain_i_pulse_ilevel = math.min(drain_pulse_ilimit, DRAIN_I_PULSE_ILIMIT)		-- DRAIN_V and DRAIN_I SMUs will both supply current; limit is a redundant check
	else
		drain_i_pulse_ilevel = math.max(drain_pulse_ilimit - DRAIN_V_PULSE_ILIMIT, 0)	-- DRAIN_I SMU will supply current only if DRAIN_V SMU alone can't
	end --if

	print()
	print("drain_i_pulse_ilevel:|"..drain_i_pulse_ilevel)
	
	-- Specify/check timing parameters including passed parameters
	
	local drain_v_pulse_width = DrainPulseWidth
	local drain_v_pulse_delay = 0
	
	local drain_i_pulse_width = IsrcPulseWidth
	local drain_i_pulse_delay = 0
	
	if VsrcCmplOff then
		drain_v_pulse_width = drain_v_pulse_width + 50e-6	-- In compliance-off mode, there is a 50us holdoff after setting the compliance DAC
															--   before before setting the source level DAC; pulse width will be shorter than expected
															--   so I am trying to account for this.  On the other hand, Greg Roberts believes that the
															--   low-level timer that keeps track of source ON-time starts when the complinace DAC is
															--   set and the source level DAC, which means that the max pulse width for a given region
															--   is effectively reduced by 50us.  Greg told me to let him know if I observe something
															--   different (this was as of 24 Jan 2011)
		drain_i_pulse_delay = drain_i_pulse_delay + 50e-6	-- Want to hold off Isrc so its source level changes at the same time that the Vsrc level changes
	end --if
	
	-- function CheckRegionLimits_IvonsMod(region, pulse_width, duty_cycle)
	local flag, msg
	local ChkPulseWidth = math.max(drain_v_pulse_width, drain_i_pulse_width)	-- was math.max(DrainPulseWidth, IsrcPulseWidth)
	-- flag, msg = CheckRegionLimits_IvonsMod(DRAIN_SMU_REGION, DrainPulseWidth, DrainDutyCycle)	-- Borrowed from KIPulse Factory Script (20 Dec 2010)
	flag, msg = CheckRegionLimits_IvonsMod(DRAIN_SMU_REGION, ChkPulseWidth, DrainDutyCycle)		-- Ivons changed from above on 21 Jan 2011
    if (flag == false) then
    	print()
    	print(msg)	-- msg is a message
        return
    end --if	

	if VsrcLagDelay > 0 then
		drain_v_pulse_delay = drain_v_pulse_delay + VsrcLagDelay
	elseif VsrcLagDelay < 0 then
		drain_i_pulse_delay = drain_i_pulse_delay + math.abs(VsrcLagDelay)
	else
		-- Do nothing
	end --if
		
	-- Set up drain pulse and related timing parameters
	--local drain_pulse_ilimit = DrainIlimit / 2					-- Moved earlier
	local period = 1.00 * DrainPulseWidth / DrainDutyCycle		-- Change 1.00 to 1.02 for 2% margin
	
	local pulse_delay = period / 2								-- Start Drain Pulse in middle of Period, i.e. Gate ON time
	
	if localnode.linefreq ~= 60 then localnode.linefreq = 60 end	-- Ivons added added on 23 Dec 2010 beccause of issues with line freq autodetect
																	-- Clearly this is not appropriate for countries where line freq = 50 Hz
	local measure_aperture = Nplc / localnode.linefreq
			
	local measure_delay = DrainPulseWidth - measure_aperture - 50e-6	-- Measure at end of pulse; allow 50us of overhead at end of pulse
	if measure_delay < 0 then
		print()
		print("NPLC setting too big")
		return
	end --if
	
	local digitize_delay
	if Digitize == true	then	-- Ivons added on 05 Jan 2010
		digitize_delay = pulse_delay - DigInterval * math.floor(DigCount * PreTrigPercent / 100)
		if digitize_delay < 0 then
			print("Pre-Trigger interval is too big")
        	return
        end --if
	end --if
	
	print()
	print("DrainPulseWidth:|"..DrainPulseWidth)
	print("drain_v_pulse_width:|"..drain_v_pulse_width)		-- Ivons added on 24 Jan 2011
	print("drain_i_pulse_width:|"..drain_i_pulse_width)		-- Ivons added on 24 Jan 2011
	print("DrainDutyCycle:|"..DrainDutyCycle)	-- Fixed on 05 Jan 2010; had been concatenating "period" instead of "DrainDutyCycle"
	print("period:|"..period)
	print("pulse_delay:|"..pulse_delay)
	print("drain_v_pulse_delay:|"..drain_v_pulse_delay)		-- Ivons added on 24 Jan 2011
	print("drain_i_pulse_delay:|"..drain_i_pulse_delay)		-- Ivons added on 24 Jan 2011
	print("Line Frequency:|"..localnode.linefreq)
	print("measure_aperture:|"..measure_aperture)
	print("Overhead allowed at end of pulse:|"..50e-6)
	print("measure_delay:|"..measure_delay)

	print("digitize_delay:|"..tostring(digitize_delay))	-- Ivons added on 05 Jan 2011; digitize_delay will be nil if Digitize flag ~= true	
	
	--local gate_measure_delay = pulse_delay + pulse_measure_delay	
	
	--Create aliases for the timers used for the sweep
	local PERIOD_TIMER = N1.trigger.timer[1]
	
	local PULSE_DELAY_TIMER = N1.trigger.timer[2]
	
	local VSRC_LAG_DELAY_TIMER			-- Ivons added VSRC_LAG_DELAY_TIMER on 24 Jan 2011
	local ISRC_LAG_DELAY_TIMER			-- Ivons added ISRC_LAG_DELAY_TIMER on 24 Jan 2011
	if drain_v_pulse_delay > drain_i_pulse_delay then 
		VSRC_LAG_DELAY_TIMER = N2.trigger.timer[2]	-- Delay start of V-pulse re I-Pulse
		ISRC_LAG_DELAY_TIMER = nil
	elseif drain_i_pulse_delay > drain_v_pulse_delay then
		ISRC_LAG_DELAY_TIMER = N3.trigger.timer[2]	-- Delay start of I-pulse re V-Pulse
		VSRC_LAG_DELAY_TIMER = nil
	else
		VSRC_LAG_DELAY_TIMER = nil
		ISRC_LAG_DELAY_TIMER = nil
	end --if
	
	local PULSE_WIDTH_TIMER = N1.trigger.timer[3]	-- Ivons commented out on 24 Jan 2011, but then decided to keep it running on Node 1
	local DRAIN_V_PULSE_WIDTH_TIMER = N2.trigger.timer[3]
	local DRAIN_I_PULSE_WIDTH_TIMER = N3.trigger.timer[3]
	
	local MEASURE_DELAY_TIMER = N1.trigger.timer[4]
	local DIGITIZE_DELAY_TIMER = N1.trigger.timer[5]	-- Ivons added on 05 Jan 2011 to support use of ASYNC measurements
	--local DRAIN_MEASURE_TIMER = node[2].trigger.timer[3]
	--local GATE_MEASURE_TIMER = node[1].trigger.timer[2]
	
	--Create aliases for the blenders used for the sweep
	local OK_TO_MEASURE_BLENDER = N1.trigger.blender[1]
	local OK_TO_END_PULSE_BLENDER = N1.trigger.blender[2]

	local ZEROAMP_OFFSTATE_Z
	if string.upper(DrainIsrc_ZeroAmpMode) == "HIGHZ" then
		ZEROAMP_OFFSTATE_Z = DRAIN_I.OUTPUT_HIGH_Z
	else
		ZEROAMP_OFFSTATE_Z = DRAIN_I.OUTPUT_NORMAL	-- Need 1.0.0RC29 to use DRAIN_I.OUTPUT_ACTIVE_LOAD	-- Ivons changed on 21 Jan 2011; was DRAIN_I.OUTPUT_NORMAL
	end --if
	
	-- Check passed parameters

	if EnableHighC == nil then EnableHighC = false end
	
	-- Set up gate sweep parameters
	local gate_max_vmag = math.max(math.abs(GateStartV), math.abs(GateStopV))
	local gate_sweep_npoints = math.abs((GateStopV-GateStartV) / GateStepV + 1)
	print()
	print("gate_max_vmag:|"..gate_max_vmag)
	print("gate_sweep_npoints:|"..gate_sweep_npoints)

	--Reset the system and clear the errorqueue
	reset()
	errorqueue.clear()		-- On the local node
	
	-- Configure 26XXA Displays
	N1.display.screen = display.SMUA						-- Display SMU A only
	N1.display.smua.measure.func = display.MEASURE_DCVOLTS	-- Display the SMU A current reading
	N2.display.smua.measure.func = display.MEASURE_DCAMPS	-- Display the SMU A current reading
	N3.display.smua.measure.func = display.MEASURE_DCVOLTS	-- Display the SMU B voltage reading

	-- Setup general SMU source parameters

	--Configure general source parameters for GATE (Gate, 2612A)
	if Use2wire == true then
		GATE.sense = GATE.SENSE_LOCAL		-- Use local (2-wire) sensing
	else
		GATE.sense = GATE.SENSE_REMOTE		-- Use remote (4-wire) sensing
	end --if
	GATE.source.func = GATE.OUTPUT_DCVOLTS	-- DC Volts is default source function
	GATE.source.rangev = gate_max_vmag	-- Set GATE source voltage range; use fixed range to guarantee timing
	GATE.source.limiti = GateIlimit			-- Idle compliance limit
	GATE.source.delay = 0					-- Source Delay disabled by default
	GATE.source.offmode = GATE.OUTPUT_NORMAL	-- Set output-off impedance state to NORMAL mode (default setting)
	GATE.source.offlimiti = 0.001				-- Default is 1mA
--[[	-- Ivons commented out this block on 18 Jan 2010
	if EnableHighC then
		GATE.source.highc = GATE.ENABLE			-- Enable HIGH Capacitance mode
		GATE.measure.highcrangedelayfactor = 1
	else
		GATE.source.highc = GATE.DISABLE
	end --if
]]	
	print()
	print("GATE sense mode:|"..GATE.sense)	-- Ivons added on 21 Jan 2011
	print("GATE V-source range:|"..GATE.source.rangev)

	--Configure source ranges and limits for DRAIN_V and DRAIN_I SMUs (2651A}
	if Use2wire == true then	-- Ivons added option for 2-wire for James Niemann test on 20 Jan 2010; had been exclusively 4-wire
		DRAIN_V.sense = DRAIN_V.SENSE_LOCAL		-- Use local (2-wire) sensing
		DRAIN_I.sense = DRAIN_I.SENSE_LOCAL		-- Use local (2-wire) sensing
	else
		DRAIN_V.sense = DRAIN_V.SENSE_REMOTE	-- Use remote (4-wire) sensing
		DRAIN_I.sense = DRAIN_I.SENSE_REMOTE	-- Use remote (4-wire) sensing
	end --if
	
	DRAIN_V.source.func = DRAIN_V.OUTPUT_DCVOLTS	-- DC Volts is default source function
	DRAIN_I.source.func = DRAIN_I.OUTPUT_DCAMPS		-- Use I-source to effectively increase the I-compliance of V-source (DRAIN_V)

--	local drain_i_pulse_ilevel
--	if drain_smu_mode == 1 then
--		drain_i_pulse_ilevel = math.min(drain_pulse_ilimit, DRAIN_I_PULSE_ILIMIT)	-- DRAIN_V and DRAIN_I SMUs will both supply current; limit is a redundant check
--	else
--		drain_i_pulse_ilevel = math.max(drain_pulse_ilimit - DRAIN_V_PULSE_ILIMIT, 0)	-- DRAIN_I SMU will supply current only if DRAIN_V SMU alone can't
--	end --if
	
	DRAIN_V.source.rangev = math.min(DrainVpulseLevel, DRAIN_V_PULSE_VLIMIT)	-- Set DRAIN_V source voltage range; limit is a redundant check
	DRAIN_V.source.limiti = DRAIN_V_IDLE_ILIMIT				-- was math.min(0.1, DRAIN_V_IDLE_ILIMIT)	-- Idle compliance limit; this is a redundant check
	if VsrcCmplOff then		-- Ivons added on 25 Jan 2011
		DRAIN_V.trigger.source.limiti = "off"	-- This compliance setting is used when SMU goes into compliance during pulse rise/fall when the compliance circuit can't keep up with the slew rate	
	else
			DRAIN_V.trigger.source.limiti = DRAIN_V_PULSE_ILIMIT	-- was drain_pulse_ilimit	-- This compliance setting is used to enable EOA operation when needed	
	end --if
	DRAIN_I.source.rangei = DRAIN_I_PULSE_ILIMIT	-- was math.max(drain_i_pulse_ilevel, 0.1)	-- Ivons added 12/28/2010; don't use I-source range less than 100mA	
	DRAIN_I.source.limitv = DRAIN_I_IDLE_VLIMIT		-- Idle compliance limit
	DRAIN_I.trigger.source.limitv = DRAIN_I_PULSE_VLIMIT	-- was DRAIN_V.source.rangev		-- was math.min(1.2 * math.abs(DrainVpulseLevel), DRAIN_SMU_REGION.vlimit)	-- This compliance setting is used to enable EOA operation when needed
		
	print()
	print("DRAIN_V sense mode:|"..DRAIN_V.sense)	-- Ivons added on 21 Jan 2011
	print("DRAIN_V V-source range:|"..DRAIN_V.source.rangev)
	print("DRAIN_V Idle I-limit:|"..DRAIN_V.source.limiti)	-- fixed after Test10 on 29 Dec 2010; was DRAIN_I.source.limiti
	print("DRAIN_V Triggered I-limit:|"..DRAIN_V.trigger.source.limiti)
	print()
--	print("drain_i_pulse_ilevel:|"..drain_i_pulse_ilevel)
	print("DRAIN_I sense mode:|"..DRAIN_I.sense)	-- Ivons added on 21 Jan 2011
	print("DRAIN_I I-source range:|"..DRAIN_I.source.rangei)
	print("DRAIN_I Idle V-limit:|"..DRAIN_I.source.limitv)	-- fixed after Test10 on 29 Dec 2010; was DRAIN_V.source.limitv
	print("DRAIN_I Triggered V-limit:|"..DRAIN_I.trigger.source.limitv)
		
	DRAIN_V.source.delay = 0						-- Zero is default
	DRAIN_I.source.delay = 0						-- Zero is default
	
	local v_fw = string.upper(string.sub(node[2].revision,-4))	-- Ivons added on 25 Jan 2011
	if v_fw >= "RC29" then	-- Ivons added this TEMPORARY conditional on 25 Jan 2011; need to remove when final FW is released
		DRAIN_V.source.offmode = DRAIN_V.OUTPUT_ACTIVE_LOAD	-- Ivons changed on 21 Jan 2011 (requires 1.0.0RC29 FW or later); was DRAIN_V.OUTPUT_NORMAL
	else
		DRAIN_V.source.offmode = DRAIN_V.OUTPUT_NORMAL		-- Set output-off impedance state to NORMAL mode (default setting)
	end --if
	
	local i_fw = string.upper(string.sub(node[3].revision,-4))	-- Ivons added on 25 Jan 2011
	if i_fw >= "RC29" then	-- Ivons added this TEMPORARY conditional on 25 Jan 2011; need to remove when final FW is released
		DRAIN_I.source.offmode = DRAIN_I.OUTPUT_ACTIVE_LOAD	-- Ivons changed on 21 Jan 2011 (requires 1.0.0RC29 FW or later); was DRAIN_V.OUTPUT_NORMAL
	else
		DRAIN_I.source.offmode = DRAIN_I.OUTPUT_NORMAL		-- Set output-off impedance state to NORMAL mode (default setting)
	end --if
	
--[[	-- Ivons commented out this block on 25 Jan 2011	
	DRAIN_V.source.offmode = DRAIN_V.OUTPUT_NORMAL	-- DRAIN_V.OUTPUT_ACTIVE_LOAD	-- Ivons changed on 21 Jan 2011 (requires 1.0.0RC29 FW or later); was DRAIN_V.OUTPUT_NORMAL	-- Set output-off impedance state to NORMAL mode (default setting)
	if drain_i_pulse_ilevel == 0 then
		-- DRAIN_I.source.offmode = ZEROAMP_OFFSTATE_Z			-- Either NORMAL or HIGH-Z depending on value of DrainIsrc_ZeroAmpMode
		DRAIN_I.source.offmode = DRAIN_I.OUTPUT_NORMAL	-- DRAIN_I.OUTPUT_ACTIVE_LOAD		-- Ivons changed on 21 Jan 2011 (requires 1.0.0RC29 FW or later)
	else
		-- DRAIN_I.source.offmode = DRAIN_I.OUTPUT_NORMAL		-- Set output-off impedance state to NORMAL mode (default setting)
		DRAIN_I.source.offmode = DRAIN_I.OUTPUT_NORMAL	-- DRAIN_I.OUTPUT_ACTIVE_LOAD		-- Ivons changed on 21 Jan 2011 (requires 1.0.0RC29 FW or later)
	end --if
]]	
	print()
	print("DRAIN_V Output-off Impedance State:|"..DRAIN_V.source.offmode)	-- Ivons added on 21 Jan 2011
	print("DRAIN_I Output-off Impedance State:|"..DRAIN_I.source.offmode)
	
	DRAIN_V.source.offlimiti = 0.001		-- Compliance limit when output is OFF and Off-State Impedance is NORMAL; default is 1mA
	DRAIN_I.source.offlimiti = 0.001		-- Compliance limit when output is OFF and Off-State Impedance is NORMAL; default is 1mA
	
	if EnableHighC then
		DRAIN_V.source.highc = DRAIN_V.ENABLE		-- Enable HIGH Capacitance mode
--		DRAIN_I.source.highc = DRAIN_I.ENABLE		-- Enable HIGH Capacitance mode;	Ivons commented out on 17 Jan 2010
		DRAIN_V.measure.highcrangedelayfactor = 1
--		DRAIN_I.measure.highcrangedelayfactor = 1	-- Ivons commented out on 17 Jan 2010
	else
		DRAIN_V.source.highc = DRAIN_V.DISABLE
		DRAIN_I.source.highc = DRAIN_I.DISABLE
	end --if

	--[[ NOTE:	In the following several lines, 50e-6 is an estimate of
				measurement overhead.  ALL forms of instrument measure
				autoranging source must be disabled for this to be valid.  This
				includes measure autoranging for the source function, which is
				counterintuitive because the source parameter can only be
				measured on the source range.  It has been determined that the
				latter requirement is due to a bug and NCM06284 was submitted
				on 18 Mar 2010.

				Timing calculations also assume that all source and meaure delays
				are zero, and that autozero is disabled before the measurements.
	]]
	
	-- Setup general SMU measure parameters (e.g. NPLC, Range, etc) and buffers

	--Configure general measure parameters for GATE
	GATE.measure.count = 1						-- Number of measurements made when smuX.measure.Y() or 
												--   smuX.trigger.measure.Y()functions are invoked. Default is 1.
--	GATE.measure.rangei = 100e-6				-- Use 100uA for now
	GATE.measure.rangei = GateIlimit			-- Set I-measure range (use compliance setting); use fixed range for optimum timing; V-measure range determined by source range
--	GATE.measure.autorangei = GATE.AUTORANGE_ON	-- Use autorange until know value to set fixed range for measuring gate current (Note: this causes error -221, Settings Conflict if High-C is enabled)
	GATE.measure.autorangev = GATE.AUTORANGE_OFF
	GATE.measure.nplc = Nplc					-- Set integration time
	
	print()
	print("GATE I-measure range:|"..GATE.measure.rangei)
	
	GATE.nvbuffer1.clear()
	GATE.nvbuffer1.appendmode = 1
	GATE.nvbuffer1.collectsourcevalues = 1
	GATE.nvbuffer1.collecttimestamps = 1
	
	GATE.nvbuffer2.clear()
	GATE.nvbuffer2.appendmode = 1
	GATE.nvbuffer2.collectsourcevalues = 1
	GATE.nvbuffer2.collecttimestamps = 1

	--Configure general measure parameters for DRAIN_V

	DRAIN_V.measure.rangei = DRAIN_V_PULSE_ILIMIT	-- was drain_pulse_ilimit	-- Set I-measure range (use compliance setting); use fixed range for optimum timing; V-measure range determined by source range
	DRAIN_V.measure.autorangev = DRAIN_V.AUTORANGE_OFF	-- Added on 23 Dec 2010 because buffer status indicated that autorange occured for source readback	

	print()
	print("DRAIN_V I-measure range:|"..DRAIN_V.measure.rangei)
	
	if Digitize == true then	-- Ivons added on 05 Jan 2010
		DRAIN_V.measure.interval = DigInterval
		DRAIN_V.measure.count = DigCount
	else
		DRAIN_V.measure.interval = 0
		DRAIN_V.measure.count = 1		-- Number of measurements made when smuX.measure.Y() or 
										--   smuX.trigger.measure.Y()functions are invoked. Default is 1.
	end --if
	
	DRAIN_V.measure.nplc = Nplc			-- Set integration time; does not apply if using the high-speed ADC

	DRAIN_V.nvbuffer1.clear()
	DRAIN_V.nvbuffer1.appendmode = 1
	DRAIN_V.nvbuffer1.collecttimestamps = 1
	if Digitize == true then	-- Ivons added on 06 Jan 2011
		DRAIN_V.nvbuffer1.collectsourcevalues = 0	-- was getting Error 5064, "SMU A: Cannot use reading buffer that collects source values"
													--  not sure if this is because using high-speed ADC or because using asynchronous measurements
	else
		DRAIN_V.nvbuffer1.collectsourcevalues = 1
	end --if
	
	DRAIN_V.nvbuffer2.clear()
	DRAIN_V.nvbuffer2.appendmode = 1
	DRAIN_V.nvbuffer2.collecttimestamps = 1
	if Digitize == true then	-- Ivons added on 06 Jan 2011
		DRAIN_V.nvbuffer2.collectsourcevalues = 0	-- was getting Error 5064, "SMU A: Cannot use reading buffer that collects source values"
													--  not sure if this is because using high-speed ADC or because using asynchronous measurements
	else
		DRAIN_V.nvbuffer2.collectsourcevalues = 1
	end --if

	--Configure general measure parameters for DRAIN_I
	DRAIN_I.measure.autorangei = DRAIN_I.AUTORANGE_OFF	-- Added on 23 Dec 2010 because buffer status indicated that autorange occured for source readback												
	DRAIN_I.measure.rangev = DRAIN_V.source.rangev	-- was DRAIN_I_PULSE_VLIMIT	-- was wrongly set to DRAIN_I.source.limitv	-- Set V-measure range (use compliance setting); was math.min(1.2 * math.abs(DrainVpulseLevel), DRAIN_SMU_REGION.mblv)
													--   Use fixed range for optimum timing; I-measure range determined by source range
	print("DRAIN_I V-measure range:|"..DRAIN_I.measure.rangev)	-- Should I use DRAIN_I_PULSE_VLIMIT instead?
	
	if Digitize == true then	-- Ivons added on 05 Jan 2010
		DRAIN_I.measure.interval = DigInterval
		DRAIN_I.measure.count = DigCount
	else
		DRAIN_I.measure.interval = 0
		DRAIN_I.measure.count = 1		-- Number of measurements made when smuX.measure.Y() or 
										--   smuX.trigger.measure.Y()functions are invoked. Default is 1.
	end --if

	DRAIN_I.measure.nplc = Nplc			-- Set integration time; does not apply if using the high-speed ADC

	DRAIN_I.nvbuffer1.clear()
	DRAIN_I.nvbuffer1.appendmode = 1
	DRAIN_I.nvbuffer1.collecttimestamps = 1
	if Digitize == true then	-- Ivons added on 06 Jan 2011
		DRAIN_I.nvbuffer1.collectsourcevalues = 0	-- was getting Error 5064, "SMU A: Cannot use reading buffer that collects source values"
													--  not sure if this is because using high-speed ADC or because using asynchronous measurements
	else
		DRAIN_I.nvbuffer1.collectsourcevalues = 1
	end --if
	
	DRAIN_I.nvbuffer2.clear()
	DRAIN_I.nvbuffer2.appendmode = 1
	DRAIN_I.nvbuffer2.collecttimestamps = 1
	if Digitize == true then	-- Ivons added on 06 Jan 2011
		DRAIN_I.nvbuffer2.collectsourcevalues = 0	-- was getting Error 5064, "SMU A: Cannot use reading buffer that collects source values"
													--  not sure if this is because using high-speed ADC or because using asynchronous measurements
	else
		DRAIN_I.nvbuffer2.collectsourcevalues = 1
	end --if
	
	--Configure sweep-related and pulse-related source and measure settings

	--[[
	Note:	Use the smuX.trigger.source.limitY attribute to perform extended operating area (EOA) pulse mode sweeps.
			If the attribute is set to smuX.LIMIT_AUTO, the SMU will use the normal limit setting during sweeping. 
			If this attribute is set to any other value, the SMU will switch in this limit at the start of the
			source action and then switch back to the normal limit setting at the end of the end pulse action.

			When using the EOA, the SMU will automatically start the end pulse action if the SMU is not triggered 
			before its maximum pulse width. It will also delay the source action if necessary to limit the pulse 
			duty cycle to stay within the capabilities of the SMU
	]]

	-- Set up gate voltage sweep (Vgs)
	GATE.trigger.source.linearv(GateStartV, GateStopV, gate_sweep_npoints)	-- linearX (start, stop, points); define the source action for GATE

	GATE.trigger.source.limiti = GATE.LIMIT_AUTO	-- Use the idle limit value (previously explicitly was GateIlimit); this compliance setting is used to enable EOA operation when needed
	GATE.trigger.source.action = GATE.ENABLE		-- Enable source action in GATE trigger model
	
	GATE.trigger.endpulse.action = GATE.SOURCE_HOLD		-- Controls end pulse source action
	GATE.trigger.endsweep.action = GATE.SOURCE_HOLD		-- Controls source action at end of sweep
														-- Stay at last set level (HOLD) or go to idle level (IDLE)
	
	GATE.trigger.measure.iv(GATE.nvbuffer1,GATE.nvbuffer2)	--Configures measurements to be made in subsequent sweep; define measure action for GATE
	GATE.trigger.measure.action = GATE.ENABLE				-- Enable measure action in GATE trigger model
	
	-- Use 2 SMUs in parallel to pulse the drain (Vds) at DrainVpulseLevel with DrainIlimit total compliance;
	-- drain_pulse_limit = DrainIlimit/2.  Pulsewidth is DrainPulseWidth.

	DRAIN_V.trigger.source.listv({DrainVpulseLevel})		-- Do a single point list sweep; define source action for DRAIN_V
															--   Actually a list N points will be generated where N = Trigger Count
--	DRAIN_V.trigger.source.limiti = DRAIN_V_PULSE_ILIMIT	-- was drain_pulse_ilimit	-- This compliance setting is used to enable EOA operation when needed
	DRAIN_V.trigger.source.action = DRAIN_V.ENABLE			-- Enable source action in DRAIN_V trigger model

	DRAIN_V.trigger.endpulse.action = DRAIN_V.SOURCE_IDLE		-- Controls source action at endpulse action block
																--   Stay at last set level (HOLD) or go to idle level (IDLE)
																--   Set to SOURCE_IDLE to generate pulses (i.e. pulse sweep)
	
	DRAIN_V.trigger.endsweep.action = DRAIN_V.SOURCE_HOLD		-- Controls source action at end of sweep
																--   Stay at last set level (HOLD) or go to idle level (IDLE)
	
	if Digitize == true then	-- Ivons added on 05 Jan 2011
		DRAIN_V.measure.adc = DRAIN_V.ADC_FAST								-- Use high-speed ADC for measurements; new to Krabs
		DRAIN_V.trigger.measure.iv(DRAIN_V.nvbuffer1, DRAIN_V.nvbuffer2)	-- Configures measurements to be made in subsequent sweep; define measure action for DRAIN_V
		DRAIN_V.trigger.measure.action = DRAIN_V.ASYNC						-- Enable ASYNChronous measurements in DRAIN_V trigger model
	else
		DRAIN_V.measure.adc = DRAIN_V.ADC_INTEGRATE							-- Use integrating ADC for measurements; default; option new to Krabs	
		DRAIN_V.trigger.measure.iv(DRAIN_V.nvbuffer1, DRAIN_V.nvbuffer2)	-- Configures measurements to be made in subsequent sweep; define measure action for DRAIN_V
		DRAIN_V.trigger.measure.action = DRAIN_V.ENABLE						-- Enable synchronous (or normal) measure action in DRAIN_V trigger model
	end --if

--	DRAIN_I.trigger.source.listi({drain_i_pulse_ilevel})		-- Do a single point list sweep; define source action for DRAIN_I
	DRAIN_I.trigger.source.lineari(drain_i_pulse_ilevel,drain_i_pulse_ilevel,gate_sweep_npoints)	-- Alternate way to generate a list of N identical
																									--   points, where N = gate_sweep_npoints
--	DRAIN_I.trigger.source.limitv = DRAIN_V.source.rangev		-- was math.min(1.2 * math.abs(DrainVpulseLevel), DRAIN_SMU_REGION.vlimit)	-- This compliance setting is used to enable EOA operation when needed
	DRAIN_I.trigger.source.action = DRAIN_I.ENABLE				-- Enable source action in DRAIN_I trigger model
	
	DRAIN_I.trigger.endpulse.action = DRAIN_I.SOURCE_IDLE		-- Controls source action at endpulse action block		
	DRAIN_I.trigger.endsweep.action = DRAIN_I.SOURCE_HOLD		-- Controls source action at end of sweep
	
	if Digitize == true then	-- Ivons added on 05 Jan 2011
		DRAIN_I.measure.adc = DRAIN_I.ADC_FAST								-- Use high-speed ADC for measurements; new to Krabs	
		DRAIN_I.trigger.measure.iv(DRAIN_I.nvbuffer1, DRAIN_I.nvbuffer2)	--Configures measurements to be made in subsequent sweep
		DRAIN_I.trigger.measure.action = DRAIN_I.ASYNC						-- Enable ASYNChronous measurements in DRAIN_I trigger model
	else
		DRAIN_I.measure.adc = DRAIN_I.ADC_INTEGRATE							-- Use integrating ADC for measurements; default; option new to Krabs					
		DRAIN_I.trigger.measure.iv(DRAIN_I.nvbuffer1, DRAIN_I.nvbuffer2)	--Configures measurements to be made in subsequent sweep
		DRAIN_I.trigger.measure.action = DRAIN_I.ENABLE						-- Enable synchronous (or normal) measure action in DRAIN_I trigger model
	end --if

	print()
	print("DRAIN_V Pulse I-limit:|"..DRAIN_V.trigger.source.limiti)
	print("DRAIN_I Pulse V-limit:|"..DRAIN_I.trigger.source.limitv)

	if CheckParamOnly then
		return -99, "Check Parameters Only"	-- Function returns -99 if exits here because only checking values of parameters
	end --if

	-- Set up Digital I/O and TSP-link Trigger Line(s) and Mode on Each Node
	N1.digio.trigger[1].mode = N1.digio.TRIG_FALLING	--digio.TRIG_SYNCHRONOUSA
	
	N1.digio.trigger[2].mode = N1.digio.TRIG_FALLING
	N1.digio.trigger[3].mode = N1.digio.TRIG_FALLING
	N1.digio.trigger[4].mode = N1.digio.TRIG_FALLING
	
	N1.digio.trigger[2].stimulus = PERIOD_TIMER.EVENT_ID
	N1.digio.trigger[3].stimulus = OK_TO_MEASURE_BLENDER.EVENT_ID
	N1.digio.trigger[4].stimulus = OK_TO_END_PULSE_BLENDER.EVENT_ID	--GATE.trigger.SOURCE_COMPLETE_EVENT_ID	--PULSE_DELAY_TIMER.EVENT_ID

	if Digitize == true then	-- Ivons added on 06 Jan 2011
	
		-- digio.trigger[N].mode = digio.TRIG_SYNCHRONOUSM
		N1.tsplink.trigger[1].mode = N1.tsplink.TRIG_FALLING	-- Trigger on falling edge signal
		N2.tsplink.trigger[1].mode = N2.tsplink.TRIG_FALLING	-- Trigger on falling edge signal
		N3.tsplink.trigger[1].mode = N3.tsplink.TRIG_FALLING	-- Trigger on falling edge signal
	
		N1.tsplink.trigger[2].mode = N1.tsplink.TRIG_FALLING	-- Trigger on falling edge signal
		N2.tsplink.trigger[2].mode = N2.tsplink.TRIG_FALLING	-- Trigger on falling edge signal
		N3.tsplink.trigger[2].mode = N3.tsplink.TRIG_FALLING	-- Trigger on falling edge signal
	
		N1.tsplink.trigger[3].mode = N1.tsplink.TRIG_FALLING	-- Trigger on falling edge signal
		N2.tsplink.trigger[3].mode = N2.tsplink.TRIG_FALLING	-- Trigger on falling edge signal
		N3.tsplink.trigger[3].mode = N3.tsplink.TRIG_FALLING	-- Trigger on falling edge signal
	
	else
	
		-- digio.trigger[N].mode = digio.TRIG_SYNCHRONOUSM
		N1.tsplink.trigger[1].mode = N1.tsplink.TRIG_SYNCHRONOUSM		-- was	node[1].tsplink.TRIG_FALLING	-- Trigger on falling edge signal
		N2.tsplink.trigger[1].mode = N2.tsplink.TRIG_SYNCHRONOUSA
		N3.tsplink.trigger[1].mode = N3.tsplink.TRIG_SYNCHRONOUSA
	
		N1.tsplink.trigger[2].mode = N1.tsplink.TRIG_SYNCHRONOUSM		-- was	node[1].tsplink.TRIG_FALLING	-- Trigger on falling edge signal
		N2.tsplink.trigger[2].mode = N2.tsplink.TRIG_SYNCHRONOUSA
		N3.tsplink.trigger[2].mode = N3.tsplink.TRIG_SYNCHRONOUSA
	
		N1.tsplink.trigger[3].mode = N1.tsplink.TRIG_FALLING	-- Trigger on falling edge signal
		N2.tsplink.trigger[3].mode = N2.tsplink.TRIG_FALLING	-- Trigger on falling edge signal
		N3.tsplink.trigger[3].mode = N3.tsplink.TRIG_FALLING	-- Trigger on falling edge signal
	
	end --if
	 
	--Configure timer attributes

	PERIOD_TIMER.delay = period
	PERIOD_TIMER.stimulus = N1.digio.trigger[1].EVENT_ID	-- was GATE.trigger.ARMED_EVENT_ID
	PERIOD_TIMER.count = gate_sweep_npoints - 1				-- Effectively gate_sweep_npoints because passthrough = true
	PERIOD_TIMER.passthrough = true							-- Output an "event" immediately when timer is triggered

	PULSE_DELAY_TIMER.delay = pulse_delay
	PULSE_DELAY_TIMER.stimulus = PERIOD_TIMER.EVENT_ID		-- was node[2].tsplink.trigger[1].EVENT_ID
	PULSE_DELAY_TIMER.count = 1
	PULSE_DELAY_TIMER.passthrough = false
	
	PULSE_WIDTH_TIMER.delay = drain_v_pulse_width			-- was DrainPulseWidth; Ivons changed on 21 Jan 2011 and again on 24 Jan 2011
	PULSE_WIDTH_TIMER.stimulus = PULSE_DELAY_TIMER.EVENT_ID
	PULSE_WIDTH_TIMER.count = 1
	PULSE_WIDTH_TIMER.passthrough = false

	if VSRC_LAG_DELAY_TIMER then
	
		VSRC_LAG_DELAY_TIMER.delay = drain_v_pulse_delay
		VSRC_LAG_DELAY_TIMER.stimulus = N2.tsplink.trigger[1].EVENT_ID
		VSRC_LAG_DELAY_TIMER.count = 1
		VSRC_LAG_DELAY_TIMER.passthrough = false
		
		DRAIN_V_PULSE_WIDTH_TIMER.delay = drain_v_pulse_width				-- was DrainPulseWidth; Ivons changed on 21 Jan 2011 and again on 24 Jan 2011
		DRAIN_V_PULSE_WIDTH_TIMER.stimulus = VSRC_LAG_DELAY_TIMER.EVENT_ID	-- was PULSE_DELAY_TIMER.EVENT_ID
		DRAIN_V_PULSE_WIDTH_TIMER.count = 1
		DRAIN_V_PULSE_WIDTH_TIMER.passthrough = false
		
	else
	
		DRAIN_V_PULSE_WIDTH_TIMER.delay = drain_v_pulse_width				-- was DrainPulseWidth; Ivons changed on 21 Jan 2011 and again on 24 Jan 2011
		DRAIN_V_PULSE_WIDTH_TIMER.stimulus = N2.tsplink.trigger[1].EVENT_ID	-- was PULSE_DELAY_TIMER.EVENT_ID
		DRAIN_V_PULSE_WIDTH_TIMER.count = 1
		DRAIN_V_PULSE_WIDTH_TIMER.passthrough = false
		
	end --if
	
	if ISRC_LAG_DELAY_TIMER then
	
		ISRC_LAG_DELAY_TIMER.delay = drain_i_pulse_delay
		ISRC_LAG_DELAY_TIMER.stimulus = N3.tsplink.trigger[1].EVENT_ID
		ISRC_LAG_DELAY_TIMER.count = 1
		ISRC_LAG_DELAY_TIMER.passthrough = false
		
		DRAIN_I_PULSE_WIDTH_TIMER.delay = drain_i_pulse_width				-- was DrainPulseWidth; Ivons changed on 21 Jan 2011 and again on 24 Jan 2011
		DRAIN_I_PULSE_WIDTH_TIMER.stimulus = ISRC_LAG_DELAY_TIMER.EVENT_ID	-- was PULSE_DELAY_TIMER.EVENT_ID
		DRAIN_I_PULSE_WIDTH_TIMER.count = 1
		DRAIN_I_PULSE_WIDTH_TIMER.passthrough = false
		
	else
	
		DRAIN_I_PULSE_WIDTH_TIMER.delay = drain_i_pulse_width				-- was DrainPulseWidth; Ivons changed on 21 Jan 2011 and again on 24 Jan 2011
		DRAIN_I_PULSE_WIDTH_TIMER.stimulus = N3.tsplink.trigger[1].EVENT_ID	-- was PULSE_DELAY_TIMER.EVENT_ID
		DRAIN_I_PULSE_WIDTH_TIMER.count = 1
		DRAIN_I_PULSE_WIDTH_TIMER.passthrough = false
		
	end --if
	
	if Digitize == true then	-- Ivons added on 06 Jan 2011
	
		DIGITIZE_DELAY_TIMER.delay = digitize_delay
		DIGITIZE_DELAY_TIMER.stimulus = PERIOD_TIMER.EVENT_ID
		DIGITIZE_DELAY_TIMER.count = 1
		DIGITIZE_DELAY_TIMER.passthrough = false	
	
	else
	
		-- Do nothing
		
	end --if
	
	MEASURE_DELAY_TIMER.delay = measure_delay				-- was pulse_measure_delay
	MEASURE_DELAY_TIMER.stimulus = PULSE_DELAY_TIMER.EVENT_ID
	MEASURE_DELAY_TIMER.count = 1
	MEASURE_DELAY_TIMER.passthrough = false


	
--	DRAIN_MEASURE_TIMER.delay = pulse_measure_delay
--	DRAIN_MEASURE_TIMER.stimulus = PULSE_DELAY_TIMER.EVENT_ID
--	DRAIN_MEASURE_TIMER.count = 1
--	DRAIN_MEASURE_TIMER.passthrough = false
	
--	GATE_MEASURE_TIMER.delay = gate_measure_delay
--	GATE_MEASURE_TIMER.stimulus = PERIOD_TIMER.EVENT_ID
--	GATE_MEASURE_TIMER.count = 1
--	GATE_MEASURE_TIMER.passthrough = false

	if Digitize == true then	-- Ivons added on 06 Jan 2011
	
		OK_TO_MEASURE_BLENDER.stimulus[1] = MEASURE_DELAY_TIMER.EVENT_ID
		OK_TO_MEASURE_BLENDER.stimulus[2] = GATE.trigger.SOURCE_COMPLETE_EVENT_ID
		OK_TO_MEASURE_BLENDER.stimulus[3] = 0		-- Disable input; default setting
		
		OK_TO_END_PULSE_BLENDER.stimulus[1] = PULSE_WIDTH_TIMER.EVENT_ID
		OK_TO_END_PULSE_BLENDER.stimulus[2] = GATE.trigger.MEASURE_COMPLETE_EVENT_ID
		OK_TO_END_PULSE_BLENDER.stimulus[3] = 0		-- Disable input; default setting
		
	else
	
		OK_TO_MEASURE_BLENDER.stimulus[1] = MEASURE_DELAY_TIMER.EVENT_ID
		OK_TO_MEASURE_BLENDER.stimulus[2] = GATE.trigger.SOURCE_COMPLETE_EVENT_ID
		OK_TO_MEASURE_BLENDER.stimulus[3] = N1.tsplink.trigger[1].EVENT_ID

		OK_TO_END_PULSE_BLENDER.stimulus[1] = PULSE_WIDTH_TIMER.EVENT_ID
		OK_TO_END_PULSE_BLENDER.stimulus[2] = GATE.trigger.MEASURE_COMPLETE_EVENT_ID
		OK_TO_END_PULSE_BLENDER.stimulus[3] = N1.tsplink.trigger[2].EVENT_ID

	end --if

	if Digitize == true then	-- Ivons added on 06 Jan 2011
	
		-- Configure TSP-LINK trigger line stimulus
		N1.tsplink.trigger[1].stimulus = PULSE_DELAY_TIMER.EVENT_ID	-- was PERIOD_TIMER.EVENT_ID	
		N1.tsplink.trigger[2].stimulus = DIGITIZE_DELAY_TIMER.EVENT_ID
		N1.tsplink.trigger[3].stimulus = OK_TO_END_PULSE_BLENDER.EVENT_ID
		
	else
	
		-- Configure TSP-LINK trigger line stimulus
		N1.tsplink.trigger[1].stimulus = PULSE_DELAY_TIMER.EVENT_ID	-- was PERIOD_TIMER.EVENT_ID	
		N1.tsplink.trigger[2].stimulus = OK_TO_MEASURE_BLENDER.EVENT_ID
		N1.tsplink.trigger[3].stimulus = OK_TO_END_PULSE_BLENDER.EVENT_ID
	
		N2.tsplink.trigger[1].stimulus = DRAIN_V.trigger.SOURCE_COMPLETE_EVENT_ID
		N2.tsplink.trigger[2].stimulus = DRAIN_V.trigger.MEASURE_COMPLETE_EVENT_ID

		N3.tsplink.trigger[1].stimulus = DRAIN_I.trigger.SOURCE_COMPLETE_EVENT_ID
		N3.tsplink.trigger[2].stimulus = DRAIN_I.trigger.MEASURE_COMPLETE_EVENT_ID
		
	end --if
	
	--Configure SMU trigger models
	
	GATE.trigger.arm.count = 1
	GATE.trigger.arm.stimulus = 0										-- Zero is equivalent to Immediate
	GATE.trigger.count = gate_sweep_npoints							-- Sweep will execute gate_sweep_npoints source values
	GATE.trigger.source.stimulus = PERIOD_TIMER.EVENT_ID
	GATE.trigger.measure.stimulus = OK_TO_MEASURE_BLENDER.EVENT_ID		-- was GATE_MEASURE_TIMER.EVENT_ID
	GATE.trigger.endpulse.stimulus = OK_TO_END_PULSE_BLENDER.EVENT_ID	-- was 0
	
	DRAIN_V.trigger.arm.count = 1	-- was gate_sweep_npoints			-- Also the number of pulses
	DRAIN_V.trigger.arm.stimulus = 0
	DRAIN_V.trigger.count = gate_sweep_npoints	-- was 1
	if VSRC_LAG_DELAY_TIMER then	-- Ivons added on 24 Jan 2011
		DRAIN_V.trigger.source.stimulus = VSRC_LAG_DELAY_TIMER.EVENT_ID	-- Ivons changed on 24 Jan 2011; was N2.tsplink.trigger[1].EVENT_ID	-- was PULSE_DELAY_TIMER.EVENT_ID 
	else
		DRAIN_V.trigger.source.stimulus = N2.tsplink.trigger[1].EVENT_ID
	end --if
	DRAIN_V.trigger.measure.stimulus = N2.tsplink.trigger[2].EVENT_ID	-- was DRAIN_MEASURE_TIMER.EVENT_ID
	DRAIN_V.trigger.endpulse.stimulus = DRAIN_V_PULSE_WIDTH_TIMER.EVENT_ID	-- Ivons changed on 24 Jan 2011; was N2.tsplink.trigger[3].EVENT_ID	-- was PULSE_WIDTH_TIMER.EVENT_ID 

	DRAIN_I.trigger.arm.count = 1	-- was gate_sweep_npoints			-- Also the number of pulses	
	DRAIN_I.trigger.arm.stimulus = 0
	DRAIN_I.trigger.count = gate_sweep_npoints	--was 1
	if ISRC_LAG_DELAY_TIMER then	-- Ivons added on 24 Jan 2011
		DRAIN_I.trigger.source.stimulus = ISRC_LAG_DELAY_TIMER.EVENT_ID	-- Ivons changed on 24 Jan 2011; was N2.tsplink.trigger[1].EVENT_ID	-- was PULSE_DELAY_TIMER.EVENT_ID 
	else
		DRAIN_I.trigger.source.stimulus = N2.tsplink.trigger[1].EVENT_ID
	end --if
	DRAIN_I.trigger.measure.stimulus = N3.tsplink.trigger[2].EVENT_ID	-- was DRAIN_MEASURE_TIMER.EVENT_ID
	DRAIN_I.trigger.endpulse.stimulus = DRAIN_I_PULSE_WIDTH_TIMER.EVENT_ID	-- Ivons changed on 24 Jan 2011; was N3.tsplink.trigger[3].EVENT_ID	-- was PULSE_WIDTH_TIMER.EVENT_ID 

	-- Perform test
	
	-- Execute autozero function once and then disable for duration of test
	GATE.measure.autozero = GATE.AUTOZERO_ONCE     --(Value is 1)
	DRAIN_V.measure.autozero = DRAIN_V.AUTOZERO_ONCE     --(Value is 1)
	DRAIN_I.measure.autozero = DRAIN_I.AUTOZERO_ONCE     --(Value is 1)

	-- Clear all timer event and overrun detectors; unclear if this step is really necessary
	PERIOD_TIMER.clear()
	PULSE_DELAY_TIMER.clear()
	MEASURE_DELAY_TIMER.clear()
	PULSE_WIDTH_TIMER.clear()
	DIGITIZE_DELAY_TIMER.clear()	-- Ivons added on 06 Jan 2010
--	GATE_MEASURE_TIMER.clear()
--	DRAIN_MEASURE_TIMER.clear()

	-- Turn ON all SMUs used for test
	GATE.source.output = GATE.OUTPUT_ON
	DRAIN_V.source.output = DRAIN_V.OUTPUT_ON
	if drain_i_pulse_ilevel == 0 and string.upper(DrainIsrc_ZeroAmpMode) == "HIGHZ" then
		DRAIN_I.source.output = DRAIN_I.OUTPUT_OFF
	else
		DRAIN_I.source.output = DRAIN_I.OUTPUT_ON
	end --if

	waitcomplete()	-- Make sure all operations have completed before intiating trigger models

	--Initiate the SMU trigger models
	DRAIN_V.trigger.initiate()		-- Won't proceed until GATE is initiated

	if drain_i_pulse_ilevel == 0 and string.upper(DrainIsrc_ZeroAmpMode) == "HIGHZ" then
		-- Do nothing
	else
		DRAIN_I.trigger.initiate()		-- Won't proceed until GATE is initiated
	end --if
	
	
--	delay(0.01)		-- Make sure that DRAIN_V and DRAIN_I are ready and waiting before initiating GATE;
					-- can't use waitcomplete(); not sure exactly how much time is required
	
	GATE.trigger.initiate()
	
	delay(0.01)
	
	N1.digio.trigger[1].assert()
		
	-- Wait for test to complete; trigger model operation is an overlapped operation
	waitcomplete()

	-- Turn OFF all SMUs used for test	
	DRAIN_I.source.output = DRAIN_I.OUTPUT_OFF	
	DRAIN_V.source.output = DRAIN_V.OUTPUT_OFF
--	DRAIN_I.source.output = DRAIN_I.OUTPUT_OFF	
	GATE.source.output = GATE.OUTPUT_OFF

	-- Print out data (Use "print" loop for TSB and "postbuftime" and "postbuffer" for ACS

local headings = "i".."|".."GateSwpSrcVal".."|".."Gate_Imeas".."|".."Gate_Vmeas"..
					  "|".."DRAIN_V_Imeas".."|".."DRAIN_V_Vmeas"..
					  "|".."DRAIN_I_Imeas".."|".."DRAIN_I_Vmeas".."|".."Drain_TotalCurrent"
local dig_headings = "j".."|".."GateSwpSrcVal".."|".."Gate_Imeas_Tstamp".."|".."Gate_Vmeas_Tstamp"..
					  "|".."DRAIN_V_Imeas_Tstamp".."|".."DRAIN_V_Vmeas_Tstamp"..
					  "|".."DRAIN_I_Imeas_Tstamp".."|".."DRAIN_I_Vmeas_Tstamp"..
					  "|".."j".."|".."GateSwpSrcVal".."|".."Gate_Imeas".."|".."Gate_Vmeas"..
					  "|".."DRAIN_V_Imeas".."|".."DRAIN_V_Vmeas"..
					  "|".."DRAIN_I_Imeas".."|".."DRAIN_I_Vmeas".."|".."Drain_TotalCurrent"..
					  "|".."j".."|".."GateSwpSrcVal".."|".."Gate_Imeas_Status".."|".."Gate_Vmeas_Status"..
					  "|".."DRAIN_V_Imeas_Status".."|".."DRAIN_V_Vmeas_Status"..
					  "|".."DRAIN_I_Imeas_Status".."|".."DRAIN_I_Vmeas_Status"
local readings = {}
local timestamps = {}
local statuses = {}

if Digitize == true then	-- Ivons added on 06 Jan 2011

	local start_count
	for i = 1, GATE.nvbuffer1.n do
	
		start_count = (i-1) * DigCount + 1
		for j = start_count, (i * DigCount) do
			readings[j] = j.."|"..GATE.nvbuffer1.sourcevalues[i].."|"..GATE.nvbuffer1[i].."|"..GATE.nvbuffer2[i]..
					 	 	 "|"..DRAIN_V.nvbuffer1[j].."|"..DRAIN_V.nvbuffer2[j]..
					 	 	 "|"..DRAIN_I.nvbuffer1[j].."|"..DRAIN_I.nvbuffer2[j].."|"..(DRAIN_V.nvbuffer1[j]+DRAIN_I.nvbuffer1[j])
			timestamps[j] = j.."|"..GATE.nvbuffer1.sourcevalues[i].."|"..GATE.nvbuffer1.timestamps[i].."|"..GATE.nvbuffer2.timestamps[i]..
						   	   "|"..DRAIN_V.nvbuffer1.timestamps[j].."|"..DRAIN_V.nvbuffer2.timestamps[j]..
						   	   "|"..DRAIN_I.nvbuffer1.timestamps[j].."|"..DRAIN_I.nvbuffer2.timestamps[j]
			statuses[j] = j.."|"..GATE.nvbuffer1.sourcevalues[i].."|"..GATE.nvbuffer1.statuses[i].."|"..GATE.nvbuffer2.statuses[i]..
					 	 	 "|"..DRAIN_V.nvbuffer1.statuses[j].."|"..DRAIN_V.nvbuffer2.statuses[j]..
					 	 	 "|"..DRAIN_I.nvbuffer1.statuses[j].."|"..DRAIN_I.nvbuffer2.statuses[j]
		end --for
	end --for

else

	for i = 1, GATE.nvbuffer1.n do
		readings[i] = i.."|"..GATE.nvbuffer1.sourcevalues[i].."|"..GATE.nvbuffer1[i].."|"..GATE.nvbuffer2[i]..
					 	 "|"..DRAIN_V.nvbuffer1[i].."|"..DRAIN_V.nvbuffer2[i]..
					 	 "|"..DRAIN_I.nvbuffer1[i].."|"..DRAIN_I.nvbuffer2[i].."|"..(DRAIN_V.nvbuffer1[i]+DRAIN_I.nvbuffer1[i])
		timestamps[i] = i.."|"..GATE.nvbuffer1.sourcevalues[i].."|"..GATE.nvbuffer1.timestamps[i].."|"..GATE.nvbuffer2.timestamps[i]..
						   "|"..DRAIN_V.nvbuffer1.timestamps[i].."|"..DRAIN_V.nvbuffer2.timestamps[i]..
						   "|"..DRAIN_I.nvbuffer1.timestamps[i].."|"..DRAIN_I.nvbuffer2.timestamps[i]
		statuses[i] = i.."|"..GATE.nvbuffer1.sourcevalues[i].."|"..GATE.nvbuffer1.statuses[i].."|"..GATE.nvbuffer2.statuses[i]..
					 	 "|"..DRAIN_V.nvbuffer1.statuses[i].."|"..DRAIN_V.nvbuffer2.statuses[i]..
					 	 "|"..DRAIN_I.nvbuffer1.statuses[i].."|"..DRAIN_I.nvbuffer2.statuses[i]
	end --for

end --if

print()
if Digitize == true then	-- Ivons added on 06 Jan 2011
	print(dig_headings)
	-- print()
	for i = 1, table.getn(readings) do
		print(timestamps[i].."|"..readings[i].."|"..statuses[i])
	end --for
else

	print(headings)
	print()
	for i = 1, table.getn(readings) do
		print(readings[i])
	end --for

	print()
	for i = 1, table.getn(timestamps) do
		print(timestamps[i])
	end --for

	print()
	for i = 1, table.getn(statuses) do
		print(statuses[i])
	end --for
end --if

--[[
	print()
	print("        i        ","  GateSwpSrcVal","   Gate_Imeas","  Gate_Vmeas","  DRAIN_V_Imeas","  DRAIN_V_Vmeas","  DRAIN_I_Imeas","  DRAIN_I_Vmeas","  Drain_TotalCurrent")
	for i = 1, GATE.nvbuffer1.n do
		print(i,GATE.nvbuffer1.sourcevalues[i],GATE.nvbuffer1[i],GATE.nvbuffer2[i],DRAIN_V.nvbuffer1[i],"    ",DRAIN_V.nvbuffer2[i],"    ",DRAIN_I.nvbuffer1[i],"    ",DRAIN_I.nvbuffer2[i],"    ",DRAIN_V.nvbuffer1[i]+DRAIN_I.nvbuffer1[i])
	end --for

	print()
	print("        i        ","  GateSwpSrcVal","   Gate_Imeas","  Gate_Vmeas","  DRAIN_V_Imeas","  DRAIN_V_Vmeas","  DRAIN_I_Imeas","  DRAIN_I_Vmeas","  Drain_TotalCurrent")
	for i = 1, GATE.nvbuffer1.n do
		print(i,GATE.nvbuffer1.sourcevalues[i],GATE.nvbuffer1.timestamps[i],GATE.nvbuffer2.timestamps[i],DRAIN_V.nvbuffer1.timestamps[i],"    ",DRAIN_V.nvbuffer2.timestamps[i],"    ",DRAIN_I.nvbuffer1.timestamps[i],"    ",DRAIN_I.nvbuffer2.timestamps[i])
	end --for
	
	print()
	print("        i        ","  GateSwpSrcVal","   Gate_Imeas","  Gate_Vmeas","  DRAIN_V_Imeas","  DRAIN_V_Vmeas","  DRAIN_I_Imeas","  DRAIN_I_Vmeas","  Drain_TotalCurrent")
	for i = 1, GATE.nvbuffer1.n do
		print(i,GATE.nvbuffer1.sourcevalues[i],GATE.nvbuffer1.statuses[i],GATE.nvbuffer2.statuses[i],DRAIN_V.nvbuffer1.statuses[i],"    ",DRAIN_V.nvbuffer2.statuses[i],"    ",DRAIN_I.nvbuffer1.statuses[i],"    ",DRAIN_I.nvbuffer2.statuses[i])
	end --for
]]
--[[
	
	-- postbuftime(�name�, start_index, end_index, buff_name, avg_num)
	postbuftime("GateSwpTimestamps",1,GATE.nvbuffer1.n,GATE.nvbuffer1,1)
	
	-- postbuffer(�name�, start_index, end_index, buff_name, avg_num)
	postbuffer("GateSwpSrcValues",1,GATE.nvbuffer1.n,GATE.nvbuffer1.sourcevalues,1)
	postbuffer("Gate_Vmeas",1,GATE.nvbuffer2.n,GATE.nvbuffer2,1)
	postbuffer("Gate_Imeas",1,GATE.nvbuffer1.n,GATE.nvbuffer1,1)
	postbuffer("Drain_DRAIN_V_Vmeas",1,DRAIN_V.nvbuffer2.n,DRAIN_V.nvbuffer2,1)
	postbuffer("Drain_DRAIN_V_Imeas",1,DRAIN_V.nvbuffer1.n,DRAIN_V.nvbuffer1,1)
	postbuffer("Drain_DRAIN_I_Vmeas",1,DRAIN_I.nvbuffer2.n,DRAIN_I.nvbuffer2,1)
	postbuffer("Drain_DRAIN_I_Imeas",1,DRAIN_I.nvbuffer1.n,DRAIN_I.nvbuffer1,1)
]]

	return 0, "Ran OK"	-- Function returns zero if runs to completion

end --function

ResetTspLink(true)

PrintUnitInfo()

--print("SweepGate_PulseDrain(GateStartV, GateStopV, GateStepV, GateIlimit, DrainSmuMode, DrainSmuRegionIndex, DrainVpulseLevel, DrainIlimit, DrainIsrc_ZeroAmpMode, DrainPulseWidth, DrainDutyCycle, Nplc, EnableHighC)")


-- SweepGate_PulseDrain(GateStartV, GateStopV, GateStepV, GateIlimit, DrainSmuMode, DrainSmuRegionIndex, DrainVpulseLevel, DrainIlimit, DrainIsrc_ZeroAmpMode, DrainPulseWidth, DrainDutyCycle, Nplc, EnableHighC)

local VoltageLevels = {1,2,4,5,6,8,9,10,12,14,15,16,18,19,20,22,24,25,26,28,30,32,34,35,36,38,39,40}	-- Ivons added on 11 Jan 2011
local VoltageLevelToTest = 10					-- Ivons added on 12 Jan 2011 *******************************************
--local VoltageLevelsToTest = {1,2,5,9}			-- Ivons added on 11 Jan 2011
--local VoltageLevelsToTest = {10,12,18,19}		-- Ivons added on 11 Jan 2011
--local VoltageLevelsToTest = {20,22,25,30}		-- Ivons added on 11 Jan 2011
--local VoltageLevelsToTest = {35,38,39,40}		-- Ivons added on 11 Jan 2011
local CmplMultiplier = {1, 1.2}					-- Ivons added on 11 Jan 2011
local SmuMode = {1,2}							-- Ivons added on 11 Jan 2011

for i = 1, table.getn(VoltageLevels) do						-- Ivons added on 11 Jan 2011
--	for m = 1, table.getn(VoltageLevelsToTest) do			-- Ivons added on 11 Jan 2011; Ivons commented out on 12 Jan 2011
--		if VoltageLevels[i] == VoltageLevelsToTest[m] then	-- Ivons added on 11 Jan 2011; Ivons commented out on 12 Jan 2011
		if VoltageLevels[i] == VoltageLevelToTest then		-- Ivons added on 12 Jan 2011
			for j = 1, 2 do									-- Ivons added on 11 Jan 2011
				for k = 1, 2 do								-- Ivons added on 11 Jan 2011

print()										-- Ivons added on 11 Jan 2011
--print("i:|"..i.."|j:|"..j.."|k:|"..k)		-- Ivons added on 11 Jan 2011
print("i,j,k:|"..i..","..j..","..k)			-- Ivons added on 11 Jan 2011
print()										-- Ivons added on 11 Jan 2011
		 
GateStartV = 0
GateStopV = 1	-- was 5, , Ivons changed to 1 beginning with Test 27 
GateStepV = 1
GateIlimit = 0.1
DrainSmuMode = SmuMode[k]	-- was 1 or 2
DrainSmuRegionIndex = 0	-- Zero (0) is pick automatically
DrainVpulseLevel = VoltageLevels[i]		-- was 10
DrainIlimit = 	CmplMultiplier[j] * VoltageLevels[i]	-- was 10		-- Enter TOTAL compliance for both SMUs; script will divide in half for each individual SMU
DrainIsrc_ZeroAmpMode = "ZeroAmp"	-- Set to "ZeroAmp" or "HighZ"
DrainPulseWidth = 300e-6	--was 300e-6
DrainDutyCycle = 0.001	-- was 0.003
Nplc = 0.003
EnableHighC = false
Digitize = true			-- Ivons added on 06 Jan  2011
DigInterval = 1e-6		-- Ivons added on 06 Jan  2011
DigCount = 800			-- Ivons added on 06 Jan  2011;  originally was 500, Ivons increased to 600 beginning with Test 27; changed to 800 starting with Test 28 
PreTrigPercent = 10		-- Ivons added on 06 Jan  2011
CheckParamOnly = false	-- Ivons added on 11 Jan 2011
VsrcCmplOff = false
VsrcLagDelay = 0
IsrcPulseWidth = 300e-6
Use2wire = true
-- status = SweepGate_PulseDrain(GateStartV, GateStopV, GateStepV, GateIlimit, DrainVpulseLevel, DrainIlimit, DrainPulseWidth, EnableHighC)

Status, Msg = SweepGate_PulseDrain(GateStartV, GateStopV, GateStepV, GateIlimit, DrainSmuMode, DrainSmuRegionIndex, DrainVpulseLevel, DrainIlimit, DrainIsrc_ZeroAmpMode, DrainPulseWidth, DrainDutyCycle, Nplc, EnableHighC, 
									Digitize, DigInterval, DigCount, PreTrigPercent, CheckParamOnly, VsrcCmplOff, VsrcLagDelay, IsrcPulseWidth, Use2wire)
print("Status:|"..Status)
print(Msg)
if not(CheckParamOnly) then delay(35) end	-- Ivons added on 11 Jan 2011
				end --for k		-- Ivons added on 11 Jan 2011
			end --for j			-- Ivons added on 11 Jan 2011
		end --if				-- Ivons added on 11 Jan 2011
--	end --for m					-- Ivons added on 11 Jan 2011; Ivons commented out on 12 Jan 2011
end --for i						-- Ivons added on 11 Jan 2011


--postdata("Status",status)
