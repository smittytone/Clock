// Clock
// Copyright 2014-20, Tony Smith

// ********** IMPORTS **********
#require "Rocky.agent.lib.nut:3.0.0"
#require "Twilio.class.nut:1.0"

// If you are NOT using Squinter or a similar tool, replace the following #import statement(s)
// with the contents of the named file(s):
#import "../generic/simpleslack.nut"        // Source: https://github.com/smittytone/generic
#import "../generic/crashReporter.nut"      // Source: https://github.com/smittytone/generic
#import "img_delete.nut"                    // Source: https://github.com/smittytone/Clock
#import "img_silence.nut"                   // Source: https://github.com/smittytone/Clock
#import "img_low.nut"                       // Source: https://github.com/smittytone/Clock
#import "img_mid.nut"                       // Source: https://github.com/smittytone/Clock
#import "img_high.nut"                      // Source: https://github.com/smittytone/Clock
const HTML_STRING = @"
#import "clock_ui.html"
";                                          // Source: https://github.com/smittytone/Clock


// ********** CONSTANTS **********
const APP_CODE = "B14E7692-6D05-4AC6-B66A-AB40C98E3D5B";
const MAX_ALARMS = 8;
const ALARM_DURATION = 2;


// ********** MAIN VARIABLES **********
local settings = null;
local api = null;
local stateChange = false;
local slack = null;

// ADDED IN 2.2.0
// Use the following lines to enable Twilio support,
// which requires a Twilio account (https://www.twilio.com/)
// Assign an instance of the Twilio class (https://developer.electricimp.com/libraries/webservices/twilio) to 'twilio'
// Assign an phone number as a string to 'target'
local twilio = null;
local target = null;


// ********** FUNCTIONS **********
// NOTE These primarily centre around device settings:
//      sending them to the newly booted device, sending them to
//      controllers, eg. Apple Watch and the web UI

function sendPrefsToDevice(ignore) {
    // The clock has requested the current settings data, so send it as a table
    if (settings.debug) server.log("Sending stored preferences to the Clock");
    device.send("clock.set.prefs", settings);
}

function encodePrefsForUI() {
    // Responds to the UI's request for the clock's settings
    // by sending all the clock's settings plus its connected state
    local data = { "mode"        : settings.hrmode,
                   "bst"         : settings.bst,
                   "flash"       : settings.flash,
                   "colon"       : settings.colon,
                   // Web UI expects brightness in range 1-16, so add 1 here (app range: 0 to 15)
                   "bright"      : settings.brightness + 1,
                   "world"       : { "utc"    : settings.utc,
                   // Web UI expects offset in range 0-24, so add 12 here (app range: -12 to +12)
                                     "offset" : settings.utcoffset + 12 },
                   "on"          : settings.on,
                   "debug"       : settings.debug,
                   "isconnected" : device.isconnected(),
                   // ADDED IN 2.1.0:
                   // Times to disable clock (eg. over night)
                   "timer"       : { "on"  : { "hour" : settings.timer.on.hour,  "min"  : settings.timer.on.min },
                                     "off" : { "hour" : settings.timer.off.hour, "min" : settings.timer.off.min },
                                     "isset" : settings.timer.isset },
                   "alarms"      : settings.alarms
                };

    return http.jsonencode(data, {"compact":true});
}

function encodePrefsForWatch() {
    // Responds to Controller's request for the clock's settings
    // with a subset of the current device settings
    local data = { "mode"        : settings.hrmode,
                   "bright"      : settings.brightness,
                   "world"       : { "utc" : settings.utc },
                   "on"          : settings.on,
                   "isconnected" : device.isconnected() };
    return http.jsonencode(data, {"compact":true});
}

function resetPrefs() {
	// Clear the prefs and re-save
    // NOTE This is handy if we change the number of keys in prefs table
	server.save({});

	// Reset 'prefs' values to the defaults
	initialisePrefs();

    // Resave the prefs
    server.save(settings);
}

