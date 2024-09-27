local feedback = love.thread.getChannel'log'
local log = {}
local files = {}
local done = 0
local todo = 0
local updating, launching

function osCall(call, options)
    local b = package.cpath:match'%p[\\|/]?%p(%a+)'
    if b == "dll" then -- windows
        os.execute('start cmd /c call "'..call..'" '..(options or ''))
    elseif b == "dylib" then -- macos
        os.execute('chmod +x "'..call..'" '..(options or ''))
    elseif b == "so" then -- Linux
        os.execute('chmod +x "'..call..'" '..(options or ''))
    end
end

local exeFound = love.filesystem.getInfo'bin/SupremeCommander.exe'

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
                        updating = false
                        feedback:push'Finished updating'
                    end
                end
            end
        end
    end,
    objects = {
        require'ui.elements.button'{
            text = 'Update',
            posXN = 0,
            posYN = 1,
            offsetXN = 0.5,
            offsetXP = 50,
            offsetYN = -0.5,
            offsetYP = -50,
            type = 'regular',
            onPress = function(self, UI)
                if launching then return end
                if self.inactive then return end
                self.inactive = true
                updating = true
                self.text = 'Updating'
                love.thread.newThread'utils/threads/update.lua':start()
            end,
            update = function(self, UI, delta)
                if not updating and self.text=='Updating' then
                    self.text = 'Updated'
                end
            end,
        },
        require'ui.elements.button'{
            text = exeFound and 'Launch game' or 'Game exe not found',
            inactive = not exeFound,
            posXN = 0,
            posYN = 1,
            offsetXN = 1.5,
            offsetXP = 100,
            offsetYN = -0.5,
            offsetYP = -50,
            type = 'regular',
            onPress = function(self, UI)
                if updating then return end
                if self.inactive then return end
                self.inactive = true
                self.text = 'Launching'
                launching = true
                osCall('bin/SupremeCommander.exe', '/log "..\\LOUD\\bin\\Loud.log" /init "..\\LOUD\\bin\\LoudDataPath.lua"')
                os.exit()
            end,
            update = function(self, UI, delta)
                if exeFound then
                    self.inactive = updating
                end
            end,
        },
    },
    draw = function(self)
        require'ui.intro'.draw(self)
        local scale = love.graphics.getWidth()/1152
        for i, text in ipairs(log) do
            love.graphics.printf(text, 576*scale, (337+(i-1)*20)*scale, 556, 'right', 0, scale, scale)
        end
        if updating~=nil then
            love.graphics.printf(('Files downloading: %d   Queued: %d   Finished: %d'):format(#files, todo, done), 20*scale, 337*scale, 556, 'right', 0, scale, scale)
        end
        for i, text in ipairs(files) do
            love.graphics.printf(files[text], 20*scale, (337+(i)*20)*scale, 556, 'right', 0, scale, scale)
        end
    end,
}
