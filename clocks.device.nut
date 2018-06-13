// Clock
// Copyright 2014-18, Tony Smith

// IMPORTS
// NOTE If you're not using Squinter or an equivalent tool,
// cut and paste the named library's code over the following line
#import "../HT16K33Segment/HT16K33Segment.class.nut"
#import "../generic/utilities.nut"
#import "../generic/bootmessage.nut"
#import "../generic/disconnect.nut"


// CONSTANTS
const TICK_TIME = 0.5;
const TICK_TOTAL = 4;
const HALF_TICK_TOTAL = 2;


// MAIN VARIABLES
// Objects
local display = null;
local tickTimer = null;
local settings = null;
local alarms = [];

// Numeric values
local hours = 0;
local minutes = 0;
local seconds = 0;
local tickCount = 0;

// Runtime flags
local tickFlag = true;
local pmFlag = false;
local discFlag = false;
local debug = true;
local alarmFlag = 0;


// DISPLAY FUNCTIONS
function setDisplay() {
    // The main function for updating the display

    // Not supposed to be showing the LED? Then bail
    // NOTE if settings.on is false, the display will already be powered down
    if (!settings.on) return;

    // Set the digit counters a and b
    local a = hours;
    local b = 0;

    // Clear the display and colon
    display.clearBuffer().setColon(false);

    // Set the hours digits
    if (settings.hrmode == true) {
        // 24-hour clock mode
        // NOTE The first digit's decimal point is set if the clock is disconnected
        // ie. if 'discFlag' is true
        if (a < 10) {
            display.writeNumber(0, 16, discFlag);
            display.writeNumber(1, a, false);
        } else if (a > 9 && a < 20) {
            display.writeNumber(0, 1, discFlag)
            display.writeNumber(1, a - 10, false);
        } else if (a > 19) {
            display.writeNumber(0, 2, discFlag);
            display.writeNumber(1, a - 20, false);
        }
    } else {
        // 12-hour clock mode
        // NOTE The first digit's decimal point is set if the clock is disconnected,
        // ie. if 'discFlag' is true
        if (a == 12 || a == 0 ) {
            display.writeNumber(0, 1, discFlag);
            display.writeNumber(1, 2, false);
        } else if (a < 10) {
            display.writeNumber(0, 16, discFlag);
            display.writeNumber(1, a, false);
        } else if (a == 10 || a == 11) {
            display.writeNumber(0, 1, discFlag);
            display.writeNumber(1, a - 10, false);
        } else if (a > 12 && a < 22) {
            display.writeNumber(1, a - 12, false);
        } else if (a == 22 || a == 23) {
            display.writeNumber(0, 1, discFlag);
            display.writeNumber(1, a - 22, false);
        }
    }

    // Set the minutes digits
    if (minutes > 9) {
        a = minutes;
        while (a >= 0) {
            a = a - 10;
            b++;
        }

        // NOTE The fourth digit's decimal point is set if the clock is in 12-hour mode
        // and we're in PM time, ie. if 'pmFlag' is true
        display.writeNumber(4, (minutes - (10 * (b - 1))), (pmFlag && !settings.hrmode));
        display.writeNumber(3, b - 1, false);
    } else {
        display.writeNumber(4, minutes, (pmFlag && !settings.hrmode));
        display.writeNumber(3, 0, false);
    }

    // If the colon should appear - its on permanently or in a flash - set it
    local colonState = settings.colon ? (settings.flash ? tickFlag : true) : false;

    // Update the screen with time and colon
    display.setColon(colonState).updateDisplay();

    // Check for alarms **** EXPERIMENTAL ****
    if (alarmFlag == 1) display.setDisplayFlash(2);
    if (alarmFlag == -1) display.setDisplayFlash(0);
    alarmFlag = 0;
}

function syncText() {
    // Display 'SYNC' after the clock is powered up and until it receives its preferences from the agent
    local letters = [0x6D, 0x6E, 0x00, 0x37, 0x39];
    foreach (index, char in letters) display.writeGlyph(index, char, false);
    display.updateDisplay();
}


