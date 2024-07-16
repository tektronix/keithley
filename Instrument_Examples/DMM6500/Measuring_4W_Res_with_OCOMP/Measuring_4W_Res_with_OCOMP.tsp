--Reset the Model DMM6500 to the default settings.
reset()

--Set the measure function to 4-wire resistance.
dmm.measure.func = dmm.FUNC_4W_RESISTANCE

--Enable autorange.
dmm.measure.autorange = dmm.ON

--Enable autozero.
dmm.measure.autozero.enable = dmm.ON

--Enable offset compensation.
dmm.measure.offsetcompensation.enable = dmm.ON

--Set the number of power line cycles to 1.
dmm.measure.nplc = 1

--Read the resistance value.
print(dmm.measure.read())


