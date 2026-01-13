require'love.timer'.sleep(0.5)

local writePath = love.filesystem.isFused() and 'SCFA/LOUD/' or ''
local feedback = love.thread.getChannel'log'

local lastLog = writePath..'bin/LOUD.log'

if love.filesystem.getInfo(lastLog) then
    local ok, chunk = pcall(love.filesystem.read, lastLog)
    if ok and chunk then
        require'utils.debug'.logAnalyse(chunk, false, 'previous game log')
    end
end
