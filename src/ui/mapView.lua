local selected
local textHeadings, textValues, textDesc
local white, grey = {1,1,1}, {0.5, 0.5, 0.5}
local throbber = love.graphics.newImage'graphics/throbber.png'
local writePath = love.filesystem.isFused() and 'SCFA/LOUD/' or ''
local downloading = {}
local outOfDate, localPath, scenarioInfoPath

return {
    set = function(self, data)
        if type(data)=='table' and type(data.file)=='string' then
            selected = data
            local font = love.graphics.getFont()
            textHeadings, textValues, textDesc = love.graphics.newTextBatch(font), love.graphics.newTextBatch(font), love.graphics.newTextBatch(font)

            textValues:setf({
                white, selected.name         or '<error: no name>', grey, '   (V', selected.version or '<error: no version>', ')',
                white, '\n', selected.author or '<error: no author>',
                '\n', selected.players       or '<error: no players>',
                '\n', getMapSizeFromIndex(selected.size)   or '<error: no size>',
                '\n', selected.downloads     or '<error: no downloads>',
            }, 308, 'left' )
            if textValues:getHeight()==90 then
                textHeadings:setf({
                    grey, 'Name:',
                    '\nAuthor:',
                    '\nPlayers:',
                    '\nSize:',
                    '\nDownloads:',
                }, 162, 'right' )
            else
                local temp = love.graphics.newTextBatch(font)
                local headings = {grey}
                for i, ps in ipairs{
                    {'Name:', (selected.name or '<error: no name>')..'   (V'..(selected.version or '<error: no version>')..')'},
                    {'\nAuthor:', selected.author or '<error: no author>'},
                    {'\nPlayers:',selected.players or '<error: no players>'},
                    {'\nSize:',   getMapSizeFromIndex(selected.size) or '<error: no size>'},
                    {'\nDownloads:', selected.downloads or '<error: no downloads>'},
                } do
                    temp:setf(ps[2], 308, 'left')
                    table.insert(headings, ps[1])
                    table.insert(headings, ('\n'):rep(temp:getHeight()/18-1))
                end
                textHeadings:setf(headings, 162, 'right' )
            end
            textDesc:setf({
                white, ('\n'):rep(textValues:getHeight()/18+1),
                selected.description and selected.description
                    :gsub('\\r', '\r')
                    :gsub('\\n', '\n')
                    :gsub('\\t', '\t')
                or '<error: no description>',
            }, 480, 'left' )
            localPath = ('%susermaps/%s'):format(writePath, selected.identifier)
            scenarioInfoPath = ('%susermaps/%s/%s_scenario.lua'):format(writePath, selected.identifier, selected.identifier)
            if love.filesystem.getInfo(scenarioInfoPath) then
                scenarioInfo = love.filesystem.read(scenarioInfoPath)
                local localVersion = (scenarioInfo:match('map_version%s*%=%s*([^,%s]*)%s*,') or '')
                outOfDate = tostring(selected.version):gsub('["\']', '')~=localVersion:gsub('["\']', '')
            end

            return true
        end
    end,
    update = function(self, delta)
        require'ui.mapLib':update(delta) -- fetch any incoming data for drawCached
    end,
    draw = function(self, w)
        if not selected then return end

        local textOffsetY = 320*w.scale
        local textSpace = w.h-textOffsetY
        local textOverflowing = (textDesc:getHeight()*w.scale)>textSpace

        local imageXpos, imageYpos, imageSize
        if w.scaleY>0.75 then
            imageXpos, imageYpos, imageSize = 575*w.scale, 100*w.scale, 540*math.min(w.scale, w.scaleY)
            if textOverflowing then
                require'ui.intro':draw(w, -270)
                textOffsetY = 50*w.scale
                imageYpos = textOffsetY
            else
                require'ui.intro':draw(w)
            end
        else
            require'ui.intro':draw(w, -310)
            imageYpos = 0
            imageSize = baseWindowHeight*w.scaleY
            imageXpos = baseWindowWidth*w.scale-imageSize
            textOffsetY = 10
        end

        if selected.thumbnail then drawCached(selected.thumbnail, imageXpos, imageYpos, imageSize, imageSize) end
        drawCached(selected.image,      imageXpos, imageYpos, imageSize, imageSize, selected.thumbnail)

        love.graphics.draw(textHeadings,248*w.scale, textOffsetY, 0, w.scale, w.scale, 162)
        love.graphics.draw(textValues,  258*w.scale, textOffsetY, 0, w.scale, w.scale)
        love.graphics.draw(textDesc,     86*w.scale, textOffsetY, 0, w.scale, w.scale)
    end,
    objects = {
        require'ui.elements.button'{
            icon = love.graphics.newImage'graphics/back.png',
            posXN = 0,
            posYN = 1,
            offsetXN = 0.5,
            offsetXP = 10,
            offsetYN = -0.5,
            offsetYP = -10,
            type = 'bigicon',
            onPress = function(self, UI)
                UI:goBack()
            end,
        },
        require'ui.elements.button'{
            text = 'Download',
            posXN = 0,
            posYN = 1,
            offsetXN = 0.5,
            offsetXP = 10,
            offsetYN = -1.5,
            offsetYP = -20,
            type = 'bigicon',
            onPress = function(self, UI)
                if self.inactive then return end
                love.filesystem.remove(scenarioInfoPath)
                love.thread.getChannel'getMap':push(selected)
                love.thread.newThread'utils/threads/getMap.lua':start()
                downloading[selected.identifier] = true
                selected.downloads = selected.downloads+1
                self.inactive = true
                outOfDate = nil
            end,
            update = function(self, UI, delta)
                if outOfDate then
                    self.inactive = nil
                    self.icon = nil
                    self.text = 'Update'
                elseif love.filesystem.getInfo(scenarioInfoPath) then
                    self.inactive = true
                    self.icon = nil
                    self.text = 'Installed'
                else
                    self.inactive = downloading[selected.identifier]
                    self.icon = downloading[selected.identifier] and throbber or nil
                    self.text = (not self.icon) and 'Download' or nil
                end
                self.iconAngle = love.timer.getTime()
            end,
        },
        require'ui.elements.button'{
            text = 'Uninstall',
            posXN = 0,
            posYN = 1,
            offsetXN = 0.5,
            offsetXP = 10,
            offsetYN = -2.5,
            offsetYP = -30,
            type = 'bigicon',
            onPress = function(self, UI)
                if self.inactive then return end
                downloading[selected.identifier] = nil
                outOfDate = nil
                require'utils.filesystem'
                forEachFile(localPath, function(path, name)
                    love.filesystem.remove(path..'/'..(name or ''))
                end)
                love.filesystem.remove(localPath)
            end,
            update = function(self, UI, delta)
                self.inactive = not love.filesystem.getInfo(scenarioInfoPath)
            end,
            showIf = function(self, UI)
                return love.filesystem.getInfo(scenarioInfoPath)
            end,
        },
    },
    goBack = function(self)
        setUIMode(require'ui.mapLib')
    end,
}
