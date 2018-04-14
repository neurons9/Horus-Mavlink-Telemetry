-- Script by Jochen Anglett
-- V 1.0, 2017/12/15
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- A copy of the GNU General Public License is available at <http://www.gnu.org/licenses/>
--
-- HUD is based on Marco Ricci openxsensor hud
-- Dynamic widgets is based on johfla                                   
-- Some widgets are based on work by Ollicious                                   

-- colors
-- std = BLUE			-- standard value color: `WHITE`,`GREY`,`LIGHTGREY`,`DARKGREY`,`BLACK`,`YELLOW`,`BLUE`,`RED`,`DARKRED`
-- min = GREEN			-- standard min value color
-- max = YELLOW			-- standard max value color
-- alm = RED			-- standard alarm value color
-- lab = LIGHTGREY		-- standard label value color
-- uni = LIGHTGREY		-- standard type value color
-- lin = GREY	    	-- standard line value color


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
fixetype[2] = "GPS Fix 2D"
fixetype[3] = "DGPS"


local options = {
	{ "Cells", VALUE, 3, 2, 12 },			-- lipo cells
	{ "Mode", SOURCE, 1},			        -- switch for toggle screens
	{ "Template", VALUE, 1, 1, 3 },	        -- widget templates
}

local function create(zone, options)
	-- path of widget/images on SD-Card
	local imagePath = "/WIDGETS/MAVTEL/images/"
	-- colors
	local colors = {std = BLUE, min = GREEN, max = YELLOW, alm = RED, lab = LIGHTGREY, uni = LIGHTGREY, lin = GREY}
	-- Text formats
	local modeSize = {sml = SMLSIZE, mid = MIDSIZE, dbl = DBLSIZE, smlH = 12, midH = 18, dbl = 24}
	local modeAlign = {ri = RIGHT, le = LEFT}
		
	local offsetValue = {x = 0.68, y = 30} 			-- x in %
	local offsetUnit  = {x = 0, y = 16}    			-- y offset from bottom of box
	local offsetLabel = {x = 4, y = 3}     			-- y offset from top of box
	local offsetMax   = {x = 4, y = 2}     			-- y offset from top of box
	local offsetPic   = {x = 2, y = 3, batt = 30}  	-- y offset from bottom of box, battery icon from top

	local context  = { 
		zone			= zone, 
		options			= options,
		imagePath		= imagePath,
		colors			= colors,
		modeSize		= modeSize, 
		modeAlign		= modeAlign,
		offsetValue		= offsetValue, 
		offsetUnit		= offsetUnit, 
		offsetLabel		= offsetLabel, 
		offsetMax		= offsetMax, 
		offsetPic		= offsetPic
	}
	return context
end

local function update(context, newOptions)
	context.options = newOptions
end

-- #################### Definition of Widgets #################

local function widget(modeSwitch, template)
	local switchPos = getValue(modeSwitch)
	local widgetDefinition = {}
	-- standard sensors: battery heading vfas curr alt speed vspeed rssi rxbat timer 
	-- Ardupilot  AP:    armed fm battery gps ap_alt ap_msl ap_volt ap_curr ap_drawn ap_dist ap_speed mavtype ap_pitch ap_roll ap_yaw hud hud_hdg
	-- if one widget needs more space you can add "0" in the row after (max. 2 times). "1" for empty space
	-- {{column1-row1,column1-row2,column1-row3},{column2-row1,column2-row2,column2-row3},{etc}}
	
	-- 3 examples of widget definitions with 3 screens, you can even add more
	if     template == 1 and switchPos <  0 then
		widgetDefinition = {{"mavtype", "armed", "fm"},{"ap_batt", 0, "timer"},{"ap_volt", "ap_curr", "rssi"},}
	elseif template == 1 and switchPos == 0 then
		widgetDefinition = {{"gps", "ap_alt", "ap_msl"},{"ap_dist", "ap_speed",1}}
	elseif template == 1 and switchPos >  0 then
		widgetDefinition = {{"ap_roll", "ap_pitch", "ap_yaw"},{"hud_hdg"},{"hdg",1,1}}
		
	elseif template == 2 and switchPos <  0 then
		widgetDefinition = {{"mavtype", "armed", "fm", "timer"},{"ap_batt", 0, 0, "rxbat"},{"ap_volt", "ap_curr", "ap_drawn", "rssi"},{"gps", "ap_alt", "ap_speed", "ap_dist"}}
	elseif template == 2 and switchPos == 0 then
		widgetDefinition = {{"ap_roll", "ap_pitch", "ap_yaw", 1},{"hud_hdg"},{"gps", "ap_alt", "ap_speed", "ap_dist"}}
	elseif template == 2 and switchPos >  0 then
		widgetDefinition = {{"msg"}}
		
	elseif template == 3 and switchPos <  0 then
		widgetDefinition = {{"mavtype", "armed", "fm", "timer"},{"ap_batt", 0, 0, "rxbat"},{"ap_volt", "ap_curr", "ap_drawn", "rssi"},{"gps", "ap_alt", "ap_speed", "ap_dist"}}
	elseif template == 3 and switchPos == 0 then
		widgetDefinition = {{"ap_roll", "ap_pitch", "ap_yaw", 1},{"hud_hdg"},{"gps", "ap_alt", "ap_speed", "ap_dist"}}
	elseif template == 3 and switchPos >  0 then
		widgetDefinition = {{"msg"}}
	else
		widgetDefinition = {{"ERROR"}}
	end
	
	return widgetDefinition
