-- Load config from a configfile
-- Sample:
-- {
--   "monit": {
--     "username": "foo",
--     "password": "bar,
--     "host": "http://10.0.01:1234"
--   }
-- }

local f = io.open(hs.fs.pathToAbsolute("~").."/.hammerspoon-user-config.json", "rb")
local CONFIG = hs.json.decode(f:read("*all"))
f:close()

------------------------------------------------------------
-- AIRPODS input switching
------------------------------------------------------------
airpodsTray = hs.menubar.new()

function trayClicked()
    output = hs.execute("/usr/local/bin/SwitchAudioSource -s 'Built-in Microphone' -t input")
    hs.alert.show(output)
end

if airpodsTray then
    airpodsTray:setTitle("si")
    airpodsTray:setClickCallback(trayClicked)
end

-----------------------------------------------------------
-- Spark switch screen
-----------------------------------------------------------
sparkTray = hs.menubar.new()

function sparkTrayClicked()
    thunderboltDisplay = hs.screen.find("Thunderbolt Display")
    dx80 = hs.screen.find("DX80")
    -- raise() => Move screen to top but don't put the focus on it
    sparkWindow = hs.application.get("Cisco Spark"):mainWindow()
    -- If spark is on the DX80, move it to the thunderboltDisplay, otherwise,
    -- move it to the DX80
    if sparkWindow:screen() == dx80 then
        sparkWindow:moveToScreen(thunderboltDisplay):raise()
    else
        sparkWindow:moveToScreen(dx80):raise()
    end
end

if sparkTray then
    -- sparkTray:setTitle("spark")
    sparkTray:setIcon(hs.configdir.."/spark-tray-icon.png")
    sparkTray:setClickCallback(sparkTrayClicked)
end

-----------------------------------------------------------
-- Spark new contact
-----------------------------------------------------------
-- Use [[ my multi-line string ]] for mult-line strings
CONTACT_APPLESCRIPT=[[tell application "System Events"
	tell process "Cisco Spark"
		set plusButton to button "+" of splitter group 1 of splitter group 1 of window 1
		click plusButton
		set popOver to pop over 1 of plusButton
		UI elements of popOver
		set contactPersonButton to button "B" of popOver
		click contactPersonButton
	end tell
end tell]]

-- Thank you kind sir: https://github.com/Hammerspoon/hammerspoon/issues/664#issuecomment-202829038
sparkHotKeys = hs.hotkey.new('⌘', 'k', function()
      hs.osascript.applescript(CONTACT_APPLESCRIPT)
  end)
--
hs.window.filter.new('Cisco Spark')
    :subscribe(hs.window.filter.windowFocused,function() sparkHotKeys:enable() end)
    :subscribe(hs.window.filter.windowUnfocused,function() sparkHotKeys:disable() end)

--------------------------------------------------------
-- Delete ansible vault file on sleep
--------------------------------------------------------

local screenLog = hs.logger.new('screen-log', 'info')
screenLog.setLogLevel('info')

function onScreenEvent(event)
    -- screenLog.i(event)
    if event == hs.caffeinate.watcher.systemWillSleep then
        screenLog.i("Deleting ~/.ansible-vault-password")
        hs.execute("rm -rf ~/.ansible-vault-password")
    end
end

local screenWatcher = hs.caffeinate.watcher
screenWatcher.new(onScreenEvent):start()


--------------------------------------------------------
-- Monit status tray icon
--------------------------------------------------------
-- NOTE: This makes use of the xml2json command: npm install -g xml2json-command

local statusLog = hs.logger.new('status-log', 'info')

local statusTray = hs.menubar.new()
statusTray:setTitle(hs.styledtext.new("●", { color = { red = 0, blue = 1, green = 0 }, font = {size=16}}))

-- Replace any $ signs with \$ in config values because we'll be using these in bash commands and without
-- escaping this will cause problems
local monit_host = CONFIG['monit']['host']:gsub("%$", "\\$")
local monit_username = CONFIG['monit']['username']:gsub("%$", "\\$")
local monit_password = CONFIG['monit']['password']:gsub("%$", "\\$")

hs.timer.doEvery(5, function ()
    -- Get status from configured Monit host
    -- We use this using curl so we can pipe the output into xml2json and then deal with json in hammerspoon
    -- Much easier than to download a lua XML lib and do the parsing that way
    local command = "curl -su '"..monit_username..":"..monit_password.."' "..
                    monit_host.."/_status?format=xml | xml2json"
    local output = hs.execute(command, true)
    data = hs.json.decode(output)

    -- some helper variables
    local now_sec = hs.execute('date +%s')
    local now_full = hs.execute('date "+%Y-%m-%d %H:%M:%S"')
    local TYPE_LOOKUP = { ["4"] = "service", ["5"] = "system", ["7"] = "program" }
    local statusTable = { }
    local overallStatus = 0

    -- Add a menuitem for every service we encounter
    local services = data['monit']['service']
    for i = 1, #services do
      local name = services[i]['name']['$t']
      local type = services[i]['type']
      local collected_sec = services[i]['collected_sec']['$t']
      local time_diff_sec = now_sec - collected_sec
      local status_code = services[i]['status']['$t']
      local status = "[OK]"
      if status_code ~= "0" then
        status = "[NOK]"
      end
      overallStatus = overallStatus + status_code

      local menuItem = "["..TYPE_LOOKUP[type].."] "..name.."  ("..time_diff_sec.."s ago)  "..status
      -- insert menuItem at i + 2 to account for first two rows
      statusTable[i] = { title = menuItem, fn = function()
          hs.urlevent.openURL(monit_host.."/"..name)
      end }
    end
    statusTable[#statusTable + 1] = { title = "-"}
    statusTable[#statusTable + 1] = { title="Last ran "..now_full, disabled = true}

    -- Modify the status icon based on overallStatus. All OK =  green icon, otherwise = red icon.
    if overallStatus > 0 then
      statusTray:setTitle(hs.styledtext.new("●", { color = { red = 1, blue = 0, green = 0 }, font = {size=16}}))
    else
      statusTray:setTitle(hs.styledtext.new("●", { color = { red = 0, blue = 0, green = 1 }, font = {size=16}}))
    end

    statusTray:setMenu(statusTable)
end)
