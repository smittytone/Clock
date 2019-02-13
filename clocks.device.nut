// Clock
// Copyright 2014-19, Tony Smith

// ********** IMPORTS **********
// NOTE If you're not using Squinter or an equivalent tool, cut and 
//      paste the named library's code in place of the appropriate line
#import "../HT16K33Segment/HT16K33Segment.class.nut"
#import "../generic/utilities.nut"
#import "../generic/disconnect.nut"


// ********** CONSTANTS **********
const DISCONNECT_TIMEOUT = 60;
const RECONNECT_TIMEOUT = 15;
const TICK_DURATION = 0.5;
const TICK_TOTAL = 4;
const HALF_TICK_TOTAL = 2;
const ALARM_DURATION = 2;
//const INITIAL_ANGLE = 0;
const ALARM_NO_ACTION = 0;
const ALARM_START_FLASH = 1;
const ALARM_STOP_FLASH = 2;

// ********** GLOBAL VARIABLES **********
// Objects
local display = null;
local tickTimer = null;
local syncTimer = null;
local settings = null;
local alarms = [];

// Numeric values
local seconds = 0;
local minutes = 0;
local hours = 0;
local dayw = 0;
local day = 0;
local month = 0;
local year = 0;
local tickCount = 0;
local disTime = 0;

// Runtime flags
local isDisconnected = false;
local isConnecting = false;
local isAdvanceSet = false;
local isPM = false;
local tickFlag = true;
local debug = true;

// Alarms
// 'alarmstate' has three possible values: 
//    ALARM_NO_ACTION
//    ALARM_START_FLASH
//    ALARM_STOP_FLASH
local alarmState = ALARM_NO_ACTION;


// ********** TIME AND DISPLAY CONTROL FUNCTIONS **********
function clockTick() {
    // Set a trigger for the next tick. We do this so that the time taken
    // to run the clock_tick code to minimise the drift
    tickTimer = imp.wakeup(TICK_DURATION, clockTick);

    // Get the current time from the imp's RTC
    local now = date();
    hours = now.hour;
    minutes  = now.min;
    seconds = now.sec;
    dayw = now.wday;
    day = now.day;
    month = now.month;
    year = now.year;

    // Update the value of 'hours' to reflect displayed time
    if (settings.utc) {
        // If UTC is set, add the international time offset (-12 TO +12)
        hours = hours + settings.utcoffset;
        if (hours > 24) {
            hours = hours - 24;
        } else if (hours < 0) {
            hours = hours + 24;
        }
    } else {
        // We are displaying local time -
        // is daylight savings being observed?
        if (settings.bst && utilities.bstCheck()) hours++;
        if (hours > 23) hours = 0;
    }

    // Is it PM?
    isPM = hours > 11 ? true : false;

    // Update the tick counter and flag
    tickCount = tickCount == TICK_TOTAL ? 0 : tickCount + 1;
    tickFlag = tickCount < HALF_TICK_TOTAL ? true : false;

    // ADDED IN 2.0.0
    // Check for Alarms
    checkAlarms();

    // ADDED IN 2.1.0
    // Should the display be enabled or not?
    if (settings.timer.isset) {
        local should = shouldShowDisplay();
        if (settings.on != should) {
            // Change the state of the display
            setDisplay(should);
            settings.on = should;
        }
    }

    // Present the current time
    if (settings.on) displayTime();
}