end

---------------------------------------------
-- get value --------------------------------
---------------------------------------------
local function getValueOrDefault(sensor)
	local tmp = getValue(sensor)
	
	if tmp == nil then
		return 0
	else
		return tmp
	end
	
end

---------------------------------------------
-- round value ------------------------------
---------------------------------------------
local function round(num, decimal)
    local mult = 10^(decimal or 0)
    return math.floor(num * mult + 0.5) / mult
end



-- ############################# Widgets #################################

------------------------------------------------- 
-- Dynamic widget images ------------------------
-------------------------------------------------

local function dynamicWidgetImg(xCoord, yCoord, cellHeight, name, myImgValue, img, context)
	local image
	-- static image if img not 1
	if img ~= 1 then
		image = Bitmap.open(context.imagePath..img)
	end
	
	-- dynamic image for gps
	if name == "gps" then
		if myImgValue < 3 then
			image = Bitmap.open(context.imagePath.."satoff.png")
		else
			image = Bitmap.open(context.imagePath.."saton.png")
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
		image = Bitmap.open(context.imagePath.."rssi"..rssiIndex..".png")
	end
	
	-- dynamic image for heading
	if name == "heading" then
		hdgIndex = math.floor (myImgValue/15+0.5) --+1
		if hdgIndex > 23 then hdgIndex = 23 end		-- ab 352 Grad auf Index 23
		image = Bitmap.open(context.imagePath.."arrow"..hdgIndex..".png")
	end
	
	-- dynamic image for flightmode
	if name == "fm" then
		if myImgValue == 0 then
			image = Bitmap.open(context.imagePath.."sleep.png")
		elseif myImgValue == 4 or mod == 5 or mod == 6 or mod == 7 or mod == 10 or mod == 17 then
			image = Bitmap.open(context.imagePath.."auto.png")
		else
			image = Bitmap.open(context.imagePath.."human.png")
		end
	end
	
	-- dynamic image for arm
	if name == "armed" then
		if myImgValue == 0 then
			image = Bitmap.open(context.imagePath.."disarmed.png")
		else
			image = Bitmap.open(context.imagePath.."armed.png")
		end
	end
	
	local w, h = Bitmap.getSize(image)
	local xPic = xCoord+context.offsetLabel.x; yPic = yCoord  + (cellHeight) - h - context.offsetPic.y
	lcd.drawBitmap(image, xPic, yPic)
	
end

