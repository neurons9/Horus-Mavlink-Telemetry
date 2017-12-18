# Horus-Mavlink-Telemetry
A universal lua script for displaying mavlink values on FrSky Horus OpenTX

This Lua Widget script shows varius Mavlink Data and / or standard sensors data and values on your screen.

<img src="https://raw.githubusercontent.com/zendrones/Horus-Mavlink-Telemetry/master/img/screenshot_x12s_17-12-16_00-26-26.png">
<img src="https://raw.githubusercontent.com/zendrones/Horus-Mavlink-Telemetry/master/img/screenshot_x12s_17-12-16_00-26-32.png">
<img src="https://raw.githubusercontent.com/zendrones/Horus-Mavlink-Telemetry/master/img/screenshot_x12s_17-12-16_00-26-38.png">

To invoke the Passthrough Telemetrie follow these steps:

1. you need a serial converter as described here: http://ardupilot.org/copter/docs/common-frsky-passthrough.html
2. Set your SERIAL#_PROTOCOL to 10
3. Copy pass.lua to your Horus SD Card /SCRIPTS/MIXES/
4. Copy the widget folder to /WIDGETS
5. Invoke the background Script in your model settings tab "custom scripts"
6. Connect your vehicle with battery or USB Power and go to your models telemetry sensors and add the new sensors
6. Go to your telemetrie setup and build a new screen, use the 1x1 layout and deactivate sliders and trim
7. select the "telemetrie" widget.
8. Configure the widget to our needs:

Cells		 -- lipo cells<br>
Mode     -- switch for toggle screens<br>
Setting  -- here you can define which setting to use<br>

The widget definition examples should now display the following screens on your Horus:<br>
Screen 1 (switch position 1) shows varius sensors and data<br>
Screen 2 (switch position 2) shows Mavlink Messages (12 rows)<br>
Screen 3 (switch position 3) shows an artificial horizon


The "hud" widget needs at least 1/3 cell width and 2x height.<br>
The "cfas" and "batt_ap" widget needs at least 3x cell height because.

If you like my theme background image, you can find it in /THEMES/Default/ this is the place to take it. Dont forget to backup your original background.png. 


# Known Bugs and issues:
1. hud horizon disapears some time
2. latency to high?
3. Mavlink msg are some times wraped or cutted
4. ...


