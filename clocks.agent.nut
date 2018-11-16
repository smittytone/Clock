// Clock
// Copyright 2014-18, Tony Smith

// IMPORTS
#require "Rocky.class.nut:2.0.1"

// CONSTANTS
// If you are NOT using Squinter or a similar tool, replace the #import statement below
// with the contents of the named file (clock_ui.html)
const DELETE_PNG = "\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x00\x00\x00\x14\x00\x00\x00\x14\x08\x06\x00\x00\x00\x8D\x89\x1D\x0D\x00\x00\x00\x01\x73\x52\x47\x42\x00\xAE\xCE\x1C\xE9\x00\x00\x00\x09\x70\x48\x59\x73\x00\x00\x0B\x13\x00\x00\x0B\x13\x01\x00\x9A\x9C\x18\x00\x00\x03\xA8\x69\x54\x58\x74\x58\x4D\x4C\x3A\x63\x6F\x6D\x2E\x61\x64\x6F\x62\x65\x2E\x78\x6D\x70\x00\x00\x00\x00\x00\x3C\x78\x3A\x78\x6D\x70\x6D\x65\x74\x61\x20\x78\x6D\x6C\x6E\x73\x3A\x78\x3D\x22\x61\x64\x6F\x62\x65\x3A\x6E\x73\x3A\x6D\x65\x74\x61\x2F\x22\x20\x78\x3A\x78\x6D\x70\x74\x6B\x3D\x22\x58\x4D\x50\x20\x43\x6F\x72\x65\x20\x35\x2E\x34\x2E\x30\x22\x3E\x0A\x20\x20\x20\x3C\x72\x64\x66\x3A\x52\x44\x46\x20\x78\x6D\x6C\x6E\x73\x3A\x72\x64\x66\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x77\x77\x77\x2E\x77\x33\x2E\x6F\x72\x67\x2F\x31\x39\x39\x39\x2F\x30\x32\x2F\x32\x32\x2D\x72\x64\x66\x2D\x73\x79\x6E\x74\x61\x78\x2D\x6E\x73\x23\x22\x3E\x0A\x20\x20\x20\x20\x20\x20\x3C\x72\x64\x66\x3A\x44\x65\x73\x63\x72\x69\x70\x74\x69\x6F\x6E\x20\x72\x64\x66\x3A\x61\x62\x6F\x75\x74\x3D\x22\x22\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x78\x6D\x6C\x6E\x73\x3A\x78\x6D\x70\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x6E\x73\x2E\x61\x64\x6F\x62\x65\x2E\x63\x6F\x6D\x2F\x78\x61\x70\x2F\x31\x2E\x30\x2F\x22\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x78\x6D\x6C\x6E\x73\x3A\x74\x69\x66\x66\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x6E\x73\x2E\x61\x64\x6F\x62\x65\x2E\x63\x6F\x6D\x2F\x74\x69\x66\x66\x2F\x31\x2E\x30\x2F\x22\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x20\x78\x6D\x6C\x6E\x73\x3A\x65\x78\x69\x66\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x6E\x73\x2E\x61\x64\x6F\x62\x65\x2E\x63\x6F\x6D\x2F\x65\x78\x69\x66\x2F\x31\x2E\x30\x2F\x22\x3E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x3C\x78\x6D\x70\x3A\x4D\x6F\x64\x69\x66\x79\x44\x61\x74\x65\x3E\x32\x30\x31\x38\x2D\x30\x39\x2D\x31\x33\x54\x31\x37\x3A\x30\x39\x3A\x38\x31\x3C\x2F\x78\x6D\x70\x3A\x4D\x6F\x64\x69\x66\x79\x44\x61\x74\x65\x3E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x3C\x78\x6D\x70\x3A\x43\x72\x65\x61\x74\x6F\x72\x54\x6F\x6F\x6C\x3E\x50\x69\x78\x65\x6C\x6D\x61\x74\x6F\x72\x20\x33\x2E\x37\x2E\x34\x3C\x2F\x78\x6D\x70\x3A\x43\x72\x65\x61\x74\x6F\x72\x54\x6F\x6F\x6C\x3E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x3C\x74\x69\x66\x66\x3A\x4F\x72\x69\x65\x6E\x74\x61\x74\x69\x6F\x6E\x3E\x31\x3C\x2F\x74\x69\x66\x66\x3A\x4F\x72\x69\x65\x6E\x74\x61\x74\x69\x6F\x6E\x3E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x3C\x74\x69\x66\x66\x3A\x43\x6F\x6D\x70\x72\x65\x73\x73\x69\x6F\x6E\x3E\x30\x3C\x2F\x74\x69\x66\x66\x3A\x43\x6F\x6D\x70\x72\x65\x73\x73\x69\x6F\x6E\x3E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x3C\x74\x69\x66\x66\x3A\x52\x65\x73\x6F\x6C\x75\x74\x69\x6F\x6E\x55\x6E\x69\x74\x3E\x32\x3C\x2F\x74\x69\x66\x66\x3A\x52\x65\x73\x6F\x6C\x75\x74\x69\x6F\x6E\x55\x6E\x69\x74\x3E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x3C\x74\x69\x66\x66\x3A\x59\x52\x65\x73\x6F\x6C\x75\x74\x69\x6F\x6E\x3E\x37\x32\x3C\x2F\x74\x69\x66\x66\x3A\x59\x52\x65\x73\x6F\x6C\x75\x74\x69\x6F\x6E\x3E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x3C\x74\x69\x66\x66\x3A\x58\x52\x65\x73\x6F\x6C\x75\x74\x69\x6F\x6E\x3E\x37\x32\x3C\x2F\x74\x69\x66\x66\x3A\x58\x52\x65\x73\x6F\x6C\x75\x74\x69\x6F\x6E\x3E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x3C\x65\x78\x69\x66\x3A\x50\x69\x78\x65\x6C\x58\x44\x69\x6D\x65\x6E\x73\x69\x6F\x6E\x3E\x32\x30\x3C\x2F\x65\x78\x69\x66\x3A\x50\x69\x78\x65\x6C\x58\x44\x69\x6D\x65\x6E\x73\x69\x6F\x6E\x3E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x3C\x65\x78\x69\x66\x3A\x43\x6F\x6C\x6F\x72\x53\x70\x61\x63\x65\x3E\x31\x3C\x2F\x65\x78\x69\x66\x3A\x43\x6F\x6C\x6F\x72\x53\x70\x61\x63\x65\x3E\x0A\x20\x20\x20\x20\x20\x20\x20\x20\x20\x3C\x65\x78\x69\x66\x3A\x50\x69\x78\x65\x6C\x59\x44\x69\x6D\x65\x6E\x73\x69\x6F\x6E\x3E\x32\x30\x3C\x2F\x65\x78\x69\x66\x3A\x50\x69\x78\x65\x6C\x59\x44\x69\x6D\x65\x6E\x73\x69\x6F\x6E\x3E\x0A\x20\x20\x20\x20\x20\x20\x3C\x2F\x72\x64\x66\x3A\x44\x65\x73\x63\x72\x69\x70\x74\x69\x6F\x6E\x3E\x0A\x20\x20\x20\x3C\x2F\x72\x64\x66\x3A\x52\x44\x46\x3E\x0A\x3C\x2F\x78\x3A\x78\x6D\x70\x6D\x65\x74\x61\x3E\x0A\xF5\x77\xCF\x2B\x00\x00\x02\x10\x49\x44\x41\x54\x38\x11\xA5\x55\x31\x4F\x54\x41\x10\xFE\xF6\x01\x16\x84\x0A\x0B\x13\x28\x28\x34\xD0\x19\x12\x94\xD8\x98\xF8\x13\x0E\x08\xB1\x02\xAC\x08\x0D\x39\x28\x0E\x94\x3F\x80\xF1\x12\xB1\xB1\xA0\xD3\x18\x5A\xE0\x17\x10\x2B\x43\x21\x84\x02\x8A\x3B\x8F\x88\x85\x97\x50\x12\xA8\x38\xB8\x61\xBE\xB7\xEF\xED\xEE\x7B\x77\xC4\x80\x93\xEC\xDB\x99\x6F\x66\xBF\x9D\xBD\x9D\x9D\x33\x68\x23\x32\x82\x2E\x5C\xA0\xA0\xAE\x02\x04\xCF\x74\xEE\x4B\xC2\xEA\x30\xF8\xA9\xFA\x36\x7A\xB0\x6D\xF6\xD0\x48\x70\x37\x19\xA7\x25\x8A\x0C\x62\x4C\xD5\xB2\x8E\xC7\x79\x5F\xCE\x3E\x56\xBB\x64\xAA\xD8\x0A\xF1\x28\x35\x04\x88\x64\x08\x1F\xD4\xDE\xD4\xF1\x2F\x32\x2E\x63\xCC\x26\xD7\x70\x2D\x01\x8A\xCB\x30\x26\x13\x94\x2C\x7C\xC7\xAF\x41\xD9\x54\xB0\xE4\x08\x93\x63\x32\x33\x2B\x53\xF3\x40\x77\x0F\xB0\xBE\x9A\x22\xD9\x79\x6E\x05\x38\x3F\x03\x36\x3E\x87\xF8\x78\x7C\x7C\x5E\x80\x12\xD6\x74\x48\x3C\xCA\xCB\xE2\xE4\xCB\x9A\xC5\x52\x1F\xE7\xAF\x9F\x9C\x5B\x18\xEB\x7D\xB5\xF8\x32\xF5\xA8\x93\x01\x28\x72\xB0\xEB\x17\x50\x0B\x49\x43\x32\xFA\xF6\x7F\x84\x84\x42\xAE\x4E\xCD\x99\xE5\xE1\x65\x7E\x02\xF8\xF6\x1D\x18\x78\x62\xB1\x99\x05\x3B\x1B\xFD\xB9\xA7\x8B\x3E\xEE\x4F\x0D\x28\x4E\x7A\xDB\x6A\x05\xA3\xD9\x55\x54\x1F\xCC\x78\x1E\xF5\x67\x49\x33\x4E\x35\x48\x36\xF5\x0A\x38\xFD\x9B\xF7\x54\x79\xDD\x69\xD1\x7A\x27\x03\xB9\x80\x0B\xF3\x72\x3B\x19\x23\xFB\x5C\xFD\xE4\xD7\xC5\xBB\xEF\xEE\xB4\xC0\x20\xD6\x9A\x99\x8B\x23\x61\xDD\x59\xA1\xB2\xB2\x06\xBC\x9E\x0D\x11\xAB\x13\x7B\xF7\xB1\x15\xB7\x48\x3D\x4A\xDE\x66\x36\x80\x64\xE9\x65\xD0\xC3\x63\x86\xC7\x7F\xB3\xD8\x9E\x94\xEF\xBC\xA5\x6C\xD6\x57\x59\x10\x5E\x4E\x7E\x89\xBC\xEC\xB7\x83\x7A\x28\x8C\xF5\x75\x18\x97\x4D\xC4\xAE\xA1\x39\xF0\xA1\x5B\x19\x7E\x91\x6A\xD9\xDB\x6C\x77\x51\x4F\x47\x7D\x2C\x39\x2C\x17\xA0\xBB\x8C\xB9\x9D\x46\x1F\x8A\x1C\xEE\x89\x9C\x54\x6D\x56\x61\x06\xD4\x99\xED\xEF\x8A\xC8\xD1\xBE\xC8\xF3\xDE\x30\x43\x76\xA9\x5B\x9A\x43\x87\xD6\x7B\xA4\xF7\xD5\xB8\x0C\x33\xF0\x7A\xD7\x03\xA0\xD9\x04\xAE\xAF\x2C\x96\x6F\x0E\x44\xE3\x16\x34\x84\xF7\xAA\xDC\xAD\xE3\x28\x99\x3E\x8D\xB7\xFA\x8E\x74\x87\x20\x43\x1A\x14\x1E\x5F\xA7\x7B\x37\x58\xD7\x0F\x63\xB6\xE4\xF3\x3F\x7F\x01\x37\xD6\xCA\x50\x44\xC4\x44\x73\x24\x00\x00\x00\x00\x49\x45\x4E\x44\xAE\x42\x60\x82";
const APP_CODE = "B14E7692-6D05-4AC6-B66A-AB40C98E3D5B";
const MAX_ALARMS = 8;
// If you are NOT using Squinter or a similar tool, replace the following 
// #import statement with the contents of the named file (clock_ui.html)
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
*/

