-- #############################################################################################
-- ##                                                                                         ##
-- ## Script by Jochen Anglett                                                                ##
-- ## V 1.0, 2017/12/15                                                                       ##
-- ##                                                                                         ##
-- ## This program is free software: you can redistribute it and/or modify                    ##
-- ## it under the terms of the GNU General Public License as published by                    ##
-- ## the Free Software Foundation, either version 3 of the License, or                       ##
-- ## (at your option) any later version.                                                     ##
-- ##                                                                                         ##
-- ## This program is distributed in the hope that it will be useful,                         ##
-- ## but WITHOUT ANY WARRANTY; without even the implied warranty of                          ##
-- ## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                           ##
-- ## GNU General Public License for more details.                                            ##
-- ##                                                                                         ##
-- ## A copy of the GNU General Public License is available at <http://www.gnu.org/licenses/> ##
-- ##                                                                                         ##
-- ## HUD is based on Marco Ricci openxsensor hud                                             ##
-- ## Dynamic widgets is based on johfla                                                      ##                                   
-- ## Some widgets are based on work by Ollicious                                             ##                                            
-- ##                                                                                         ##
-- #############################################################################################


local imagePath = "/WIDGETS/UNI/images/" 	-- path of widget/images on SD-Card

-- colors
local col_std = BLUE			-- standard value color: `WHITE`,`GREY`,`LIGHTGREY`,`DARKGREY`,`BLACK`,`YELLOW`,`BLUE`,`RED`,`DARKRED`
local col_min = GREEN			-- standard min value color
local col_max = YELLOW			-- standard max value color
local col_alm = RED				-- standard alarm value color
local col_lab = LIGHTGREY		-- standard label value color
local col_uni = LIGHTGREY		-- standard type value color
local col_lin = GREY	    	-- standard line value color

-- Params for font size and offsets
local modeSize = {sml = SMLSIZE, mid = MIDSIZE, dbl = DBLSIZE, smlH = 12, midH = 18, dbl = 24}
local modeAlign = {ri = RIGHT, le = LEFT}

local offsetValue = {x = 0.75, x2 = 0.65, y = 30, y2 = 25}
local offsetUnit  = {x = 0, y = 16} -- y offset from bottom of box
local offsetLabel = {x = 4, y = 2}  -- y offset from top of box
local offsetMax   = {x = 4, y = 2}  -- y offset from top of box
local offsetPic   = {x = 2, y = 30} -- y offset from top of box (only battery icon for now)

-- frsky passthrough vars
local svr,msg = 0,0
local iterator = 0

-- Mavlink strings
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
flightMode[0] = "offline"
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
armed[0] = "DISARMED"
armed[1] = "ARMED"

local fixetype = {}
fixetype[0] = "No GPS"
fixetype[1] = "No Fix"
fixetype[2] = "GPS Fix"
fixetype[3] = "DGPS"

-- Mavlink messages
messages = {}
for i = 1, 12 do
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

-- artificial horizon
local cosRoll, sinRoll, mapRatio
local X1, Y1, X2, Y2, XH, YH
local delta


local options = {
	{ "Capacity", VALUE, 1000, 500, 2400 },	-- lipo capacity
	{ "Cells", VALUE, 3, 2, 6 },			-- lipo cells
	{ "Arm", SOURCE, 1},		            -- arming switch (BF only)
	{ "Mode", SOURCE, 1},			        -- bf: switch for flightmodes / AP: switch for toggle screens
	{ "Setting", VALUE, 1, 1, 4 },	        -- widget templates bf: 1-3 / AP 4
}

function create(zone, options)
	local context  = { zone=zone, options=options }
		lipoCapa      = context.options.Capacity
		lipoCells     = context.options.Cells
		armSwitch     = context.options.Arm
		modeSwitch    = context.options.Mode
		setting       = context.options.Setting
		if setting <= 3 then
			autopilot = "BF"
		else
			autopilot = "AP"
		end
		widget()
	return context
end

