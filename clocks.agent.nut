// Clock
// Copyright 2014-17, Tony Smith

// IMPORTS

#require "Rocky.class.nut:2.0.0"

// CONSTANTS

const HTML_STRING = @"<!DOCTYPE html><html lang='en-US'><meta charset='UTF-8'>
<html>
    <head>
        <title>cløck</title>
        <link rel='stylesheet' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css'>
        <link href='https://fonts.googleapis.com/css?family=Michroma' rel='stylesheet'>
        <link rel='apple-touch-icon' href='https://smittytone.github.io/images/ati-clock.png'>
        <link rel='shortcut icon' href='https://smittytone.github.io/images/ico-clock.ico' />
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <style>
            .center { margin-left: auto; margin-right: auto; margin-bottom: auto; margin-top: auto; }
            .error-message {color: white}
            .showhide {cursor: pointer}
            body {background-color: #6BA6D7;}
            p {color: white; font-family: Michroma, sans-serif; font-size:0.9em}
            h2 {color: white; font-family: Michroma, sans-serif; font-weight:bold}
            h4 {color: white; font-family: Michroma, sans-serif}
            td {color: white; font-family: Michroma, sans-serif}
            hr {border-color: white}
        </style>
    </head>
    <body>
        <div class='container' style='padding: 20px;'>
            <div style='border: 2px solid white'>
                <h2 align='center'>CLØCK</h2>
                <p align='center'>Your Digital Clock</p>
                <p align='center' class='clock-status'><i><span>This cløck is online</span></i><br>&nbsp;</p>
                <div class='settings-area' align='center'>
                    <table width='100%%'>
                        <tr>
                            <td width='20%%'>&nbsp;</td>
                            <td width='60%%'>
                                <h4 align='center'>Time Settings</h4>
                                <div class='mode-checkbox' style='color:white;font-family:Michroma, sans-serif'>
                                    <small><input type='checkbox' name='mode' id='mode' value='mode'> 24-Hour Mode (Switch off for AM/PM)</small>
                                </div>
                                <div class='mode-checkbox' style='color:white;font-family:Michroma, sans-serif'>
                                    <small><input type='checkbox' name='bst' id='bst' value='bst'> Apply Daylight Savings Time Automatically</small>
                                </div>
                                <div class='utc-controls'>
                                    <div class='utc-checkbox' style='color:white;font-family:Michroma, sans-serif'>
                                        <small><input type='checkbox' name='utc' id='utc' value='utc'> Show World Time</small>
                                    </div>
                                    <br>
                                    <div class='utc-slider'>
                                        <input type='range' name='utcs' id='utcs' value='0' min='0' max='24'>
                                        <table width='100%%'><tr><td width='30%%' align='left'><small>-12</small></td><td width='40%%' align='center'><small>0</small></td><td width='30%%' align='right'><small>+12</small></td></tr></table>
                                        <p class='utc-status' align='right'>Offset from local time: <span></span> hours</p>
                                    </div>
                                </div>
                                <hr>
                                <h4 align='center'>Display Settings</h4>
                                <div class='slider'>
                                    <p>&nbsp;<br>Brightness</p>
                                    <input type='range' name='brightness' id='brightness' value='15' min='1' max='15'>
                                    <table width='100%%'><tr><td width='50%%' align='left'><small>Low</small></td><td width='50%%' align='right'><small>High</small></td></tr></table>
                                    <p class='brightness-status' align='right'>Current: <span></span></p>
                                </div>
                                <div class='seconds-checkbox' style='color:white;font-family:Michroma, sans-serif'>
                                    <small><input type='checkbox' name='seconds' id='seconds' value='seconds'> Show Seconds Indicator</small>
                                </div>
                                <div class='flash-checkbox' style='color:white;font-family:Michroma, sans-serif'>
                                    <small><input type='checkbox' name='flash' id='flash' value='seconds'> Flash Seconds Indicator</small>
                                </div>
                                <br>
                                <div class='onoff-button' align='center'>
                                    <button type='submit' id='onoff' style='height:32px;width:200px;color:dimGrey;weight:bold'>Turn off Display</button>
                                </div>
                                <hr>
                                <div class='advancedsettings'>
                                    <h4 class='showhide' align='center'>Click for Advanced Settings</h4>
                                    <div class='advanced' align='center'>
                                        <br>
                                        <div class='debug-checkbox'>
                                            <small><input type='checkbox' name='debug' id='debug' value='debug'> Debug Mode</small>
                                        </div>
                                        <br>
                                        <div class='reset-button' align='center'>
                                            <button type='submit' id='reset' style='height:32px;width:200px;color:dimGrey;weight:bold'>Reset Cløck</button>
                                        </div>
                                    </div>
                                </div>
                                <hr>
                            </td>
                            <td width='20%%'>&nbsp;</td>
                        </tr>
                    </table>
                </div>
                <p class='text-center'><small>CLØCK &copy; 2014-17 Black Pyramid (Time)</small><br>&nbsp;<br><a href='https://github.com/smittytone/clock'><img src='https://smittytone.github.io/images/rassilon.png' width='32' height='32'></a></p>
            </div>
        </div>

        <script src='https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js'></script>
        <script>
            $('.advanced').hide();

            // Variables
            var agenturl = '%s';
            var displayon = true;
            var stateflag = false;

            // Get initial readings
            getState(updateReadout);

            // Set UI click actions: Checkboxes
            $('#mode').click(setmode);
            $('#bst').click(setbst);
            $('#seconds').click(setcolon);
            $('#flash').click(setflash);
            $('#utc').click(setutc);
            $('#debug').click(setdebug);

            // Buttons
            $('.reset-button button').click(reset);
            $('.onoff-button button').click(setlight);

            // Brightness Slider
            var slider = document.getElementById('brightness');
            slider.addEventListener('mouseup', updateSlider);
            slider.addEventListener('touchend', updateSlider);
            $('.brightness-status span').text(slider.value);

            // UTC Slider
            slider = document.getElementById('utcs');
            slider.addEventListener('mouseup', updateutc);
            slider.addEventListener('touchend', updateutc);
            $('.utc-status span').text(slider.value - 12);

            $('.showhide').click(function(){
                $('.advanced').toggle();
            });

            // Functions
            function updateSlider() {
                $('.brightness-status span').text($('#brightness').val());
                setbright();
            }

            function updateutc() {
                var u = $('#utcs').val();
                $('.utc-status span').text(u - 12);
                if (document.getElementById('utc').checked == true) {
                    setutc();
                }
            }

            function updateReadout(data) {
                var s = data.split('.');
                document.getElementById('mode').checked = (s[0] == '1') ? true : false;
                document.getElementById('bst').checked = (s[1] == '1') ? true : false;
                document.getElementById('seconds').checked = (s[3] == '1') ? true : false;
                document.getElementById('flash').checked = (s[2] == '1') ? true : false;
                document.getElementById('utc').checked = (s[5] == '1') ? true : false;
                document.getElementById('debug').checked = (s[9] == '1') ? true : false;
                var u = parseInt(s[6]);
                $('.utc-status span').text(u - 12);
                $('#utcs').val(u);
                console.log(u);

                $('.onoff-button button').text((s[7] == '1') ? 'Turn off Display' : 'Turn on Display');
                displayon = (s[7] == '1');

                var b = parseInt(s[4]);
                $('.brightness-status span').text(b);
                $('#brightness').val(b);

                updateState(s[8]);

                // Auto-reload data in 120 seconds
                if (!stateflag) {
                    checkState();
                    stateflag = true;
                }
            }

            function updateState(s) {
                if (s == 'd') {
                    $('.clock-status span').text('This cløck is offline');
                } else {
                    $('.clock-status span').text('This cløck is online');
                }
            }

            function getState(callback) {
                // Request the current data
                $.ajax({
                    url : agenturl + '/settings',
                    type: 'GET',
                    success : function(response) {
                        if (callback) {
                            callback(response);
                        }
                    },
                    error : function(xhr, textStatus, error) {
                        if (error) {
                            $('.clock-status span').text(error);
                        }
                    }
                });
            }

            function checkState() {
                $.ajax({
                    url : agenturl + '/state',
                    type: 'GET',
                    success : function(response) {
                        updateState(response)
                        setTimeout(checkState, 120000);
                    },
                    error : function(xhr, textStatus, error) {
                        if (error) {
                            $('.clock-status span').text(error);
                        }
                    }
                });
            }

            function setmode() {
                var d = { 'setmode' : ((document.getElementById('mode').checked == true) ? '1' : '0') };
                sendstate(d);
            }

            function setbst() {
                var d = { 'setbst' : ((document.getElementById('bst').checked == true) ? '1' : '0') };
                sendstate(d);
            }

            function setcolon() {
                var d = { 'setcolon' : ((document.getElementById('seconds').checked == true) ? '1' : '0') };
                sendstate(d);
            }

            function setflash() {
                var d = { 'setflash' : ((document.getElementById('flash').checked == true) ? '1' : '0') };
                sendstate(d);
            }

            function setbright() {
                var d = { 'setbright' : ($('#brightness').val()) };
                sendstate(d);
            }

            function setlight() {
                displayon = !displayon;
                $('.onoff-button button').text(displayon ? 'Turn off Display' : 'Turn on Display');
                var s = (displayon ? '1' : '0');
                var d = { 'setlight' :  s };
                sendstate(d);
            }

            function setutc() {
                var d = { 'setutc' : ((document.getElementById('utc').checked == true) ? '1' : '0'), 'utcval' : $('#utcs').val() };
                sendstate(d);
            }

            function sendstate(data) {
                $.ajax({
                    url : agenturl + '/settings',
                    type: 'POST',
                    data: JSON.stringify(data),
                    success: function() {
                        getState(updateReadout);
                    },
                    error : function(xhr, textStatus, error) {
                        if (error) {
                            $('.clock-status span').text(error);
                        }
                    }
                });
            }

            function reset() {
                // Trigger a settings reset
                $.ajax({
                    url : agenturl + '/action',
                    type: 'POST',
                    data: JSON.stringify({ 'action' : 'reset' }),
                    success : function(response) {
                        getState(updateReadout);
                    }
                });
            }

            function setdebug() {
                // Tell the device to enter or leave debug mode
                var d = (document.getElementById('debug').checked == true) ? '1' : '0';
                $.ajax({
                    url : agenturl + '/action',
                    type: 'POST',
                    data: JSON.stringify({ 'action' : 'debug', 'debug' :  d}),
                    error : function(xhr, textStatus, error) {
                        if (error) {
                            $('.clock-status span').text(error);
                        }
                    }
                });
            }

            function reboot() {
                // Trigger a device restart
                $.ajax({
                    url : agenturl + '/action',
                    type: 'POST',
                    data: JSON.stringify({ 'action' : 'reboot' }),
                    success : function(response) {
                        getState(updateReadout);
                    },
                    error : function(xhr, textStatus, error) {
                        if (error) {
                            $('.clock-status span').text(error);
                        }
                    }
                });
            }
        </script>
    </body>
</html>";

// MAIN VARIABLES

local prefs = null;
local api = null;
local debug = false;

// FUNCTIONS

function sendPrefs() {
    // The clock has requested the current settings data, so send it as a table
    device.send("clock.set.prefs", prefs);
}

function appResponse() {
    // Responds to the app's request for the clock's set-up data
    // Generates a string in the form:
    //    1.1.1.1.01.1.01.1.d.1
    // for the values
    //    0. mode
    //    1. bst state
    //    2. colon flash
    //    3. colon state
    //    4. brightness
    //    5. utc state
    //    6. utc offset (0-24 -> -12 to 12)
    //    7. display state
    //    8. connection status
    //    9. debug status
    //
    // UTC offset is the value for the app's control, ie. 0 to 24
    // (mapping in device code to offset values of +12 to -12)
    // .d is ONLY added if the agent detects the device is not
    // connected when this method is called

    local rs = "0.";
    if (prefs.hrmode == true) rs = "1.";
    rs = rs + (prefs.bst ? "1." : "0.");
    rs = rs + (prefs.flash ? "1." : "0.");
    rs = rs + (prefs.colon ? "1." : "0.");
    rs = rs + prefs.brightness.tostring() + ".";
    rs = rs + (prefs.utc ? "1." : "0.");
    local o = prefs.offset + 12;
    rs = rs + o.tostring() + ".";
    rs = rs + (prefs.on ? "1." : "0.");
    rs = rs + (device.isconnected() ? "d." : "c.");
    rs = rs + (debug ? "1" : "0");
    return rs;
}

function resetToDefaults() {
	// Clear the prefs and re-save
    // NOTE This is handy if we change the number of keys in prefs table
	server.save({});

	// Reset 'prefs' values to the defaults
	prefs.hrmode = true;
	prefs.bst = true;
	prefs.utc = false;
	prefs.offset = 0;
	prefs.colon = true;
	prefs.flash = true;
	prefs.brightness = 15;
	prefs.on = true;
	prefs.debug = false;
	prefs.alarms = [];
	debug = false;

    // Resave the prefs
    server.save(prefs);
}

// START

// Cache the clock preferences
prefs = {};
prefs.hrmode <- true;   // true/false for 24/12-hour view
prefs.bst <- true;      // true for observing BST, false for GMT
prefs.utc <- false;     // true/false for UTC set/unset
prefs.offset <- 0;      // GMT offset (-12 to +12)
prefs.flash <- true;    // true/false for colon flashing or static
prefs.colon <- true;    // true/false for colon visible or not
prefs.brightness <- 15; // 1 to 15 for boot-set LED brightness
prefs.on <- true;       // true/false for whether the clock LED is lit
prefs.debug <- debug;   // true/false for whether the clock is in debug mode
prefs.alarms <- [];     // array of alarm times

// Load in the server-saved preferences table
local savedPrefs = server.load();

if (savedPrefs.len() != 0) {
    // Table is NOT empty so set 'prefs' to the loaded table
    prefs = savedPrefs;

    if (!("debug" in prefs)) {
        // No debug key in prefs, so add it
        prefs.debug <- debug;
        server.save(prefs);
    } else {
        debug = prefs.debug;
    }

    if (debug) server.log("Clock settings loaded: " + appResponse());
}

// Register device-sent message handlers:
// NOTE This is the signal from the device that it is ready,
// so all device-sending events should be registered here
device.on("clock.get.prefs", function(dummy) {
	sendPrefs();
});

// Set up the web API
api = Rocky();

api.get("/", function(context) {
    // A GET request made to root, so return the UI HTML
    context.send(200, format(HTML_STRING, http.agenturl()));
});

api.get("/state", function(context) {
    // A GET request made to /state, so return clock's connection state
    local a = (device.isconnected() ? "c" : "d");
    context.send(200, a);
});

api.get("/settings", function(context) {
    // A GET request made to /settings, so return the clock settings
    context.send(200, appResponse());
});

api.post("/settings", function(context) {
    // A POST request made to /settings, so apply the requested setting
    try {
        local data = http.jsondecode(context.req.rawbody);

        // Check for a mode-set message
        if ("setmode" in data) {
            if (data.setmode == "1") {
                prefs.hrmode = true;
            } else if (data.setmode == "0") {
                prefs.hrmode = false;
            } else {
                if (debug) server.error("Mis-formed parameter to setmode");
                context.send(400, "Mis-formed parameter sent");
                return;
            }

            if (server.save(prefs) > 0) server.error("Could not save mode setting");
            if (debug) server.log("Clock mode turned to " + (prefs.hrmode ? "24 hour" : "12 hour"));
            device.send("clock.switch.mode", prefs.hrmode);
        }

        // Check for a BST set/unset message
        if ("setbst" in data) {
            if (data.setbst == "1") {
                prefs.bst = true;
            } else if (data.setbst == "0") {
                prefs.bst = false;
            }  else {
                if (debug) server.error("Mis-formed parameter to setbst");
                context.send(400, "Mis-formed parameter sent");
                return;
            }

            if (server.save(prefs) > 0) server.error("Could not save BST/GMT setting");
            if (debug) server.log("Clock bst observance turned " + (prefs.bst ? "on" : "off"));
            device.send("clock.switch.bst", prefs.bst);
        }

        // Check for a set brightness message
        if ("setbright" in data) {
            prefs.brightness = data.setbright.tointeger();
            if (server.save(prefs) != 0) server.error("Could not save brightness setting");
            if (debug) server.log(format("Brightness set to %i", prefs.brightness));
            device.send("clock.set.brightness", prefs.brightness);
        }

        // Check for a set flash message
        if ("setflash" in data) {
            if (data.setflash == "1") {
                prefs.flash = true;
            } else if (data.setflash == "0") {
                prefs.flash = false;
            } else {
                if (debug) server.error("Mis-formed parameter to setflash");
                context.send(400, "Mis-formed parameter sent");
                return;
            }

            if (server.save(prefs) > 0) server.error("Could not save colon flash setting");
            if (debug) server.log("Clock colon flash turned " + (prefs.flash ? "on" : "off"));
            device.send("clock.switch.flash", prefs.flash);
        }

        // Check for a set colon show message
        if ("setcolon" in data) {
            if (data.setcolon == "1") {
                prefs.colon = true;
            } else if (data.setcolon == "0") {
                prefs.colon = false;
            } else {
                if (debug) server.error("Attempt to pass an mis-formed parameter to setcolon");
                context.send(400, "Mis-formed parameter sent");
                return;
            }

            if (server.save(prefs) > 0) server.error("Could not save colon visibility setting");
            if (debug) server.log("Clock colon turned " + (prefs.colon ? "on" : "off"));
            device.send("clock.switch.colon", prefs.colon);
        }

        // Check for set light message
        if ("setlight" in data) {
            if (data.setlight == "1") {
                prefs.on = true;
            } else if (data.setlight == "0") {
                prefs.on = false;
            } else {
                if (debug) server.error("Attempt to pass an mis-formed parameter to setlight");
                contex.send(400, "Mis-formed parameter sent");
                return;
            }

            if (server.save(prefs) > 0) server.error("Could not save display light setting");
            if (debug) server.log("Clock display turned " + (prefs.on ? "on" : "off"));
            device.send("clock.set.light", prefs.on);
        }

        if ("setutc" in data) {
            if (data.setutc == "0") {
                prefs.utc = false;
                device.send("clock.set.utc", "N");
            } else if (data.setutc == "1") {
                prefs.utc = true;
                if ("utcval" in data) {
                    prefs.offset = data.utcval.tointeger() - 12;
                    device.send("clock.set.utc", prefs.offset);
                }
            } else {
                if (debug) server.error("Attempt to pass an mis-formed parameter to setutc");
                contex.send(400, "Mis-formed parameter sent");
                return;
            }

            if (server.save(prefs) > 0) server.error("Could not save world time setting");
            if (debug) server.log("World time turned " + (prefs.utc ? "on" : "off") + ", offset: " + prefs.offset);
        }

        context.send(200, "OK");
    } catch (err) {
        server.error(err);
        context.send(400, "Bad data posted");
        return;
    }

    context.send(200, "OK");
});

api.post("/action", function(context) {
    // A POST request made to /action, so perform the requested action
    try {
        local data = http.jsondecode(context.req.rawbody);

        if ("action" in data) {
            if (data.action == "reset") {
                // A RESET message sent
                resetToDefaults();
                device.send("clock.set.prefs", prefs);
                if (debug) server.log("Clock settings reset");
                if (server.save(prefs) != 0) server.error("Could not save clock settings after reset");
            }

            if (data.action == "debug") {
                // A DEBUG message sent
                debug = (data.debug == "1") ? true : false;
                prefs.debug = debug;
                if (server.save(prefs) > 0) server.error("Could not save debug setting");
                device.send("clock.set.debug", debug);
                server.log("Debug mode " + (debug ? "on" : "off"));
            }
        }

        context.send(200, "OK");
    } catch (err) {
        context.send(400, "Bad data posted");
        server.error(err);
        return;
    }
});