api.get("/settings", function(context) {
    // A GET request made to /settings, so return the clock settings
    context.send(200, encodePrefsForUI());
});

api.post("/settings", function(context) {
    // A POST request made to /settings, so apply the requested setting
    try {
        server.log(context.req.rawbody);
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
                device.send("clock.set.mode", prefs.hrmode);
                if (debug) server.log("Clock mode turned to " + (prefs.hrmode ? "24 hour" : "12 hour"));
            }

            // Check for a BST set/unset message
            if (setting == "bst") {
                if (value != "true" && value != "false") {
                    error = "Mis-formed parameter for bst";
                    break;
                }

                prefs.bst = value == "true" ? true : false;
                device.send("clock.set.bst", prefs.bst);
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
                device.send("clock.set.colon", prefs.colon);
                if (debug) server.log("Clock colon turned " + (prefs.colon ? "on" : "off"));
            }

            // Check for a set colon flash messages
            if (setting == "flash") {
                if (value != "true" && value != "false") {
                    error = "Mis-formed parameter for flash";
                    break;
                }

                prefs.flash = value == "true" ? true : false;
                device.send("clock.set.flash", prefs.flash);
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
                }
                
                device.send("clock.set.utc", (prefs.utc ? prefs.offset : "N"));
                if (debug) server.log("World time turned " + (prefs.utc ? "on" : "off") + ", offset: " + prefs.offset);
            }

            if (setting == "alarm") {
                if (typeof value != "table") {
                    error = "Mis-formed parameter for alarm";
                    break;
                }

                if ("action" in value) {
                    if (value.action == "add") {
                        if (alarms.len() == MAX_ALARMS) {
                            error = "Maximum number of alarms exceeded";
                            break;
                        }

                        local alarm = {};
                        if ("hour" in value) alarm.hour <- value.hour.tointeger();
                        if ("min" in value) alarm.min <- value.min.tointeger();
                        if ("repeat" in value) alarm.repeat <- (value.repeat == "true" ? true : false);
                        
                        device.send("clock.set.alarm", alarm);
                        if (debug) server.log("Alarm set for " + alarm.hour + ":" + alarm.min + " (Repeat: " + (alarm.repeat ? "yes" : "no") + ")");
                    }

                    if (value.action == "delete") {
                        if ("index" in value) device.send("clock.clear.alarm", value.index.tointeger());
                    }
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
    context.setHeader("Content-Type", "image/png");
    local path = context.matches[1];
    //local imageData = ONLINE_PNG;
    //if (path == "off.png") imageData = OFFLINE_PNG;
    context.send(200, DELETE_PNG);
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