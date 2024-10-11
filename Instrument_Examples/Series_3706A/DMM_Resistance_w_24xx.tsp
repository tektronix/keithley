--[[

Configures a 3706A with a 3760 in slot 1 and a 3723 in slot 2
A 24xx graphical SMU sources current into the Output channel of the 3760 card that is routed to channels 3-5 of the 3760 card
Channels 1-3 of the 3723 measure voltage
Channel pairings are 3760:3723 - 5:1, 4:2, 3:3
3 resistors are connected, one for each channel pairing, to create a 4-wire/Kelvin measurement system. 
A scan of all resistors is executed to measure resistance. 
Average resistance of each channel is calculated and displayed on the 24xx screen.
The measurements repeat when OK is pressed on the 24xx screen. 
This setup is appropriate for measuring very low resistances, as the 24xx can use a higher test current than the 3706A

This script was written to demonstrate battery weld resistance measurements at The Battery Show 2024. 

]]

-- Helper Functions --

-- List all the cards in the 3706A
function list_cards()
    for x=1,6 do 
        print(slot[x].idn)
    end
end

-- List all closed channels
function closed_ch()
    print(channel.getclose("allslots"))
end

--Print a buffer
function printbuff(bufferVar)
    printbuffer(1, bufferVar.n, bufferVar)
end

-- Program Functions --

-- Takes a resistor number and averages all readings of that resistor from a buffer that has been used in a scan
function avg_v(rnum, bufferVar)
    local sum = 0
    local count = 1
    for i = rnum, bufferVar.n, 3 do
        sum = sum + bufferVar[i]
        count = count+1
    end
    return sum / count
end

-- Displays values r1-r3 on the connected 24xx SMU, also calls for another scan when OK is pressed. 
function Report(r1, r2, r3)
    node[2].display.prompt(
        node[2].display.BUTTONS_OK,
        "Average Resistances are:\nWeld 1 ="..string.format("%.3f",r1).." Ohms\nWeld 2 = "..string.format("%.3f",r2).." Ohms\nWeld 3 = "..string.format("%.3f",r3).." Ohms"
    )
    node[2].display.waitevent()
    Scan_Start()
end

-- Executes the configured scan and calculates average resistances. 
function Scan_Start()   
    smu.source.output = 1
    scan.execute(rb)
    smu.source.output = 0

    r1 = avg_v(1, rb)/srclvl
    r2 = avg_v(2, rb)/srclvl
    r3 = avg_v(3, rb)/srclvl

    channel.open("allslots")
    Report(r1, r2, r3)
end

-- Creates a scan. 
function Scan_Create()
    scan.reset()
    -- DMM Configuration
    dmm.func = "dcvolts"
    dmm.autodelay = dmm.ON
    dmm.configure.set("mydcv")
    -- Always configure DMM settings before configuring the scan. 
    dmm.setconfig("slot2", "mydcv")

    -- Channel Configurations
    -- We set a pattern first for readability, but it's not strickly necessary
    channel.pattern.setimage("1005,2001,2911", "r1")
    channel.pattern.setimage("1004,2002,2911", "r2")
    channel.pattern.setimage("1003,2003,2911", "r3")

    -- Scan Configuration
    -- Here we use the .addimagestep command so multiple channels are closed in a single step.
    -- You must manually close the backplane channels (x9xx) when using .addimagestep that connect the internal DMM to a channel. 
    scan.addimagestep("r1", "mydcv")
    scan.addimagestep("r2", "mydcv")
    scan.addimagestep("r3", "mydcv")
    scan.scancount = scancnt
end

--------------------------------------------------------------------------------------------------

-- Main Program
-- TSP-Link Init
tsplink.reset()

-- Globals
srclvl = 0.5 -- this is the current the SMU will source, it is not measured but it could be. 
scancnt = 100 -- this is the number of scans that will be used, if you edit this you may also need to edit dmm.makebuffer()
smu = node[2].smu -- We alias node[2].smu as a helper

-- SMU Configuration
smu.source.func = smu.FUNC_DC_CURRENT
smu.source.level = srclvl
smu.source.vlimit.level = 18
smu.measure.func = smu.FUNC_DC_CURRENT

-- Buffer Configuration
rb = dmm.makebuffer(900)

Scan_Create()
Scan_Start()