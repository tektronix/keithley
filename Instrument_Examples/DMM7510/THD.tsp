--[[
THD (Total Harmonic Distortion) Measurement

Purpose: Creates a user swipe screen to display computed THD in % and dB from digitized voltage measurements. (THD computation is Copilot-generated).

Written by: EEVBlog user rusoaie (https://www.eevblog.com/forum/profile/?u=1027903)
Source thread: https://www.eevblog.com/forum/testgear/tsp-and-lua-scripts-for-modern-keithley-dmms-smus-etc/msg6341928/#msg6341928
Reproduced with permission.

]]

-- Configure the DMM7510 digitizer for voltage capture
local fs = 20000           -- sample rate (Hz)
local N = 20000           -- number of samples
dmm.digitize.func = dmm.FUNC_DIGITIZE_VOLTAGE      -- Digitize voltage mode
dmm.digitize.range = 1                            -- 1 V range (fixed)
-- dmm.digitize.displaydigits = dmm.DIGITS_6_5
dmm.digitize.samplerate = fs                     -- 40 kHz sampling
--- dmm.digitize.aperture = dmm.APERTURE_AUTO        -- auto aperture for best accuracy
dmm.digitize.count = N                           -- number of samples to acquire
-- dmm.digitize.inputimpedance = dmm.IMPEDANCE_AUTO -- auto input impedance
defbuffer1.capacity = N                          -- allocate buffer for N points
-- defbuffer1.fillmode = buffer.FILL_ONCE

display.settext(display.TEXT1, "")
display.settext(display.TEXT2, "Capturing data...")

defbuffer1.clear()                               -- clear any existing data
dmm.digitize.read()                              -- perform the digitize and fill defbuffer1

-- Ensure data was captured
if defbuffer1.n < 2 then
    print("Error: No data captured.")
    return
end

local num = defbuffer1.n

-- compute mean
local sum = 0.0
for i = 1, num do
    sum = sum + defbuffer1[i]
end
local mean = sum / num
display.settext(display.TEXT2, "Searching fundamental...")

-- Zero-crossing using mean (negative->positive edges)
local count = 0
local prev_sign = (defbuffer1[1] - mean) >= 0
local prev_index = 1
local period_sum = 0
for i = 2, num do
      local v = defbuffer1[i] - mean
      if (not prev_sign) and (v >= 0) then
            count = count + 1
            if count > 1 then
                  period_sum = period_sum + (i - prev_index)
            end
            prev_index = i
      end
      prev_sign = (v >= 0)
end

local f0 = 0
if count > 1 then
    local avg_period = period_sum/(count-1)
    f0 = fs/avg_period
else
    -- Fallback: estimate from FFT peak (simple approach)
    print("Zero-crossing failed; cannot reliably find fundamental.")
    return
end

display.settext(display.TEXT1, string.format("Freq: %.4f Hz", f0))
display.settext(display.TEXT2, "Computing harmonics...")

-- Harmonic sums (compute amplitude without modifying defbuffer1)
local amps = {}
for k = 1, 7 do
    local freq = f0 * k
    local sum_cos = 0.0
    local sum_sin = 0.0
    local phaseInc = 2*math.pi*freq/fs
    local phase = 0.0
    for n = 1, num do
        local v = defbuffer1[n] - mean            -- <-- subtract mean here
        sum_cos = sum_cos + v * math.cos(phase)
        sum_sin = sum_sin + v * math.sin(phase)
        phase = phase + phaseInc
        if phase > 2*math.pi then phase = phase - 2*math.pi end
    end
    local magnitude = math.sqrt(sum_cos*sum_cos + sum_sin*sum_sin)
    amps[k] = 2.0 * magnitude / num
end

display.settext(display.TEXT2, "Computing THD...")

-- Compute THD (using harmonics 2–7)
local harm_sum_sq = 0
for k = 2, 7 do
    harm_sum_sq = harm_sum_sq + amps[k]^2
end
local thd_ratio = math.sqrt(harm_sum_sq) / (amps[1] ~= 0 and amps[1] or 1)
local thd_pct = thd_ratio * 100
local thd_db = 20 * math.log10(thd_ratio)

-- Print results to instrument console
print(string.format("Detected fundamental frequency: %.2f Hz", f0))
print("Harmonic\tFrequency (Hz)\tAmplitude (V)")
for k = 1, 7 do
    local hk = f0 * k
    print(string.format("%d\t\t%.4f\t\t%.9f", k, hk, amps[k]))
end

-- Update front-panel display with fundamental and THD
display.changescreen(display.SCREEN_USER_SWIPE)
display.settext(display.TEXT2, string.format("THD = %.4f%% (%.1f dB)", thd_pct, thd_db))