function initialisePrefs() {
    // Reset 'settings' values to the defaults
    // The existing table, if there is one, will be garbage-collected
    settings = {};
    settings.hrmode <- true;   // true/false for 24/12-hour view
    settings.bst <- true;      // true for observing BST, false for GMT
    settings.utc <- false;     // true/false for UTC set/unset
    settings.utcoffset <- 0;   // GMT offset (-12 to +12)
    settings.flash <- true;    // true/false for colon flashing or static
    settings.colon <- true;    // true/false for colon visible or not
    settings.brightness <- 7;  // 0 to 15 for boot-set LED brightness
    settings.on <- true;       // true/false for whether the clock LED is lit
    settings.debug <- false;   // true/false for whether the clock is in debug mode
    settings.alarms <- [];     // array of alarm times

    // ADDED IN 2.1.0
    // Times to temporarily disable clock display (eg. over night)
    settings.timer <- { "on"  : { "hour" : 7,  "min" : 00 },
                        "off" : { "hour" : 22, "min" : 30 },
                        "isset" : false,
                        "isadv" : false };
}

function reportAPIError(func) {
    // Assemble an API response error message
    return ("Mis-formed parameter sent (" + func +")");
}

function debugAPI(context, next) {
    // Display a UI API activity report
    if (settings.debug) {
        server.log("API received a request at " + time() + ": " + context.req.method.toupper() + " @ " + context.req.path.tolower());
        if (context.req.rawbody.len() > 0) server.log("Request body: " + context.req.rawbody.tolower());
    }

    // Invoke the next middleware
    next();
}

// ********** RUNTIME START **********

// ADDED IN 2.1.0
// Load up the crash reporter
#import "~/OneDrive/Programming/Generic/slack.nut"

// ADDED IN 2.2.0
// Load up the Twilio handler
#import "~/OneDrive/Programming/impClock/twilio.nut"

// Initialize the clock's preferences - we will read in saved values, if any, next
initialisePrefs();

// Load in the server-saved preferences table
local savedPrefs = server.load();

if (savedPrefs.len() != 0) {
    // Table is NOT empty so set 'settings' to the loaded table
    // The existing table, if there is one, will be garbage-collected
    settings = savedPrefs;

    if (!("debug" in settings)) {
        // No debug key in prefs, so add it
        settings.debug <- false;
        server.save(settings);
    }

    // ADDED IN 2.1.0
    // Times to temporarily disable clock display (eg. over night)
    if (!("timer" in settings)) {
        settings.timer <- { "on"  : { "hour" : 7,  "min" : 00 },
                         "off" : { "hour" : 22, "min" : 30 },
                         "isset" : false,
                         "isadv" : false };
        server.save(settings);
    }

    if (settings.debug) server.log("Clock settings loaded: " + encodePrefsForUI());
} else {
    // Table is empty, so this must be a first run
    if (settings.debug) server.log("First Clock run");
}

// Register device-sent message handlers:
// NOTE This is the signal from the device that it is ready,
//      so all device-sending events should be registered here
device.on("clock.get.prefs", sendPrefsToDevice);

// ADDED IN 2.1.0
device.on("display.state", function(state) {
    stateChange = true;
    settings.on = state.on;
    settings.timer.isadv = state.advance;
    server.save(settings);
});

// Update the list of alarms maintained by the agent
device.on("update.alarms", function(new) {
    stateChange = true;
    settings.alarms = new;
    stateChange = true;
    if (settings.debug) server.log("Alarm list updated: " + settings.alarms.len() + " alarms listed");
});

// ADDED IN 2.2.0
device.on("post.alarm.sms", function(alarmTime) {
    // Signal an alarm via SMS and Twilio

    // Check that Twilio is in use
    if (twilio != null) {
        local msg = "impClock " + imp.configparams.deviceid + " ALARM @ " + alarmTime;
        twilio.send(target, msg, function(response) {
            server.log("Alarm SMS TX code: " + response.statuscode + " (" + response.body + ")");
        });
    }
});

// Set up the web UI and data API
api = Rocky.init();
api.use(debugAPI);

// Set up UI access security: HTTPS only
api.authorize(function(context) {
    // Mandate HTTPS connections
    if (context.getHeader("x-forwarded-proto") != "https") return false;
    return true;
});

api.onUnauthorized(function(context) {
    // Incorrect level of access security
    context.send(401, "Insecure access forbidden");
});

