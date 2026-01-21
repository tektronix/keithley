--[[
Volt_Co():
This program performs a voltage coefficient measurement on a 10GΩ part.
Required equipment:
(1) Single-channel Keithley Series 2600 System SourceMeter® instrument
(1) 10GΩ resistor
Running this script creates functions that can be used to measure the voltage coefficient
of resistances.
The functions created are:
1. Volt_Co(v1src, v2src) --Default values v1src = 100V, v2src = 200V
2. Check_Comp()
3. Calc_Val(v1src, v2src, i1meas, i2meas)
4. Print_Data(voltco,res1,res2)
See detailed information listed in individual functions.
To run:
1) From Test Script Builder
- Right-click in the program window, select "Run as TSP"
- At the TSP> prompt in the Instrument Control Panel, type Volt_Co()
3) From an external program
- Send the entire program text as a string using standard GPIB Write calls.
Rev1: JAC 5.9.2007
]]--


function Volt_Co(v1src, v2src) 
	--Configure instrument to supply two user-defined
	--voltages and measure current.

	--Instrument variables.
	local l_srcdelay = 0 --Source delay before measurement
	local l_icmpl = 1E-3 --Source compliance
	local l_nplc = 1 --Measurement Integration Rate
	local l_v1src = v1src --First voltage source value
	local l_v2src = v2src --Second voltage source value
	--Define measured and calculated variables
	local l_i1meas = 0 --Initialize first current measurement
	local l_res1 = 0 --Initialize first resistance measurement
	local l_i2meas = 0 --Initialize second current measurement
	local l_res2 = 0 --Initialize second resistance measurement
	local l_voltco = 0 --Initialize voltage coefficient calculation
	local l_comp_val = false --Initialize compliance variable

	--Default values and level check

	if (l_v1src == nil) then --Use default value
		l_v1src = 100
	end --if

	if (l_v1src > 100) then --Coerce source value within range
		l_v1src = 100
		print("Maximum voltage value is 202V!!")
	end --if

	if (l_v2src == nil) then --Use default value
		l_v2src = 200
	end --if

	if (l_v2src > 200) then --Coerce source value within range
		l_v2src = 200
		print("Maximum voltage value is 202V!!")
	end --if


	--Configure source and measure settings

	smua.reset() --Reset SMU
	errorqueue.clear() --Clear the error queue
	smua.source.func = smua.OUTPUT_DCVOLTS --Output Voltage
	smua.source.levelv = 0 --Source 0 before enabling output
	smua.measure.nplc = l_nplc --Set integration rate
	smua.source.autorangev = smua.AUTORANGE_ON --Enable source autorange
	smua.source.limiti = l_icmpl
	smua.measure.autorangei = smua.AUTORANGE_ON --Enable measurement autorange
	smua.source.output = smua.OUTPUT_ON --Enable output
	smua.source.levelv = l_v1src --Source programmed value
	l_comp_val = Check_Comp() --check compliance
	if l_comp_val == true then
		smua.source.output = smua.OUTPUT_OFF --Disable output
		smua.source.levelv = 0 --Return source to 0
	else
		delay(l_srcdelay) --wait before making measurement
		l_i1meas = smua.measure.i() --measure current
		smua.source.levelv = l_v2src --Source programmed value
		delay(l_srcdelay) --wait before making measurement
		l_i2meas = smua.measure.i() --Measure current
		smua.source.output = smua.OUTPUT_OFF --Disable output
		l_voltco, l_res1, l_res2 = Calc_Val(l_v1src, l_v2src, l_i1meas,l_i2meas)
	--calculate
		Print_Data(l_voltco, l_res1, l_res2) --print
end --if

end --function Volt_Co()


function Check_Comp() --Function checks state of compliance, if true, prints warning and
	--returns boolean?
	--to run_test()
	local l_comp_val = false --Initialize local variable
	l_comp_val = smua.source.compliance --Check compliance
	if l_comp_val == true then
	print("")
	print("SMU Source in Compliance!")
	print("Ensure proper connections, stable device, and settings are correct")
	print("Rerun Test")
	print("")
	end --if
	return l_comp_val
end --function Check_Comp()


function Calc_Val(v1src, v2src, i1meas, i2meas) --function calculates resistance and
	--voltage coefficient
	local l_res1 = v1src/i1meas --Return quotient = resistance calculation
	local l_res2 = v2src/i2meas --Return quotient = resistance calculation
	local l_voltco = 100*(l_res2-l_res1)/(l_res1*(v2src-v1src)) --Return quotient =
	--voltage coefficient
	return l_voltco, l_res1, l_res2 --Return values
end --function Calc_Val()


function Print_Data(voltco,res1,res2)
	local l_voltco = voltco
	local l_res1 = res1
	local l_res2 = res2
	print("")
	print("**** Data ****")
	print("")
	print("Voltage Coefficient: ", voltco, "%/V") --Print Voltage Coefficient
	print("")
	print("Resistance R1: ", res1, "Ohms") --Print resistance value
	print("Resistance R2: ", res2, "Ohms") --Print resistance value
end --function Print_Data()

--Volt_Co() --Call Volt_Co()