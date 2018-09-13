// Clock
// Copyright 2014-18, Tony Smith

// IMPORTS
#require "Rocky.class.nut:2.0.1"

// CONSTANTS
// If you are NOT using Squinter or a similar tool, replace the #import statement below
// with the contents of the named file (clock_ui.html)
const APP_CODE = "B14E7692-6D05-4AC6-B66A-AB40C98E3D5B";
const MAX_ALARMS = 8;
const HTML_STRING = @"
#import "clock_ui.html"
";

// MAIN VARIABLES
local prefs = null;
local api = null;
local debug = false;
local alarms = [];

// FUNCTIONS
function sendPrefs() {
    // The clock has requested the current settings data, so send it as a table
    device.send("clock.set.prefs", prefs);
}
/*
function encodePrefs() {
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
    rs = rs + (device.isconnected() ? "c." : "d.");
    rs = rs + (debug ? "1" : "0");
    return rs;
}
*/
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
                   "alarms"      : [] };
    
    if (alarms.len() > 0) {
        foreach (alarm in alarms) {
            data.alarms.append(alarm);
        }
    }

    return http.jsonencode(data);
}

function encodePrefsForWatch() {
    // Responds to Controller's request for the clock's settings
    // with a subset of the current device settings
    local data = { "mode"        : prefs.hrmode,
                   "bright"      : prefs.brightness,
                   "world"       : { "utc" : prefs.utc },
                   "on"          : prefs.on,
                   "isconnected" : device.isconnected() };
    return http.jsonencode(data);
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
    prefs.brightness <- 15; // 1 to 15 for boot-set LED brightness
    prefs.on <- true;       // true/false for whether the clock LED is lit
    prefs.debug <- debug;   // true/false for whether the clock is in debug mode
    prefs.alarms <- [];     // array of alarm times
	debug = false;
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
    context.send(200, encodePrefsForUI());
});

api.post("/settings", function(context) {
    // A POST request made to /settings, so apply the requested setting
    try {
        local data = http.jsondecode(context.req.rawbody);
        local error = null;

        foreach (setting, value in data) {

            // Check for a mode-set message
            if (setting == "mode") {
                if (value != "true" && value != "false") {
                    error = "Mis-formed parameter for mode";
                    break;
                }

                prefs.hrmode = value == "true" ? true : false;
                device.send("clock.switch.mode", prefs.hrmode);
                if (debug) server.log("Clock mode turned to " + (prefs.hrmode ? "24 hour" : "12 hour"));
            }

            // Check for a BST set/unset message
            if (setting == "bst") {
                if (value != "true" && value != "false") {
                    error = "Mis-formed parameter for bst";
                    break;
                }

                prefs.bst = value == "true" ? true : false;
                device.send("clock.switch.bst", prefs.bst);
                if (debug) server.log("Clock bst observance turned " + (prefs.bst ? "on" : "off"));
            }

            // Check for a set brightness message
            if (setting == "bright") {
                try {
                    value = value.tointeger()
                } catch (err) {
                    error = "Mis-formed parameter for bright";
                    break;
                }

                prefs.brightness = value;
                device.send("clock.set.brightness", prefs.brightness);
                if (debug) server.log(format("Brightness set to %i", prefs.brightness));
            }

            // Check for a set colon show message
            if (setting == "colon") {
                if (value != "true" && value != "false") {
                    error = "Mis-formed parameter for colon";
                    break;
                }

                prefs.colon = value == "true" ? true : false;
                device.send("clock.switch.colon", prefs.colon);
                if (debug) server.log("Clock colon turned " + (prefs.colon ? "on" : "off"));
            }

            // Check for a set colon flash messages
            if (setting == "flash") {
                if (value != "true" && value != "false") {
                    error = "Mis-formed parameter for flash";
                    break;
                }

                prefs.flash = value == "true" ? true : false;
                device.send("clock.switch.flash", prefs.flash);
                if (debug) server.log("Clock colon flash turned " + (prefs.flash ? "on" : "off"));
            }

            // Check for set display on/off message 
            if (setting == "on") {
                if (value != "true" && value != "false") {
                    error = "Mis-formed parameter for on";
                    break;
                }

                prefs.on = value == "true" ? true : false;
                device.send("clock.set.light", prefs.on);
                if (debug) server.log("Clock display turned " + (prefs.on ? "on" : "off"));
            }

            // Check for set/unset world time messages
            if (setting == "world") {
                if (typeof value != "table") {
                    error = "Mis-formed parameter for world";
                    break;
                }

                if ("utc" in value) {
                    if (value.utc != "true" && value != "false") {
                        error = "Mis-formed parameter for world.utc";
                        break;
                    }
                }

                prefs.utc = value.utc == "true" ? true : false;

                if ("offset" in value) {
                    try {
                        value.offset = value.offset.tointeger();
                    } catch (err) {
                        error = "Mis-formed parameter for world.offset";
                        break;
                    }

                    prefs.offset = value.offset - 12;
                    device.send("clock.set.utc", prefs.offset);
                }

                device.send("clock.set.light", prefs.on);
                if (debug) server.log("World time turned " + (prefs.utc ? "on" : "off") + ", offset: " + prefs.offset);
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
        context.send(400, "Bad data posted");
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

api.get("/alarms", function(context) {
    // A GET request made to /alarms requesting a list of alarms
    local alarmList = {};
    alarmList.alarms <- [];
    
    if (alarms.len() > 0) {
        foreach (alarm in alarms) {
            local a = {};
            a.hour <- alarm.hour.tostring();
            a.minute <- alarm.mins.tostring();
            a.repeat <- alarm.repeat;
            alarmList.alarms.append(a);
        }
    }

    context.send(200, http.jsonencode(alarmList));
});

api.post("/alarms", function(context) {
    // A POST request made to /alarms setting an alarm
    if (alarms.len() == MAX_ALARMS) {
        context.send(400, "Maximum number of alarms exceeded");
        return;
    }

    try {
        local data = http.jsondecode(context.req.rawbody);
        local alarm = {};
        
        if ("hour" in data) alarm.hour <- data.hour.tointeger();
        if ("minute" in data) alarm.mins <- data.minute.tointeger();
        if ("repeat" in data) alarm.repeat <- (data.repeat == "true" ? true : false);
        if (debug) server.log("Alarm set for " + data.hour + ":" + data.minute + " (Repeat: " + (alarm.repeat ? "yes" : "no") + ")");
        
        device.send("clock.set.alarm", alarm);
        context.send(200, "Alarm set");
    } catch (err) {
        context.send(400, "Bad data posted");
        server.error(err);
    }
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