function shouldShowDisplay() {
    // ADDED IN 2.1.0
    // Returns true if the display should be on, false otherwise - default is true / on
    // If we have auto-dimming set, we need only check whether we need to turn the display off
    // NOTE The function should only be called if 'settings.timer.isset' is true, ie. we're
    //      in night mode

    // Assume we will enable the display
    local shouldShow = true;

    // Should we disable the advance? Only if it's set and we've hit the start or end end 
    // of the night period
    // NOTE 'isAdvanceSet' is ONLY set if 'settings.timer.isset' is TRUE
    if (isAdvanceSet) {
        // 'isAdvanceSet' is unset when the next event time (display goes on or off) is reached
        if (hours == settings.timer.on.hour && minutes >= settings.timer.on.min) isAdvanceSet = false;
        if (hours == settings.timer.off.hour && minutes >= settings.timer.off.min) isAdvanceSet = false;
    }

    // Have we crossed into the night period? If so, unset 'shouldShow'
    // Check by converting all times to minutes
    local start = settings.timer.on.hour * 60 + settings.timer.on.min;
    local end = settings.timer.off.hour * 60 + settings.timer.off.min;
    local now = hours * 60 + minutes;
    local delta = end - start;
    
    // End and start times are identical
    if (delta == 0) return !isAdvanceSet;
    
    if (delta > 0) {
        if (now >= start && now < end) shouldShow = false;
    } else {
        if (now >= start || now < end) shouldShow = false;
    }

    // 'isAdvancedSet' inverts the expected state
    return (isAdvanceSet ? !shouldShow : shouldShow);
}

function setDisplay(state) {
    // ADDED IN 2.1.0
    // Power up or power down the display according to the supplied state (true or false)
    if (state) {
        display.powerUp();
        agent.send("display.state", { "on" : true, "advance" : isAdvanceSet });
        if (debug) server.log("Brightening display at " + format("%02i", hours) + ":" + format("%02i", minutes));
    } else {
        display.powerDown();
        agent.send("display.state", { "on" : false, "advance" : isAdvanceSet });
        if (debug) server.log("Dimming display at " + format("%02i", hours) + ":" + format("%02i", minutes));
    }
}

function displayTime() {
    // The main function for updating the display

    // Set the digit counters a and b
    local a = hours;
    local b = 0;

    // Clear the display and colon
    display.clearBuffer().setColon(false);

    // Set the hours
    if (settings.mode) {
        // 24-hour clock mode
        // NOTE The first digit's decimal point is set if the clock is disconnected
        // ie. if 'isDisconnected' is true
        if (a < 10) {
            display.writeNumber(0, 0, isDisconnected);
            display.writeNumber(1, a, false);
        } else if (a > 9 && a < 20) {
            display.writeNumber(0, 1, isDisconnected)
            display.writeNumber(1, a - 10, false);
        } else if (a > 19) {
            display.writeNumber(0, 2, isDisconnected);
            display.writeNumber(1, a - 20, false);
        }
    } else {
        // 12-hour clock mode
        // NOTE The first digit's decimal point is set if the clock is disconnected,
        // ie. if 'isDisconnected' is true
        if (a == 12 || a == 0 ) {
            display.writeNumber(0, 1, isDisconnected);
            display.writeNumber(1, 2, false);
        } else if (a < 10) {
            display.writeNumber(0, 16, isDisconnected);
            display.writeNumber(1, a, false);
        } else if (a == 10 || a == 11) {
            display.writeNumber(0, 1, isDisconnected);
            display.writeNumber(1, a - 10, false);
        } else if (a > 12 && a < 22) {
            display.writeNumber(1, a - 12, false);
        } else if (a == 22 || a == 23) {
            display.writeNumber(0, 1, isDisconnected);
            display.writeNumber(1, a - 22, false);
        }
    }

    // Set the minutes
    if (minutes > 9) {
        a = minutes;
        while (a >= 0) {
            a = a - 10;
            b++;
        }

        // NOTE The fourth digit's decimal point is set if the clock is in 12-hour mode
        // and we're in PM time, ie. if 'isPM' is true
        display.writeNumber(4, (minutes - (10 * (b - 1))), (isPM && !settings.mode));
        display.writeNumber(3, b - 1, false);
    } else {
        display.writeNumber(4, minutes, (isPM && !settings.mode));
        display.writeNumber(3, 0, false);
    }

    // Check whether the colon should appear
    local colonState = settings.colon ? (settings.flash ? tickFlag : true) : false;

    // Update the screen with time and colon
    display.setColon(colonState).updateDisplay();

    // Check for alarms
    if (alarmState == ALARM_START_FLASH) display.setDisplayFlash(2);
    if (alarmState == ALARM_STOP_FLASH) display.setDisplayFlash(0);
    alarmState = ALARM_NO_ACTION;
}