// CLOCK FUNCTIONS
function clockTick() {
    // Set a trigger for the next tick. We do this so that the time taken
    // to run the clock_tick code to minimise the drift
    tickTimer = imp.wakeup(TICK_TIME, clockTick);

    // Update the time using imp's RTC
    local now = date();
    hours = now.hour;
    seconds = now.sec;
    minutes  = now.min;

    // Update the value of 'hours' to reflect displayed time
    if (settings.utc) {
        // If UTC is set, add the international time offset (-12 TO +12)
        hours = hours + settings.offset;
        if (hours > 24) {
            hours = hours - 24;
        } else if (hours < 0) {
            hours = hours + 24;
        }
    } else {
        // We are displaying local time -
        // is daylight savings being observed?
        if (settings.bst && utilities.bstCheck()) hours++;
        if (hours > 23) hours = 0
    }

    // Is it PM?
    pmFlag = (hours > 11) ? true : false;

    // Update the tick counter and flag
    tickCount = (tickCount == TICK_TOTAL) ? 0 : tickCount + 1;
    tickFlag = (tickCount < HALF_TICK_TOTAL) ? true : false;

    // Check for Alarms
    checkAlarms();

    // Update the display
    setDisplay();
}

function checkAlarms() {
    // Do we need to display an alarm screen flash? **** EXPERIMENTAL ****
    if (alarms.len() > 0) {
        foreach (alarm in alarms) {
            if (alarm.hours == hours && alarm.minutes == minutes) {
                if (!("on" in alarm) && !alarm.done) {
                    if (debug) server.log("Alarm triggered");
                    alarmFlag = 1;
                    alarm.offminutes = alarm.minutes + 5;
                    alarm.offhours = alarm.hours;
                    if (alarm.offminutes > 59) {
                        alarm.offminutes = 60 - alarm.offminutes;
                        alarm.offhours++;
                        if (alarm.offhours > 23) alarm.offhours = 24 - alarm.offhours;
                    }

                    alarm.on <- true;
                }
            }

            if (alarm.offhours == hours && alarm.offminutes == minutes) {
                alarmFlag = -1;
                if (debug) server.log("Alarm stopped");
                if (!alarm.repeat) alarm.done = true;
            }
        }

        local i = 0;
        while (i < alarms.len()) {
            local alarm = alarms[i];
            if (alarm.done == true) {
                alarms.remove(i);
                if (debug) server.log("Alarm deleted");
            } else {
                i++;
            }
        }
    }
}


// PREFERENCES-RELATED FUNCTIONS
function switchMode(value) {
    // This function is called when 12/24 modes are switched by app
    // 'value' is passed in from the agent as a bool
    if (debug) server.log("Setting 24-hour mode " + (value ? "on" : "off"));
    settings.hrmode = value;
}

function setBST(value) {
    // This function is called when the app sets or unsets BST
    // 'value' is passed in from the agent as a bool
    if (debug) server.log("Setting BST monitoring" + (value ? "on" : "off"));
    settings.bst = value;
}

function setUTC(value) {
    // This function is called when the app sets or unsets UTC
    if (value == "N") {
        // If 'value' is a string - and specifically "N" - it means 'disable UTC'
        settings.utc = false;
    } else {
        // 'value' is the integer offset: -12 to 12
        settings.utc = true;
        settings.offset = value;
    }
}

function setBright(brightness) {
    // This function is called when the app changes the clock's brightness
    // 'brightness' is passed in from the agent as an integer
    if (brightness < 0 || brightness > 15 || brightness == settings.brightness) return;
    if (debug) server.log("Setting clock brightness " + brightness);
    settings.brightness = brightness;
    display.setBrightness(brightness);
}

function setFlash(value) {
    // This function is called when the app sets or unsets the colon flash
    // 'value' is passed in from the agent as a bool
    if (debug) server.log("Setting colon flash " + (value ? "on" : "off"));
    settings.flash = value;
}