------------------------------------------------- 
-- Standard Widget	-----------------------------
------------------------------------------------- 
local function stdWidget(xCoord, yCoord, cellWidth, cellHeight, name, sensor, label, unit, digits, minmax, img, context)
	local myValue
	local myMinMaxValue
	
	local xTxt1 = xCoord + cellWidth  * context.offsetValue.x
	local yTxt1 = yCoord + cellHeight - context.offsetValue.y
	local yTxt2 = yCoord + cellHeight - context.offsetUnit.y
    
    if sensor ~= nil then
		if type(sensor) == number then
        	myValue = sensor
    	else
    		if sensor == "ERROR" then
    			myValue = "Error in Widget"
    		else
    			if digits ~= nil then
    				myValue = round(getValueOrDefault(sensor),digits)
    			else
    				myValue = getValueOrDefault(sensor)
    			end
    		end
    	end
		lcd.setColor(CUSTOM_COLOR, context.colors.std)
		lcd.drawText(xTxt1, yTxt1, myValue, context.modeSize.mid + context.modeAlign.ri + CUSTOM_COLOR)
	end
	
    if minmax ~= nil then
    	if type( minmax ) == number then
			myMinMaxValue = minmax
		else
			if digits ~= nil then
    			myMinMaxValue = round(getValueOrDefault(minmax),digits)
    		else
    			myMinMaxValue = getValueOrDefault(minmax)
    		end
			
		end
		lcd.setColor(CUSTOM_COLOR, context.colors.max)
		lcd.drawText(xCoord + cellWidth - context.offsetMax.x, yCoord + context.offsetMax.y, myMinMaxValue, context.modeSize.sml + context.modeAlign.ri + CUSTOM_COLOR)
	end
	
	if unit ~= nil then
		lcd.setColor(CUSTOM_COLOR, context.colors.uni)
		lcd.drawText(xTxt1, yTxt2, unit, context.modeSize.sml + context.modeAlign.le + CUSTOM_COLOR)
	end
	
	if label ~= nil then
		lcd.setColor(CUSTOM_COLOR, context.colors.lab)
		lcd.drawText(xCoord + context.offsetLabel.x, yCoord + context.offsetLabel.y, label, context.modeSize.sml + CUSTOM_COLOR)
	end
	
	if img ~= nil then
		dynamicWidgetImg(xCoord, yCoord, cellHeight, name, myValue, img, context)
	end
end

------------------------------------------------- 
-- GPS Widget -----------------------------------
------------------------------------------------- 
local function gpsWidget(xCoord, yCoord, cellWidth, cellHeight, name, img, context)
	local myValue
	local myMinMaxValue
	local myImgValue
	local myLabel
	
	local xTxt1 = xCoord + cellWidth  * context.offsetValue.x
	local yTxt1 = yCoord + cellHeight - context.offsetValue.y
	local yTxt2 = yCoord + cellHeight - context.offsetUnit.y
    
    myValue = getValueOrDefault("HDP")
    myMinMaxValue = getValueOrDefault("SAT")
    myImgValue = getValueOrDefault("FIX")
    myLabel = fixetype[myImgValue]
    
	lcd.setColor(CUSTOM_COLOR, context.colors.std)
	lcd.drawText(xTxt1, yTxt1, round(myValue,1), context.modeSize.mid + context.modeAlign.ri + CUSTOM_COLOR)
	
	lcd.setColor(CUSTOM_COLOR, context.colors.max)
	lcd.drawText(xCoord + cellWidth - context.offsetMax.x, yCoord + context.offsetMax.y, myMinMaxValue, context.modeSize.sml + context.modeAlign.ri + CUSTOM_COLOR)
	
	lcd.setColor(CUSTOM_COLOR, context.colors.uni)
	lcd.drawText(xTxt1, yTxt2, "m", context.modeSize.sml + context.modeAlign.le + CUSTOM_COLOR)
	
	lcd.setColor(CUSTOM_COLOR, context.colors.lab)
	lcd.drawText(xCoord + context.offsetLabel.x, yCoord + context.offsetLabel.y, myLabel, context.modeSize.sml + CUSTOM_COLOR)
	
	if img ~= nil then
		dynamicWidgetImg(xCoord, yCoord, cellHeight, name, myImgValue, img, context)
	end
end

------------------------------------------------- 
-- Timer ------------------------------- timer --
------------------------------------------------- 
local function timerWidget(xCoord, yCoord, cellWidth, cellHeight, name, img, context)
	local teleV_tmp = model.getTimer(0) -- Timer 1
	local myTimer = teleV_tmp.value
	local minute = math.floor(myTimer/60)
	local sec = myTimer - (minute*60)
	local valText
	
	if sec > 9 then
		valTxt = string.format("%i",minute)..":"..string.format("%i",sec)
	else
		valTxt = string.format("%i",minute)..":0"..string.format("%i",sec)
	end 
	
	local xTxt1 = xCoord + cellWidth  * context.offsetValue.x
	local yTxt1 = yCoord + cellHeight - context.offsetValue.y
	local yTxt2 = yCoord + cellHeight - context.offsetUnit.y
	
	lcd.setColor(CUSTOM_COLOR, context.colors.std)
	lcd.drawText(xTxt1, yTxt1, valTxt, context.modeSize.mid + context.modeAlign.ri + CUSTOM_COLOR)
	lcd.setColor(CUSTOM_COLOR, context.colors.uni)
	lcd.drawText(xTxt1, yTxt2, "m:s", context.modeSize.sml + context.modeAlign.le + CUSTOM_COLOR)
	lcd.setColor(CUSTOM_COLOR, context.colors.lab)
	lcd.drawText(xCoord + context.offsetLabel.x, yCoord + context.offsetLabel.y, "Airborne", context.modeSize.sml + CUSTOM_COLOR)
	
	if img ~= nil then
		dynamicWidgetImg(xCoord, yCoord, cellHeight, name, myImgValue, img, context)
	end
