-- General note, don't use 'local' variables because those get garbage collected after a while:
--- https://github.com/Hammerspoon/hammerspoon/issues/1103#issuecomment-264663745

-- Load config from a configfile
-- Sample:
-- {
--   "sensu": {
--     "username": "foo",
--     "password": "bar,
--     "host": "http://10.0.0.1:1234"
--   },
--   "uchiwa": {
--        "host": "http://10.0.0.1:5678"
--    }
-- }

f = io.open(hs.fs.pathToAbsolute("~").."/.hammerspoon-user-config.json", "rb")
CONFIG = hs.json.decode(f:read("*all"))
f:close()

------------------------------------------------------------
-- AIRPODS input switching
------------------------------------------------------------
--airpodsTray = hs.menubar.new()

function trayClicked()
    output = hs.execute("/usr/local/bin/SwitchAudioSource -s 'Built-in Microphone' -t input")
    hs.alert.show(output)
end

--if airpodsTray then
--    airpodsTray:setTitle("si")
--    airpodsTray:setClickCallback(trayClicked)
--end

-----------------------------------------------------------
-- Spark switch screen
-----------------------------------------------------------
--sparkTray = hs.menubar.new()

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

--if sparkTray then
    -- sparkTray:setTitle("spark")
--    sparkTray:setIcon(hs.configdir.."/spark-tray-icon.png")
--    sparkTray:setClickCallback(sparkTrayClicked)
--end

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
-- sparkHotKeys = hs.hotkey.new('⌘', 'k', function()
--      hs.osascript.applescript(CONTACT_APPLESCRIPT)
--  end)
--
-- hs.window.filter.new('Cisco Spark')
--    :subscribe(hs.window.filter.windowFocused,function() sparkHotKeys:enable() end)
--    :subscribe(hs.window.filter.windowUnfocused,function() sparkHotKeys:disable() end)

--------------------------------------------------------
-- Delete ansible vault file on sleep
--------------------------------------------------------

screenLog = hs.logger.new('screen-log', 'info')
screenLog.setLogLevel('info')

function onScreenEvent(event)
    -- screenLog.i(event)
    if event == hs.caffeinate.watcher.systemWillSleep then
        screenLog.i("Deleting ~/.ansible-vault-password")
        hs.execute("rm -rf ~/.ansible-vault-password")
    end
end

screenWatcher = hs.caffeinate.watcher
screenWatcher.new(onScreenEvent):start()


--------------------------------------------------------
-- Sensu status tray icon
--------------------------------------------------------

-- statusLog = hs.logger.new('status-log', 'info')

-- statusTray = hs.menubar.new()
-- statusTray:setTitle(hs.styledtext.new("●", { color = { red = 0, blue = 1, green = 0 }, font = {size=16}}))

-- Replace any $ signs with \$ in config values because we'll be using these in bash commands and without
-- escaping this will cause problems

-- sensu_host = CONFIG['sensu']['host']:gsub("%$", "\\$")
-- sensu_username = CONFIG['sensu']['username']:gsub("%$", "\\$")
-- sensu_password = CONFIG['sensu']['password']:gsub("%$", "\\$")
-- uchiwa_host = CONFIG['uchiwa']['host']:gsub("%$", "\\$")

