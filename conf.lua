function love.conf(t)
    t.version = "11.5"
    --t.console = true
    love.filesystem.setIdentity'LOVE-LOUD'
    t.externalstorage = true
    t.window.fullscreen = false
    t.window.usedpiscale = false
    t.window.title = 'LÖVE LOUD'
    t.window.icon = 'graphics/icon/032-LOUD.png'
    t.window.resizable = true
    t.window.width  = 1152
    t.window.height = 648
end
