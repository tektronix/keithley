--[[
BJTFast():

This program performs a sequence of
standard transistor tests with values setup
for a 2N3904 part.

This script creates the following functions that perform standard tests
for a Bipolar Junction Transistor:

1) Setup
2) VCEO
3) VCEsat (Performs VCEsat and VBEsat tests simultaneously)
4) HFE/Beta Gain test

Required equipment:

(1) Keithley 2602 System Sourcemeter(c)
(1) Keithley 8101-04-TRX Test Fixture
(2) Keithley 2600-DEMO-TRX cables

Rev1: JAC 4.7.2005
Rev2: Add Print Data option
      JAC 4.22.2005
]] --

------------------ Keithley TSP Function ------------------
function BJTFast(num, return_data)
  local bin_fail_VCEO = 0
  local bin_fail_VCEsat = 0
  local bin_fail_VBEsat = 0
  local bin_fail_HFE = 0
  local bin_all_pass = 0

  --clear the front panel display and prompt for input parameters if missing
  display.clear()

  if num == nil then
    num = display.prompt("0000", " Parts", "Enter number of parts to test", 50, 1, 9999)
  end --end if


  function setup()
    --Sets up instrument

    Collector = smua
    Base = smub
    D = 0.0005

    I = 1
    J = 1
    LabelCount = 4
    GoodParts = 0

    NPLC2 = 0.05
    NPLC = 0.001

    VCEO_data = {}
    VCEsat_data = {}
    VBEsat_data = {}
    BETA1_data = {}

    Label = { "**VCEO**", "**VCEsat**", "**VBEsat**", "**BETA1**" }


    AZERO = smua.AUTOZERO_OFF
    --AZERO = smua.AUTOZERO_AUTO

    digio.writeport(0)   -- Set All Digital I/O lines lo
    display.clear()      --Clear 2602 display

    Base.reset()         --Reset base
    Collector.reset()    --Reset collector

    Base.source.func = Base.OUTPUT_DCVOLTS
    Base.measure.autozero = Base.AUTOZERO_AUTO
    Base.measure.nplc = NPLC
    Base.measure.v()
    Base.measure.i()
    Base.measure.autozero = AZERO
    Base.measure.autorangei = Base.AUTORANGE_OFF
    Base.measure.autorangev = Base.AUTORANGE_OFF
    Base.source.autorangei = Base.AUTORANGE_OFF
    Base.source.autorangev = Base.AUTORANGE_OFF

    Base.source.rangei = 0.01   --smu current range
    Base.source.levelv = 0      --smu source value
    Base.source.output = Base.OUTPUT_ON


    Collector.source.func = Collector.OUTPUT_DCVOLTS
    Collector.measure.autozero = Collector.AUTOZERO_AUTO
    Collector.measure.nplc = NPLC
    Collector.measure.v()
    Collector.measure.i()
    Collector.measure.autozero = AZERO
    Collector.measure.autorangei = Collector.AUTORANGE_OFF
    Collector.measure.autorangev = Collector.AUTORANGE_OFF
    Collector.source.autorangei = Collector.AUTORANGE_OFF
    Collector.source.autorangev = Collector.AUTORANGE_OFF

    Collector.source.rangev = 40   --smu voltage range
    Collector.source.levelv = 0    --smu source value
    Collector.source.output = Collector.OUTPUT_ON
  end

  function VCEO(i)
    --Source current on collector, open base, and
    --measure voltage on the collector/emitter

    local VCEOlimit = 40

    Collector.measure.nplc = NPLC
    Base.measure.nplc = NPLC

    Base.source.func = Base.OUTPUT_DCAMPS
    Base.source.rangev = 40
    Base.source.limitv = 40
    Base.source.leveli = 0                            --smua source value
    Base.source.rangei = 100E-9                       --smua current range
    Base.measure.rangev = 40
    delay(D)                                          --Delay

    Collector.source.func = Collector.OUTPUT_DCAMPS   --SMU to source current
    Collector.source.rangev = 40
    Collector.source.rangei = 0.01
    Collector.source.leveli = 0.01   --Set Source level
    Collector.source.limitv = 40
    Collector.measure.rangev = 40
    delay(D)                               --Delay

    VCEO_data[i] = Collector.measure.v()   --Measure V

    --End of SDM cycle

    if (VCEO_data[i] > 30) then   --Evaluate Pass/Fail criterion
      Pass = 1                    --Pass is True
    else
      Pass = 0                    --Reinitialize Pass
      Fail_VCEO = 1
    end                           --end if

    --Write Pass/Fail
    WriteHandler(Pass)
    --End of Decision Time
  end   --end function VCEO()

  function HFE1(i)
    --Performs a binary search for the target Gain/Beta/HFE value.

    local k                   --binary search loop count variable
    local VCESource = 1       --VCEsource value
    local HIGHIb = 10e-7      --Start Ib high limit
    local LOWIb = 1e-9        --Start Ib lo limit
    local HFE1limit = 40      --HFE limit
    local TARGETIc = 100e-6   --Target Ic for binary search

    Collector.measure.nplc = NPLC2
    Base.measure.nplc = NPLC2

    Collector.source.func = Collector.OUTPUT_DCVOLTS
    Collector.source.limiti = (5 * TARGETIc)
    Collector.source.rangev = 6
    Collector.measure.rangei = 10e-3

    Base.source.func = Base.OUTPUT_DCAMPS
    Base.measure.rangei = 100e-6
    Base.source.limiti = HIGHIb
    Base.source.rangev = 6
    Base.measure.rangev = 6
    Base.source.limitv = 6

    --Start test
    Collector.source.levelv = VCESource
    Base.source.leveli = 0
    Collector.source.output = Collector.OUTPUT_ON   --open relay (open base)
    delay(0.001)                                    --Delay

    --Search for the right base current
    k = 0

    repeat
      k = k + 1
      Ib = ((HIGHIb - LOWIb) / 2) + LOWIb
      Base.source.leveli = Ib
      delay(0.001)
      IcMeas = Collector.measure.i()

      if (TARGETIc < IcMeas) then
        HIGHIb = Ib
      else
        LOWIb = Ib
      end   --end if
    until ((math.abs(IcMeas - TARGETIc) < (0.05 * TARGETIc)) or (k > 10))

    --iteration limit reached
    if (k > 10) then
    end    --end if

    BETA1_data[i] = IcMeas / Ib

    if (BETA1_data[i] > HFE1limit) then    --Evaluate Pass/Fail criterion
      Pass = 1                             --Pass is True
    else
      Pass = 0
      Fail_HFE = 1
    end    --end if

    --Write Pass/Fail
    WriteHandler(Pass)
  end   --end function HFE1()

  function VCEsat(i)
    SourceCollector = 10E-3
    LimitVCEsat = 0.2

    SourceBase = 1E-3
    LimitVBEsat = 1.1

    Collector.measure.rangev = 1
    Collector.source.rangei = SourceCollector
    Collector.source.leveli = SourceCollector

    Base.measure.rangev = 1
    Base.source.rangei = SourceBase
    Base.source.leveli = SourceBase
    delay(0.001)
    VCEsat_data[i] = Collector.measure.v()

    VBEsat_data[i] = Base.measure.v()

    if (VCEsat_data[i] < LimitVCEsat) then   --Evaluate Pass/Fail criterion
      Pass = 1                               --Pass is True
    else
      Pass = 0
      Fail_VCEsat = 1
    end   --end if

    WriteHandler(Pass)

    if (VBEsat_data[i] < LimitVBEsat) then   --Evaluate Pass/Fail criterion
      Pass = 1                               --Pass is True
    else
      Pass = 0
      Fail_VBEsat = 1
    end   --end if

    --Write Pass/Fail
    WriteHandler(Pass)
  end   --end function VCEsat()

  function WriteHandler(Pass)
    if (Pass == 1) then
      digio.writebit(2, 1)  --Set bit 2 Hi, DUT pass
    else
      digio.writebit(8, 1)  --Set bit 8 Hi, DUT Fail
    end

    delay(D)
    digio.writeport(0)   --Reset Digital I/O
  end                    --end function Writehandler()

  ----------***** Start Test *****----------

  timer.reset()
  setup()
  SetupTime = timer.measure.t()

  timer.reset()

  display.settext("Test In Progress")
  display.setcursor(2, 1)
  display.settext("Testing " .. num .. " parts")

  for i = 1, num do
    Fail_VCEO = 0
    Fail_VCEsat = 0
    Fail_VBEsat = 0
    Fail_HFE = 0

    VCEO(i)
    VCEsat(i)
    HFE1(i)

    -- Bin
    if Fail_VCEO == 1 then
      bin_fail_VCEO = bin_fail_VCEO + 1
      PartStatus = " BAD"
    elseif Fail_VCEsat == 1 then
      bin_fail_VCEsat = bin_fail_VCEsat + 1
      PartStatus = " BAD"
    elseif Fail_VBEsat == 1 then
      bin_fail_VBEsat = bin_fail_VBEsat + 1
      PartStatus = " BAD"
    elseif Fail_HFE == 1 then
      bin_fail_HFE = bin_fail_VBEsat + 1
      PartStatus = " BAD"
    else
      bin_all_pass = bin_all_pass + 1
      PartStatus = " GOOD"
    end   --end if
  end     --end Main for loop

  TestTime = timer.measure.t() / num

  --Return instrument to idle state
  Base.source.func = Base.OUTPUT_DCVOLTS
  Base.source.levelv = 0

  Collector.source.func = Collector.OUTPUT_DCVOLTS
  Collector.source.levelv = 0

  Base.measure.autozero = smua.AUTOZERO_AUTO
  Base.measure.nplc = NPLC
  Base.measure.v()
  Base.measure.i()

  Collector.measure.autozero = smua.AUTOZERO_AUTO
  Collector.measure.nplc = NPLC
  Collector.measure.v()
  Collector.measure.i()

  Collector.source.output = Collector.OUTPUT_OFF
  Base.source.output = Base.OUTPUT_OFF

  -- Show Stats
  Throughput = 1 / TestTime
  Percent = GoodParts / (num * LabelCount) * 100

  display.clear()
  display.settext("Part Status:" .. PartStatus)
  display.setcursor(2, 1)
  display.settext("Bin Counts:" ..
  bin_fail_VCEO .. " " .. bin_fail_VCEsat .. " " .. bin_fail_VBEsat .. " " .. bin_fail_HFE .. " " .. bin_all_pass)
  delay(3)


  display.clear()
  Throughput = 1 / TestTime
  display.settext("Parts per sec:" .. string.format("%d", Throughput))
  delay(3)

  display.screen = 2


  function Print_data()
    for j = 1, LabelCount do
      print(Label[j])

      for i = 1, num do
        if j == 1 then
          print(VCEO_data[i])
        elseif j == 2 then
          print(VCEsat_data[i])
        elseif j == 3 then
          print(VBEsat_data[i])
        elseif j == 4 then
          print(BETA1_data[i])
        end   --end if
      end     --end for loop
      print()
    end       --end for loop
  end         --end function Print_data1()

  if return_data == "yes" then
    Print_data()
  end   --if

  --Print_data1()
end --end function BJTFast()

BJTFast(nil, 'yes')
display.loadmenu.add("BJTTest_Fast", "BJTFast(nil,'no')")
