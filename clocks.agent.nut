// Clock
// Copyright 2014-18, Tony Smith

// IMPORTS
#require "Rocky.class.nut:2.0.2"

// CONSTANTS
const APP_CODE = "B14E7692-6D05-4AC6-B66A-AB40C98E3D5B";
const MAX_ALARMS = 8;
// If you are NOT using Squinter or a similar tool, replace the following #import statements
// with the contents of the named files (clock_ui.html, silence_img.nut and delete_img.nut)
// Source code for these files here: https://github.com/smittytone/Clock
#import "img_delete.nut"
#import "img_silence.nut"
#import "img_low.nut"
#import "img_high.nut"
// If you are NOT using Squinter or a similar tool, replace the following 
// #import statement with the contents of the named file (clock_ui.html)
const HTML_STRING = @"
#import "clock_ui.html"
";

// MAIN VARIABLES
local prefs = null;
local api = null;
local debug = false;
local stateUpdate = false;
local alarms = [];

// FUNCTIONS
function sendPrefs() {
    // The clock has requested the current settings data, so send it as a table
    device.send("clock.set.prefs", prefs);
}

function encodePrefsForUI() {
    // Responds to the UI's request for the clock's settings
    // with all the clock's settings
    local data = { "mode"        : prefs.hrmode,
                   "bst"         : prefs.bst,
                   "flash"       : prefs.flash,
                   "colon"       : prefs.colon,
                   "bright"      : prefs.brightness,
                   "world"       : { "utc"    : prefs.utc,
                                     "offset" : prefs.offset + 12 },
                   "on"          : prefs.on,
                   "debug"       : debug,
                   "isconnected" : device.isconnected(),
                   "alarms"      : [],
                   // ADDED IN 2.1.0: 
                   // Times to disable clock (eg. over night)
                   "timer"       : { "on"  : { "hour" : prefs.timer.on.hour,  "min"  : prefs.timer.on.min },
                                     "off" : { "hour" : prefs.timer.off.hour, "min" : prefs.timer.off.min },
                                     "isset" : prefs.timer.isset }
                };
    
    // Write in the alarms, if any
    if (alarms.len() > 0) {
        foreach (alarm in alarms) {
            data.alarms.append(alarm);
        }
    }

    return http.jsonencode(data, {"compact":true});
}

function encodePrefsForWatch() {
    // Responds to Controller's request for the clock's settings
    // with a subset of the current device settings
    local data = { "mode"        : prefs.hrmode,
                   "bright"      : prefs.brightness,
                   "world"       : { "utc" : prefs.utc },
                   "on"          : prefs.on,
                   "isconnected" : device.isconnected() };
    return http.jsonencode(data, {"compact":true});
}

function resetPrefs() {
	// Clear the prefs and re-save
    // NOTE This is handy if we change the number of keys in prefs table
	server.save({});

	// Reset 'prefs' values to the defaults
	setPrefs();

    // Resave the prefs
    server.save(prefs);
}

function setPrefs() {
    // Reset 'prefs' values to the defaults
    // The existing table, if there is one, will be garbage-collected
    prefs = {};
    prefs.hrmode <- true;   // true/false for 24/12-hour view
    prefs.bst <- true;      // true for observing BST, false for GMT
    prefs.utc <- false;     // true/false for UTC set/unset
    prefs.offset <- 0;      // GMT offset (-12 to +12)
    prefs.flash <- true;    // true/false for colon flashing or static
    prefs.colon <- true;    // true/false for colon visible or not
    prefs.brightness <- 15; // 0 to 15 for boot-set LED brightness
    prefs.on <- true;       // true/false for whether the clock LED is lit
    prefs.debug <- debug;   // true/false for whether the clock is in debug mode
    prefs.alarms <- [];     // array of alarm times
	debug = false;

    // ADDED IN 2.1.0
    // Add night mode timer support
    prefs.timer <- { "on"  : { "hour" : 7,  "min" : 00 },
                     "off" : { "hour" : 22, "min" : 30 },
                     "isset" : false,
                     "isadv" : false };
}

function reportAPIError(func) {
    // Assemble an API response error message
    return ("Mis-formed parameter sent (" + func +")");
}


// RUNTIME START
// Initialize the clock's preferences - we will read in saved values, if any, next
setPrefs();

// Load in the server-saved preferences table
local savedPrefs = server.load();

if (savedPrefs.len() != 0) {
    // Table is NOT empty so set 'prefs' to the loaded table
    // The existing table, if there is one, will be garbage-collected
    prefs = savedPrefs;

    if (!("debug" in prefs)) {
        // No debug key in prefs, so add it
        prefs.debug <- debug;
        server.save(prefs);
    } else {
        debug = prefs.debug;
    }

    // ADDED IN 2.1.0
    // Add night mode timer support
    if (!("timer" in prefs)) {
        prefs.timer <- { "on"  : { "hour" : 7,  "min" : 00 },
                         "off" : { "hour" : 22, "min" : 30 },
                         "isset" : false,
                         "isadv" : false };
        server.save(prefs);
    }

    if (debug) server.log("Clock settings loaded: " + encodePrefsForUI());
}

