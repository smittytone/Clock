// Clock
// Copyright 2014-18, Tony Smith

// IMPORTS
#require "Rocky.class.nut:2.0.1"

// CONSTANTS
// If you are NOT using Squinter or a similar tool, replace the #import statement below
// with the contents of the named file (clock_ui.html)
const HTML_STRING = @"
#import "clock_ui.html"
";

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
    rs = rs + (device.isconnected() ? "c." : "d.");
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

api.get("/info", function(context) {
    local info = {};
    info.app <- "B14E7692-6D05-4AC6-B66A-AB40C98E3D5B";
    info.watchsupported <- "false";
    context.send(200, http.jsonencode(info));
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
                server.log("Clock settings reset");
                if (server.save(prefs) != 0) server.error("Could not save clock settings after reset");
                context.send(200, "Settings reset");
                return
            }

            if (data.action == "debug") {
                // A DEBUG message sent
                debug = (data.debug == "1") ? true : false;
                prefs.debug = debug;
                if (server.save(prefs) > 0) server.error("Could not save debug setting");
                device.send("clock.set.debug", debug);
                server.log("Debug mode " + (debug ? "on" : "off"));
                context.send(200, "OK");
                return
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
