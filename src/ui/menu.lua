local feedback = love.thread.getChannel'log'
local log, visibleLog = {}
local files = {}
local done = 0
local todo = 0
local updating, launching, allStarted

local writePath = love.filesystem.isFused() and 'SCFA/LOUD/' or ''
local exeFound = love.filesystem.getInfo('SCFA/bin/SupremeCommander.exe') and 'bin/SupremeCommander.exe' or love.filesystem.getInfo('SCFA/bin/ForgedAlliance.exe') and 'bin/ForgedAlliance.exe'

function updateLoudDataPath()
    local path = writePath..'bin/LoudDataPath.lua'
    local str = love.filesystem.read("string", path)
    love.filesystem.write(path, require'utils.files.LoudDataPath'(str))
end

local throbber = love.graphics.newImage'graphics/throbber.png'
local folderIcon = love.graphics.newImage'graphics/folder.png'
local githubIcon = love.graphics.newImage'graphics/github.png'

menuActiveTab = 'config'
local buttonUpColour = {0,22/255,38/255}

local logTop = 337
local logWidth = 556
local logScrollOffset = 0
local logMaxHeight = 185
local logHeightTester = love.graphics.newTextBatch(love.graphics.getFont())

local function getLogLength()
    local len = 0
end

local function getLogEntryHeight(entry)
    logHeightTester:setf(entry.logObject or entry, logWidth, 'right')
    return logHeightTester:getHeight()
end

local function trimVisibleLog(self)
    for i=#self.objects, 1, -1 do
        if self.objects[i].logObject then
            table.remove(self.objects, i)
        end
    end
    visibleLog = {}
    local scale = love.graphics.getWidth()/1152
    logMaxHeight = math.floor((love.graphics.getHeight()/scale)-(logTop+155))
    local logStartIndex
    local scrollMaxed
    do
        local checkHeight = 0
        local maxFit
        for i=#log+logScrollOffset, 1, -1 do
            checkHeight = checkHeight+getLogEntryHeight(log[i])
            if logMaxHeight<checkHeight then
                break
            else
                logStartIndex = i
            end
            if i==1 then
                scrollMaxed = true
            end
        end
    end
    if not logStartIndex then return end
    local logRelativePos = 0
    local lastLog
    for i=logStartIndex, #log do
        local entry = log[i]
        local height = getLogEntryHeight(entry)
        if logRelativePos+height<logMaxHeight then
            if entry.logObject then
                table.insert(visibleLog, entry.logObject)
                table.insert(self.objects, entry)
                entry.offsetYP=logTop+logRelativePos+(entry.logOffset or 0)
            else
                for j, v in ipairs(entry) do
                    table.insert(visibleLog, v)
                end
            end
            logRelativePos = logRelativePos+height
            lastLog = i
        end
    end
    if scrollMaxed then
        logScrollOffset = lastLog-#log
    end
end

--[[
NOTE: On scheme colours:
    LOUD blue: {0,   0.4, 0.7}
    Scarlet:   {0.7, 0,   0.3}
    Lime:      {0.4, 0.7, 0}
    Orange     {0.7, 0.3, 0.0}
    Loud Invert{1,   0.6, 0.3}
]]