end


------------------------------------------------- 
-- Flightmode ----------------------------- fm --
------------------------------------------------- 
local function fmWidget(xCoord, yCoord, cellWidth, cellHeight, name, img, context)
	local myImgValue
	local myImgValue = getValueOrDefault("MOD")
	local valTxt = flightMode[myImgValue]
	
	local xTxt1 = xCoord + cellWidth
	local yTxt1 = yCoord + cellHeight/2 - context.modeSize.smlH/2
	
	lcd.setColor(CUSTOM_COLOR, context.colors.std)
	lcd.drawText(xTxt1, yTxt1, valTxt, context.modeSize.sml + context.modeAlign.ri + CUSTOM_COLOR)
	
	lcd.setColor(CUSTOM_COLOR, context.colors.lab)			
	lcd.drawText(xCoord + context.offsetLabel.x, yCoord + context.offsetLabel.y, "Mode [AP]", context.modeSize.sml + CUSTOM_COLOR)
	
	if img ~= nil then
		dynamicWidgetImg(xCoord, yCoord, cellHeight, name, myImgValue, img, context)
	end
end

------------------------------------------------- 
-- Armed/Disarmed (Switch) ------------- armed --
------------------------------------------------- 
local function armedWidget(xCoord, yCoord, cellWidth, cellHeight, name, img, context)
	local myImgValue = getValueOrDefault("ARM")
	local valTxt     = armed[myImgValue]
	if myImgValue == 0 then
		lcd.setColor(CUSTOM_COLOR, context.colors.std)	
	else
		lcd.setColor(CUSTOM_COLOR, context.colors.alm)
	end

	local xTxt1 = xCoord + cellWidth
	local yTxt1 = yCoord + cellHeight/2 - context.modeSize.smlH/2
		
	lcd.drawText(xTxt1, yTxt1, valTxt, context.modeSize.sml + context.modeAlign.ri + CUSTOM_COLOR)
	lcd.setColor(CUSTOM_COLOR, context.colors.lab)
	lcd.drawText(xCoord + context.offsetLabel.x, yCoord + context.offsetLabel.y, "Motor", context.modeSize.sml + CUSTOM_COLOR)
	
	if img ~= nil then
		dynamicWidgetImg(xCoord, yCoord, cellHeight, name, myImgValue, img, context)
	end
end

------------------------------------------------- 
-- Mavtype --------------------------- mavtype --
------------------------------------------------- 
local function mavtypeWidget(xCoord, yCoord, cellWidth, cellHeight, name, img, context)
	local modelinfo = model.getInfo()
	-- local mav  = getValueOrDefault("MAV")
	local mav = model.getGlobalVariable(0, 0)
	
	if mav == nil then
		mav = 0
	end
	
	local xTxt1 = xCoord + cellWidth
	local yTxt1 = yCoord + cellHeight/2 - context.modeSize.smlH/2
	
	lcd.setColor(CUSTOM_COLOR, context.colors.std)
	lcd.drawText(xTxt1, yTxt1, modelinfo.name, context.modeSize.sml + context.modeAlign.ri + CUSTOM_COLOR)
	lcd.setColor(CUSTOM_COLOR, context.colors.lab)
	lcd.drawText(xCoord + context.offsetLabel.x, yCoord + context.offsetLabel.y, mavType[mav], context.modeSize.sml + CUSTOM_COLOR)
end


