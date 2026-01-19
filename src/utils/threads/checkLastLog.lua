require'love.timer'.sleep(0.5)

local writePath = love.filesystem.isFused() and 'SCFA/LOUD/' or ''
local feedback = love.thread.getChannel'log'

local lastLog = writePath..'bin/LOUD.log'
local logInfo = love.filesystem.getInfo(lastLog)

if logInfo then
    local ok, chunk = pcall(love.filesystem.read, lastLog)
    if ok and chunk then
        local logTime = logInfo.modtime and os.date(' from %Y %B %d, %H:%M', logInfo.modtime) or ''
        require'utils.debug'.logAnalyse(chunk, false, 'previous game log'..logTime)

        local realPath = 'file://'..love.filesystem.getRealDirectory(lastLog)..(love.filesystem.isFused() and '/LOUD/' or '/')..'bin/LOUD.log'
        feedback:push{'weblink', realPath, 'View original log'}
    end
end
