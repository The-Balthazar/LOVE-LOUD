require'utils.maths'
require'utils.table'

local uiMode = require'ui.intro'

function setUIMode(mode) uiMode = mode end
function getUIMode() return uiMode end

function love.load()
    love.resize(love.graphics.getDimensions())
    if love.filesystem.isFused() then
        assert(love.filesystem.mountFullPath(love.filesystem.getSourceBaseDirectory(), 'SCFA', 'readwrite', true), "Failed to mount game folder with write permissions.")
    end
end

local windowData = {}

function love.resize(x,y)
    local w = windowData
    w.w, w.h = x, y
    w.scale = x/1152
    w.scaleY = y/648
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
        uiMode:draw()
    end
    if uiMode.objects then
        for i, v in ipairs(uiMode.objects) do
            if v.draw then
                v:draw(uiMode, windowData)
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if uiMode.objects then
        for i, v in ipairs(uiMode.objects) do
            if v.mouse and v.positional then
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
    if uiMode.objects then
        for i, v in ipairs(uiMode.objects) do
            if v.mouse and v.positional and v.mouseOver and v.onPress then
                v:onPress(uiMode)
            end
        end
    end
end
