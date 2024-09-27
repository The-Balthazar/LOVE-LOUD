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

local writePath = love.filesystem.isFused() and 'SCFA/LOUD/' or ''
local exeFound = love.filesystem.getInfo'bin/SupremeCommander.exe'

function updateLoudDataPath()
    local path = writePath..'bin/LoudDataPath.lua'
    local str = love.filesystem.read("string", path)
    love.filesystem.write(path, require'utils.files.LoudDataPath'(str))
end

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
        require'ui.elements.button'{
            text = userConfig.docMods and 'Documents mods enabled' or 'Documents mods disabled',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -50,
            offsetYN = -0.5,
            offsetYP = -50,
            type = 'pencil',
            onPress = function(self, UI)
                userConfig.docMods = not userConfig.docMods
                self.text = userConfig.docMods and 'Documents mods enabled' or 'Documents mods disabled'
                saveUserConfig()
                updateLoudDataPath()
            end,
            onHover = function(self, UI)
                if self.mouseOver then
                    self.text = userConfig.docMods and 'Disable documents mods' or 'Enable documents mods'
                else
                    self.text = userConfig.docMods and 'Documents mods enabled' or 'Documents mods disabled'
                end
            end,
            update = function(self, UI, delta)
                self.inactive = not userConfig.docMods
            end,
        },
        require'ui.elements.button'{
            text = userConfig.docMaps and 'Documents maps enabled' or 'Documents maps disabled',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -50,
            offsetYN = -1.5,
            offsetYP = -55,
            type = 'pencil',
            onPress = function(self, UI)
                userConfig.docMaps = not userConfig.docMaps
                self.text = userConfig.docMaps and 'Documents maps enabled' or 'Documents maps disabled'
                saveUserConfig()
                updateLoudDataPath()
            end,
            onHover = function(self, UI)
                if self.mouseOver then
                    self.text = userConfig.docMaps and 'Disable documents maps' or 'Enable documents maps'
                else
                    self.text = userConfig.docMaps and 'Documents maps enabled' or 'Documents maps disabled'
                end
            end,
            update = function(self, UI, delta)
                self.inactive = not userConfig.docMaps
            end,
        },
        require'ui.elements.strategiciconbutton'('LARGE-classic',  -0.5, -300, -0.5, -50),
        require'ui.elements.strategiciconbutton'('LARGE',          -0.5, -300, -1.5, -55),
        require'ui.elements.strategiciconbutton'('MEDIUM-classic', -1.5, -305, -0.5, -50),
        require'ui.elements.strategiciconbutton'('MEDIUM',         -1.5, -305, -1.5, -55),
        require'ui.elements.strategiciconbutton'('SMALL-classic',  -2.5, -310, -0.5, -50),
        require'ui.elements.strategiciconbutton'('SMALL',          -2.5, -310, -1.5, -55),
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
