# Horus-Mavlink-Telemetry
A universal lua script for displaying mavlink values on FrSky Horus OpenTX

This Lua Widget script shows varius Mavlink Data and / or standard sensors data and values on your screen.

<img src="https://raw.githubusercontent.com/zendrones/Horus-Mavlink-Telemetry/master/img/screenshot_x12s_17-12-16_00-26-26.png">
<img src="https://raw.githubusercontent.com/zendrones/Horus-Mavlink-Telemetry/master/img/screenshot_x12s_17-12-16_00-26-38.png">
<img src="https://raw.githubusercontent.com/zendrones/Horus-Mavlink-Telemetry/master/img/screenshot_x12s_17-12-16_00-26-32.png">

To invoke the Passthrough Telemetrie follow these steps:

1. you need a serial converter as described here: http://ardupilot.org/copter/docs/common-frsky-passthrough.html
2. Set your SERIAL#_PROTOCOL to 10
3. Copy pas1.lua and pas2.lua to your Horus SD Card /SCRIPTS/MIXES/
4. Copy the widget folder to /WIDGETS
5. Invoke the background Scripts in your model settings tab "custom scripts"
6. Connect your vehicle with battery or USB Power and go to your models telemetry sensors and add the new sensors
6. Go to your telemetrie setup and build a new screen, use the 1x1 layout and <strong>deactivate sliders and trim</strong>
7. select the "MAVTEL" widget.
8. Configure the widget to our needs:

Cells		 -- lipo cells<br>
Mode     -- switch for toggle screens<br>
Template -- here you can define which setting to use<br>

The widget definition examples should now display the following screens on your Horus:<br>
Screen 1 (switch position 1) shows varius sensors and data<br>
Screen 2 (switch position 2) shows an artificial horizon
Screen 3 (switch position 3) shows varius sensors and data<br>

The "hud" widget needs at least 1/3 cell width and 2x height.<br>
The "vfas" and "ap_batt" widget needs at least 3x cell height because.
The "msg" was removed, there will be an extra widget for that

You can configure your own settings like this:
widgetDefinition = {{"mavtype", "armed", "fm", "timer"},{"ap_batt", 0, 0, "rxbat"},{"ap_volt", "ap_curr", "ap_drawn", "rssi"},{"gps", "ap_alt", "ap_speed", "ap_dist"}}

There is place for up to 16 Values, 4 rows and 4 columns.

If you like my theme background image, you can find it in /THEMES/Default/ this is the place to take it. Dont forget to backup your original background.png. 

For testing the SPort Passthrough, there is a second widget in folder "Passthrough". This script dosn't need the background mixes and is still faster. So i have to deals with less widgets and grafics at one time.

Thanks to some valuable tips, the script now works again. You never stop learning :-)
https://github.com/opentx/opentx/issues/5818
1. Widgets names can have a maximum of 10 characters
2. Variables and functions should not be global in the Lua environment
3. It is best to pass all variables via the create () object


## Known Bugs and issues:
1. hud horizon disapears some time
2. latency to high?
3. Mavlink msg are some times wraped or cutted
4. some times i get the message "Sensors lost". Mix scripts are running with less priority and have only a short run-time of 30ms, execution is not guarantied. So seeking a better solution is on agenda. To avoid this the background Script is splitted in two scripts pas1.lua and pas2.lua but the message still appears.



https://www.facebook.com/zenuavsolutions
https://www.instagram.com/zenuavsolutions
https://www.pinterest.de/zenuavsolutions
https://www.xing.com/xbp/pages/zen-uav-solutions
https://github.com/zenuavsolutions