/*
    CLOCK ENDPOINTS

    SETTINGS
        GET  /settings -> JSON, settings + connection state
        POST /settings <- JSON, one or more settings to change.

    ACTIONS
        POST /actions <- JSON, action type, eg. reset, plus binary switches

    STATUS
        GET /status -> JSON, connection state + should UI force an update

    CONTROLLER SUPPORT
        GET /controller/info -> JSON, app ID, watch support
        GET controller/state -> JSON, subset of settings + connection state
*/

// Serve the web UI for a GET at the agent root
api.get("/", function(context) {
    // A GET request made to root, so return the UI HTML
    context.send(200, format(HTML_STRING, http.agenturl()));
});

// Serve up the settings JSON for a GET to /settings
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
            // Check for a mode-set message (value arrives as a bool)
            // eg. { "setmode" : true }
            if (setting == "setmode") {
                if (typeof value != "bool") {
                    error = reportAPIError("setmode");
                    break;
                }

                settings.hrmode = value;
                device.send("clock.set.mode", settings.hrmode);
                if (settings.debug) server.log("UI says change mode to " + (settings.hrmode ? "24 hour" : "12 hour"));
            }

            // Check for a BST set/unset message (value arrives as a bool)
            // eg. { "setbst" : true }
            if (setting == "setbst") {
                if (value != "bool") {
                    error = reportAPIError("setbst");
                    break;
                }

                settings.bst = value;
                device.send("clock.set.bst", settings.bst);
                if (settings.debug) server.log("UI says turn auto BST observance " + (settings.bst ? "on" : "off"));
            }

            // Check for a set colon show message (value arrives as a bool)
            // eg. { "setcolon" : true }
            if (setting == "setcolon") {
                if (typeof value != "bool") {
                    error = reportAPIError("setcolon");
                    break;
                }

                settings.colon = value;
                device.send("clock.set.colon", settings.colon);
                if (settings.debug) server.log("UI says turn colon " + (settings.colon ? "on" : "off"));
            }

            // Check for a set flash message (value arrives as a bool)
            // eg. { "setflash" : true }
            if (setting == "setflash") {
                if (typeof value != "bool") {
                    error = reportAPIError("setflash");
                    break;
                }

                settings.flash = value;
                device.send("clock.set.flash", settings.flash);
                if (settings.debug) server.log("UI says turn colon flashing " + (settings.flash ? "on" : "off"));
            }

            // Check for set light message (value arrives as a bool)
            // eg. { "setlight" : true }
            if (setting == "setlight") {
                if (typeof value != "bool") {
                    error = reportAPIError("setlight");
                    break;
                }

                settings.on = value;
                device.send("clock.set.light", settings.on);
                if (settings.debug) server.log("UI says turn display " + (settings.on ? "on" : "off"));
            }

            // Check for a set brightness message (value arrives as a string)
            // eg. { "setbright" : 10 }
            if (setting == "setbright") {
                // Check that the conversion to integer works
                try {
                    value = value.tointeger();
                } catch (err) {
                    error = reportAPIError("setbright");
                    break;
                }

                settings.brightness = value - 1;
                device.send("clock.set.brightness", settings.brightness);
                if (settings.debug) server.log(format("UI says set display brightness to %i", settings.brightness));
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

                    settings.utc = value.state;
                }

                if ("offset" in value) {
                    // Check that it can be converted to an integer
                    try {
                        value.offset = value.offset.tointeger();
                    } catch (err) {
                        error = reportAPIError("setutc.offset");
                        break;
                    }

                    settings.utcoffset = value.offset - 12;
                }

                device.send("clock.set.utc", { "state" : settings.utc, "offset" : settings.utcoffset });
                if (settings.debug) server.log("UI says turn world time mode " + (settings.utc ? "on" : "off") + ", offset: " + settings.utcoffset);

            }

            // ADDED IN 2.1.0
            // Check for use dimmer time message (value arrives as a bool)
            // eg. { "setnight" : true }
            if (setting == "setnight") {
                if (typeof value != "bool") {
                    error = reportAPIError("setnight");
                    break;
                }

                settings.timer.isset = value;
                device.send("clock.set.nightmode", settings.timer.isset);
                if (settings.debug) server.log("UI says " + (settings.timer.isset ? "enable" : "disable") + " night mode");
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

                settings.timer.on.hour = value.dimmeron.hour;
                settings.timer.on.min = value.dimmeron.min;
                settings.timer.off.hour = value.dimmeroff.hour;
                settings.timer.off.min = value.dimmeroff.min;

                device.send("clock.set.nighttime", settings.timer);
                if (settings.debug) server.log("UI says set night time to start at " + format("%02i", settings.timer.on.hour) + ":" + format("%02i", settings.timer.on.min) + " and end at " + format("%02i", settings.timer.off.hour) + ":" + format("%02i", settings.timer.off.min));
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
                        if (settings.alarms.len() == MAX_ALARMS) {
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

                        device.send("clock.set.alarm", alarm);
                        settings.alarms.append(alarm);
                        if (settings.debug) server.log("UI says set alarm for " + format("%02i", alarm.hour) + ":" + format("%02i", alarm.min) + " (repeat: " + (alarm.repeat ? "yes" : "no") + ")");
                    } else if (value.action == "delete") {
                        if ("index" in value) {
                            try {
                                // Check that index value can be converted to an integer
                                value.index = value.index.tointeger();
                            } catch (err) {
                                error = reportAPIError("setalarm.delete.index");
                                break;
                            }

                            device.send("clock.clear.alarm", value.index);
                            settings.alarms.remove(value.index);
                            if (settings.debug) server.log("UI says delete alarm at index " + value.index);
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

                            device.send("clock.stop.alarm", value.index);
                            if (settings.debug) server.log("UI says silence alarm at index " + value.index);
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
            if (settings.debug) server.error(error);
        } else {
            // Send the updated prefs back to the UI (may not be used)
            local ua = context.getHeader("user-agent");
            local r = ua == "Controller/ClockInterfaceController" ? encodePrefsForWatch() : encodePrefsForUI();
            context.send(200, r);

            // Save the settings changes
            server.save(settings);
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
                initialisePrefs();
                server.save(settings);
                device.send("clock.set.prefs", settings);
                server.log("Clock settings reset");
                context.send(200, http.jsonencode({"reset":true}));
                return;
            }

            if (data.action == "debug") {
                // A DEBUG message sent
                settings.debug = data.debug;
                server.save(settings);
                device.send("clock.set.debug", settings.debug);
                server.log("Debug mode " + (settings.debug ? "on" : "off"));
                context.send(200, http.jsonencode({"debug":settings.debug}));
                return;
            }

            if (data.action = "world") {
                // A SWITCH WORLD VIEW ON/OFF message sent
                settings.utc = ! settings.utc;
                if (settings.debug) server.log("World time switched " + (settings.utc ? "on" : "off"));
                context.send(200, http.jsonencode({"world":{"utc":settings.utc}}));
                erver.save(settings);
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

// Serve the clock status for a GET to /status
api.get("/status", function(context) {
    // A GET request made to /settings, so return the clock settings
    local resp = { "connected" : device.isconnected() };
    if (stateChange) resp.force <- true;
    context.send(200, http.jsonencode(resp, {"compact" : true}));
    stateChange = false;
});

// Any call to the endpoint /images is sent the correct PNG data
api.get("/images/([^/]*)", function(context) {
    // Determine which image has been requested and send the appropriate
    // stored data back to the requesting web browser
    local path = context.path;
    local name = path[path.len() - 1];
    local image = DELETE_PNG;
    if (name == "low.png") image = LOW_PNG;
    if (name == "mid.png") image = MID_PNG;
    if (name == "high.png") image = HIGH_PNG;
    if (name == "silence.png") image = SILENCE_PNG;

    context.setHeader("Content-Type", "image/png");
    context.send(200, image);
});

// Controller support endpoints
api.get("/controller/info", function(context) {
    // GET at /controller/info returns app info for Controller
    local info = { "appcode": APP_CODE,
                   "watchsupported": "true" };
    context.send(200, http.jsonencode(info));
});

api.get("/controller/state", function(context) {
    // GET call to /controller/state returns device status
    // Send a relevant subset of the settings as JSON
    context.send(200, encodePrefsForWatch());
});
