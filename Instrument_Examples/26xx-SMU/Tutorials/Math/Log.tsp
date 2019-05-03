--[[
***********************************************************
*** Copyright 2019 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

log.tsp

This is an illustration how you can use the Math Library features to evaluate the IV relationship of a
diode. The 260x is a great instrument for evaluating and testing diodes. We will use the IV relationship
equation typically used for a diode:

If = Is(EXP(v/nVt))

where:
If		The current in the forward region
Is		Saturation current
v		Applied voltage
n		A value between 1 and 2
Vt		Thermal Voltage

Commands used:
math.exp(x)
 Returns the exponential function of x; that is, ex, where e is the base of the natural logarithms.

math.log(x)
 Returns the natural logarithm function of x.
   

Rev1: JLT 9.10.2005
]]--

-- In this example, you can supply the constant values for Is, n, and Vt. A loop will be used to source
-- the forward voltages, from 0 to 1 volt. The 'math.exp' function will help us to compute the expected 
-- forward current so that we can compare the actual results to the mathematical results.

Is = 100e-12									-- 100pA Saturation Current
n = 2											-- constant
Vt = 25e-3										-- Thermal Voltage Constant

-- Create loop to output forward voltage with 260x. Set for DC Volts output and turn output on.

smua.source.func = smua.OUTPUT_DCVOLTS			-- Set the source function to DC Volts
smua.source.output = smua.OUTPUT_ON				-- Turns on the output

for Vf= 0, 1.05, 0.05 do						-- Create a For..Do loop to sweep the voltage
   	smua.source.levelv = Vf						-- Set the output level 
   	current = smua.measure.i( )					-- Measure the current.
   	calcI = Is*math.exp(Vf/(n * Vt))			-- Calculate If
   	calcVf = n*Vt*math.log(current/Is)			-- Calculate Vf based on measured current
   	print("Vf = ",Vf,", Measured If = ",current,", Calculate If = ",calcI,", and Calculated Vf = ",calcVf)
   	delay(0.5)	 
end

smua.source.output = smua.OUTPUT_OFF			-- Turns off the output
