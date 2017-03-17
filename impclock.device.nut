#require "utilities.nut:1.0.0"

#import "../HT16K33Segment/HT16K33Segment.class.nut"

// Set up WiFi disconnection response policy right at the start
server.setsendtimeoutpolicy(RETURN_ON_ERROR, WAIT_TIL_SENT, 10);

// CONSTANTS

const DIS_TIMEOUT = 60.0;
const TICK_TIME = 0.5;
const TICK_TOTAL = 4;
const HALF_TICK_TOTAL = 2;

// MAIN VARIABLES

// Objects
local display = null;
local disMessage = null;
local tickTimer = null;
local settings = null;
local alarms = [];

// Numeric values
local minutes = 0;
local hours = 0;
local seconds = 0;
local tickCount = 0;
local disTime = -1;

// Runtime flags
local tickFlag = true;
local pmFlag = false;
local disFlag = false;
local debug = false;
local alarmFlag = 0;

// DISPLAY FUNCTIONS

function setDisplay() {
    // Controls the display

    // Set the digit counters a and b
    local a = hours;
    local b = 0;

    // Zero the display buffer
    display.clearBuffer().setColon(false);

    // Not showing the LED? Update an empty screen and bail
    if (!settings.on) {
        display.updateDisplay();
        return;
    }

    // Hours
    if (settings.hrmode == true) {
        // 24 hour clock
        if (a < 10) {
            display.writeNumber(0, 16, disFlag);
            display.writeNumber(1, a, false);
        } else if (a > 9 && a < 20) {
            display.writeNumber(0, 1, disFlag)
            display.writeNumber(1, a - 10, false);
        } else if (a > 19) {
            display.writeNumber(0, 2, disFlag);
            display.writeNumber(1, a - 20, false);
        }
    } else {
        // 12 hour clock
        if (a == 12 || a == 0 ) {
            display.writeNumber(0, 1, disFlag);
            display.writeNumber(1, 2, false);
        } else if (a < 10) {
            display.writeNumber(0, 16, disFlag);
            display.writeNumber(1, a, false);
        } else if (a == 10 || a == 11) {
            display.writeNumber(0, 1, disFlag);
            display.writeNumber(1, a - 10, false);
        } else if (a > 12 && a < 22) {
            display.writeNumber(1, a - 12, false);
        } else if (a == 22 || a == 23) {
            display.writeNumber(0, 1, disFlag);
            display.writeNumber(1, a - 22, false);
        }
    }

    // Minutes
    if (minutes > 9) {
        a = minutes;
        while (a >= 0) {
            a = a - 10;
            b++;
        }

        display.writeNumber(4, (minutes - (10 * (b - 1))), pmFlag && !settings.hrmode);
        display.writeNumber(3, b - 1, false);
    } else {
        display.writeNumber(4, minutes, pmFlag && !settings.hrmode);
        display.writeNumber(3, 0, false);
    }

    // Check whether the colon should appear
    local colonState = false;

    if (settings.colon) {
        if (settings.flash) {
            colonState = tickFlag;
        } else {
            colonState = true;
        }
    }

    // Update the screen with time and colon
    display.setColon(colonState).updateDisplay();

    // Check for alarms

    if (alarmFlag == 1) display.setDisplayFlash(2);
    if (alarmFlag == -1) display.setDisplayFlash(0);
    alarmFlag = 0;
}

function syncText() {
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
        // If UTC is set, add the international time offset
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
    pmFlag = false;
    if (hours > 11) pmFlag = true;

    // Update the tick counter
    tickCount++;
    tickFlag = false;
    if (tickCount == TICK_TOTAL) tickCount = 0;
    if (tickCount < HALF_TICK_TOTAL) tickFlag = true;

    // Check for Alarms
    checkAlarms();

    // Update the display
    setDisplay();
}

function checkAlarms() {
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
                        ++alarm.offhours;
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
                ++i;
            }
        }
    }
}

// SERVER-RELATED FUNCTIONS