function update(context, options)
	context.options = options
	lipoCapa      = context.options.Capacity
	lipoCells     = context.options.Cells
	armSwitch     = context.options.Arm
	modeSwitch    = context.options.Mode
	setting       = context.options.Setting
	if setting <= 3 then
		autopilot = "BF"
	else
		autopilot = "AP"
	end
	context.back = nil
	widget()
end

-- #################### Definition of Widgets #################

function widget()
	local switchPos = getValue(modeSwitch)
	-- standard sensors: battery heading vfas curr alt speed vspeed rssi rxbat timer 
	-- betaflight BF:    armed fm 
	-- Ardupilot  AP:    armed fm battery msg gps alt_ap msl_ap volt_ap curr_ap drawn_ap dist_ap speed_ap mavtype pitch roll yaw hud
	-- if on widget needs more space you can add "0" in the row after (max. 2 times). "1" for empty space
	-- {{column1-row1,column1-row2,column1-row3},{column2-row1,column2-row2,column2-row3},{etc}}
	
	if     setting == 1 then
		widgetDefinition = {{"armed", "fm", "timer"},{"battery", 0, "heading"},{"vfas", "rxbat", "rssi"}}
	elseif setting == 2 then
		widgetDefinition = {{"armed", "fm", "heading"},{"battery"},{"vfas", "rssi", "rxbat", "timer"}}
	elseif setting == 3 then
		widgetDefinition = {{"armed", "fm", "heading"},{"battery"},{"vfas", "rssi", "rxbat", "timer"}}
	elseif setting == 4 and switchPos < 0 then
		widgetDefinition = {{"armed", "fm", "mavtype", "timer"},{"battery", 0, 0, "rxbat"},{"volt_ap", "curr_ap", "drawn_ap", "rssi"},{"gps", "alt_ap", "speed_ap", "dist_ap"}}
	elseif setting == 4 and switchPos == 0 then
		widgetDefinition = {{"msg"}}
	elseif setting == 4 and switchPos > 0 then
		widgetDefinition = {{"hud"},{"roll", "pitch", "yaw", 1},{"gps", "alt_ap", "speed_ap", "dist_ap"}}
	else
		widgetDefinition = {}
	end
end


---------------------------------------------
-- get value --------------------------------
---------------------------------------------
local function getValueOrDefault(value)
	local tmp = getValue(value)
	
	if tmp == nil then
		return 0
	end
	
	return tmp
end

---------------------------------------------
-- get value rounded ------------------------
---------------------------------------------
local function round(num, decimal)
    local mult = 10^(decimal or 0)
    return math.floor(num * mult + 0.5) / mult
end

---------------------------------------------
-- convert bytes into a string --------------
---------------------------------------------
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

---------------------------------------------
-- get and store messages from mavlink ------
--------------------------------------------- 
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
			if messageLatest == 12 then
				for i = 1, 11 do
					messages[i] = messages[i+1]
				end
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

---------------------------------------------
-- get and store SPort Passthrough MSG ------
--------------------------------------------- 
local function getSPort()
	local i0,i1,i2,v = sportTelemetryPop()
	
	-- unpack 5000 packet
	if i2 == 20480 then
		svr = bit32.extract(v,0,3)
		msg = bit32.extract(v,0,32)
		getMessages(msg)
	end

end


-- ############################# Widgets #################################

------------------------------------------------- 
-- Dynamic widget images ------------------------
-------------------------------------------------