function syncText() {
    // Display 'SYNC' after the clock is powered up and until it receives its preferences from the agent
    if (!settings.on) return;
    local letters = [0x6D, 0x6E, 0x00, 0x37, 0x39];
    foreach (index, char in letters) {
        if (index != 2) display.writeGlyph(index, char, false);
    }
    display.updateDisplay();
}


// ********** PREFERENCES FUNCTIONS **********
function setPrefs(prefsTable) {
    // Cancel the 'Sync' display timer if it has yet to fire
    if (debug) server.log("Received preferences from agent");
    if (syncTimer) imp.cancelwakeup(syncTimer);
    syncTimer = null;

    // Set the debug state
    if ("debug" in prefsTable) setDebug(prefsTable.debug);

    // Parse the set-up data table provided by the agent
    settings.mode = prefsTable.hrmode;
    settings.bst = prefsTable.bst;
    settings.flash = prefsTable.flash;
    settings.colon = prefsTable.colon;
    settings.utc = prefsTable.utc;
    settings.utcoffset = prefsTable.utcoffset;

    // Set the display state
    if (settings.on != prefsTable.on) setLight(prefsTable.on);

    // Set the brightness
    if (settings.brightness != prefsTable.brightness) {
        settings.brightness = prefsTable.brightness;
        
        // Only set the brightness now if the display is on
        if (settings.on) display.setBrightness(prefsTable.brightness);
    }

    // Clear the local list of alarms
    if (alarms != null) alarms = [];
    if (prefsTable.alarms.len() > 0) {
        foreach (alarm in prefsTable.alarms) setAlarm(alarm);
        if (debug) server.log(alarms.len() + " alarms added");
    }

    // Only call clockTick() if we have come here *before*
    // the main clock loop, which sets tickTimer, has started
    if (tickTimer == null) clockTick();
}

function setMode(value) {
    // This function is called when 12/24 modes are switched by app
    // 'value' is passed in from the agent as a bool
    if (debug) server.log("Setting 24-hour mode " + (value ? "on" : "off"));
    settings.mode = value;
}

function setBST(value) {
    // This function is called when the app sets or unsets BST
    // 'value' is passed in from the agent as a bool
    if (debug) server.log("Setting BST monitoring" + (value ? "on" : "off"));
    settings.bst = value;
}

function setUTC(value) {
    // This function is called when the app sets or unsets UTC
    settings.utc = value.state;
    settings.utcoffset = value.offset;
}

function setBright(brightness) {
    // This function is called when the app changes the clock's brightness
    // 'brightness' is passed in from the agent as an integer
    if (brightness < 0 || brightness > 15 || brightness == settings.brightness) return;
    if (debug) server.log("Setting display brightness " + brightness);
    settings.brightness = brightness;
    
    // Tell the display(s) to change their brightness
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
    // Enable or disble debugging messaging in response to a message from the UI via the agent
    debug = state;
    server.log("Setting device-side debug messages " + (state ? "on" : "off"));
}

function setDefaultPrefs() {
    // Initialise the clock's local preferences store
    settings = {};
    settings.on <- true;
    settings.mode <- true;
    settings.bst <- true;
    settings.colon <- true;
    settings.flash <- true;
    settings.brightness <- 15;
    settings.utc <- false;
    settings.utcoffset <- 0;
    settings.alarms <- [];
    settings.timer <- { "on"  : { "hour" : 7,  "min" : 00 }, 
                        "off" : { "hour" : 22, "min" : 30 },
                        "isset" : false };
}


