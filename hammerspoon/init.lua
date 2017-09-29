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
    sparkTray:setTitle("spark")
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

local screenLog = hs.logger.new('screen-log')
screenLog.setLogLevel('info')

local screenWatcher = hs.caffeinate.watcher
function onScreenEvent(event)
    -- screenLog.i(event)
    if event == hs.caffeinate.watcher.systemWillSleep then
        screenLog.i("Deleting ~/.ansible-vault-password")
        hs.execute("rm -rf ~/.ansible-vault-password")
    end
end

screenWatcher.new(onScreenEvent):start()

