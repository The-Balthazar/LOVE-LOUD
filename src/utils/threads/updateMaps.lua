local network = require'utils.network'
local feedback = love.thread.getChannel'log'
local updatingMarker = love.thread.getChannel'updatingMarker'
feedback:push'Fetching map library data'
local libdata = network.getMapLibData()

if type(libdata) == 'string' then
    love.thread.getChannel'wastefulSingleUseChannelToMarkMapUpdateComplete':push'no'
    return feedback:push{{0.7, 0, 0.3}, libdata, '\n'}
end

feedback:push'Checking maps'
for i, data in ipairs(libdata) do
    if data.outOfDate then
        updatingMarker:push{data.identifier, true}
        feedback:push(1)
    end
end
for i, data in ipairs(libdata) do
    if data.outOfDate then
        feedback:push(-1)
        network.getMap(data)
    end
end
feedback:push'All maps up to date'
love.thread.getChannel'wastefulSingleUseChannelToMarkMapUpdateComplete':push'yes'
