"""
Software-trig_26x4B

    ************************************************************************
    *** Copyright Tektronix, Inc.                                        ***
    *** See www.tek.com/sample-license for licensing terms.              ***
    ************************************************************************

Description:
	This python script was written by Keithley Apps Engineer Andrea Clary. 

    The 2604B, 2614B, and 2634B are lower priced versions of the 2602B, 2612B,
    and 2636B. They have no digital I/O for external triggering on the DB25 
    connector. Additionally, they have no TSP-Link for triggering and communicating
    with other TSP enabled instruments. They also have no contact check feature
    and the 2634B lacks the low, 100pA measure range of the 2636B. 

    For triggering and coordinating instruments, a software or bus trigger
    should be used. 

    This NON-FUNCTIONAL python code shows how the trigger model can be used to wait 
    for the *TRG software trigger. When the smuX.trigger.initiate() command is sent, 
    the SMU moves from the IDLE state and into the yellow Arm Layer. We’ve 
    assigned the Arm Event Detector to use the trigger.EVENT_ID() as a stimulus 
    which occurs when the *TRG is issued.

    After the *TRG stimulus is received, the operation will advance into the green 
    Trigger Layer and carry out the 7-point list sweep. The two entries in the 
    source list will just be toggled thru, 7 times: 0, 5, 0, 5, 0, 5, 0

    This script illustrates how the *TRG issued by the PC is an available means 
    to coordinate SMU action with external devices.

    This script will not work without additional code to connect to my_instr 
    using pyVISA or another VISA layer command set. 

"""

my_instr.write("reset()")
my_instr.write("errorqueue.clear()")

my_instr.write("smu = node[1].smua")

my_instr.write("smu.nvbuffer1.clear()")
my_instr.write("smu.nvbuffer1.appendmode = 1")
my_instr.write("smu.nvbuffer2.clear()")
my_instr.write("smu.nvbuffer2.appendmode = 1")

my_instr.write("smu.source.func = smu.OUTPUT_DCVOLTS")
my_instr.write("smu.source.rangev = 5")
my_instr.write("smu.source.limiti = 0.01")

my_instr.write("smu.trigger.source.action = smu.ENABLE")
my_instr.write("smu.trigger.source.listv({0,5})")
my_instr.write("smu.trigger.source.limiti = 0.01")
my_instr.write("smu.trigger.measure.action = smu.ENABLE")
my_instr.write("smu.trigger.measure.iv(smu.nvbuffer1, smu.nvbuffer2)")
my_instr.write("smu.trigger.endpulse.action = smu.SOURCE_HOLD")
my_instr.write("smu.trigger.endsweep.action = smu.SOURCE_IDLE")
my_instr.write("smu.trigger.count = 7")
my_instr.write("smu.trigger.arm.stimulus = trigger.EVENT_ID") # wait for the *TRG command
my_instr.write("smu.trigger.source.stimulus = 0")
my_instr.write("smu.trigger.measure.stimulus = 0")
my_instr.write("smu.trigger.endpulse.stimulus = 0")

my_instr.write("smu.source.output = smu.OUTPUT_ON")
my_instr.write("smu.trigger.initiate()")

#after some delay the *TRG is sent
time.sleep(3)
my_instr.write("*TRG")