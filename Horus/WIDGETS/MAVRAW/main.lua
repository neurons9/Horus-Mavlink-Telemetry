--    Copyright by Jochen Anglett
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    A copy of the GNU General Public License is available at <http://www.gnu.org/licenses/>.
--
--    Mavlink Messages are based on the work from kam
--    https://github.com/xkam1x/TelemetryPro
--
--    after long research i found this secrets about getting the passthrough bytes correct:
--    http://www.craftandtheoryllc.com/forums/topic/a-diy-script-to-rediscover-more-telem-sensors-with-or-without-flightdeck/
--
--    the rest is documented here:
--    https://cdn.rawgit.com/ArduPilot/ardupilot_wiki/33cd0c2c/images/FrSky_Passthrough_protocol.xlsx


local options = {
    { "Color", COLOR, WHITE }
}

-- This function is runned once at the creation of the widget
function create(zone, options)
    local values = {svr=0,msg=0,yaw=0,pit=0,rol=0,mod=0,arm=0,sat=0,alt=0,msl=0,spd=0,dst=0,vol=0,cur=0,drw=0,cap=0,lat=0,lon=0,hdp=0,vdp=0,sat=0,fix=0,mav=0}
    local context = { zone=zone, options=options, values=values }

    return context
end

local function update(context, newOptions)
    context.options = newOptions
end


local mavType = {}
mavType[0] = "Generic"
mavType[1] = "Fixed wing aircraft"
mavType[2] = "Quadrotor"
mavType[3] = "Coaxial Helicopter"
mavType[4] = "Helicopter"
mavType[5] = "Antenna Tracker"
mavType[6] = "Ground Station"
mavType[7] = "Airship"
mavType[8] = "Free Balloon"
mavType[9] = "Rocket"
mavType[10] = "Ground Rover"
mavType[11] = "Boat"
mavType[12] = "Submarine"
mavType[13] = "Hexarotor"
mavType[14] = "Octorotor"
mavType[15] = "Tricopter"
mavType[16] = "Flapping Wing"
mavType[17] = "Kite"
mavType[18] = "Companion Computer"
mavType[19] = "Two-rotor VTOL"
mavType[20] = "Quad-rotor VTOL"
mavType[21] = "Tiltrotor VTOL"
mavType[22] = "VTOL"
mavType[23] = "VTOL"
mavType[24] = "VTOL"
mavType[25] = "VTOL"
mavType[26] = "Gimbal"
mavType[27] = "ADSB peripheral"
mavType[28] = "Steerable airfoil"

local flightMode = {}
flightMode[0] = ""
flightMode[1] = "Stabilize"
flightMode[2] = "Acro"
flightMode[3] = "Alt Hold"
flightMode[4] = "Auto"
flightMode[5] = "Guided"
flightMode[6] = "Loiter"
flightMode[7] = "RTL"
flightMode[8] = "Circle"
flightMode[10] = "Land"
flightMode[12] = "Drift"
flightMode[14] = "Sport"
flightMode[15] = "Flip"
flightMode[16] = "Auto-Tune"
flightMode[17] = "Pos Hold"
flightMode[18] = "Brake"
flightMode[19] = "Throw"
flightMode[20] = "ADSB"
flightMode[21] = "Guided No GPS"

local armed = {}
armed[0] = "disarmed"
armed[1] = "armed"

local fixetype = {}
fixetype[0] = "No GPS"
fixetype[1] = "No Fix"
fixetype[2] = "GPS 2D Fix"
fixetype[3] = "GPS 3D Fix"

local messages = {}
for i = 1, 7 do
    messages[i] = nil
end

local currentMessageChunks = {}
for i = 1, 36 do
    currentMessageChunks[i] = nil
end

local currentMessageChunkPointer = 0
local messageSeverity = -1
local messageLatest = 0
local messagesAvailable = 0
local messageLastChunk = 0

-- Function to convert the bytes into a string
local function bytesToString(bytesArray)
    local tempString = ""
    for i = 1, 36 do
        if bytesArray[i] == '\0' or bytesArray[i] == nil then
            return tempString
        end
        if bytesArray[i] >= 0x20 and bytesArray[i] <= 0x7f then
            tempString = tempString .. string.char(bytesArray[i])
        end
    end
    return tempString
end

