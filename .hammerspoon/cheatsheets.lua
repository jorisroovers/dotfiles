windowLog = hs.logger.new('window-log', 'info')

webViewRect = hs.geometry.rect(1200, 100, 500, 500)
cheatsheetScreen = hs.screen.find('DESKPRO')
windowLog.i(hs.inspect.inspect(cheatsheetScreen))
cheatsheetWebview = hs.webview.new(cheatsheetScreen:localToAbsolute(webViewRect))

function onWindowChange(appName, event)
    if event == hs.application.watcher.activated then
        windowLog.i(hs.inspect.inspect(appName), hs.inspect.inspect(event))
        cheatsheetPath = hs.fs.pathToAbsolute("~").."/.cheatsheets/" .. appName .. ".html"
        
        if hs.fs.attributes(cheatsheetPath) ~= nil then -- check if file exists
            url = hs.http.encodeForQuery("file://" .. cheatsheetPath)
            cheatsheetWebview:url(url)
            -- windowLog.i(url)
            
            -- Always be on top of other screens:
            -- cheatsheetWebview:level(hs.drawing.windowLevels["normal"]+1)
            cheatsheetWebview:show()
        else
            cheatsheetWebview:hide()
        end

    end
end

watcher = hs.application.watcher.new(onWindowChange)
watcher:start()