local function dynamicWidgetImg(xCoord, yCoord, cellHeight, name, myImgValue, img)
	
	-- static image if img not 1
	if img ~= 1 then
		image = Bitmap.open(imagePath..img)
	end
	
	-- dynamic image for gps
	if name == "gps" then
		if myImgValue < 3 then
			image = Bitmap.open(imagePath.."satoff.png")
		else
			image = Bitmap.open(imagePath.."saton.png")
		end
	end
	
	-- dynamic image for rssi
	if name == "rssi" then
		percent = ((math.log(myImgValue-28, 10)-1)/(math.log(72, 10)-1))*100
		if myImgValue <=37 then rssiIndex = 1
		elseif
			myImgValue > 99 then rssiIndex = 11
		else
			rssiIndex = math.floor(percent/10)+2
		end
		image = Bitmap.open(imagePath.."rssi"..rssiIndex..".png")
	end
	
	-- dynamic image for heading
	if name == "heading" then
		hdgIndex = math.floor (myImgValue/15+0.5) --+1
		if hdgIndex > 23 then hdgIndex = 23 end		-- ab 352 Grad auf Index 23
		image = Bitmap.open(imagePath.."pfeil"..hdgIndex..".png")
	end
	
	-- dynamic image for flightmode
	if name == "fm" then
		if myImgValue == 0 then
			image = Bitmap.open(imagePath.."sleep.png")
		elseif mod == 4 or mod == 5 or mod == 6 or mod == 7 or mod == 10 or mod == 17 then
			image = Bitmap.open(imagePath.."auto.png")
		else
			image = Bitmap.open(imagePath.."human.png")
		end
	end
	
	-- dynamic image for arm
	if name == "armed" then
		if myImgValue == 0 then
			image = Bitmap.open(imagePath.."disarmed.png")
		else
			image = Bitmap.open(imagePath.."armed.png")
		end
	end
	
	w, h = Bitmap.getSize(image)
	xPic = xCoord+offsetLabel.x; yPic = yCoord  + (cellHeight) - h - 3
	lcd.drawBitmap(image, xPic, yPic)
	
end

------------------------------------------------- 
-- Standard Widget	-----------------------------
------------------------------------------------- 
local function stdWidget(xCoord, yCoord, cellHeight, name, sensor, label, unit, digits, minmax, img)
	local myValue
	local myMinMaxValue
	
	xTxt1 = xCoord + cellWidth   * offsetValue.x2
	yTxt1 = yCoord + cellHeight - offsetValue.y
	yTxt2 = yCoord + cellHeight - offsetUnit.y
    
    if sensor ~= nil then
		if type(sensor) == number then
        	myValue = sensor
    	else 
    		myValue = round(getValueOrDefault(sensor),digits)
    	end
		lcd.setColor(CUSTOM_COLOR, col_std)
		lcd.drawText(xTxt1, yTxt1, myValue, modeSize.mid + modeAlign.ri + CUSTOM_COLOR)
	end
	
    if minmax ~= nil then
    	if type( minmax ) == number then
			myMinMaxValue = minmax
		else
			myMinMaxValue = round(getValueOrDefault(minmax),digits)
		end
		lcd.setColor(CUSTOM_COLOR, col_max)
		lcd.drawText(xCoord + cellWidth - offsetMax.x, yCoord + offsetMax.y, myMinMaxValue, modeSize.sml + modeAlign.ri + CUSTOM_COLOR)
	end
	
	if unit ~= nil then
		lcd.setColor(CUSTOM_COLOR, col_uni)
		lcd.drawText(xTxt1, yTxt2, unit, modeSize.sml + modeAlign.le + CUSTOM_COLOR)
	end
	
	if label ~= nil then
		lcd.setColor(CUSTOM_COLOR, col_lab)
		lcd.drawText(xCoord + offsetLabel.x, yCoord + offsetLabel.y, label, modeSize.sml + CUSTOM_COLOR)
	end
	
	if img ~= nil then
		dynamicWidgetImg(xCoord, yCoord, cellHeight, name, myValue, img)
	end
end

------------------------------------------------- 
-- GPS Widget -----------------------------------
------------------------------------------------- 
local function gpsWidget(xCoord, yCoord, cellHeight, name, img)
	local myValue
	local myMinMaxValue
	local myLabel
	
	xTxt1 = xCoord + cellWidth   * offsetValue.x2
	yTxt1 = yCoord + cellHeight - offsetValue.y
	yTxt2 = yCoord + cellHeight - offsetUnit.y
    
    myValue = getValueOrDefault("HDP")
    myMinMaxValue = getValueOrDefault("SAT")
    myImgValue = getValueOrDefault("FIX")
    myLabel = fixetype[myImgValue]
    
	lcd.setColor(CUSTOM_COLOR, col_std)
	lcd.drawText(xTxt1, yTxt1, myValue, modeSize.mid + modeAlign.ri + CUSTOM_COLOR)
	
	lcd.setColor(CUSTOM_COLOR, col_max)
	lcd.drawText(xCoord + cellWidth - offsetMax.x, yCoord + offsetMax.y, myMinMaxValue, modeSize.sml + modeAlign.ri + CUSTOM_COLOR)
	
	lcd.setColor(CUSTOM_COLOR, col_uni)
	lcd.drawText(xTxt1, yTxt2, "m", modeSize.sml + modeAlign.le + CUSTOM_COLOR)
	
	lcd.setColor(CUSTOM_COLOR, col_lab)
	lcd.drawText(xCoord + offsetLabel.x, yCoord + offsetLabel.y, myLabel, modeSize.sml + CUSTOM_COLOR)
	
	if img ~= nil then
		dynamicWidgetImg(xCoord, yCoord, cellHeight, name, myImgValue, img)
	end
