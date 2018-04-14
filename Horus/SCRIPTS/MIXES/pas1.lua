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

local function initFunc()
	local mod,arm,bfs,efs,sat,fix,hdp,vdp,msl = 0,0,0,0,0,0,0,0,0
	local j0,j1,j2,jv
end

local function runFunc()
	
	-- sportTelemetryPop() returns 4 values:
	-- sensor ID (number) -> i0
	-- frame ID  (number) -> i1
	-- data ID   (number) -> i2
	-- value     (number) -> v
	
	j0,j1,j2,jv = sportTelemetryPop()
	
	
	-- unpack 5001 packet
	if j2 == 0x5001 then
		mod = bit32.extract(jv,0,5)
		arm = bit32.extract(jv,8,1)
		bfs = bit32.extract(jv,9,1)
		efs = bit32.extract(jv,10,1)
		setTelemetryValue (5001,0,30,mod,0,0,"MOD")
		setTelemetryValue (5001,0,31,arm,0,0,"ARM")
		if bfs == 1 or efs == 1 then
			setTelemetryValue (5001,0,32,1,0,0,"FS")
		elseif bfs == 0 and efs == 0 then
			setTelemetryValue (5001,0,32,0,0,0,"FS")
		end
	end
	
	-- unpack 5002 packet
	if j2 == 0x5002 then
		sat = bit32.extract(jv,0,4)
		fix = bit32.extract(jv,4,2)
		hdp = bit32.extract(jv,7,7)*(10^(bit32.extract(jv,6,1)-1))
		vdp = bit32.extract(jv,15,7)*(10^(bit32.extract(jv,14,1)-1))
		msl = bit32.extract(jv,24,7)*(10^bit32.extract(jv,22,2))
		setTelemetryValue (5002,0,33,sat,0,0,"SAT")
		setTelemetryValue (5002,0,34,fix,0,0,"FIX")
		setTelemetryValue (5002,0,35,hdp,9,1,"HDP")
		setTelemetryValue (5002,0,36,vdp,9,1,"VDP")
		setTelemetryValue (5002,0,37,msl,9,1,"MSL")
	end

end

return{run=runFunc, init=initFunc}