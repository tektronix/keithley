--[[
***********************************************************
*** Copyright 2026 Tektronix, Inc.                      ***
*** See www.tek.com/sample-license for licensing terms. ***
***********************************************************

Purpose: The script demonstrates basic commands for interacting with a MP5000 mainframe over a remote connection. 

This script does not demonstrate every possible status command, refer to the Reference Mnaual for more. 

Particularly useful are the shell queries "remote?" and "login?" when sent over a connection to verify local/remote status or whether a user is logged in. 
These queries cannot be used in scripts. 

This script is designed around functions so that once running the script, the individual functions can be called again without running the whole script. 

Author: Brad O. 10/5/2026

TODO: Allow finding other MP5103 mainframes over TSP-Link and iterate over them. 

]]

-- Functions
-- This function is not called in this script, but is handy to have
function listScripts()
    for index, name in script.table() do
        print(tostring(index), name)
    end
end

function utcToReadable(utcseconds, utcfractionalseconds)
    local seconds = utcseconds + (utcfractionalseconds or 0)

    -- os.date() only accepts an integer timestamp, so handle
    -- the fractional portion separately.
    local wholeSeconds = math.floor(seconds)
    local fraction = seconds - wholeSeconds

    return os.date("!%Y-%m-%d %H:%M:%S", wholeSeconds)
        .. string.format(".%06d", math.floor(fraction * 1000000 + 0.5))
        .. " UTC"
end

function basicInfo()
    print("~ Basic Information ~")

    print("Manufacturer:    ", localnode.manufacturer)
    print("Model:           ", localnode.model)
    print("Serial Number:   ", localnode.serialno)
    print("FW Version:      ", localnode.revision)
    print("User Description:", localnode.description)
    print("Auto line freq?  ", localnode.autolinefreq)
    print("Line frequency:  ", tostring(localnode.linefreq))
    print("Autostart slots: ", slot.autostart)
    print("System time:     ", utcToReadable(os.time()))
    print("Timezone:        ", gettimezone())
    print("userstrings:     ", tostring(table.getn(userstring.table())))
    print("Saved Scripts:   ", tostring(table.getn(script.table())))
    print("Eventlog Events: ", tostring(eventlog.count))

    print("")

end

function slotInfo()
    print("~ Module Information ~")
    for Z = 1,3 do
        if slot[Z] then
            print("Slot ", tostring(Z))
            print("\tManufacturer:    ", slot[Z].manufacturer)
            print("\tModel:           ", slot[Z].model)
            print("\tSerial Number:   ", slot[Z].serialno)
            print("\tFW Version:      ", slot[Z].revision)
        else
            print("Slot ", tostring(Z), " is empty.")
        end
    end
    print("")
end

function lanInfo()
    print("~ LAN Settings ~")
    print("Status:             ", lan.enable)
    print("Config Method:      ", lan.config.method)
    print("IP Address:         ", lan.status.ipaddress)
    print("Gateway:            ", lan.status.gateway)
    print("Subnet Mask:        ", lan.status.subnetmask)
    print("Hostname:           ", lan.status.dns.name)
    print("LAN Link Monitoring:", lan.autoconnect)
    print("DNS Status:         ", lan.config.dns.dynamic)
    print("LAN Speed:          ", tostring(lan.status.speed))

    print("")

end

function securityInfo()
    print("~ Security Settings ~")

    print("DNS Verify:", lan.config.dns.verify)
    print("HiSLIP Status:", lan.hislip.access)
    print("Sockets Status:", lan.rawsocket.access)
    print("Telnet Status:", lan.telnet.access)
    print("Ping Response:", lan.ping.enable)
    print("mDNS Status:", lan.mdns.enable)
    print("Webpage Status:", lan.web.enable)

    print("USBTMC Status:", usbtmc.access)
    -- Options are ENABLE or PROTECT, usbtmc cannot be disabled. This controls whether a password is required when connecting over USB via the rear-panel USB port. 

    print("")

end

function tspInfo()
    print("~ TSP-Link Status ~")

    print("TSP-Link:", tsplink.state)
    print("TSP-Link Node:", tostring(tsplink.node))

    print("")
end

function allInfo()
    basicInfo()
    slotInfo()
    lanInfo()
    securityInfo()
    tspInfo()
end

-- Main Script
allInfo()