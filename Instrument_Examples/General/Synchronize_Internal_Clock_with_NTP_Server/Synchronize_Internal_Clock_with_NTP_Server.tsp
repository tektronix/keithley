-- Synchronize internal clock with an NTP server
function syncTime(utcOffset, observeDST, verbose)
-- TODO: Add ability to synchronize to the second, by waiting until the transition to the next second before setting time
      local defaultTimezone = -5 -- EST time zone offset
      local ntp_address = "128.138.141.172"
      local ntp_name = "time.nist.gov"
      local timePort = 13 -- day time protocol port

      if verbose == nil then
            verbose = false
      end

      -- Given a string and a pattern will return an array of strings
      local function stringSplit(str, inSplitPattern, outResults )
            if not outResults then
                  outResults = { }
            end
            local theStart = 1
            local theSplitStart, theSplitEnd = string.find( str, inSplitPattern, theStart )
            while theSplitStart do
                  table.insert( outResults, string.sub( str, theStart, theSplitStart-1 ) )
                  theStart = theSplitEnd + 1
                  theSplitStart, theSplitEnd = string.find( str, inSplitPattern, theStart )
            end
            table.insert( outResults, string.sub( str, theStart ) )
            return outResults
      end

      -- Split string from NTP and return date and time
      local function parseNTPTime(timeStr)
            local data = stringSplit(timeStr, " ")
            local date = stringSplit(data[2], "-")
            local time = stringSplit(data[3], ":")

            return date, time
      end

      -- Check to see if between March 8 and November 11
      local function isDaylightSavings(date, time)
            local formattedTime = os.time({year = tonumber("20"..date[1]), month = tonumber(date[2]), day = tonumber(date[3]), hour = tonumber(time[1]), min = tonumber(time[2]), sec = tonumber(time[3])})
            if (formattedTime >= os.time({year = tonumber("20"..date[1]), month = 3, day = 8, hour = 2}) and (formattedTime < os.time({year=tonumber("20"..date[1]), month = 11, day = 1, hour = 2}))) then
                  return true
            else
                  return false
            end
      end

      -- set to default if not defined
      if utcOffset == nil then
            utcOffset = defaultTimezone
      end
      if observeDST == nil then
            observeDST = true
      end

      -- Connect over LAN to the NTP server
      tspnet.reset()
      tspnet.timeout = 0.5
      local id = tspnet.connect(ntp_address, timePort, "") -- NTP server address
      if id == nil then
            print("Unable to connect to "..ntp_address.." ("..ntp_name.."), check network connection and try again...")
            exit()
      end

      local timeStr = tspnet.read(id, "%s")
      tspnet.disconnect(id) -- The NTP server will automatically disconnect so we also need to disconnect
      local date, time = parseNTPTime(timeStr)
      if observeDST and isDaylightSavings(date, time) then
            utcOffset = utcOffset + 1 -- add an hour ("spring" ahead)
      end

      -- Get the unit's current time
      if verbose then print("Before: "..os.date('%c', gettime())) end

      time[1] = tonumber(time[1]) -- capture hour
      date[3] = tonumber(date[3]) -- capture day
      local offsetRemainder = utcOffset
      if time[1] > offsetRemainder then -- negative offset
            offsetRemainder = offsetRemainder + time[1]
            if offsetRemainder < 0 then
                  time[1] = 24 + offsetRemainder
                  date[3] = date[3] - 1 -- Adjust day, because local time hasn't passed midnight
            else
                  time[1] = offsetRemainder
            end
      elseif time[1] < offsetRemainder then -- positive offset
            offsetRemainder = offsetRemainder - time[1]
            if offsetRemainder > 0 then
                  date[3] = date[3] + 1 -- Adjust day, because local time hasn't passed midnight
            end
            time[1] = offsetRemainder
      end

      -- Set the unit's clock
      localnode.settime(tonumber("20"..date[1]), tonumber(date[2]), date[3], time[1], tonumber(time[2]), tonumber(time[3]))

      if verbose then print("After: "..os.date('%c', gettime())) end
end
