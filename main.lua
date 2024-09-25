local ftp = require'socket.ftp'

local uiMode = require'ui.intro'

function setUIMode(mode) uiMode = mode end
function getUIMode() return uiMode end

function love.load()
    require'utils.maths'
    for i, v in pairs(ftp) do
        print(i, type(v), v)
    end
end

function love.update(delta)
    if uiMode.update then
        uiMode:update(delta)
    end
end

function love.draw()
    if uiMode.draw then
        uiMode:draw()
    end
end