// ********** ALARM FUNCTONS **********
function checkAlarms() {
    // ADDED IN 2.0.0
    // Do we need to display an alarm screen flash?
    if (alarms.len() > 0) {
        foreach (alarm in alarms) {
            // Might an alarm be triggered?
            if (alarm.hour == hours && alarm.min == minutes) {
                if (!alarm.on && !alarm.done) {
                    // Set the flag to start the display flashing
                    alarmState = ALARM_START_FLASH;
                    if (debug) server.log("Alarm triggered");
                    
                    // Set the off time
                    alarm.offmins = alarm.min + ALARM_DURATION;
                    alarm.offhour = alarm.hour
                    if (alarm.offmins > 59) {
                        alarm.offmins = 60 - alarm.offmins;
                        alarm.offhour++;
                        if (alarm.offhour > 23) alarm.offhour = 24 - alarm.offhour;
                    }

                    // Mark the alarm as active
                    alarm.on = true;
                }
            }

            // Might an alarm be disabled
            if (alarm.offhour == hours && alarm.offmins == minutes) {
                // Clear the off times so we don't perform this code again
                alarm.offhour = 99;
                alarm.offmins = 99;

                // Set the flag to stop the display flashing
                alarmState = ALARM_STOP_FLASH;
                if (debug) server.log("Alarm stopped");
                
                // Mark alarm for deletion if it's not on repeat
                if (!alarm.repeat) alarm.done = true;
            }
        }

        // Tidy up the alarm list: delete any alarms that are done
        local i = 0;
        local flag = false;
        while (i < alarms.len()) {
            local alarm = alarms[i];
            if (alarm.done == true) {
                flag = true;
                alarms.remove(i);
                if (debug) server.log("Alarm " + i + " deleted");
            } else {
                i++;
            }
        }

        // If we deleted any alarms, tell the agent
        if (flag) agent.send("update.alarms", alarms);
    }
}

function sortAlarms() {
    // ADDED IN 2.0.0
    // Sort the alarms into order
    alarms.sort(function(a, b) {
        // Sort by hour
        if (a.hour > b.hour) return 1;
        if (a.hour < b.hour) return -1;

        // Sort by min
        if (a.min > b.min) return 1;
        if (a.min < b.min) return -1;

        // Alarms are identical
        return 0;
    });
}

function sortFunction(first, second) {
  local tab = {"one" : 1, "two" : 2, "three" : 3, "four" : 4, "five" : 5};
	
  // Sort strings based on the numeric value in the table
  local a = tab[first];
  local b = tab[second];
	
  if (a > b) return 1;
  if (a < b) return -1;
  return 0;
}

function setAlarm(newAlarm) {
    // ADDED IN 2.0.0, UPDATED IN 2.1.0
    // Add a new alarm to the list
    if (alarms.len() > 0) {
        foreach (alarm in alarms) {
            if (alarm.hour == newAlarm.hour && alarm.min == newAlarm.min) {
                // Alarm matches an existing one - is the use just updating repeat?
                if (alarm.repeat == newAlarm.repeat) return;
                alarm.repeat = newAlarm.repeat;
                if (debug) server.log("Alarm updated");
                agent.send("update.alarms", alarms);
                return;
            }
        }
    }

    newAlarm.on <- false;
    newAlarm.done <- false;
    newAlarm.offmins <- 99;
    newAlarm.offhour <- 99;
    alarms.append(newAlarm);
    sortAlarms();
    if (debug) server.log("Alarm set (" + alarms.len() + ")");
    agent.send("update.alarms", alarms);
}

function clearAlarm(index) {
    // ADDED IN 2.1.0
    // Delete the specified alarm
    if (alarms.len() > 0) {
        if (index < 0 || index > alarms.len() - 1) return;
        local alarm = alarms[index];
        if (alarm.on) stopAlarm(index);
        alarms.remove(index);
        if (debug) server.log("Alarm " + index + " removed (" + alarms.len() + " left)");
        agent.send("update.alarms", alarms);
    }
}

function stopAlarm(index) {
    // ADDED IN 2.1.0
    // Silence the specified alarm
    if (alarms.len() > 0) {
        if (index < 0 || index >= alarms.len()) return;
        local alarm = alarms[index];
        if (alarm.on) {
            alarm.on = false;
            if (!alarm.repeat) alarm.done = true;
            if (debug) server.log("Alarm " + index + " silenced");
            alarmState = ALARM_STOP_FLASH;
        }
    }
}


