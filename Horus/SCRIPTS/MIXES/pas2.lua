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
-- 0	Raw unit (no unit)	UNIT_RAW
-- 1	Volts				UNIT_VOLTS
-- 2	Amps				UNIT_AMPS
-- 3	Milliamps			UNIT_MILLIAMPS
-- 4	Knots				UNIT_KTS
-- 5	Meters per Second	UNIT_METERS_PER_SECOND
-- 6	Feet per Second		UNIT_FEET_PER_SECOND
-- 7	Kilometers per Hour	UNIT_KMH
-- 8	Miles per Hour		UNIT_MPH
-- 9	Meters				UNIT_METERS
-- 10	Feet				UNIT_FEET
-- 11	Degrees Celsius		UNIT_CELSIUS
-- 12	Degrees Fahrenheit	UNIT_FAHRENHEIT
-- 13	Percent				UNIT_PERCENT
-- 14	Milliamp per Hour	UNIT_MAH
-- 15	Watts				UNIT_WATTS
-- 16	Milliwatts			UNIT_MILLIWATTS
-- 17	dB					UNIT_DB
-- 18	RPM					UNIT_RPMS
-- 19	G					UNIT_G
-- 20	Degrees				UNIT_DEGREE
-- 21	Radians				UNIT_RADIANS
-- 22	Milliliters			UNIT_MILLILITERS
-- 23	Fluid Ounces		UNIT_FLOZ
-- 24	Hours				UNIT_HOURS
-- 25	Minutes				UNIT_MINUTES
-- 26	Seconds				UNIT_SECONDS
-- 27						UNIT_CELLS
-- 28						UNIT_DATETIME
-- 29						UNIT_GPS
-- 30						UNIT_BITFIELD
-- 31						UNIT_TEXT

-- initialize variables
-- ***************************

local function init_func()
	local vol,cur,drw,dst,alt,spd,yaw,rol,pit,mav,cap = 0,0,0,0,0,0,0,0,0,0,0
	local i0,i1,i2,v
end

local function run()
	
	-- sportTelemetryPop() returns 4 values:
	-- sensor ID (number) -> i0
	-- frame ID  (number) -> i1
	-- data ID   (number) -> i2
	-- value     (number) -> v
	
	i0,i1,i2,v = sportTelemetryPop()
	
	-- splitted into two parts for more performance
	
	-- unpack 5003 packet
	if i2 == 0x5003 then
		vol = bit32.extract(v,0,9)
		cur = bit32.extract(v,10,7)*(10^bit32.extract(v,9,1))
		drw = bit32.extract(v,17,15)
		setTelemetryValue (5003,0,37,vol,1,1,"VOL")
		setTelemetryValue (5003,0,38,cur,2,1,"CUR")
		setTelemetryValue (5003,0,39,drw,3,0,"DRW")
	end
	
	-- unpack 5004 packet
	if i2 == 0x5004 then
		dst = bit32.extract(v,0,12)
		alt = bit32.extract(v,21,10)*(10^bit32.extract(v,19,2))
        if (bit32.extract(v,31,1) == 1) then alt = -alt end
		setTelemetryValue (5004,0,40,dst,9,0,"DST")
		setTelemetryValue (5004,0,41,alt,9,1,"ALT")
	end
	
	-- unpack 5005 packet
	if i2 == 0x5005 then
		spd = bit32.extract(v,10,7)*(10^bit32.extract(v,9,1))/10
		yaw = bit32.extract(v,17,11) * 0.2
		setTelemetryValue (5005,0,42,spd,7,0,"SPD")
		setTelemetryValue (5005,0,43,yaw,20,0,"YAW")
	end
	
	-- unpack 5006 packet
	if i2 == 0x5006 then
		rol = (bit32.extract(v,0,11) -900) * 0.2
		pit = (bit32.extract(v,11,10 ) -450) * 0.2
		setTelemetryValue (5006,0,44,rol,20,0,"ROL")
		setTelemetryValue (5006,0,45,pit,20,0,"PIT")
	end
	
	-- unpack 5007 packet if GL1 and GL2 == 0
	if i2 == 0x5007 then
		local ParamID = bit32.extract(v,24,8)
		if ParamID == 0x1 then 
			mav = bit32.extract(v,0,8)
			model.setGlobalVariable(0, 0, mav)
			--setTelemetryValue (5007,0,46,mav,0,0,"MAV")
		end
		if ParamID == 0x4 then
			cap = bit32.extract(v,0,24)
			model.setGlobalVariable(1, 0, cap/10)
			--setTelemetryValue (5007,0,47,cap,3,0,"CAP")
		end
	end

end

return{run=run, init=init_func}