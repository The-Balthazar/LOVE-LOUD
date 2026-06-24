require'utils.maths'
require'utils.table'
require'utils.system'
require'utils.filesystem'
require'utils.localization'

function love.conf(t)
    t.version = "12.0"
    t.console = not love.filesystem.isFused()
    love.filesystem.setIdentity'LOVE-LOUD'
    t.externalstorage = true
    t.window.fullscreen = false
    t.window.usedpiscale = false
    t.window.title = 'LÖVE LOUD'
    t.window.icon = 'graphics/icon/032-LOUD.png'
    t.window.resizable = true
    baseWindowWidth, baseWindowHeight = 1152, 677
    t.window.width  = baseWindowWidth
    t.window.height = baseWindowHeight
    pcall(function()
        require'love.window'
        local width, height = love.window.getDesktopDimensions()
        if t.window.width>=width or t.window.height>=height then
            t.window.width = width*0.9
            t.window.height = height*0.9
        end
    end)
end