------------------------------------------------- 
-- Battery --------------------------- battery --
-------------------------------------------------
local function batteryWidget(xCoord, yCoord, cellWidth, cellHeight, name, context)

	local myVoltage
	local myPercent = 0
	local battCell  = context.options.Cells.."S"
	-- local battCapa  = getValueOrDefault("CAP")
	local battCapa  = model.getGlobalVariable(1, 0)*10
	
	local _6SL = 21      -- 6 cells 6s | Warning
    local _6SH = 25.2    -- 6 cells 6s
	local _4SL = 13.4    -- 4 cells 4s | Warning
    local _4SH = 16.8    -- 4 cells 4s
    local _3SL = 10.4    -- 3 cells 3s | Warning
    local _3SH = 12.6    -- 3 cells 3s
    local _2SL = 7       -- 2 cells 2s | Warning
    local _2SH = 8.4     -- 2 cells 2s
    
	
	if name == "vfas" then
		myVoltage = getValueOrDefault("VFAS")
	elseif name == "ap_batt" then
		myVoltage = getValueOrDefault("VOL")
	end
	
	
    if context.options.Cells == 6 then
		if myVoltage > 3 then
			myPercent = math.floor((myVoltage-_6SL) * (100/(_6SH - _6SL)))
		end
	end
	if context.options.Cells == 4 then
		if myVoltage > 3 then
			myPercent = math.floor((myVoltage-_4SL) * (100/(_4SH - _4SL)))
		end
	end
	if context.options.Cells == 3 then
		if myVoltage > 3 then
			myPercent = math.floor((myVoltage-_3SL) * (100/(_3SH - _3SL)))
		end
	end
	if context.options.Cells == 2 then
		if myVoltage > 3 then
			myPercent = math.floor((myVoltage-_2SL) * (100/(_2SH - _2SL)))
		end
	end
	
	lcd.setColor(CUSTOM_COLOR, context.colors.lab)
	lcd.drawText(xCoord + context.offsetLabel.x, yCoord + context.offsetLabel.y, "["..battCell.."/"..battCapa.."mAh]", context.modeSize.sml + CUSTOM_COLOR)
		
	local xTxt1 = xCoord + cellWidth  * context.offsetValue.x
	local yTxt1 = yCoord + cellHeight - context.offsetValue.y
	local yTxt2 = yCoord + cellHeight - context.offsetUnit.y
		
	lcd.setColor(CUSTOM_COLOR, context.colors.uni)
	lcd.drawText(xTxt1, yTxt2, "%", context.modeSize.sml + context.modeAlign.le + CUSTOM_COLOR)
	
	if myPercent > 100 then myPercent = 100 end
	if myPercent < 0   then myPercent =   0 end
	if myPercent < 30  and  myPercent >= 20 then
		lcd.setColor(CUSTOM_COLOR, YELLOW)
	elseif myPercent < 20  then
		lcd.setColor(CUSTOM_COLOR, RED)
	else
		lcd.setColor(CUSTOM_COLOR, context.colors.std)
	end
	
	
	lcd.drawText(xTxt1, yTxt1, myPercent, context.modeSize.mid + context.modeAlign.ri + CUSTOM_COLOR)
		
	
	-- dyn batt icon -----
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
	
	if  batName ~= context.imagePath.."B"..batIndex..".png" then
		batName  = context.imagePath.."B"..batIndex..".png"
		batImage = Bitmap.open(batName)
	end
	
	local w, h = Bitmap.getSize(batImage)
	local xPic = xCoord + (cellWidth * 0.5) - (w * 0.5); yPic = yCoord + context.offsetPic.batt
	lcd.drawBitmap(batImage, xPic, yPic)
end