end

------------------------------------------------- 
-- Timer ------------------------------- timer --
------------------------------------------------- 
local function timerWidget(xCoord, yCoord, cellHeight, name)
	local teleV_tmp = model.getTimer(0) -- Timer 1
	local myTimer = teleV_tmp.value
	local minute = math.floor(myTimer/60)
	local sec = myTimer - (minute*60)
	
	if sec > 9 then
		valTxt = string.format("%i",minute)..":"..string.format("%i",sec)
	else
		valTxt = string.format("%i",minute)..":0"..string.format("%i",sec)
	end 
	
	xTxt1 = xCoord + cellWidth   * offsetValue.x2
	yTxt1 = yCoord + cellHeight - offsetValue.y
	yTxt2 = yCoord + cellHeight - offsetUnit.y
	
	lcd.setColor(CUSTOM_COLOR, col_std)
	lcd.drawText(xTxt1, yTxt1, valTxt, modeSize.mid + modeAlign.ri + CUSTOM_COLOR)
	lcd.setColor(CUSTOM_COLOR, col_uni)
	lcd.drawText(xTxt1, yTxt2, "m:s", modeSize.sml + modeAlign.le + CUSTOM_COLOR)
	lcd.setColor(CUSTOM_COLOR, col_lab)
	lcd.drawText(xCoord + offsetLabel.x, yCoord + offsetLabel.y, "Airborne", modeSize.sml + CUSTOM_COLOR)
end

------------------------------------------------- 
-- Mavlink Messages ---------------------- msg --
------------------------------------------------- 
local function msgWidget(xCoord, yCoord, cellHeight, name)
	
	xTxt1 = xCoord + offsetLabel.x
	yTxt1 = yCoord + modeSize.smlH*2
	
	lcd.setColor(CUSTOM_COLOR, col_lin)
	lcd.drawLine(xCoord, yCoord + modeSize.midH, xCoord + cellWidth, yCoord + modeSize.midH, DOTTED, CUSTOM_COLOR)
	
	lcd.setColor(CUSTOM_COLOR, col_std)
	
	for i = 1, 12 do
		if messages[i] ~= nil then
			lcd.drawText(xTxt1, yTxt1 + modeSize.smlH *i, messages[i], modeSize.sml + modeAlign.le + CUSTOM_COLOR)
		end
	end
	
	lcd.setColor(CUSTOM_COLOR, col_lab)
	lcd.drawText(xCoord + offsetLabel.x, yCoord + offsetLabel.y, "Mavlink MSG", modeSize.sml + CUSTOM_COLOR)
end


------------------------------------------------- 
-- Flightmode ----------------------------- fm --
------------------------------------------------- 
local function fmWidget(xCoord, yCoord, cellHeight, name, img)
	local myImgValue
	if autopilot == "BF" then
		local switchPos = getValueOrDefault(modeSwitch)
		if switchPos < 0 then
			valTxt = "HORIZON"
		elseif switchPos > 0 then
			valTxt = "ANTI GRAVITY" 
		else
			valTxt = "ANGLE"
		end
		myImgValue = nil
	elseif autopilot == "AP" then
		myImgValue = getValueOrDefault("MOD")
		valTxt = flightMode[myImgValue]
	end
	
	xTxt1 = xCoord + cellWidth
	yTxt1 = yCoord + cellHeight/2 - modeSize.smlH/2
	
	lcd.setColor(CUSTOM_COLOR, col_std)
	lcd.drawText(xTxt1, yTxt1, valTxt, modeSize.sml + modeAlign.ri + CUSTOM_COLOR)
	
	lcd.setColor(CUSTOM_COLOR, col_lab)			
	lcd.drawText(xCoord + offsetLabel.x, yCoord + offsetLabel.y, "Mode ["..autopilot.."]", modeSize.sml + CUSTOM_COLOR)
	
	if img ~= nil then
		dynamicWidgetImg(xCoord, yCoord, cellHeight, name, myImgValue, img)
	end