return {
    resize = function(self, w)
        trimVisibleLog(self)
    end,
    wheelmoved = function(self, x, y)
        logScrollOffset = math.min(math.max(-#log+1, logScrollOffset-y), 0)
        trimVisibleLog(self)
    end,
    update = function(self, delta)
        while feedback:peek() do
            local msg = feedback:pop()
            local msgType = type(msg)
            if msg=='allOpperationsStarted' then
                allStarted = true
            elseif msgType=='number' then
                todo=todo+msg
            elseif msgType=='string' then
                table.insert(log, {{1,1,1}, msg, '\n'})
                logScrollOffset = 0
                trimVisibleLog(self)
            elseif msgType=='table' and type(msg[1])=='table' then
                table.insert(log, msg)
                logScrollOffset = 0
                trimVisibleLog(self)
            elseif msgType=='table' and msg[1]=='weblink' then
                local link, title = msg[2], msg[3]
                local shortlink = #link<=26 and link:match'https?://(.*)' or link:sub(1,22):match'https?://(.*)'..'...'
                table.insert(log, require'ui.elements.button'{
                    logObject = '\n\n',
                    text = title or shortlink,
                    posXN = 1,
                    posYN = 0,
                    offsetXN = -0.5,
                    offsetXP = -20,
                    offsetYN = 0.5,
                    offsetYP = 0,
                    logOffset = 4,
                    widthBase = 150,
                    heightBase = 30,
                    icon = link:match'github' and githubIcon or nil,
                    onPress = function(self, UI)
                        love.system.openURL(link)
                    end,
                    onHover = function(self, UI)
                        if self.mouseOver then
                            self.text = shortlink
                        else
                            self.text = title or shortlink
                        end
                    end,
                })
                logScrollOffset = 0
                trimVisibleLog(self)
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
                end
            end
        end
        if updating and allStarted and todo==done then
            updating = false
            allStarted = nil
            feedback:push'Finished updating'
        end
    end,
    objects = {
        require'ui.elements.button'{
            text = exeFound and 'Launch game' or 'Game exe not found',
            inactive = not exeFound,
            posXN = 0,
            posYN = 1,
            offsetXN = 0.5,
            offsetXP = 50,
            offsetYN = -0.5,
            offsetYP = -50,
            widthBase = 197,
            heightBase = 60,
            onPress = function(self, UI)
                if updating then return end
                if self.inactive then return end
                self.inactive = true
                self.text = 'Launching'
                launching = true
                osCall(exeFound, '/log "..\\LOUD\\bin\\LOUD.log" /init "..\\LOUD\\bin\\LoudDataPath.lua"')
                os.exit()
            end,
            update = function(self, UI, delta)
                if exeFound then
                    self.inactive = updating or ( (#files+todo+done)>0 and todo~=done )
                end
            end,
        },

        require'ui.elements.button'{
            text = 'Update LOUD',
            posXN = 0,
            posYN = 1,
            offsetXN = 0.5,
            offsetXP = 297,
            offsetYN = -0.5,
            offsetYP = -50,
            widthBase = 150,
            heightBase = 60,
            onPress = function(self, UI)
                if launching then return end
                if self.inactive then return end
                self.inactive = true
                updating = true
                self.text = 'Updating'
                self.icon = throbber
                love.thread.newThread'utils/threads/update.lua':start()
            end,
            update = function(self, UI, delta)
                if not updating and self.text=='Updating' then
                    self.text = 'LOUD Updated'
                    self.icon = nil
                end
                self.iconAngle = love.timer.getTime()*2
            end,
        },
        require'ui.elements.button'{
            text = 'Update maps',
            posXN = 0,
            posYN = 1,
            offsetXN = 1.5,
            offsetXP = 302,
            offsetYN = -0.5,
            offsetYP = -50,
            widthBase = 150,
            heightBase = 60,
            onPress = function(self, UI)
                if launching then return end
                if self.inactive then return end
                self.inactive = true
                self.text = 'Updating'
                self.icon = throbber
                love.thread.newThread'utils/threads/updateMaps.lua':start()
            end,
            update = function(self, UI, delta)
                if self.inactive then
                    local val = love.thread.getChannel'wastefulSingleUseChannelToMarkMapUpdateComplete':pop()
                    if val=='yes' then
                        self.text = 'Maps updated'
                        self.icon = nil
                    elseif val=='no' then
                        self.text = 'Retry map update'
                        self.inactive = nil
                        self.icon = nil
                    end
                end
                self.iconAngle = love.timer.getTime()*2
            end,
        },
        require'ui.elements.button'{
            icon = love.graphics.newImage'graphics/maps.png',
            posXN = 0,
            posYN = 1,
            offsetXN = 0.5,
            offsetXP = 607,
            offsetYN = -0.5,
            offsetYP = -50,
            widthBase = 60,
            heightBase = 60,
            onPress = function(self, UI)
                setUIMode(require'ui.mapLib')
            end,
        },

        require'ui.elements.button'{
            text = 'Game config',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -335,
            offsetYN = -0.5,
            offsetYP = -125,
            widthBase = 100,
            heightBase = 30,
            update = function(self, UI, delta)
                self.inactive = menuActiveTab~='config'
            end,
            onPress = function(self, UI)
                menuActiveTab = 'config'
            end,
        },
        require'ui.elements.button'{
            text = 'Folder links',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -230,
            offsetYN = -0.5,
            offsetYP = -125,
            widthBase = 100,
            heightBase = 30,
            update = function(self, UI, delta)
                self.inactive = menuActiveTab~='folders'
            end,
            onPress = function(self, UI)
                menuActiveTab = 'folders'
            end,
        },
        require'ui.elements.button'{
            text = 'Web links',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -125,
            offsetYN = -0.5,
            offsetYP = -125,
            widthBase = 100,
            heightBase = 30,
            update = function(self, UI, delta)
                self.inactive = menuActiveTab~='links'
            end,
            onPress = function(self, UI)
                menuActiveTab = 'links'
            end,
        },
        require'ui.elements.button'{
            width = 50,
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -50,
            offsetYN = -0.5,
            offsetYP = -125,
            widthBase = 30,
            heightBase = 30,
            icon = love.graphics.newImage'graphics/wrench.png',
            update = function(self, UI, delta)
                self.inactive = menuActiveTab~='dev'
            end,
            onPress = function(self, UI)
                menuActiveTab = 'dev'
            end,
        },
        {
            positional = true,
            widthBase = 385,
            heightBase = 5,
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetYN = -0.5,
            offsetXP = -50,
            offsetYP = -120,
            draw = function(self, UI, w)
                love.graphics.setColor(buttonUpColour)
                love.graphics.rectangle('fill', self.cornerX, self.cornerY, self.width, self.height)
                love.graphics.setColor(1,1,1)
            end,
        },

        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='config' end,
            text = userConfig.docMods and 'Documents mods enabled' or 'Documents mods disabled',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -85,
            offsetYN = -0.5,
            offsetYP = -50,
            widthBase = 200,
            heightBase = 30,
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
            showIf = function(self, UI, delta) return menuActiveTab=='config' end,
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -50,
            offsetYN = -0.5,
            offsetYP = -50,
            widthBase = 30,
            heightBase = 30,
            icon = folderIcon,
            onPress = function(self, UI)
                love.system.openURL(love.filesystem.getFullCommonPath'userdocuments'..'/my games/Gas Powered Games/Supreme Commander Forged Alliance/mods')
            end,
        },
        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='config' end,
            text = userConfig.docMaps and 'Documents maps enabled' or 'Documents maps disabled',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -85,
            offsetYN = -1.5,
            offsetYP = -55,
            widthBase = 200,
            heightBase = 30,
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
        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='config' end,
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -50,
            offsetYN = -1.5,
            offsetYP = -55,
            widthBase = 30,
            heightBase = 30,
            icon = folderIcon,
            onPress = function(self, UI)
                love.system.openURL(love.filesystem.getFullCommonPath'userdocuments'..'/my games/Gas Powered Games/Supreme Commander Forged Alliance/maps')
            end,
        },
        require'ui.elements.strategiciconbutton'('LARGE-classic',  -0.5, -335, -0.5, -50),
        require'ui.elements.strategiciconbutton'('LARGE',          -0.5, -335, -1.5, -55),
        require'ui.elements.strategiciconbutton'('MEDIUM-classic', -1.5, -340, -0.5, -50),
        require'ui.elements.strategiciconbutton'('MEDIUM',         -1.5, -340, -1.5, -55),
        require'ui.elements.strategiciconbutton'('SMALL-classic',  -2.5, -345, -0.5, -50),
        require'ui.elements.strategiciconbutton'('SMALL',          -2.5, -345, -1.5, -55),

        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='folders' end,
            text = 'LOUD.log folder',
            posXN = 1,
            posYN = 1,
            offsetXN = -1.5,
            offsetXP = -55,
            offsetYN = -1.5,
            offsetYP = -55,
            widthBase = 190,
            heightBase = 30,
            icon = folderIcon,
            onPress = function(self, UI)
                love.system.openURL(love.filesystem.getRealDirectory(writePath)..(love.filesystem.isFused() and '/LOUD/bin' or '/bin'))
            end,
        },
        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='folders' end,
            text = 'Replays folder',
            posXN = 1,
            posYN = 1,
            offsetXN = -1.5,
            offsetXP = -55,
            offsetYN = -0.5,
            offsetYP = -50,
            widthBase = 190,
            heightBase = 30,
            icon = folderIcon,
            onPress = function(self, UI)
                love.system.openURL(love.filesystem.getFullCommonPath'userdocuments'..'/my games/Gas Powered Games/Supreme Commander Forged Alliance/replays')
            end,
        },
        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='folders' end,
            text = 'LOUD user maps',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -50,
            offsetYN = -1.5,
            offsetYP = -55,
            widthBase = 190,
            heightBase = 30,
            icon = folderIcon,
            onPress = function(self, UI)
                love.filesystem.createDirectory(writePath..'usermaps')
                love.system.openURL(love.filesystem.getRealDirectory(writePath)..(love.filesystem.isFused() and '/LOUD/usermaps' or '/usermaps'))
            end,
        },
        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='folders' end,
            text = 'LOUD user mods',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -50,
            offsetYN = -0.5,
            offsetYP = -50,
            widthBase = 190,
            heightBase = 30,
            icon = folderIcon,
            onPress = function(self, UI)
                love.filesystem.createDirectory(writePath..'usermods')
                love.system.openURL(love.filesystem.getRealDirectory(writePath)..(love.filesystem.isFused() and '/LOUD/usermods' or '/usermods'))
            end,
        },

        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='links' end,
            text = 'Unit wiki',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -345,
            offsetYN = -1.5,
            offsetYP = -55,
            widthBase = 90,
            heightBase = 30,
            icon = githubIcon,
            onPress = function(self, UI)
                love.system.openURL('https://github.com/LOUD-Project/Git-LOUD/wiki/')
            end,
            onHover = function(self, UI)
                if self.mouseOver then
                    self.text = 'github...'
                else
                    self.text = 'Unit wiki'
                end
            end,
        },
        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='links' end,
            text = 'Donate on PayPal',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -145,
            offsetYN = -1.5,
            offsetYP = -55,
            widthBase = 195,
            heightBase = 30,
            icon = love.graphics.newImage'graphics/pp.png',
            onPress = function(self, UI)
                love.system.openURL('https://paypal.me/TheLOUDProject')
            end,
            onHover = function(self, UI)
                if self.mouseOver then
                    self.text = 'paypal.me/TheLOUDProject'
                else
                    self.text = 'Donate on PayPal'
                end
            end,
        },
        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='links' end,
            text = 'OneDrive',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -50,
            offsetYN = -1.5,
            offsetYP = -55,
            widthBase = 90,
            heightBase = 30,
            icon = love.graphics.newImage'graphics/onedrive.png',
            onPress = function(self, UI)
                love.system.openURL('https://onedrive.live.com/?authkey=!APAfOJusxNHJJWM&id=730910080073E6E6!4068&cid=730910080073E6E6')
            end,
            onHover = function(self, UI)
                if self.mouseOver then
                    self.text = 'live.com...'
                else
                    self.text = 'OneDrive'
                end
            end,
        },
        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='links' end,
            text = 'LOUD changelog',
            posXN = 1,
            posYN = 1,
            offsetXN = -1.5,
            offsetXP = -55,
            offsetYN = -0.5,
            offsetYP = -50,
            widthBase = 190,
            heightBase = 30,
            icon = githubIcon,
            onPress = function(self, UI)
                love.system.openURL('https://github.com/LOUD-Project/Git-LOUD/blob/master/CHANGELOG.txt')
            end,
            onHover = function(self, UI)
                if self.mouseOver then
                    self.text = 'github.com... changelog.txt'
                else
                    self.text = 'LOUD changelog'
                end
            end,
        },
        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='links' end,
            text = 'LOUD Discord',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -50,
            offsetYN = -0.5,
            offsetYP = -50,
            widthBase = 190,
            heightBase = 30,
            icon = love.graphics.newImage'graphics/discord.png',
            onPress = function(self, UI)
                love.system.openURL('https://discord.gg/ZCC6tns6vb')
            end,
            onHover = function(self, UI)
                if self.mouseOver then
                    self.text = 'discord.gg/ZCC6tns6vb'
                else
                    self.text = 'LOUD Discord'
                end
            end,
        },

        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='dev' end,
            text = 'Generate SCFA_FileInfo.txt',
            posXN = 1,
            posYN = 1,
            offsetXN = -1.5,
            offsetXP = -55,
            offsetYN = -1.5,
            offsetYP = -55,
            widthBase = 190,
            heightBase = 30,
            onPress = function(self, UI)
                love.thread.newThread'utils/threads/generateCRC.lua':start()
            end,
        },
        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='dev' end,
            text = 'LOUD source code',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -50,
            offsetYN = -1.5,
            offsetYP = -55,
            widthBase = 190,
            heightBase = 30,
            icon = githubIcon,
            onPress = function(self, UI)
                love.system.openURL('https://github.com/LOUD-Project/Git-LOUD')
            end,
            onHover = function(self, UI)
                if self.mouseOver then
                    self.text = 'github.com/LOUD-Project'
                else
                    self.text = 'LOUD source code'
                end
            end,
        },
        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='dev' end,
            text = 'LOVE-LOUD source code',
            posXN = 1,
            posYN = 1,
            offsetXN = -0.5,
            offsetXP = -50,
            offsetYN = -0.5,
            offsetYP = -50,
            widthBase = 190,
            heightBase = 30,
            icon = githubIcon,
            onPress = function(self, UI)
                love.system.openURL('https://github.com/The-Balthazar/LOVE-LOUD')
            end,
            onHover = function(self, UI)
                if self.mouseOver then
                    self.text = 'github.com/.../LOVE-LOUD'
                else
                    self.text = 'LOVE-LOUD source code'
                end
            end,
        },
        require'ui.elements.button'{
            showIf = function(self, UI, delta) return menuActiveTab=='dev' end,
            text = 'Shortcut/launch commands',
            posXN = 1,
            posYN = 1,
            offsetXN = -1.5,
            offsetXP = -55,
            offsetYN = -0.5,
            offsetYP = -50,
            widthBase = 190,
            heightBase = 30,
            onPress = function(self, UI)
                setUIMode(require'ui.help.shortcut')
            end,
        },
    },
    draw = function(self, w)
        require'ui.intro'.draw(self, w)
        local scale = w.scale
        love.graphics.printf((visibleLog or log), 576*scale, logTop*scale, logWidth, 'right', 0, scale, scale)
        if updating~=nil or (#files+todo+done)>0 then
            love.graphics.printf(('Files downloading: %d   Queued: %d   Finished: %d'):format(#files, todo, done), 20*scale, logTop*scale, logWidth, 'right', 0, scale, scale)
        end
        for i, text in ipairs(files) do
            love.graphics.printf(files[text], 20*scale, (logTop+(i)*20)*scale, logWidth, 'right', 0, scale, scale)
        end
    end,
}
