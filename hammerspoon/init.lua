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