-- Function to get and store the messages from Ardupilot
local function getMessages(value)
    if (value ~= nil) and (value ~= 0) and (value ~= messageLastChunk) then
        currentMessageChunks[currentMessageChunkPointer + 1] = bit32.band(bit32.rshift(value, 24), 0x7f)
        currentMessageChunks[currentMessageChunkPointer + 2] = bit32.band(bit32.rshift(value, 16), 0x7f)
        currentMessageChunks[currentMessageChunkPointer + 3] = bit32.band(bit32.rshift(value, 8), 0x7f)
        currentMessageChunks[currentMessageChunkPointer + 4] = bit32.band(value, 0x7f)
        currentMessageChunkPointer = currentMessageChunkPointer + 4
        if (currentMessageChunkPointer > 35) or (currentMessageChunks[currentMessageChunkPointer] == '\0') then
            currentMessageChunkPointer = -1
        end
        if bit32.band(value, 0x80) == 0x80 then
            messageSeverity = messageSeverity + 1
            currentMessageChunkPointer = -1
        end
        if bit32.band(value, 0x8000) == 0x8000 then
            messageSeverity = messageSeverity + 2
            currentMessageChunkPointer = -1
        end
        if bit32.band(value, 0x800000) == 0x800000 then
            messageSeverity = messageSeverity + 4
            currentMessageChunkPointer = -1
          end
        if currentMessageChunkPointer == -1 then
            currentMessageChunkPointer = 0
            if messageLatest == 7 then
                messageLatest = 1
            else
                messageLatest = messageLatest + 1
            end
            messages[messageLatest] = bytesToString(currentMessageChunks)
            messagesAvailable = messagesAvailable + 1
            messageSeverity = messageSeverity + 1
            for i = 1, 36 do
                currentMessageChunks[i] = nil
            end
        end
        messageLastChunk = value
    end
end

local function drawTxt(context)
    lcd.setColor(CUSTOM_COLOR, context.options.Color)
    local FLAGS = SMLSIZE + LEFT + CUSTOM_COLOR

    lcd.drawText(10,50,"FrSky Mavlink Passthrough", 0 + LEFT + CUSTOM_COLOR)
    lcd.drawLine(10, 70, 470, 70, DOTTED, CUSTOM_COLOR)

    lcd.drawText(  10,80, "Msg ASCII:",      FLAGS)
    lcd.drawText(  10,95, "Msg Raw:",        FLAGS)
    lcd.drawText(  10,110,"Mode:",           FLAGS)
    lcd.drawText(  10,125,"Arm:",            FLAGS)

    lcd.drawText(  10,150,"Volt:",            FLAGS)
    lcd.drawText(  10,165,"Currrent:",       FLAGS)
    lcd.drawText(  10,180,"Cur. draw:",      FLAGS)
    lcd.drawText(  10,195,"Capacity:",       FLAGS)

    lcd.drawText(  10,220,"Yaw:",             FLAGS)
    lcd.drawText(  10,235,"Pitch:",          FLAGS)
    lcd.drawText(  10,250,"Roll:",           FLAGS)

    if messages[messageLatest] then
        lcd.drawText(120,80, messages[messageLatest], FLAGS)
    end

    lcd.drawNumber(120,95, context.values.msg, FLAGS)

    lcd.drawText(120,110,flightMode[context.values.mod],FLAGS)
    lcd.drawText(120,125,armed[context.values.arm],      FLAGS)

    lcd.drawText(120,150,context.values.vol .. "V",      FLAGS)
    lcd.drawText(120,165,context.values.cur .. "A",      FLAGS)
    lcd.drawText(120,180,context.values.drw .. "mAh",      FLAGS)
    lcd.drawText(120,195,context.values.cap .. "mAh",      FLAGS)

    lcd.drawText(120,220,context.values.yaw .. " dg",  FLAGS)
    lcd.drawText(120,235,context.values.pit .. " dg",  FLAGS)
    lcd.drawText(120,250,context.values.rol .. " dg",  FLAGS)

    -- second column
    lcd.drawText(  240,95,"Mav Type:",   FLAGS)

    lcd.drawText(  240,120,"Alt:",       FLAGS)
    lcd.drawText(  240,135,"Speed:",     FLAGS)
    lcd.drawText(  240,150,"Distance:",  FLAGS)

    lcd.drawText(  240,175,"Lat:",        FLAGS)
    lcd.drawText(  240,190,"Lon:",        FLAGS)
    -- lcd.drawText(  240,205,"Hdop:",        FLAGS)
    -- lcd.drawText(  240,220,"Vdop:",        FLAGS)
    lcd.drawText(  240,205,"Hdop:",        FLAGS)
    lcd.drawText(  240,220,"Sat count:", FLAGS)
    lcd.drawText(  240,235,"Fix Type:",  FLAGS)

    lcd.drawText(350,95,mavType[context.values.mav],     FLAGS)

    -- lcd.drawText(350,120,context.values.alt .. "m " .. " MSL: " .. context.values.msl .. "m",        FLAGS)
    lcd.drawText(350,120,context.values.alt .. "m ",    FLAGS)
    lcd.drawText(350,135,context.values.spd .. "m/s",   FLAGS)
    lcd.drawText(350,150,context.values.dst .. "m",     FLAGS)

    lcd.drawText(350,175,context.values.lat,             FLAGS)
    lcd.drawText(350,190,context.values.lon,              FLAGS)
    lcd.drawText(350,205,context.values.hdp .. "m",       FLAGS)
    --lcd.drawText(350,220,context.values.vdp .. "m",       FLAGS)
    lcd.drawText(350,220,context.values.sat,               FLAGS)
    --lcd.drawText(350,250,fixetype[context.values.fix],  FLAGS)
    lcd.drawText(350,235,fixetype[context.values.fix],  FLAGS)