// Register device-sent message handlers:
// NOTE This is the signal from the device that it is ready,
//      so all device-sending events should be registered here
device.on("clock.get.prefs", function(dummy) {
	sendPrefs();
});

// Update the list of alarms maintained by the agent
// TODO Persist this data
device.on("update.alarms", function(new) {
    alarms = new;
    stateUpdate = true;
});

// Set up the web API
api = Rocky();

api.get("/", function(context) {
    // A GET request made to root, so return the UI HTML
    context.send(200, format(HTML_STRING, http.agenturl()));
});

/*
    **Clock Endpoints**

    ** Controller Support**
        GET /controller/info -> JSON, app ID, watch support
        GET controller/state -> JSON, subset of settings + connection state

    ** Settings **
        GET  /settings -> JSON, settings + connection state
        POST /settings <- JSON, one or more settings to change.

    ** Actions **
        POST /actions <- JSON, action type, eg. reset, plus binary switches

    ** Status **
        GET /status -> JSON, connection state + should UI force an update
*/

api.get("/status", function(context) {
    // A GET request made to /settings, so return the clock settings
    local response = { "connected" : device.isconnected() };
    if (stateUpdate) response.force <- true;
    context.send(200, http.jsonencode(response, {"compact":true}));
    stateUpdate = false;
});

api.get("/settings", function(context) {
    // A GET request made to /settings, so return the clock settings
    context.send(200, encodePrefsForUI());
});