end

------------------------------------------------- 
-- Armed/Disarmed (Switch) ------------- armed --
------------------------------------------------- 
local function armedWidget(xCoord, yCoord, cellHeight, name, img)
	local myImgValue
	if autopilot == "BF" then
		local switchPos = getValueOrDefault(armSwitch)
		if switchPos < 0 then
			valTxt = "DISARMED"
			myImgValue = 0
			lcd.setColor(CUSTOM_COLOR, col_std)	
		else
			valTxt = "ARMED"
			myImgValue = 1
			lcd.setColor(CUSTOM_COLOR, col_alm)	
		end
	elseif autopilot == "AP" then
		myImgValue = getValueOrDefault("ARM")
		valTxt = armed[myImgValue]
		if myImgValue == 0 then
			lcd.setColor(CUSTOM_COLOR, col_std)	
		else
			lcd.setColor(CUSTOM_COLOR, col_alm)
		end
	end
	xTxt1 = xCoord + cellWidth
	yTxt1 = yCoord + cellHeight/2 - modeSize.smlH/2
		
	lcd.drawText(xTxt1, yTxt1, valTxt, modeSize.sml + modeAlign.ri + CUSTOM_COLOR)
	lcd.setColor(CUSTOM_COLOR, col_lab)
	lcd.drawText(xCoord + offsetLabel.x, yCoord + offsetLabel.y, "Motor", modeSize.sml + CUSTOM_COLOR)
	
	if img ~= nil then
		dynamicWidgetImg(xCoord, yCoord, cellHeight, name, myImgValue, img)
	end
end

------------------------------------------------- 
-- Mavtype --------------------------- mavtype --
------------------------------------------------- 
local function mavtypeWidget(xCoord, yCoord, cellHeight, name)
	xTxt1 = xCoord + cellWidth
	yTxt1 = yCoord + cellHeight/2 - modeSize.smlH/2
	
	lcd.setColor(CUSTOM_COLOR, col_std)
	lcd.drawText(xTxt1, yTxt1, mavType[getValueOrDefault("MAV")], modeSize.sml + modeAlign.ri + CUSTOM_COLOR)
	lcd.setColor(CUSTOM_COLOR, col_lab)
	lcd.drawText(xCoord + offsetLabel.x, yCoord + offsetLabel.y, "Vehicle", modeSize.sml + CUSTOM_COLOR) 
end


