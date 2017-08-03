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
    screen = hs.screen.find("Thunderbolt Display")
    hs.application.get("Cisco Spark"):mainWindow():moveToScreen(screen)
end

if sparkTray then
    sparkTray:setTitle("spark")
    sparkTray:setClickCallback(sparkTrayClicked)
end
