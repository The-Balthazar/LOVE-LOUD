local channel = love.thread.getChannel'get'
local network = require'utils.network'

while true do
    network.ftpGetWrite(channel:demand())
end