------------------------------------------------- 
-- Battery --------------------------- battery --
-------------------------------------------------
local function batteryWidget(xCoord, yCoord, cellHeight, name)

	local myVoltage
	local myPercent = 0
	local battCell  = lipoCells.."S"
	
	local _6SL = 21      -- 6 cells 6s | Warning
    local _6SH = 25.2    -- 6 cells 6s
	local _4SL = 13.4    -- 4 cells 4s | Warning
    local _4SH = 16.8    -- 4 cells 4s
    local _3SL = 10.4    -- 3 cells 3s | Warning
    local _3SH = 12.6    -- 3 cells 3s
    local _2SL = 7       -- 2 cells 2s | Warning
    local _2SH = 8.4     -- 2 cells 2s
    
	
	if autopilot == "BF" then
		myVoltage = getValueOrDefault("VFAS")
	elseif autopilot == "AP" then
		myVoltage = getValueOrDefault("VOL") 
	end
	
	
    if lipoCells == 6 then
		if myVoltage > 3 then
			myPercent = math.floor((myVoltage-_6SL) * (100/(_6SH - _6SL)))
		end
	end
	if lipoCells == 4 then
		if myVoltage > 3 then
			myPercent = math.floor((myVoltage-_4SL) * (100/(_4SH - _4SL)))
		end
	end
	if lipoCells == 3 then
		if myVoltage > 3 then
			myPercent = math.floor((myVoltage-_3SL) * (100/(_3SH - _3SL)))
		end
	end
	if lipoCells == 2 then
		if myVoltage > 3 then
			myPercent = math.floor((myVoltage-_2SL) * (100/(_2SH - _2SL)))
		end
	end
	
	lcd.setColor(CUSTOM_COLOR, col_lab)
	lcd.drawText(xCoord + offsetLabel.x, yCoord + offsetLabel.y, "["..battCell.."/"..lipoCapa.."mAh]", modeSize.sml + CUSTOM_COLOR)
		
	xTxt1 = xCoord + cellWidth   * offsetValue.x2
	yTxt1 = yCoord + cellHeight - offsetValue.y
	yTxt2 = yCoord + cellHeight - offsetUnit.y
		
	lcd.setColor(CUSTOM_COLOR, col_uni)
	lcd.drawText(xTxt1, yTxt2, "%", modeSize.sml + modeAlign.le + CUSTOM_COLOR)
	
	if myPercent > 100 then myPercent = 100 end
	if myPercent < 0   then myPercent = 0   end
	if myPercent < 30 and myPercent >= 20 then
		lcd.setColor(CUSTOM_COLOR, YELLOW)
	elseif myPercent < 20  then
		lcd.setColor(CUSTOM_COLOR, RED)
	else
		lcd.setColor(CUSTOM_COLOR, col_std)
	end
	
	
	lcd.drawText(xTxt1, yTxt1, myPercent, modeSize.mid + modeAlign.ri + CUSTOM_COLOR)
		
	
	-- icon Batterie -----
	if myPercent > 90 then batIndex = 9
		elseif myPercent > 80 then batIndex = 8
		elseif myPercent > 70 then batIndex = 7
		elseif myPercent > 60 then batIndex = 6
		elseif myPercent > 50 then batIndex = 5
		elseif myPercent > 40 then batIndex = 4
		elseif myPercent > 30 then batIndex = 3
		elseif myPercent > 20 then batIndex = 2
		elseif myPercent > 10 then batIndex = 1
		elseif myPercent < 10 then batIndex = "X"
	end
	
	if batName ~= imagePath.."B"..batIndex..".png" then
		batName = imagePath.."B"..batIndex..".png"
		batImage = Bitmap.open(batName)
	end
	
	w, h = Bitmap.getSize(batImage)
	xPic = xCoord + (cellWidth * 0.5) - (w * 0.5); yPic = yCoord + offsetPic.y
	lcd.drawBitmap(batImage, xPic, yPic)
end

