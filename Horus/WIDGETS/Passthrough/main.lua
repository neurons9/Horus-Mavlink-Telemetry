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
	{ "COLOR", COLOR, WHITE }
}

-- This function is runned once at the creation of the widget
local function create(zone, options)
	local context  = { zone=zone, options=options, counter=0 }
		txtcolor      = context.options.COLOR
	return context
end

local function update(context, options)
	context.options = options
	txtcolor = context.options.COLOR
end

local svr,msg,yaw,pit,rol,mod,arm,sat,alt,msl,spd,dst,vol,cur,drw,cap,lat,lon,hdp,vdp,sat,fix,mav = 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

local iterator = 0

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

messages = {}
for i = 1, 7 do
	messages[i] = nil
end

currentMessageChunks = {}
for i = 1, 36 do
	currentMessageChunks[i] = nil
end

currentMessageChunkPointer = 0
messageSeverity = -1
messageLatest = 0
messagesAvailable = 0
messageLastChunk = 0

-- Function to convert the bytes into a string
local function bytesToString(bytesArray)
	tempString = ""
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

local function drawTxt()
	lcd.setColor(CUSTOM_COLOR, txtcolor)
	local FLAGS = SMLSIZE + LEFT + CUSTOM_COLOR
	
	lcd.drawText(10,50,"FrSky Mavlink Passthrough", 0 + LEFT + CUSTOM_COLOR)
	lcd.drawLine(10, 70, 470, 70, DOTTED, CUSTOM_COLOR)
	
	lcd.drawText(  10,80, "Msg ASCII:",      FLAGS)
	lcd.drawText(  10,95, "Msg Raw:",        FLAGS)
	lcd.drawText(  10,110,"Mode:",           FLAGS)
	lcd.drawText(  10,125,"Arm:",   	     FLAGS)
	
	lcd.drawText(  10,150,"Volt:",   	     FLAGS)
	lcd.drawText(  10,165,"Currrent:",       FLAGS)
	lcd.drawText(  10,180,"Cur. draw:",      FLAGS)
	lcd.drawText(  10,195,"Capacity:",       FLAGS)
	
	lcd.drawText(  10,220,"Yaw:",   	 	 FLAGS)
	lcd.drawText(  10,235,"Pitch:", 	     FLAGS)
	lcd.drawText(  10,250,"Roll:",  	     FLAGS)
		
	if messages[messageLatest] then
		lcd.drawText(120,80, messages[messageLatest], FLAGS)
	end
	
	lcd.drawNumber(120,95, msg, FLAGS)
	
	lcd.drawText(120,110,flightMode[mod],FLAGS)
	lcd.drawText(120,125,armed[arm], 	 FLAGS)
	
	lcd.drawText(120,150,vol .. "V", 	 FLAGS)
	lcd.drawText(120,165,cur .. "A", 	 FLAGS)
	lcd.drawText(120,180,drw .. "mAh", 	 FLAGS)
	lcd.drawText(120,195,cap .. "mAh", 	 FLAGS)		
	
	lcd.drawText(120,220,yaw .. " deg",  FLAGS)
	lcd.drawText(120,235,pit .. " deg",  FLAGS)
	lcd.drawText(120,250,rol .. " deg",  FLAGS)
	
	-- second column
	lcd.drawText(  240,95,"Mav Type:",   FLAGS)
	
	lcd.drawText(  240,120,"Alt:",       FLAGS)
	lcd.drawText(  240,135,"Speed:",     FLAGS)
	lcd.drawText(  240,150,"Distance:",  FLAGS)
	
	lcd.drawText(  240,175,"Lat:",   	 FLAGS)
	lcd.drawText(  240,190,"Lon:",   	 FLAGS)
	lcd.drawText(  240,205,"Hdop:",   	 FLAGS)
	lcd.drawText(  240,220,"Vdop:",   	 FLAGS)
	lcd.drawText(  240,235,"Sat count:", FLAGS)
	lcd.drawText(  240,250,"Fix Type:",  FLAGS)
	
	lcd.drawText(350,95,mavType[mav],	 FLAGS)
	
	lcd.drawText(350,120,alt .. "m " .. " MSL: " .. msl .. "m",   	 FLAGS)
	lcd.drawText(350,135,spd .. "km/h",  FLAGS)
	lcd.drawText(350,150,dst .. "m",     FLAGS)
	
	lcd.drawText(350,175,lat,        	 FLAGS)
	lcd.drawText(350,190,lon, 			 FLAGS)
	lcd.drawText(350,205,hdp .. "m",  	 FLAGS)
	lcd.drawText(350,220,vdp .. "m",  	 FLAGS)
	lcd.drawText(350,235,sat,  			 FLAGS)
	lcd.drawText(350,250,fixetype[fix],  FLAGS)
	
end

local function refresh()
	local i0,i1,i2,v = sportTelemetryPop()
	lcd.setColor(CUSTOM_COLOR, txtcolor)
	local FLAGS = SMLSIZE + LEFT + CUSTOM_COLOR
	if i0 then lcd.drawNumber(280,50,i0, FLAGS) end
	if i1 then lcd.drawNumber(320,50,i1, FLAGS) end
	if i2 then lcd.drawNumber(360,50,i2, FLAGS) end
	lcd.drawNumber(420,50,iterator, FLAGS)
	
	-- GPS ID is outside passthrough
	gpsLatLon = getValue("GPS")
	if (type(gpsLatLon) == "table") then
		lat = gpsLatLon["lat"]
		lon = gpsLatLon["lon"]
	end
	
	-- unpack 5000 packet
	if i2 == 20480 then
		svr = bit32.extract(v,0,3)
		msg = bit32.extract(v,0,32)
		getMessages(msg)
	end
	
	-- unpack 5001 packet
	if i2 == 20481 then
		mod = bit32.extract(v,0,5)
		arm = bit32.extract(v,8,1)
	end
	
	-- unpack 5002 packet
	if i2 == 20482 then
		sat = bit32.extract(v,0,4)
		fix = bit32.extract(v,4,2)
		hdp = bit32.extract(v,6,8)/10
		vdp = bit32.extract(v,14,8)/10
		msl = bit32.extract(v,22,9)
		if fix > 3 then fix = 3 end
	end
	
	-- unpack 5003 packet
	if i2 == 20483 then
		vol = bit32.extract(v,0,9)/10
		cur = bit32.extract(v,9,8)/10
		drw = bit32.extract(v,17,15)
	end
	
	-- unpack 5004 packet
	if i2 == 20484 then
		dst = bit32.extract(v,0,12)
		alt = bit32.extract(v,19,12)/10
	end
	
	-- unpack 5005 packet
	if i2 == 20485 then
		spd = bit32.extract(v,9,8) * 0.2
		yaw = bit32.extract(v,17,11) * 0.2
	end
	
	-- unpack 5006 packet
	if i2 == 20486 then
		rol = (bit32.extract(v,0,11) -900) * 0.2
		pit = (bit32.extract(v,11,10 ) -450) * 0.2
	end
	
	-- unpack 5007 packet
	if i2 == 20487 then
		--iterator = bit32.extract(v,0,8)
		iterator = bit32.band(bit32.rshift(v, 24), 0xff)
		if iterator == 0x1 then mav = bit32.band(v, 0xffffff) end
		if iterator == 0x4 then cap = bit32.band(v, 0xffffff) end
	end
	
	drawTxt()
end

return { name="TELEMETRY", options=options, create=create, update=update, refresh=refresh }