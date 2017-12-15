# Horus-Mavlink-Telemetry
A universal lua script for displaying mavlink values on FrSky Horus OpenTX

This Lua Widget script is showing varius Data and Values on your screen.

<img src="https://raw.githubusercontent.com/zendrones/Horus-Mavlink-Telemetry/master/img/screenshot_x12s_17-12-16_00-26-26.png">
<img src="https://raw.githubusercontent.com/zendrones/Horus-Mavlink-Telemetry/master/img/screenshot_x12s_17-12-16_00-26-38.png">

To invoke the Passthrough Telemetrie follow these steps:

1. you need a serial converter as described here: http://ardupilot.org/copter/docs/common-frsky-passthrough.html
2. Set your SERIAL#_PROTOCOL to 10
3. Copy pass.lua to your Horus SD Card /SCRIPTS/MIXES/
4. Copy the widget folder to /WIDGETS
5. Invoke the background Script in your model settings tab "custom scripts"
6. Go to your telemetrie setup and build a new screen, use the 1x1 layout and deactivate sliders and trim
7. select the "telemetrie" widget.
8. Configure the widget to our needs:

Capacity -- lipo capacity<br>
Cells		 -- lipo cells<br>
Arm		   -- arming switch for Betaflight, not needed with ArduCopter<br>
Mode     -- bf: switch for flightmodes / AP: switch for toggle screens<br>
Setting  -- here you can define which setting to use (line 184)<br>

To configure it basicaly you can use the widget options:<br>
Setting 1 to 3 can be used with betaflight, cleanflight ore any other controllers, models and sensors<br>
Setting 4 is specialy for ArduCopter and contains 3 Screens which can be configured und toggled with a 3-pos switch (Mode source)

Screen 1 shows varius sensors and data<br>
Screen 2 shows Mavlink Messages (12 rows)<br>
Screen 3 shows an artificial horizon


If you like my background image, you can find it in /THEMES/Default/ this is the place to take it. Dont forget to backup your original background.png. 