------------------------------------------------- 
-- Battery --------------------------- battery --
-------------------------------------------------
local function drawHud(xCoord, yCoord, cellHeight, name)
 	
 	local rol = getValueOrDefault("ROL")
 	local pit = getValueOrDefault("PIT")
 	
	local size      = cellWidth/2
	local x_offset  = xCoord + (cellWidth-size)/2
	local y_offset  = yCoord + (cellWidth-size)/2
	
	local colAH = size/2+x_offset	-- H centerline
	local rowAH = size/2+y_offset	-- V centerline
	local radAH = size/2			-- half size of box

	local pitchR = 1	            -- Dist between pitch lines

	sinRoll = math.sin(math.rad(-rol))
	cosRoll = math.cos(math.rad(-rol))

	delta = pit % 15
	for i =  delta - 60 , 60 + delta, 15 do
		XH = pit == i % 360 and size or 10
		YH = pitchR * i							
    
		X1 = -XH * cosRoll - YH * sinRoll
    	Y1 = -XH * sinRoll + YH * cosRoll
    	X2 = (XH - 2) * cosRoll - YH * sinRoll
    	Y2 = (XH - 2) * sinRoll + YH * cosRoll
    	
    	if not (
         	   (X1 < -radAH and X2 < -radAH) 
      		or (X1 >  radAH and X2 >  radAH)
      		or (Y1 < -radAH and Y2 < -radAH)
      		or (Y1 >  radAH and Y2 >  radAH)
    	) then

      		mapRatio = (Y2 - Y1) / (X2 - X1)
      		if X1 < -radAH then  Y1 = (-radAH - X1) * mapRatio + Y1 X1 = -radAH end
      		if X2 < -radAH then  Y2 = (-radAH - X1) * mapRatio + Y1 X2 = -radAH end
      		if X1 >  radAH then  Y1 = ( radAH - X1) * mapRatio + Y1 X1 =  radAH end
      		if X2 >  radAH then  Y2 = ( radAH - X1) * mapRatio + Y1 X2 =  radAH end

      		mapRatio = 1 / mapRatio
      		if Y1 < -radAH then  X1 = (-radAH - Y1) * mapRatio + X1 Y1 = -radAH end
      		if Y2 < -radAH then  X2 = (-radAH - Y1) * mapRatio + X1 Y2 = -radAH end
      		if Y1 >  radAH then  X1 = ( radAH - Y1) * mapRatio + X1 Y1 =  radAH end
      		if Y2 >  radAH then  X2 = ( radAH - Y1) * mapRatio + X1 Y2 =  radAH end
	
	  		lcd.setColor(LINE_COLOR, RED)
      		lcd.drawLine(
        		colAH + (math.floor(X1 + 0.5)),
        		rowAH + (math.floor(Y1 + 0.5)),
        		colAH + (math.floor(X2 + 0.5)),
        		rowAH + (math.floor(Y2 + 0.5)),
        		SOLID, LINE_COLOR
      		)
		end
	end
	--lcd.setColor(CUSTOM_COLOR, col_lin)
	--lcd.drawRectangle(x_offset+size/2-size/2, y_offset+size/2-size/2, size, size, SOLID + LINE_COLOR )

	hudImage = Bitmap.open(imagePath.."hud.png")
	w, h = Bitmap.getSize(hudImage)
	xPic = xCoord + (cellWidth * 0.5) - (w * 0.5); yPic = yCoord + (cellWidth * 0.5) - (h * 0.5)
	lcd.drawBitmap(hudImage, xPic, yPic)
end

-- ############################# Call Widgets #################################
 