api.post("/settings", function(context) {
    // A POST request made to /settings, so apply the requested setting
    try {
        if (debug) server.log(context.req.rawbody);
        local data = http.jsondecode(context.req.rawbody);
        local error = null;

        foreach (setting, value in data) {
            // Check for a mode-set message (value arrives as a bool)
            // eg. { "setmode" : true }
            if (setting == "setmode") {
                if (typeof value != "bool") {
                    error = reportAPIError("setmode");
                    break;
                }

                prefs.hrmode = value;
                if (debug) server.log("UI says change mode to " + (prefs.hrmode ? "24 hour" : "12 hour"));
                device.send("clock.set.mode", prefs.hrmode);
            }

            // Check for a set colon show message (value arrives as a bool)
            // eg. { "setcolon" : true }
            if (setting == "setcolon") {
                if (typeof value != "bool") {
                    error = reportAPIError("setcolon");
                    break;
                }

                prefs.colon = value;
                if (debug) server.log("UI says turn colon " + (prefs.colon ? "on" : "off"));
                device.send("clock.set.colon", prefs.colon);
            }

            // Check for a set flash message (value arrives as a bool)
            // eg. { "setflash" : true }
            if (setting == "setflash") {
                if (typeof value != "bool") {
                    error = reportAPIError("setflash");
                    break;
                }

                prefs.flash = value;
                if (debug) server.log("UI says turn colon flashing " + (prefs.flash ? "on" : "off"));
                device.send("clock.set.flash", prefs.flash);
            }

            // Check for set light message (value arrives as a bool)
            // eg. { "setlight" : true }
            if (setting == "setlight") {
                if (typeof value != "bool") {
                    error = reportAPIError("setlight");
                    break;
                }

                prefs.on = value;
                if (debug) server.log("UI says turn display " + (prefs.on ? "on" : "off"));
                device.send("clock.set.light", prefs.on);
            }

            // Check for a BST set/unset message (value arrives as a bool)
            // eg. { "setbst" : true }
            if (setting == "setbst") {
                if (value != "bool") {
                    error = reportAPIError("setbst");
                    break;
                }

                prefs.bst = value;
                if (debug) server.log("UI says turn auto BST observance " + (prefs.bst ? "on" : "off"));
                device.send("clock.set.bst", prefs.bst);
            }

            // Check for a set brightness message (value arrives as a string)
            // eg. { "setbright" : 10 }
            if (setting == "setbright") {
                // Check that the conversion to integer works
                try {
                    value = value.tointeger()
                } catch (err) {
                    error = reportAPIError("setbright");
                    break;
                }

                prefs.brightness = value;
                if (debug) server.log(format("UI says set display brightness to %i", prefs.brightness));
                device.send("clock.set.brightness", prefs.brightness);
            }

            // UPDATED IN 2.1.0
            // Check for set world time message (value arrives as a table)
            // eg. { "setutc" : { "state" : true, "utcval" : -12 } }
            if (setting == "setutc") {
                if (typeof value != "table") {
                    error = reportAPIError("setutc");
                    break;
                }

                if ("state" in value) {
                    if (typeof value.state != "bool") {
                        error = reportAPIError("setutc.state");
                        break;
                    }

                    prefs.utc = value.state;
                }

                if ("offset" in value) {
                    // Check that it can be converted to an integer
                    try {
                        value.offset = value.offset.tointeger();
                    } catch (err) {
                        error = reportAPIError("setutc.offset");
                        break;
                    }

                    prefs.utcoffset = value.offset;
                }

                if (debug) server.log("UI says turn world time mode " + (prefs.utc ? "on" : "off") + ", offset: " + prefs.utcoffset);
                device.send("clock.set.utc", { "state" : prefs.utc, "offset" : prefs.utcoffset });
            }

            // ADDED IN 2.1.0
            // Check for use dimmer time message (value arrives as a bool)
            // eg. { "setnight" : true }
            if (setting == "setnight") {
                if (typeof value != "bool") {
                    error = reportAPIError("setnight");
                    break;
                }

                prefs.timer.isset = value;
                if (debug) server.log("UI says " + (prefs.timer.isset ? "enable" : "disable") + " night mode");
                device.send("clock.set.nightmode", prefs.timer.isset);
            }

            // ADDED IN 2.1.0
            // Check for set dimmer time message (value arrives as a table)
            // eg. { "setdimmer" : { "dimmeron" : { "hour" : 23, "min" : 0 },
            //                       "dimmeroff" : { "hour" : 7, "min" : 0 } }
            if (setting == "setdimmer") {
                if (typeof value != "table") {
                    error = reportAPIError("setdimmer");
                    break;
                }

                local set = 0;
                if ("dimmeron" in value) {
                    if ("hour" in value.dimmeron) {
                        // Check that hour value can be converted to an integer
                        try {
                            value.dimmeron.hour = value.dimmeron.hour.tointeger();
                            set++;
                        } catch (err) {
                            error = reportAPIError("setdimmer.dimmeron.hour");
                            break;
                        }
                    }

                    if ("min" in value.dimmeron) {
                        // Check that minute value can be converted to an integer
                        try {
                            value.dimmeron.min = value.dimmeron.min.tointeger();
                            set++;
                        } catch (err) {
                            error = reportAPIError("setdimmer.dimmeron.min");
                            break;
                        }
                    }
                }

                if ("dimmeroff" in value) {
                    if ("hour" in value.dimmeroff) {
                        // Check that hour value can be converted to an integer
                        try {
                            value.dimmeroff.hour = value.dimmeroff.hour.tointeger();
                            set++;
                        } catch (err) {
                            error = reportAPIError("setdimmer.dimmeroff.hour");
                            break;
                        }
                    }

                    if ("min" in value.dimmeroff) {
                        // Check that minute value can be converted to an integer
                        try {
                            value.dimmeroff.min = value.dimmeroff.min.tointeger();
                            set++;
                        } catch (err) {
                            error = reportAPIError("setdimmer.dimmeroff.min");
                            break;
                        }
                    }
                }

                if (set < 4) {
                    // Not all of the required values were set
                    error = reportAPIError("setdimmer");
                    break;
                }

                prefs.timer.on.hour = value.dimmeron.hour;
                prefs.timer.on.min = value.dimmeron.min;
                prefs.timer.off.hour = value.dimmeroff.hour;
                prefs.timer.off.min = value.dimmeroff.min;

                if (debug) server.log("UI says set night time to start at " + format("%02i", prefs.timer.on.hour) + ":" + format("%02i", prefs.timer.on.min) + " and end at " + format("%02i", prefs.timer.off.hour) + ":" + format("%02i", prefs.timer.off.min));
                device.send("clock.set.nighttime", prefs.timer);
            }

            // Check for alarm update message (value arrives as a table)
            // eg. { "setalarm" : { "action" : "<type>",
            //                      "hour" : 7, "min" : 0, "repeat" : true } }
            if (setting == "setalarm") {
                if (typeof value != "table") {
                    error = reportAPIError("setalarm");
                    break;
                }

                if ("action" in value) {
                    if (value.action == "add") {
                        if (prefs.alarms.len() == MAX_ALARMS) {
                            error = reportAPIError("setalarm") + ": Maximum number of alarms exceeded";
                            break;
                        }

                        local alarm = {};
                        
                        if ("hour" in value) {
                            try {
                                // Check that hour value can be converted to an integer
                                alarm.hour <- value.hour.tointeger();
                            } catch (err) {
                                error = reportAPIError("setalarm.add.hour");
                                break;
                            }
                        }
                        
                        if ("min" in value) {
                            try {
                                // Check that minute value can be converted to an integer
                                alarm.min <- value.min.tointeger();
                            } catch (err) {
                                error = reportAPIError("setalarm.add.min");
                                break;
                            }
                        }

                        if ("repeat" in value) {
                            if (typeof value.repeat != "bool") {
                                error = reportAPIError("setalarm.add.repeat");
                                break;
                            }

                            alarm.repeat <- value.repeat;
                        }

                        if (debug) server.log("UI says set alarm for " + format("%02i", alarm.hour) + ":" + format("%02i", alarm.min) + " (repeat: " + (alarm.repeat ? "yes" : "no") + ")");
                        device.send("clock.set.alarm", alarm);
                        prefs.alarms.append(alarm);
                    } else if (value.action == "delete") {
                        if ("index" in value) {
                            try {
                                // Check that index value can be converted to an integer
                                value.index = value.index.tointeger();
                            } catch (err) {
                                error = reportAPIError("setalarm.delete.index");
                                break;
                            }
                            
                            if (debug) server.log("UI says delete alarm at index " + value.index);
                            device.send("clock.clear.alarm", value.index);
                            prefs.alarms.remove(value.index);
                        } else {
                            error = reportAPIError("setalarm.delete");
                            break;
                        }
                    } else if (value.action == "silence") {
                        if ("index" in value) {
                            try {
                                // Check that index value can be converted to an integer
                                value.index = value.index.tointeger();
                            } catch (err) {
                                error = reportAPIError("setalarm.silence.index");
                                break;
                            }
                            
                            if (debug) server.log("UI says silence alarm at index " + value.index);
                            device.send("clock.stop.alarm", value.index);
                        } else {
                            error = reportAPIError("setalarm.delete");
                            break;
                        }
                    } else {
                        error = reportAPIError("setalarm.action");
                        break;
                    }
                } else {
                    error = reportAPIError("setalarm");
                    break;
                }
            }
        }

        if (error != null) {
            context.send(400, error);
            if (debug) server.error(error);
        } else {
            // Send the updated prefs back to the UI (may not be used)
            local ua = context.getHeader("user-agent");
            local r = ua == "Controller/ClockInterfaceController" ? encodePrefsForWatch() : encodePrefsForUI();
            context.send(200, r);

            // Save the settings changes
            if (server.save(prefs) > 0) server.error("Could not save settings");
        }
    } catch (err) {
        server.error(err);
        context.send(400, "Bad data posted: " + context.req.rawbody);
        return;
    }

    context.send(200, "OK");
});