------------------------------------------------- 
-- Horizon ------------------------------- hud --
-------------------------------------------------
local function drawHud(xCoord, yCoord, cellWidth, cellHeight, name, img, context)
	local hudImage
 	local rol = getValueOrDefault("ROL")
 	local pit = getValueOrDefault("PIT")
 	
	local size      = cellWidth/2
	local x_offset  = xCoord + (cellWidth-size)/2
	local y_offset  = yCoord + (cellWidth-size)/2
	
	local colAH = size/2+x_offset	-- H centerline
	local rowAH = size/2+y_offset	-- V centerline
	local radAH = size/2			-- half size of box

	local pitchR = 1	            -- Dist between pitch lines

	local sinRoll = math.sin(math.rad(-rol))
	local cosRoll = math.cos(math.rad(-rol))

	local delta = pit % 15
	for i =  delta - 30 , 30 + delta, 15 do
		local XH = pit == i % 360 and size or 10
		local YH = pitchR * i							
    
		local X1 = -XH * cosRoll - YH * sinRoll
    	local Y1 = -XH * sinRoll + YH * cosRoll
    	local X2 = (XH - 2) * cosRoll - YH * sinRoll
    	local Y2 = (XH - 2) * sinRoll + YH * cosRoll
    	
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
	--lcd.setColor(CUSTOM_COLOR, context.colors.lin)
	--lcd.drawRectangle(x_offset+size/2-size/2, y_offset+size/2-size/2, size, size, SOLID + LINE_COLOR )

	if name == "hud" then
		hudImage = Bitmap.open(context.imagePath.."hud.png")
	elseif name == "hud_hdg" then
		myImgValue = getValueOrDefault("YAW")
		hdgIndex = math.floor (myImgValue/15+0.5)   --+1
		if hdgIndex > 23 then hdgIndex = 23 end		-- ab 352 Grad auf Index 23
		hudImage = Bitmap.open(context.imagePath.."hud"..hdgIndex..".png")
	end
	local w, h = Bitmap.getSize(hudImage)
	local xPic = xCoord + (cellWidth * 0.5) - (w * 0.5); yPic = yCoord + (cellWidth * 0.5) - (h * 0.5)
	lcd.drawBitmap(hudImage, xPic, yPic)
end

-- ############################# Call Widgets #################################
 
local function callWidget(name, xPos, yPos, width, height, context)
	if (xPos ~= nil and yPos ~= nil) then
		-- special widgets / txt widgets
		if (name == "msg") then
			msgWidget(    xPos, yPos, width, height, name,      context)
		elseif (name == "vfas" or name == "ap_batt") then
			batteryWidget(xPos, yPos, width, height, name,      context)
		elseif (name == "armed") then
			armedWidget(  xPos, yPos, width, height, name, 1,   context)
		elseif (name == "fm") then
			fmWidget(     xPos, yPos, width, height, name, 1,   context)
		elseif (name == "gps") then
			gpsWidget(    xPos, yPos, width, height, name, 1,   context)
		elseif (name == "timer") then
			timerWidget(  xPos, yPos, width, height, name, nil, context)
		elseif (name == "mavtype") then
			mavtypeWidget(xPos, yPos, width, height, name, nil, context)
		elseif (name == "hud" or name == "hud_hdg") then
			drawHud(      xPos, yPos, width, height, name, nil, context)

		
		-- stdWidget(x,      y,      width, height, name, sensor,      label,         unit,   dig, minmax,     img, context)
				
		-- standard sensor widgets called with sensors
		elseif (name == "vfas") then
			stdWidget(xPos,  yPos,   width, height, name, "VFAS",      "Volt",        "V",    1,   "VFAS-",    nil, context)
		elseif (name == "curr") then
			stdWidget(xPos,  yPos,   width, height, name, "Curr",      "Curr",        "A",    1,   "Curr+",    nil, context)
		elseif (name == "rxbat") then
			stdWidget(xPos,  yPos,   width, height, name, "RxBt",      "RxBt",        "V",    1,   "RxBt-",    nil, context)
		elseif (name == "rssi")  then
			stdWidget(xPos,  yPos,   width, height, name, "RSSI",      "RSSI",        "db",   nil, "RSSI-",    1,   context)
		elseif (name == "speed") then
			stdWidget(xPos,  yPos,   width, height, name, "GSpd",      "H Speed",     "km/h", 0,   "GSpd+",    nil, context)
		elseif (name == "vspeed") then
			stdWidget(xPos,  yPos,   width, height, name, "V-Speed",   "V Speed",     "m/s",  0,   "V-Speed+", nil, context)
		elseif (name == "dist") then
			stdWidget(xPos,  yPos,   width, height, name, "Dist",      "Dist",        "m",    1,   "Dist-",    nil, context)
		elseif (name == "alt") then
			stdWidget(xPos,  yPos,   width, height, name, "Alt",       "Alt",         "m",    1,   "Alt+",     nil, context)
		elseif (name == "hdg") then
			stdWidget(xPos,  yPos,   width, height, name, "Hdg",       "Heading",     "dg",   1,   nil,        nil, context)
			
		-- standard widgets called with passthrough telemetry sensors
		elseif (name == "ap_alt") then
			stdWidget(xPos,  yPos,   width, height, name,  "ALT",      "AGL",         "m",    1,   "ALT+",     nil, context)
		elseif (name == "ap_vdp") then
			stdWidget(xPos,  yPos,   width, height, name,  "VDP",      "VDOP",        "m",    1,   nil,        nil, context)
		elseif (name == "ap_hdp") then
			stdWidget(xPos,  yPos,   width, height, name,  "HDP",      "HDOP",        "m",    1,   nil,        nil, context)
		elseif (name == "ap_speed") then
			stdWidget(xPos,  yPos,   width, height, name,  "SPD",      "Speed",       "km/h", nil, "SPD+",     nil, context)
		elseif (name == "ap_dist") then
			stdWidget(xPos,  yPos,   width, height, name,  "DST",      "Dist",        "m",    1,   "DST+",     nil, context)
		elseif (name == "ap_msl") then
			stdWidget(xPos,  yPos,   width, height, name,  "MSL",      "MSL",         "m",    1,   "MSL+",     nil, context)
		elseif (name == "ap_volt") then
			stdWidget(xPos,  yPos,   width, height, name,  "VOL",      "Volt",        "V",    2,   "VOL-",     nil, context)
		elseif (name == "ap_curr") then
			stdWidget(xPos,  yPos,   width, height, name,  "CUR",      "Curr",        "A",    1,   "CUR+",     nil, context)
		elseif (name == "ap_drawn") then
			stdWidget(xPos,  yPos,   width, height, name,  "DRW",      "Used",        "mAh",  nil, nil,        nil, context)
		elseif (name == "ap_yaw") then
			stdWidget(xPos,  yPos,   width, height, name,  "YAW",      "Yaw",         "dg",   nil, nil,        nil, context)
		elseif (name == "ap_pitch") then
			stdWidget(xPos,  yPos,   width, height, name,  "PIT",      "Pitch",       "dg",   nil, nil,        nil, context)
		elseif (name == "ap_roll") then
			stdWidget(xPos,  yPos,   width, height, name,  "ROL",      "Roll",        "dg",   nil, nil,        nil, context)
			
		elseif (name == "ERROR") then
			stdWidget(xPos,  yPos,   width, height, name,  "ERROR",    "error",       nil,    nil, nil,        nil, context)
		else
			return
		end
	end
