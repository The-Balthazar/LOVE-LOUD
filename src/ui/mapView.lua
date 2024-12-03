local selected
local textHeadings, textValues, textDesc
local white, grey, clear = {1,1,1}, {0.5, 0.5, 0.5}, {1,1,1,0}

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
                white, ('\n'):rep(textValues:getHeight()/18+1), selected.description and selected.description:gsub('\\r', '\r'):gsub('\\n', '\n') or '<error: no description>',
            }, 480, 'left' )

            return true
        end
    end,
    update = function(self, delta)
        require'ui.mapLib'.update(0) -- fetch any incoming data for drawCached
    end,
    draw = function(self, w)
        require'ui.intro'.draw(self)
        if not selected then return end
        drawCached(selected.image,      575*w.scale, 100*w.scale, 540*w.scale, 540*w.scale)
        love.graphics.draw(textHeadings, 86*w.scale, 320*w.scale, 0,  w.scale,     w.scale)
        love.graphics.draw(textValues,  258*w.scale, 320*w.scale, 0,  w.scale,     w.scale)
        love.graphics.draw(textDesc,     86*w.scale, 320*w.scale, 0,  w.scale,     w.scale)
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
    },
    goBack = function(self)
        setUIMode(require'ui.mapLib')
    end,
}