function switchMode(value) {
    // This function is called when 12/24 modes are switched by app
    if (debug) server.log("Setting 24-hour mode " + ((value == 24) ? "on" : "off"));
    settings.hrmode = (value == 24) ? true : false;
}

function setBST(value) {
    // This function is called when the app sets or unsets BST
    if (debug) server.log("Setting BST monitoring" + ((value == 1) ? "on" : "off"));
    settings.bst = (value == 1);
}

function setUTC(string) {
    // This function is called when the app sets or unsets UTC
    if (string == "N") {
        settings.utc = false;
    } else {
        settings.utc = true;
        settings.offset = 12 - string.tointeger();
    }
}

// PREFS-RELATED FUNCTIONS

function setBright(brightness) {
    // This function is called when the app changes the clock's brightness
    local bright = brightness.tointeger();
    if (bright < 0 || bright > 15 || bright == settings.brightness) return;
    if (bright == 0 && settings.on) {
        // Disable the display
        settings.on = false;
        display.powerDown();
        return;
    }

    // Update the setting and the display itself
    settings.brightness = bright;
    display.setBrightness(bright);
}

function setFlash(value) {
    // This function is called when the app sets or unsets the colon flash
    if (debug) server.log("Setting colon flash " + ((value == 1) ? "on" : "off"));
    settings.flash = (value == 1);
}

function setColon(value) {
    if (debug) server.log("Setting colon state " + ((value == 1) ? "on" : "off"));
    settings.colon = (value == 1);
}

function setLight(value) {
    if (debug) server.log("Setting light " + ((value == 1) ? "on" : "off"));
    if (value == 1 && !settings.on) {
        settings.on = true;
        display.powerUp();
    } else if (value == 0 && settings.on) {
        settings.on = false;
        display.powerDown();
    }
}

function setDebug(state) {
    debug = (state == 1);
}

function setAlarm(alarmTime) {

}

function setPrefs(prefsTable) {
    // Parse the set-up data table provided by the agent
    settings.hrmode = prefsTable.hrmode;
    settings.bst = prefsTable.bst;
    settings.flash = prefsTable.flash;
    settings.colon = prefsTable.colon;
    settings.utc = prefsTable.utc;
    settings.offset = 12 - prefsTable.offset;
    settings.brightness = prefsTable.brightness;
    settings.on = prefsTable.on;

    // Set the brightness
    display.setBrightness(settings.brightness);

    // Start the clock
    if (tickTimer == null) clockTick();

    if (alarms != null) alarms = null;
    alarms = prefsTable.alarms;
}

// Disconnection-related Functions

function disHandler(reason) {
    // Called if the server connection is broken or re-established
    if (reason != SERVER_CONNECTED) {
        // Server is not connected
        if (disTime == -1) {
            disTime = time();
            local now = date();
            disMessage = format("Went offline at %02d:%02d:%02d", now.hour, now.min, now.sec);
        }

        disFlag = true;
        imp.wakeup(DIS_TIMEOUT, reconnect);
    } else {
        // Server is connected
        if (debug) {
            server.log(disMessage);
            server.log("Back online after " + ((time() - disTime) * 1000) + " seconds");
        }

        disTime = -1;
        disFlag = false;
        disMessage = null;
    }
}

function reconnect() {
    if (server.isconnected()) {
        disHandler(SERVER_CONNECTED);
    } else {
        server.connect(disHandler, 30);
    }
}

// START OF PROGRAM

// Set up WiFi disconnection response policy
server.onunexpecteddisconnect(disHandler);

// Configure the display
hardware.i2c12.configure(CLOCK_SPEED_400_KHZ);
display = HT16K33Segment(hardware.i2c12, 0x70, debug);

// Display the inital text, 'sync'
syncText();

// Initialise prefs
settings = {};
settings.hrmode <- true;
settings.bst <- true;
settings.utc <- false;
settings.flash <- true;
settings.colon <- true;
settings.on <- true;
settings.brightness <- 15;
settings.offset <- 12;
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
agent.send("clock.get.prefs", 1);