function setColon(value) {
    // This function is called when the app sets or unsets the colon
    // 'value' is passed in from the agent as a bool
    if (debug) server.log("Setting colon state " + (value ? "on" : "off"));
    settings.colon = value;
}

function setLight(value) {
    // This function is called when the app turns the display on or off
    // 'value' is passed in from the agent as a bool
    if (debug) server.log("Setting light " + (value ? "on" : "off"));
    if (value != settings.on) {
        settings.on = value;
        if (value) {
            display.powerUp();
        } else {
            display.powerDown();
        }
    }
}

function setDebug(state) {
    debug = state;
    server.log("Device-side debug messages " + ((debug) ? "enabled" : "disabled"));
}

function setAlarm(alarmTime) {
    // Program an alarm **** EXPERIMENTAL ****
}

function setPrefs(prefsTable) {
    // Parse the set-up data table provided by the agent
    if (debug) server.log("Preferences received from agent");

    // Set the debug state
    if ("debug" in prefsTable) setDebug(prefsTable.debug);

    settings.hrmode = prefsTable.hrmode;
    settings.bst = prefsTable.bst;
    settings.flash = prefsTable.flash;
    settings.colon = prefsTable.colon;
    settings.utc = prefsTable.utc;
    settings.offset = prefsTable.offset;

    // Set the display state
    settings.on = prefsTable.on;
    setLight(settings.on);

    // Set the brightness
    if (settings.brightness != prefsTable.brightness) {
        settings.brightness = prefsTable.brightness;
        if (settings.on) display.setBrightness(prefsTable.brightness);
    }

    // Start the clock
    if (tickTimer == null) clockTick();

    // Clear the local list of alarms
    if (alarms != null) alarms = null;
    alarms = prefsTable.alarms;
}


// CONNECTIVITY FUNCTIONS
// Set up connectivity policy — this should come as early in the code as possible
function discHandler(event) {
    if ("message" in event) server.log(event.message);

    if ("type" in event) {
        discFlag = (event.type == "connected") ? false : true;
    }
}


// START OF PROGRAM

// Register the WiFi disconnection handler
disconnectionManager.eventCallback = discHandler;
disconnectionManager.start();

// Configure the display
hardware.i2c12.configure(CLOCK_SPEED_400_KHZ);
display = HT16K33Segment(hardware.i2c12, 0x70);
display.init();

// Display the inital text, 'sync'
// This will appear until the device receives settings from the agent
syncText();

// Initialise the clock's local preferences store
settings = {};
settings.hrmode <- true;
settings.bst <- true;
settings.utc <- false;
settings.flash <- true;
settings.colon <- true;
settings.on <- true;
settings.brightness <- 15;
settings.offset <- 0;
settings.alarms <- [];

// Set up Agent notification response triggers
agent.on("clock.set.prefs", setPrefs);
agent.on("clock.switch.mode", switchMode);
agent.on("clock.switch.bst", setBST);
agent.on("clock.set.utc", setUTC);
agent.on("clock.set.brightness", setBright);
agent.on("clock.switch.flash", setFlash);
agent.on("clock.switch.colon", setColon);
agent.on("clock.set.light", setLight);
agent.on("clock.set.debug", setDebug);

agent.on("clock.set.alarm", function(newAlarm) {
    if (alarms.len() > 0) {
        foreach (alarm in alarms) {
            if (alarm.hours == newAlarm.hours && alarm.minutes == newAlarm.minutes) {
                // Alarm matches an existing one - is the use just updating repeat?
                if (alarm.repeat == newAlarm.repeat) return;
                alarm.repeat = newAlarm.repeat;
            }
        }
    }

    alarms.append(newAlarm);
    if (debug) server.log("Alarm set");
});

agent.on("clock.stop.alarm", function(dummy) {
    // Run through each alarm and mark it done
    if (alarms.len() > 0) {
        foreach (alarm in alarms) {
            if ("on" in alarm) {
                alarm.done = true;
                alarmFlag = -1;
            }
        }
    }
});

// Request preferences from server
agent.send("clock.get.prefs", true);
if (debug) server.log("Requesting preferences from agent");
