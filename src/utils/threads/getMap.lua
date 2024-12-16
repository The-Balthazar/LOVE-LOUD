local channel = love.thread.getChannel'getMap'
local network = require'utils.network'

network.getMap(channel:demand())