api.post("/action", function(context) {
    // A POST request made to /action, so perform the requested action
    // These are intended for button-triggered actions
    try {
        local data = http.jsondecode(context.req.rawbody);

        if ("action" in data) {
            if (data.action == "reset") {
                // A RESET message sent
                resetPrefs();
                device.send("clock.set.prefs", prefs);
                server.log("Clock settings reset");
                context.send(200, http.jsonencode({"reset":true}));
                if (server.save(prefs) != 0) server.error("Could not save clock settings after reset");
                return;
            }

            if (data.action == "debug") {
                // A DEBUG message sent
                debug = (data.debug == "1") ? true : false;
                prefs.debug = debug;
                device.send("clock.set.debug", debug);
                server.log("Debug mode " + (debug ? "on" : "off"));
                context.send(200, http.jsonencode({"debug":debug}));
                if (server.save(prefs) > 0) server.error("Could not save debug setting");
                return;
            }

            if (data.action = "world") {
                // A SWITCH WORLD VIEW ON/OFF message sent
                prefs.utc = ! prefs.utc;
                if (debug) server.log("World time switched " + (prefs.utc ? "on" : "off"));
                context.send(200, http.jsonencode({"world":{"utc":prefs.utc}}));
                if (server.save(prefs) > 0) server.error("Could not save debug setting");
                return;
            }
        } else {
            context.send(404, "Missing resource");
        }
    } catch (err) {
        context.send(400, "Bad data posted");
        server.error(err);
        return;
    }
});

// Any call to the endpoint /images is sent the correct PNG data
api.get("/images/([^/]*)", function(context) {
    // Determine which image has been requested and send the appropriate
    // stored data back to the requesting web browser
    local path = context.path;
    local name = path[path.len() - 1];
    local image = DELETE_PNG;
    if (name == "low.png") image = LOW_PNG;
    if (name == "high.png") image = HIGH_PNG;
    if (name == "silence.png") image = SILENCE_PNG;
    
    context.setHeader("Content-Type", "image/png");
    context.send(200, image);
});

// Add Controller support endpoints
api.get("/controller/info", function(context) {
    // GET at /controller/info returns app info for Controller
    local info = { "appcode": APP_CODE,
                   "watchsupported": "true" };  // False for now until Controller updated
    context.send(200, http.jsonencode(info));
});

api.get("/controller/state", function(context) {
    // GET call to /controller/state returns device status
    // Send a relevant subset of the settings as JSON
    context.send(200, encodePrefsForWatch());
});