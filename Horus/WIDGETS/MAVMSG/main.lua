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


local options = {

}

local function create(zone, options)
	
	-- colors
	local colors = {std = BLUE, min = GREEN, max = YELLOW, alm = RED, lab = LIGHTGREY, uni = LIGHTGREY, lin = GREY}

	-- Params for font size and offsets
	local modeSize = {sml = SMLSIZE, mid = MIDSIZE, dbl = DBLSIZE, smlH = 12, midH = 18, dbl = 24}
	local modeAlign = {ri = RIGHT, le = LEFT}

	local offsetLabel = {x = 4, y = 3}     -- y offset from top of box

	-- frsky passthrough vars
	local svr,msg = 0,0

	-- Mavlink messages
	local messages = {}
	for i = 1, 12 do
		messages[i] = nil
	end

	local currentMessageChunks = {}
	for i = 1, 60 do
		currentMessageChunks[i] = nil
	end

	local currentMessageChunkPointer = 0
	local messageSeverity = -1
	local messageLatest = 0
	local messagesAvailable = 0
	local messageLastChunk = 0

	-- widgets
	local w, h, image, xPic, yPic, xTxt1, yTxt1, yTxt2
	local widgetDefinition = {}
	
	
	local context  = { 
		zone						= zone, 
		options						= options, 
		colors						= colors, 
		modeSize					= modeSize, 
		modeAlign					= modeAlign, 
		offsetLabel					= offsetLabel, 
		svr							= svr, 
		msg							= msg, 
		messages					= messages, 
		currentMessageChunks		= currentMessageChunks, 
		currentMessageChunkPointer	= currentMessageChunkPointer, 
		messageSeverity				= messageSeverity, 
		messageLatest				= messageLatest, 
		messagesAvailable			= messagesAvailable, 
		messageLastChunk			= messageLastChunk, 
		widgetDefinition			= widgetDefinition
	}
	
	return context
end

local function update()

end



---------------------------------------------
-- convert bytes into a string --------------
---------------------------------------------
local function bytesToString(bytesArray)
	tempString = ""
	for i = 1, 60 do
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
local function getMessages(value, context)
	if (value ~= nil) and (value ~= 0) and (value ~= messageLastChunk) then
		context.currentMessageChunks[context.currentMessageChunkPointer + 1] = bit32.band(bit32.rshift(value, 24), 0x7f)
		context.currentMessageChunks[context.currentMessageChunkPointer + 2] = bit32.band(bit32.rshift(value, 16), 0x7f)
		context.currentMessageChunks[context.currentMessageChunkPointer + 3] = bit32.band(bit32.rshift(value, 8), 0x7f)
		context.currentMessageChunks[context.currentMessageChunkPointer + 4] = bit32.band(value, 0x7f)
		context.currentMessageChunkPointer = context.currentMessageChunkPointer + 4
		if (context.currentMessageChunkPointer > 59) or (context.currentMessageChunks[context.currentMessageChunkPointer] == '\0') then
			context.currentMessageChunkPointer = -1
		end
		if bit32.band(value, 0x80) == 0x80 then
			context.messageSeverity = context.messageSeverity + 1
			context.currentMessageChunkPointer = -1
		end
		if bit32.band(value, 0x8000) == 0x8000 then
			context.messageSeverity = context.messageSeverity + 2
			context.currentMessageChunkPointer = -1
		end
		if bit32.band(value, 0x800000) == 0x800000 then
			context.messageSeverity = context.messageSeverity + 4
			context.currentMessageChunkPointer = -1
 		end
		if context.currentMessageChunkPointer == -1 then
			context.currentMessageChunkPointer = 0
			if context.messageLatest == 12 then
				for i = 1, 11 do
					context.messages[i] = context.messages[i+1]
				end
			else
				context.messageLatest = context.messageLatest + 1
			end
			context.messages[context.messageLatest] = bytesToString(context.currentMessageChunks)
			context.messagesAvailable = context.messagesAvailable + 1
			context.messageSeverity = context.messageSeverity + 1
			for i = 1, 60 do
				context.currentMessageChunks[i] = nil
			end
		end
		context.messageLastChunk = value
	end
end

---------------------------------------------
-- get and store SPort Passthrough MSG ------
--------------------------------------------- 
local function getSPort(context)
	local i0,i1,i2,v = sportTelemetryPop()
	
	-- unpack 5000 packet
	if i2 == 20480 then
		context.svr = bit32.extract(v,0,3)
		context.msg = bit32.extract(v,0,32)
		getMessages(msg, context)
	end

end


-- ############################# Widget ##################################


------------------------------------------------- 
-- Mavlink Messages ---------------------- msg --
------------------------------------------------- 
local function msgWidget(context)
	local _X = context.zone.x-10
	local _Y = context.zone.y-10
	local _W = context.zone.w + 20 -- more space
	local _H = context.zone.h + 15
	
	local xTxt1 = _X + context.offsetLabel.x
	local yTxt1 = _Y + context.modeSize.smlH*2
	
	lcd.setColor(CUSTOM_COLOR, context.colors.lin)
	lcd.drawLine(_X, _Y + context.modeSize.midH, _X + _W, _Y + context.modeSize.midH, DOTTED, CUSTOM_COLOR)
	
	lcd.setColor(CUSTOM_COLOR, context.colors.std)
	
	for i = 1, 12 do
		if context.messages[i] ~= nil then
			lcd.drawText(xTxt1, yTxt1 + context.modeSize.smlH *i, context.messages[i], context.modeSize.sml + context.modeAlign.le + CUSTOM_COLOR)
		end
	end
	
	lcd.setColor(CUSTOM_COLOR, context.colors.lab)
	lcd.drawText(_X + context.offsetLabel.x, _Y + context.offsetLabel.y, "MavLink Message Log", context.modeSize.sml + CUSTOM_COLOR)
end



-- ############################# Build Grid #################################



function refresh(context)
	-- get passthrough for mavlink msg
	getSPort(context)
	-- Build Grid --
	msgWidget(context)
end

return { name="MAV-MSG", create=create, refresh=refresh }