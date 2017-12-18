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

-- 0	Raw unit (no unit)	UNIT_RAW
-- 1	Volts	UNIT_VOLTS
-- 2	Amps	UNIT_AMPS
-- 3	Milliamps	UNIT_MILLIAMPS
-- 4	Knots	UNIT_KTS
-- 5	Meters per Second	UNIT_METERS_PER_SECOND
-- 6	Feet per Second	UNIT_FEET_PER_SECOND
-- 7	Kilometers per Hour	UNIT_KMH
-- 8	Miles per Hour	UNIT_MPH
-- 9	Meters	UNIT_METERS
-- 10	Feet	UNIT_FEET
-- 11	Degrees Celsius	UNIT_CELSIUS
-- 12	Degrees Fahrenheit	UNIT_FAHRENHEIT
-- 13	Percent	UNIT_PERCENT
-- 14	Milliamp per Hour	UNIT_MAH
-- 15	Watts	UNIT_WATTS
-- 16	Milliwatts	UNIT_MILLIWATTS
-- 17	dB	UNIT_DB
-- 18	RPM	UNIT_RPMS
-- 19	G	UNIT_G
-- 20	Degrees	UNIT_DEGREE
-- 21	Radians	UNIT_RADIANS
-- 22	Milliliters	UNIT_MILLILITERS
-- 23	Fluid Ounces	UNIT_FLOZ
-- 24	Hours	UNIT_HOURS
-- 25	Minutes	UNIT_MINUTES
-- 26	Seconds	UNIT_SECONDS
-- 27	UNIT_CELLS
-- 28	UNIT_DATETIME
-- 29	UNIT_GPS
-- 30	UNIT_BITFIELD
-- 31	UNIT_TEXT

-- initialize	global variable
-- ***************************

local function init_func()
	local yaw,pit,rol,mod,arm,sat,alt,msl,spd,dst,vol,cur,drw,cap,lat,lon,hdp,vdp,sat,fix,mav = 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	local i0,i1,i2,v
end

local function run()
	
	-- sportTelemetryPop() returns 4 values:
	-- sensor ID (number) -> i0
	-- frame ID  (number) -> i1
	-- data ID   (number) -> i2
	-- value     (number) -> v
	
	i0,i1,i2,v = sportTelemetryPop()
	
	
	-- unpack 5001 packet
	if i2 == 20481 then
		mod = bit32.extract(v,0,5)
		arm = bit32.extract(v,8,1)
		setTelemetryValue (5001,0,1,mod,0,0,"MOD")
		setTelemetryValue (5001,0,2,arm,0,0,"ARM")
	end
	
	-- unpack 5002 packet
	if i2 == 20482 then
		sat = bit32.extract(v,0,4)
		fix = bit32.extract(v,4,2)
		hdp = bit32.extract(v,6,8)
		vdp = bit32.extract(v,14,8)
		msl = bit32.extract(v,22,9)
		setTelemetryValue (5002,0,3,sat,0,0,"SAT")
		setTelemetryValue (5002,0,4,fix,0,0,"FIX")
		setTelemetryValue (5002,0,5,hdp,9,0,"HDP")
		setTelemetryValue (5002,0,6,vdp,9,0,"VDP")
		setTelemetryValue (5002,0,7,msl,9,0,"MSL")
	end
	
	-- unpack 5003 packet
	if i2 == 20483 then
		vol = bit32.extract(v,0,9)
		cur = bit32.extract(v,9,8)
		drw = bit32.extract(v,17,15)
		setTelemetryValue (5003,0,8,vol,1,0,"VOL")
		setTelemetryValue (5003,0,9,cur,2,0,"CUR")
		setTelemetryValue (5003,0,10,drw,3,0,"DRW")
	end
	
	-- unpack 5004 packet
	if i2 == 20484 then
		dst = bit32.extract(v,0,12)
		alt = bit32.extract(v,19,12)
		setTelemetryValue (5004,0,11,dst,9,0,"DST")
		setTelemetryValue (5004,0,12,alt,9,0,"ALT")
	end
	
	-- unpack 5005 packet
	if i2 == 20485 then
		spd = bit32.extract(v,9,8) * 0.2
		yaw = bit32.extract(v,17,11) * 0.2
		setTelemetryValue (5005,0,13,spd,7,0,"SPD")
		setTelemetryValue (5005,0,14,yaw,20,0,"YAW")
	end
	
	-- unpack 5006 packet
	if i2 == 20486 then
		rol = (bit32.extract(v,0,11) -900) * 0.2
		pit = (bit32.extract(v,11,10 ) -450) * 0.2
		setTelemetryValue (5006,0,15,rol,20,0,"ROL")
		setTelemetryValue (5006,0,16,pit,20,0,"PIT")
	end
	
	-- unpack 5007 packet
	if i2 == 20487 then
		--iterator = bit32.extract(v,0,8)
		iterator = bit32.band(bit32.rshift(v, 24), 0xff)
		if iterator == 0x1 then 
			mav = bit32.band(v, 0xffffff)
			setTelemetryValue (5007,0,17,mav,0,0,"MAV")
		end
		if iterator == 0x4 then 
			cap = bit32.band(v, 0xffffff)
			setTelemetryValue (5007,0,18,cap,3,0,"CAP")
		end
	end

end

return{run=run, init=init_func}