end

function refresh(context)
    local iterator=0
    local i0,i1,i2,v = sportTelemetryPop()
    lcd.setColor(CUSTOM_COLOR, context.options.Color)
    local FLAGS = SMLSIZE + LEFT + CUSTOM_COLOR
    if i0 then lcd.drawNumber(280,50,i0, FLAGS) end
    if i1 then lcd.drawNumber(320,50,i1, FLAGS) end
    if i2 then lcd.drawNumber(360,50,i2, FLAGS) end
    lcd.drawNumber(420,50,iterator, FLAGS)

    -- GPS ID is outside passthrough
    gpsLatLon = getValue("GPS")
    if (type(gpsLatLon) == "table") then
        context.values.lat = gpsLatLon["lat"]
        context.values.lon = gpsLatLon["lon"]
    end

    -- unpack 5000 packet
    if i2 == 20480 then
        context.values.svr = bit32.extract(v,0,3)
        context.values.msg = bit32.extract(v,0,32)
        getMessages(context.values.msg)
    end

    -- unpack 5001 packet
    if i2 == 20481 then
        context.values.mod = bit32.extract(v,0,5)
        context.values.arm = bit32.extract(v,8,1)
    end

    -- unpack 5002 packet
    if i2 == 20482 then
        context.values.sat = bit32.extract(v, 0, 4)
        context.values.fix = bit32.extract(v, 4, 2)

        -- Extract the HDOP
        if bit32.extract(v, 6, 1) > 0 then
            context.values.hdp = bit32.extract(v, 7, 7)
        else
            context.values.hdp = bit32.extract(v, 7, 7) / 10
        end

        -- Always 0
        -- Extract VDOP
        -- if bit32.extract(v, 14, 1) > 0 then
        --     context.values.vdp = bit32.extract(v, 15, 7)
        -- else
        --     context.values.vdp = bit32.extract(v, 15, 7) / 10
        -- end

        -- Varies way too much to be useful
        -- Extract MSL
        -- context.values.msl = bit32.extract(v, 24, 6) / 100
        -- for variable = 0, bit32.extract(v, 22, 2), 1 do
        --     context.values.msl = context.values.msl * 10
        -- end

        if context.values.fix > 3 then context.values.fix = 3 end
    end

    -- unpack 5003 packet
    if i2 == 20483 then

        -- Extract voltage
        context.values.vol = bit32.extract(v, 0, 9) / 10

        -- Extract current
        if bit32.extract(v, 10, 7) > 0 then
            context.values.cur = bit32.extract(v, 10, 7)
        else
            context.values.cur = bit32.extract(v, 10, 7) / 10
        end

        -- Extract consumed capacity
        context.values.drw = bit32.extract(v,17,15)
    end

    -- unpack 5004 packet
    if i2 == 20484 then

        -- extract home distance
        context.values.dst = bit32.extract(v, 2, 10) / 10
        for variable = 0, bit32.extract(v, 0, 2), 1 do
            context.values.dst = context.values.dst * 10
        end

        -- extract relative altitude
        context.values.alt = bit32.extract(v, 14, 10) / 100
        for variable = 0, bit32.extract(v, 12, 2), 1 do
            context.values.alt = context.values.alt * 10
        end
    end

    -- unpack 5005 packet
    if i2 == 20485 then

        -- extract speed
        if bit32.extract(v, 9, 1) then
            context.values.spd = bit32.extract(v, 10, 7) / 10
        else
            context.values.spd = bit32.extract(v, 10, 7) / 100
        end

        -- value submitted in centidegress to .2 degree increments
        -- [0;1800] is mapped to [0;360]
        context.values.yaw = bit32.extract(v,17,11) * 0.2
    end

    -- unpack 5006 packet
    if i2 == 20486 then
        context.values.rol = (bit32.extract(v,0,11) -900) * 0.2
        context.values.pit = (bit32.extract(v,11,10 ) -450) * 0.2
    end

    -- unpack 5007 packet
    if i2 == 20487 then
        --iterator = bit32.extract(v,0,8)
        iterator = bit32.band(bit32.rshift(v, 24), 0xff)
        if iterator == 0x1 then context.values.mav = bit32.band(v, 0xffffff) end
        if iterator == 0x4 then context.values.cap = bit32.band(v, 0xffffff) end
    end

    drawTxt(context)
end

return { name="MAV-RAW", options=options, create=create, update=update, refresh=refresh }
