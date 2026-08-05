local channel = love.thread.getChannel'get'
local threadIndex = love.thread.getChannel'index'
local network = require'utils.network'

local index = threadIndex:demand()
local threadGood = true

local firstThreadFails = {}
local firstThreadRetryLimit = 1

while threadGood do
    local path = channel:demand()
    local good, err = network.ftpGetWrite(path)
    if not good then
        if index==1 then
            firstThreadFails[path] = (firstThreadFails[path] or 0)+1
            if firstThreadFails[path]<=firstThreadRetryLimit then
                channel:push(path)
            else
                feedback:push{{0.7, 0, 0.3}, path, ': Download failed.', '\n'}
            end
        else
            channel:push(path)
            feedback:push{{0.7, 0, 0.3}, ('Terminating FTP thread #%d'):format(index), '\n'}
            threadGood = nil
        end
    end
end
