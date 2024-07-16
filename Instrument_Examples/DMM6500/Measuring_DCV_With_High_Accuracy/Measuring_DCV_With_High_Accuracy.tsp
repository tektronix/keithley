--Reset the instrument to the default settings.
reset()

--Set the measure function to DC voltage.
dmm.measure.func = dmm.FUNC_DC_VOLTAGE

--Set the measurement range to 10 V.
dmm.measure.range = 10

--Set the number of power line cycles to 10.
dmm.measure.nplc = 10

--Set the input impedance to auto so it selects 10 Gohm for the 10V range.
dmm.measure.inputimpedance = dmm.IMPEDANCE_AUTO

--Enable autozero.
dmm.measure.autozero.enable = dmm.ON

--Set the averaging filter type to repeating.
dmm.measure.filter.type = dmm.FILTER_REPEAT_AVG

--Set filter count to 100.
dmm.measure.filter.count = 100

--Enable the filter.
dmm.measure.filter.enable = dmm.ON

--Read the voltage value.
print(dmm.measure.read())