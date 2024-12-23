local uiMode

function setUIMode(mode)
    uiMode = mode
    if uiMode.load then
        uiMode:load()
    end
    love.update(0)
    love.mousemoved(love.mouse.getX() or 0, love.mouse.getY() or 0, 0, 0)
end
function getUIMode() return uiMode end

function love.load(arg, argUnparsed, updated)
    userConfig = loadSaveFileData'userConfig' or {}
    uiMode = require'ui.intro'
    if not updated and loadUpdatedLauncher(arg, argUnparsed) then
        return
    end
    love.thread.newThread'utils/threads/updateLauncher.lua':start()
    love.resize(love.graphics.getDimensions())
    if love.filesystem.isFused() then
        assert(love.filesystem.mountFullPath(love.filesystem.getSourceBaseDirectory(), 'SCFA', 'readwrite', true), "Failed to mount game folder with write permissions.")
    end
end

local windowData = {}

function getWindowData() return windowData end

function love.resize(x,y)
    local w = windowData
    w.w, w.h = x, y
    w.scale = x/baseWindowWidth
    w.scaleY = y/baseWindowHeight
    if uiMode.resize then
        uiMode:resize(w)
    end
end

function love.update(delta)
    if uiMode.update then
        uiMode:update(delta)
    end
    if uiMode.objects then
        for i, v in ipairs(uiMode.objects) do
            if v.positional then --XN/YN normalised 0-1 screenspace values. XP/YP unscaled pixel values
                local w = windowData
                v.width = v.widthBase *w.scale
                v.height= v.heightBase*w.scale
                v.midX = v.posXN*w.w+(v.offsetXN and v.offsetXN*v.width  or 0)+(v.offsetXP and v.offsetXP*w.scale or 0)
                v.midY = v.posYN*w.h+(v.offsetYN and v.offsetYN*v.height or 0)+(v.offsetYP and v.offsetYP*w.scale or 0)
                v.cornerX = v.midX-v.width/2
                v.cornerY = v.midY-v.height/2
            end
            if v.update then
                v:update(uiMode, delta)
            end
        end
    end
end

function love.draw()
    if uiMode.draw then
        uiMode:draw(windowData)
    end
    if uiMode.objects then
        for i, v in ipairs(uiMode.objects) do
            if v.draw and (not v.showIf or v:showIf(uiMode)) then
                v:draw(uiMode, windowData)
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if uiMode.mousemoved then
        uiMode:mousemoved(x, y, dx, dy, istouch, windowData)
    end
    if uiMode.objects then
        for i, v in ipairs(uiMode.objects) do
            if v.mouse and v.positional and (not v.showIf or v:showIf(uiMode)) then
                local oldHover = v.mouseOver
                v.mouseOver = v.cornerX<x and v.cornerX+v.width>x and v.cornerY<y and v.cornerY+v.height>y
                if oldHover~=v.mouseOver and v.onHover then
                    v:onHover(uiMode)
                end
            end
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if uiMode.mousepressed then
        uiMode:mousepressed(x, y, button, istouch, presses)
    end
    if uiMode.objects then
        for i, v in ipairs(uiMode.objects) do
            if v.mouse and v.positional and v.mouseOver and v.onPress and (not v.showIf or v:showIf(uiMode)) then
                v:onPress(uiMode)
            end
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if uiMode.mousereleased then
        uiMode:mousereleased(x, y, button, istouch, presses)
    end
    if uiMode.objects then
        for i, v in ipairs(uiMode.objects) do
            if v.mouse and v.positional and v.mouseOver and v.onRelease and (not v.showIf or v:showIf(uiMode)) then
                v:onRelease(uiMode)
            end
        end
    end
end

function love.wheelmoved(x, y)
    if uiMode.wheelmoved then
        uiMode:wheelmoved(x, y)
    end
end

function love.keypressed(key, ...)
    if uiMode.keypressed then
        if uiMode:keypressed(key, ...) then
            return
        end
    end
    if key=='escape' and uiMode.goBack then
        uiMode:goBack()
    end
end

function love.textinput(...)
    if uiMode.textinput then
        uiMode:textinput(...)
    end
end