-- statusTimer = hs.timer.new(5, function ()
--     statusLog.i("Running timer")
--     -- curl options: -s -> silent (no download bar), -m 1 -> 1 second timeout
--     command = "curl -m 1 -su '"..sensu_username..":"..sensu_password.."' "..
--                     sensu_host.."/results/casa-client"
--     output = hs.execute(command, true)
--     data = hs.json.decode(output)
--     if data == nil then
--       statusLog.i("No data received from sensu, skipping iteration")
--       statusTray:setTitle(hs.styledtext.new("●", { color = { red = 0, blue = 1, green = 0 }, font = {size=16}}))
--       return
--     else
--       statusLog.i("Data received")
--     end

--     -- some helper variables
--     now_sec = hs.execute('date +%s')
--     now_full = hs.execute('date "+%Y-%m-%d %H:%M:%S"')
--     statusTable = { }
--     overallStatus = 0
--     urlTable = {}
--     -- Add a menuitem for every check we encounter
--     checks = data
--     -- statusLog.i(hs.inspect.inspect(checks))
--     for i = 1, #checks do

--         check = checks[i]['check']
--         name = check['name']
--         collected_sec = check['executed']
--         time_diff_sec = now_sec - collected_sec
--         status_code = check['status']
--         status =  hs.styledtext.new("●", { color = { red = 0, blue = 0, green = 1 }, font = {size=16}})
--         if status_code ~= 0 then
--             status =  hs.styledtext.new("●", { color = { red = 1, blue = 0, green = 0 }, font = {size=16}})
--         end
--         overallStatus = overallStatus + status_code

--         menuItem = status..hs.styledtext.new(" "..name.." ("..time_diff_sec.."s ago) ", {font = {size=16}})

--         -- insert menuItem at i + 2 to account for first two rows
--         uchiwa_url = uchiwa_host.."#/client/casa/"..checks[i]['client'].."?check="..name
--         statusTable[i] = { title = menuItem, name=name, url=uchiwa_url, fn = function(keyModifiers, source)
--             hs.urlevent.openURL(source.url)
--         end }
--     end

--     -- sort status table alphabetically
--     table.sort(statusTable, function(item1, item2)
--         -- String comparison in Lua is based on ASCII order so we need to make both strings lower-case,
--         -- otherwise strings starting with capitals will be sorted in front of those without (as capital letters come
--         -- first in the ASCII table)
--         -- Note also that the comparison has to be strict (equal strings should return false when compared)
--         -- otherwise Lua will error with: "invalid order function"
--         return string.lower(item1.name) < string.lower(item2.name)
--     end )

--     statusTable[#statusTable + 1] = { title = "-"}
--     statusTable[#statusTable + 1] = { title="Last ran "..now_full, disabled = true}

--     -- Modify the status icon based on overallStatus. All OK =  green icon, otherwise = red icon.
--     if overallStatus > 0 then
--       statusTray:setTitle(hs.styledtext.new("●", { color = { red = 1, blue = 0, green = 0 }, font = {size=16}}))
--     else
--       statusTray:setTitle(hs.styledtext.new("●", { color = { red = 0, blue = 0, green = 1 }, font = {size=16}}))
--     end

--     statusTray:setMenu(statusTable)
--     statusLog.i("end of timer function")
-- end,true) -- true => continueOnError

-- Disabled
-- statusTimer:start()


--------------------------------------------------------
-- Boostnote insert date hotkey
--------------------------------------------------------

-- todayHotkey = hs.hotkey.new('ctrl', ';', function()
--    hs.eventtap.keyStrokes(os.date("%Y-%m-%d"))
-- end)
--
-- hs.window.filter.new('Boostnote')
--   :subscribe(hs.window.filter.windowFocused,function() todayHotkey:enable() end)
--   :subscribe(hs.window.filter.windowUnfocused,function() todayHotkey:disable() end)

----------------------------------------------------------
-- Network enabled/disable
----------------------------------------------------------

networkLog = hs.logger.new('network-log', 'info')
networkStatusTray = hs.menubar.new()
networkStatusTray:setTitle(hs.styledtext.new("●", { color = { red = 0, blue = 1, green = 0 }, font = {size=16}}))

networkConf = hs.network.configuration.open()
-- TODO: Find this interface key based on the "Display Ethernet" name instead of hardcoding it
networkLinkKey = "State:/Network/Interface/en8/Link"
-- result = networkConf:keys(".*")
-- networkLog.i(hs.inspect.inspect(result))

function updateLinkStatus(networkConf, keys)
    linkStatus = networkConf:contents(networkLinkKey)
    if linkStatus then
        -- networkLog.i(hs.inspect.inspect(linkStatus))
        -- networkLog.i(linkStatus[networkLinkKey].Active)
        linkActive = linkStatus[networkLinkKey].Active
        if linkActive then
            networkStatusTray:setTitle(hs.styledtext.new("●", { color = { red = 0, blue = 0, green = 1 }, font = {size=16}}))
        else
            networkStatusTray:setTitle(hs.styledtext.new("●", { color = { red = 1, blue = 0, green = 0 }, font = {size=16}}))
        end
    end
end

updateLinkStatus(networkConf, nil)

networkConf:monitorKeys(networkLinkKey)
networkConf:setCallback(updateLinkStatus)
networkConf:start()


function networkStatusTrayClicked()
    -- output = hs.execute("/usr/local/bin/SwitchAudioSource -s 'Built-in Microphone' -t input")
    linkStatus = networkConf:contents(networkLinkKey)
    if linkStatus then
        linkActive = linkStatus[networkLinkKey].Active
        if linkActive then
            hs.alert.show("Disabling local network connection for 30 sec")
            output = hs.execute("/usr/sbin/networksetup -setnetworkserviceenabled 'Display Ethernet' off")
            hs.timer.doAfter(30, function()
                hs.alert.show("Auto re-enabling network after 30 sec")
                output = hs.execute("/usr/sbin/networksetup -setnetworkserviceenabled 'Display Ethernet' on")
            end)
        else
            hs.alert.show("Enabling local network")
            output = hs.execute("/usr/sbin/networksetup -setnetworkserviceenabled 'Display Ethernet' on")
        end
    end

end
if networkStatusTray then
    networkStatusTray:setClickCallback(networkStatusTrayClicked)
end