// ********** NIGHT MODE FUNCTIONS **********
function setNight(value) {
    // ADDED IN 2.1.0
    // This function is called when the app enables or disables night mode
    // 'value' is passed in from the agent as a bool

    // Just set the preference because it will be applied almost immediately
    // via the 'clockTick()' loop
    settings.timer.isset = value;     

    // Disable the timer advance setting as it's only relevant if night mode is
    // on AND it has been triggered since night mode was enabled
    isAdvanceSet = false;

    local should = shouldShowDisplay();
    if (!should && !settings.timer.isset) {
        // Change the state of the display
        setDisplay(true);
        settings.on = true;
    }

    if (debug) server.log("Setting night mode " + (value ? "on" : "off"));
}

function setNightTime(data) {
    // ADDED IN 2.1.0
    // Record the times at which the display may turn on and off
    // NOTE The display will not actually change at these times unless
    //      'settings.timer.isset' is set, ie. we're in night mode
    settings.timer.on.hour = data.on.hour;
    settings.timer.on.min = data.on.min;
    settings.timer.off.hour = data.off.hour;
    settings.timer.off.min = data.off.min;
    
    if (debug) server.log("Night mode to start at " + format("%02i", settings.timer.on.hour) + ":" + format("%02i", settings.timer.on.min) + " and end at " + format("%02i", settings.timer.off.hour) + ":" + format("%02i", settings.timer.off.min));
}


// ********** OFFLINE OPERATION FUNCTIONS **********
function discHandler(event) {
    // Called if the server connection is broken or re-established
    if ("message" in event && debug) server.log("Connection Manager: " + event.message);

    if ("type" in event) {
        if (event.type == "disconnected") {
            isDisconnected = true;
            isConnecting = false;
            if (disTime == 0) disTime = event.ts;
        }

        if (event.type == "connecting") isConnecting = true;

        if (event.type == "connected") {
            // Check for settings changes
            agent.send("clock.get.prefs", 1);
            isDisconnected = false;
            isConnecting = false;
            
            if (disTime != 0) {
                local delta = event.ts - disTime;
                if (debug) server.log("Connection Manager: disconnection duration " + delta + " seconds");
                disTime = 0;
            }
        }
    }
}


// ********** START OF PROGRAM **********

// Load in generic boot message code
// NOTE If you're not using Squinter or an equivalent tool,
// cut and paste bootmessage.nut's code in place of the following line
#include "../generic/bootmessage.nut"

// Load in default prefs
setDefaultPrefs();

// Set up the network disconnection handler
disconnectionManager.eventCallback = discHandler;
disconnectionManager.reconnectDelay = DISCONNECT_TIMEOUT;
disconnectionManager.reconnectTimeout = RECONNECT_TIMEOUT;
disconnectionManager.start();

// Configure the display bus
hardware.i2c12.configure(CLOCK_SPEED_400_KHZ);

// Set up the clock display
display = HT16K33Segment(hardware.i2c12, 0x70);
display.init();

// Show the ‘sync’ message then give the text no more than
// 30 seconds to appear. If the prefs data comes from the
// agent before then, the text will automatically be cleared
// (and the timer cancelled)
syncText();
syncTimer = imp.wakeup(30.0, clockTick);

// Set up Agent notification response triggers
// First, settings-related actions
agent.on("clock.set.prefs", setPrefs);
agent.on("clock.set.bst", setBST);
agent.on("clock.set.mode", setMode);
agent.on("clock.set.utc", setUTC);
agent.on("clock.set.brightness", setBright);
agent.on("clock.set.flash", setFlash);
agent.on("clock.set.colon", setColon);
agent.on("clock.set.light", setLight);
agent.on("clock.set.debug", setDebug);
agent.on("clock.set.alarm", setAlarm);
agent.on("clock.clear.alarm", clearAlarm);
agent.on("clock.stop.alarm", stopAlarm);
agent.on("clock.set.nightmode", setNight);
agent.on("clock.set.nighttime", setNightTime);

// Next, other actions
agent.on("clock.do.reboot", function(dummy) {
    imp.reset();
});

// Get preferences from server
// NOTE no longer need this here as it's handled via DisconnectManager
// agent.send("clock.get.prefs", true);
// if (debug) server.log("Requesting preferences from agent");