local function callWidget(name, xPos, yPos, height)
	if (xPos ~= nil and yPos ~= nil) then
		-- special widgets
		if (name == "msg") then
			msgWidget(xPos, yPos, height, name)
		elseif (name == "battery") then
			batteryWidget(xPos, yPos, height, name)
		elseif (name == "armed") then
			armedWidget(xPos, yPos, height, name, 1)
		elseif (name == "fm") then
			fmWidget(xPos, yPos, height, name, 1)
		elseif (name == "gps") then
			gpsWidget(xPos,  yPos,   height, name, 1)
		elseif (name == "timer") then
			timerWidget(xPos, yPos, height, name, "timer.png")
		elseif (name == "mavtype") then
			mavtypeWidget(xPos, yPos, height, name, nil)
		elseif (name == "hud") then
			drawHud(xPos, yPos, height, name, nil)

		
		-- stdWidget(x,      y,      height, name, sensor,      label,         unit, dig, minmax,     img)
				
		-- standard widgets called with sensors
		elseif (name == "vfas") then
			stdWidget(xPos,  yPos,   height, name, "VFAS",      "Volt",        "V",    2, "VFAS-",    nil)
		elseif (name == "curr") then
			stdWidget(xPos,  yPos,   height, name, "Curr",      "Curr",        "A",    2, "Curr+",    nil)
		elseif (name == "rxbat") then
			stdWidget(xPos,  yPos,   height, name, "RxBt",      "RxBt",        "V",    2, "RxBt-",    nil)
		elseif (name == "rssi")  then
			stdWidget(xPos,  yPos,   height, name, "RSSI",      "RSSI",        "db",   2, "RSSI-",    1)
		elseif (name == "speed") then
			stdWidget(xPos,  yPos,   height, name, "GSpd",      "H Speed",     "km/h", 2, "GSpd+",    nil)
		elseif (name == "vspeed") then
			stdWidget(xPos,  yPos,   height, name, "V-Speed",   "V Speed",     "m/s",  2, "V-Speed+", nil)
		elseif (name == "dist") then
			stdWidget(xPos,  yPos,   height, name, "Dist",      "Dist",        "m",    2, "Dist-",    nil)
		elseif (name == "alt") then
			stdWidget(xPos,  yPos,   height, name, "Alt",       "Alt",         "m",    2, "Alt+",     nil)
		elseif (name == "heading") then
			stdWidget(xPos,  yPos,   height, name, "Hdg",       "Heading",     "dg",   1, nil,        nil)
			
		-- standard widgets called with passthrough telemetry sensors
		elseif (name == "alt_ap") then
			stdWidget(xPos,  yPos,   height, name, "ALT",       "AGL",         "m",    2, nil,        nil)
		elseif (name == "speed_ap") then
			stdWidget(xPos,  yPos,   height, name, "SPD",       "Speed",       "km/h", 2, nil,        nil)
		elseif (name == "dist_ap") then
			stdWidget(xPos,  yPos,   height, name, "DST",       "Dist",        "m",    2, nil,        nil)
		elseif (name == "msl_ap") then
			stdWidget(xPos,  yPos,   height, name, "MSL",       "MSL",         "m",    2, nil,        nil)
		elseif (name == "volt_ap") then
			stdWidget(xPos,  yPos,   height, name, "VOL",       "Volt",        "V",    2, nil,        nil)
		elseif (name == "curr_ap") then
			stdWidget(xPos,  yPos,   height, name, "CUR",       "Curr",        "A",    2, nil,        nil)
		elseif (name == "drawn_ap") then
			stdWidget(xPos,  yPos,   height, name, "DRW",       "Used",        "mAh",  0, nil,        nil)
		elseif (name == "yaw") then
			stdWidget(xPos,  yPos,   height, name, "YAW",       "Yaw",         "dg",   1, nil,        nil)
		elseif (name == "pitch") then
			stdWidget(xPos,  yPos,   height, name, "PIT",       "Pitch",       "dg",   1, nil,        nil)
		elseif (name == "roll") then
			stdWidget(xPos,  yPos,   height, name, "ROL",       "Roll",        "dg",   1, nil,        nil)
				
		else
			return
		end
	end
end

-- ############################# Build Grid #################################

local function buildGrid(def, context)

	local sumX = context.zone.x
	local sumY = context.zone.y
	
	noCol = # def 	-- Anzahl Spalten berechnen
	cellWidth = math.floor((context.zone.w / noCol))
	
	-- widgets grid and lines
	for i=1, noCol, 1
	do
	
		local tempCellHeight = math.floor(context.zone.h / # def[i])
		for j=1, # def[i], 1
		do
			-- lines
			if (j ~= 1) and (def[i][j] ~= 0) then
				lcd.setColor(CUSTOM_COLOR, col_lin)
				lcd.drawLine(sumX+offsetLabel.x, sumY, sumX + cellWidth-offsetLabel.x, sumY, DOTTED, CUSTOM_COLOR)
			end
			
			-- widgets
			if def[i][j] ~= 0 then
				
				if (j+2 <= # def[i]) and (def[i][j+1] == 0) and (def[i][j+2] == 0) then
					callWidget(def[i][j], sumX , sumY , tempCellHeight*3)
					sumY = sumY + tempCellHeight*3
				elseif (j+1 <= # def[i]) and (def[i][j+1] == 0) and (def[i][j+2] ~= 0) then
					callWidget(def[i][j], sumX , sumY , tempCellHeight*2)
					sumY = sumY + tempCellHeight*2
				else
					callWidget(def[i][j], sumX , sumY , tempCellHeight)
					sumY = sumY + tempCellHeight
				end
				
			end
		end
		
		-- Werte zurücksetzen
		sumY = context.zone.y
		sumX = sumX + cellWidth
	end
end

local function refresh(context)
	-- awake passthrough if FC is AP
	if autopilot == "AP" then
		 getSPort()
	end
	-- define widgets
	widget()
	-- Build Grid --
	buildGrid(widgetDefinition, context)
end

return { name="Telemetry", options=options, create=create, update=update, refresh=refresh }