end

-- ############################# Build Grid #################################

local function buildGrid(def, context)

	local sumX = context.zone.x-10
	local sumY = context.zone.y-5
	local canvasWidth  = context.zone.w + 20 -- more space
	local canvasHeight = context.zone.h + 15
	
	local noCol = # def 	-- number of Cells
	local cellWidth = math.floor((canvasWidth / noCol))
	
	-- widgets grid and lines
	for i=1, noCol, 1
	do
	
		local tempCellHeight = math.floor(canvasHeight / # def[i])
		for j=1, # def[i], 1
		do
			-- lines
			if (j ~= 1) and (def[i][j] ~= 0) then
				lcd.setColor(CUSTOM_COLOR, context.colors.lin)
				lcd.drawLine(sumX+context.offsetLabel.x, sumY, sumX + cellWidth-context.offsetLabel.x, sumY, DOTTED, CUSTOM_COLOR)
			end
			
			-- widgets
			if def[i][j] ~= 0 then
				
				if (j+2 <= # def[i]) and (def[i][j+1] == 0) and (def[i][j+2] == 0) then
					callWidget(def[i][j], sumX , sumY , cellWidth, tempCellHeight*3, context)
					sumY = sumY + tempCellHeight*3
				elseif (j+1 <= # def[i]) and (def[i][j+1] == 0) and (def[i][j+2] ~= 0) then
					callWidget(def[i][j], sumX , sumY , cellWidth, tempCellHeight*2, context)
					sumY = sumY + tempCellHeight*2
				else
					callWidget(def[i][j], sumX , sumY , cellWidth, tempCellHeight,   context)
					sumY = sumY + tempCellHeight
				end
				
			end
		end
		
		-- Werte zurücksetzen
		sumY = context.zone.y-5
		sumX = sumX + cellWidth
	end
end

function refresh(context)
	-- Build Grid --
	buildGrid(widget(context.options.Mode, context.options.Template), context)
end

return { name="MAV-TEL", options=options, create=create, update=update, refresh=refresh }