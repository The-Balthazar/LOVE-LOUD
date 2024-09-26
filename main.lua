require'utils.maths'
require'utils.table'

local uiMode = require'ui.intro'

function setUIMode(mode) uiMode = mode end
function getUIMode() return uiMode end

function love.load()
    if love.filesystem.isFused() then
        love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), 'SCFA')
    end
    love.thread.newThread'utils/threads/update.lua':start()
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
