local feedback = love.thread.getChannel'log'
local log = {}
local files = {}
local done = 0
local todo = 0

return {
    update = function(self, delta)
        while feedback:peek() do
            local msg = feedback:pop()
            local msgType = type(msg)
            if msgType=='number' then
                todo=todo+1
            elseif msgType=='string' then
                table.insert(log, msg)
            elseif msgType=='table' then
                local file = msg[1]
                local state = msg[2]
                files[file] = {{1,1,1}, file, ': ', {0,125/255,215/255}, state}
                if state=='downloading' then
                    table.insert(files, file)
                elseif state=='done' then
                    table.removeByValue(files, file)
                    files[file]=nil
                    done=done+1
                    if todo==done then
                        feedback:push'Finished updating'
                    end
                end
            end
        end
    end,
    draw = function(self)
        require'ui.intro'.draw(self)
        local scale = love.graphics.getWidth()/1152
        for i, text in ipairs(log) do
            love.graphics.printf(text, 576*scale, (337+(i-1)*20)*scale, 556, 'right', 0, scale, scale)
        end
        love.graphics.printf(('Files downloading: %d   Queued: %d   Finished: %d'):format(#files, todo, done), 20*scale, 337*scale, 556, 'right', 0, scale, scale)
        for i, text in ipairs(files) do
            love.graphics.printf(files[text], 20*scale, (337+(i)*20)*scale, 556, 'right', 0, scale, scale)
        end
    end,
}
