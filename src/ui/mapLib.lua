love.thread.newThread[[
love.thread.getChannel'mapLibData':push(
    require'utils.network'.getMapLibData()
)
while true do
    love.thread.getChannel'mapLibData':push{
        require'utils.network'.getMapLibFile(
            love.thread.getChannel'mapLibRequests':demand()
        )
    }
end
]]:start()
local mapsData, mapsDataUnfiltered
local imageCache = {}
local seton = love.graphics.newImage'graphics/map.png'
local throbber = love.graphics.newImage'graphics/throbber.png'
local folderIcon = love.graphics.newImage'graphics/folder.png'
local feedback = love.thread.getChannel'log'

local scroll = 0
local entriesPerRow = 9
local entriesY, entriesYBar, entriesPerPage, roundedEntries, barNormalSize, maxScroll, scrollNormal
local mouseHoverX, mouseHoverY, mouseHoverIndex
local frameCount, lastFetch = 0
local windowData = getWindowData()
local fullBar, smolBar, barGap
local mouseOverScroll, mousePressedOnScroll
local scrollBarSubdivisionSize

local function updateGridValues()
    entriesY = love.graphics.getHeight()/(110*windowData.scale)
    entriesYBar = math.floor(entriesY-0.8)
    entriesPerPage = entriesYBar*entriesPerRow
    roundedEntries = math.ceil((mapsData and #mapsData or 1)/entriesPerRow)*entriesPerRow
    barNormalSize = math.min(1, math.max(0.1, entriesPerPage/roundedEntries))
    maxScroll = math.ceil((roundedEntries-entriesPerPage)/entriesPerRow)
    scroll = math.max(0, math.min(maxScroll, scroll))
    scrollNormal = scroll/maxScroll
    fullBar = entriesYBar*110
    smolBar = entriesYBar*110*barNormalSize
    barGap = fullBar-smolBar
    scrollBarSubdivisionSize = barGap/maxScroll
end

updateGridValues()

function drawCached(filename, x, y, w, h, drawthrough)
    if filename and not imageCache[filename] then
        if love.filesystem.getInfo('temp/'..filename) then
            if frameCount~=lastFetch then
                imageCache[filename] = love.graphics.newImage('temp/'..filename)
                lastFetch = frameCount
            end
        else
            love.thread.getChannel'mapLibRequests':push(filename)
            imageCache[filename] = 'Loading'
        end
    end
    if filename and type(imageCache[filename])=='userdata' then
        love.graphics.draw(imageCache[filename], x, y, 0, w/imageCache[filename]:getWidth(), h/imageCache[filename]:getHeight())
    else
        if not drawthrough then
            love.graphics.draw(seton, x, y, 0, w/1024, h/1024)
        end
        love.graphics.setColor(0, 0, 0)
        love.graphics.draw(throbber, x+w/2, y+h/2, love.timer.getTime()*3, 1, 1, 20, 20)
        love.graphics.setColor(1, 1, 1)
    end
end

local downloading = {}

local filterData = {
    sizes = {},
    players = {},
}

local filtersSet = {sizes = {}, players = {}}
local filterInstalled = true

local sizes = {
    [-2] = '1.28 km',
    [-1] = '2.56 km',
    [0]  = '5.12 km',
    '10.24 km',
    '20.48 km',
    '40.96 km',
    '81.92 km',
}

function getMapSizeFromIndex(index) return sizes[index] end

function isDownloading(id) return downloading[id] end

function findMapDataById(id)
    if not mapsData then return end
    for i, map in ipairs(mapsData) do
        if map.identifier==id then
            return map
        end
    end
end

function markAsDownloading(id, val)
    downloading[id] = val
    local data = findMapDataById(id)
    if not data then return end
    data.outOfDate = nil
    if val then
        data.downloads = data.downloads+1--NOTE: Just for local view.
    else
        data.localScenarioPath = data.localScenarioPath or findMapScenarioLua(data.localPath)
    end
end

local searchFilterKey, searchButton, searchFilterButtons = 'name'

local function deselectSearch()
    if type(searchButton.text)=='table' then
        searchButton.text = searchButton.searchText[2]
        love.keyboard.setTextInput(false)
        return true
    end
end

local function updateFiltered()
    if not mapsDataUnfiltered then mapsDataUnfiltered = mapsData end
    mapsData = {}
    local searchFilter = searchButton.searchText and searchButton.searchText[2] and searchButton.searchText[2]~='' and searchButton.searchText[2]
    for i, map in ipairs(mapsDataUnfiltered) do
        if  (not next(filtersSet.sizes) or filtersSet.sizes[map.size])
        and (not next(filtersSet.players) or filtersSet.players[map.players])
        and (filterInstalled or not (map.localScenarioPath and love.filesystem.getInfo(map.localScenarioPath)))
        and (not searchFilter or map[searchFilterKey or 'name']:lower():match(searchFilter:lower()))
        then
            table.insert(mapsData, map)
        end
    end
    updateGridValues()
end

local searchIndicatorBlinkTimer

searchButton = require'ui.elements.button'{
    text = 'Search',
    icon = love.graphics.newImage'graphics/search.png',
    posXN = 0,
    posYN = 0,
    offsetXN = 0.5,
    offsetXP = 86,
    offsetYN = 0.5,
    offsetYP = 35,
    widthBase = 150,
    heightBase = 30,
    onPress = function(self, UI)
        searchIndicatorBlinkTimer = love.timer.getTime()
        self.text = self.searchText or {{1,1,1}, '', {1,1,1,1}, '|'}
        self.searchText = self.text
        love.keyboard.setTextInput(true)
    end,
    update = function(self, UI)
        if searchIndicatorBlinkTimer and type(self.text)=='table' then
            self.text[3][4] = math.floor((love.timer.getTime()-searchIndicatorBlinkTimer-1)%2)
        end
    end,
}

searchFilterButtons = {
    {key='name',text='Name'},
    {key='author',text='Author'},
    {key='description',text='Body text'},
}

local function getAndApplyLibraryData(self)
    if not mapsData and love.thread.getChannel'mapLibData':peek() then
        mapsData = love.thread.getChannel'mapLibData':pop()

        if type(mapsData)=='string' then
            feedback:push{{0.7, 0, 0.3}, mapsData}
            return setUIMode(require'ui.menu')
        end

        for i, map in ipairs(mapsData) do
            filterData.players[map.players] = (filterData.players[map.players] or 0)+1
            filterData.sizes[map.size] = (filterData.sizes[map.size] or 0)+1
        end

        local index = 0
        for i=4, -2, -1 do
            if filterData.sizes[i] then
                table.insert(self.objects, require'ui.elements.button'{
                    text = sizes[i]:match'^(%d*)'..'k',
                    inactive = true,
                    posXN = 1,
                    posYN = 0,
                    offsetXN = -0.5-index,
                    offsetXP = -86-index*5,
                    offsetYN = 0.5,
                    offsetYP = 35,
                    widthBase = 30,
                    heightBase = 30,
                    onPress = function(self, UI)
                        filtersSet.sizes[i] = not filtersSet.sizes[i] or nil
                        self.inactive = not filtersSet.sizes[i]
                        pcall(updateFiltered)
                    end,
                })
                index = index+1
            end
        end

        table.insert(self.objects, require'ui.elements.button'{
            text = 'Installed',
            posXN = 1,
            posYN = 0,
            offsetXN = -0.5,
            offsetXP = -91-(index*35),
            offsetYN = 0.5,
            offsetYP = 35,
            widthBase = 90,
            heightBase = 30,
            onPress = function(self, UI)
                filterInstalled = not filterInstalled
                self.inactive = not filterInstalled
                pcall(updateFiltered)
            end,
        })

        index = 0
        for i=1, 16 do
            if filterData.players[i] then
                table.insert(self.objects, require'ui.elements.button'{
                    text = i,
                    inactive = true,
                    posXN = 1,
                    posYN = 0,
                    offsetYN = 0.5+index,
                    offsetYP = 100+index*5,
                    offsetXN = -0.5,
                    offsetXP = -28,
                    widthBase = 30,
                    heightBase = 30,
                    onPress = function(self, UI)
                        filtersSet.players[i] = not filtersSet.players[i] or nil
                        self.inactive = not filtersSet.players[i]
                        pcall(updateFiltered)
                    end,
                })
                index = index+1
            end
        end

        table.insert(self.objects, searchButton)
        for i, base in ipairs(searchFilterButtons) do
            local key = base.key
            searchFilterButtons[base.key] = base
            base.inactive = searchFilterKey~=base.key
            base.posXN = 0
            base.posYN = 0
            base.offsetXN = 0.5+(i-1)
            base.offsetXP = 236+i*5
            base.offsetYN = 0.5
            base.offsetYP = 35
            base.widthBase = 60
            base.heightBase = 30
            base.onPress = function(self, UI)
                searchFilterKey = self.key
                for i, base in ipairs(searchFilterButtons) do
                    base.inactive = searchFilterKey~=base.key
                end
                pcall(updateFiltered)
            end
            table.insert(self.objects, require'ui.elements.button'(base))
        end

        updateGridValues()
    end
end

return {
    keypressed = function(self, key, ...)
        if key=='escape' then
            if deselectSearch() then
                return true
            end
        elseif key=='backspace' and type(searchButton.text)=='table' then
            searchButton.text[2] = searchButton.text[2]:sub(1,-2)
            searchIndicatorBlinkTimer = love.timer.getTime()
            pcall(updateFiltered)
        end
    end,
    textinput = function(self, t)
        if type(searchButton.text)=='table' then
            searchButton.text[2] = searchButton.text[2]..t
            searchIndicatorBlinkTimer = love.timer.getTime()
            pcall(updateFiltered)
        end
    end,
    update = function(self, delta)
        frameCount = frameCount+1
        getAndApplyLibraryData(self)
        while love.thread.getChannel'mapLibData':peek() do
            local val = love.thread.getChannel'mapLibData':pop()
            if type(val)=='table' and imageCache[val[1]] then
                local path, filename = val[1]:match'(.*)(/[^/]*)'
                love.filesystem.createDirectory('temp/'..path)
                love.filesystem.write('temp/'..path..filename, val[2])
                imageCache[val[1]] = love.graphics.newImage('temp/'..path..filename)
            end
        end
        if not mapsData then return end
        while love.thread.getChannel'updatingMarker':peek() do
            markAsDownloading(unpack(love.thread.getChannel'updatingMarker':pop()))
        end
    end,
    draw = function(self, w)
        require'ui.intro':draw(w)
        local i = scroll*entriesPerRow
        for y=0, math.floor(entriesY-1) do
            for x=0, entriesPerRow-1 do
                i = i+1
                if not mapsData or mapsData[i] then
                    drawCached(mapsData and (mapsData[i].thumbnail or mapsData[i].image), (86+x*110)*w.scale, (100+y*110)*w.scale, (100)*w.scale, (100)*w.scale)
                    if y==mouseHoverY and x==mouseHoverX then
                        love.graphics.rectangle('line', (86+x*110)*w.scale, (100+y*110)*w.scale, (100)*w.scale, (100)*w.scale, w.scale/2, w.scale/2, 1)
                    end
                    if mapsData then
                        if isDownloading(mapsData[i].identifier) then
                            love.graphics.setColor(0,0,0)
                            for xx=-2, 2, 2 do
                                for yy=-2, 2, 2 do
                                    love.graphics.draw(throbber, (xx+91+x*110)*w.scale, (yy+195+y*110)*w.scale, love.timer.getTime()*2, w.scale/2, w.scale/2, 20, 20)
                                end
                            end
                            love.graphics.setColor(1,1,1)
                            love.graphics.draw(throbber, (91+x*110)*w.scale, (195+y*110)*w.scale, love.timer.getTime()*2, w.scale/2, w.scale/2, 20, 20)
                        elseif mapsData[i].localScenarioPath and love.filesystem.getInfo(mapsData[i].localScenarioPath) then
                            if mapsData[i].outOfDate then
                                love.graphics.setColor(1,0,0)
                            end
                            love.graphics.draw(folderIcon, (86+x*110)*w.scale, (100+y*110)*w.scale, 0, w.scale, w.scale, 10, -80)
                            love.graphics.setColor(1,1,1)
                        end
                    end
                end
            end
        end
        if barNormalSize~=1 then
            love.graphics.setColor(0.17, 0.17, 0.17)
            love.graphics.rectangle('fill', 1076*w.scale, 100*w.scale, 10*w.scale, (fullBar-10)*w.scale, 5*w.scale, 5*w.scale, 10)
            if mouseOverScroll and not mousePressedOnScroll then
                love.graphics.setColor(1,1,1)
            end
            love.graphics.rectangle('line', 1076*w.scale, 100*w.scale, 10*w.scale, (fullBar-10)*w.scale, 5*w.scale, 5*w.scale, 10)
            if mousePressedOnScroll then
                love.graphics.setColor(1,1,1)
            else
                love.graphics.setColor(0.5, 0.5, 0.5)
            end
            love.graphics.rectangle('fill', 1078*w.scale, (102+(barGap*scrollNormal))*w.scale, 6*w.scale, (smolBar-14)*w.scale, 3*w.scale, 3*w.scale, 10)
            love.graphics.rectangle('line', 1078*w.scale, (102+(barGap*scrollNormal))*w.scale, 6*w.scale, (smolBar-14)*w.scale, 3*w.scale, 3*w.scale, 10)
            love.graphics.setColor(1,1,1)
        end
    end,
    mousemoved = function(self, x, y, dx, dy, istouch, w)
        mouseHoverX, mouseHoverY, mouseHoverIndex = nil, nil, nil
        x, y = (x/w.scale)-81, (y/w.scale)-95
        mouseOverScroll = x>990 and y>0 and x<1010 and y
        if mousePressedOnScroll and math.abs(mousePressedOnScroll-y)>scrollBarSubdivisionSize then
            local count = math.floor((mousePressedOnScroll-y)/scrollBarSubdivisionSize)
            scroll = scroll-count
            mousePressedOnScroll = mousePressedOnScroll-(count*scrollBarSubdivisionSize)
            updateGridValues()
        end
        if mouseOverScroll then return end
        if x<0 or y<0 or x>entriesPerRow*110 then return end
        local xMod, yMod = y%110, x%110
        if yMod<5 or yMod>105 or xMod<5 or xMod>105 then return end
        mouseHoverX, mouseHoverY = math.floor(x/110), math.floor(y/110)
        mouseHoverIndex = 1+mouseHoverX+(scroll+mouseHoverY)*entriesPerRow
    end,
    mousepressed = function(self, x, y, button, istouch, presses)
        deselectSearch()
        if mouseOverScroll and not mousePressedOnScroll then
            mousePressedOnScroll = mouseOverScroll
        end
        if mousePressedOnScroll or mouseOverScroll then
            return
        end
        if mouseHoverIndex and mapsData and mapsData[mouseHoverIndex] then
            if require'ui.mapView':set(mapsData[mouseHoverIndex]) then
                setUIMode(require'ui.mapView')
            end
        end
    end,
    mousereleased = function(self, x, y, button, istouch, presses)
        if mousePressedOnScroll then
            mousePressedOnScroll = nil
        end
    end,
    wheelmoved = function(self, x, y)
        if not mapsData then return end
        scroll = scroll-y
        updateGridValues()
    end,
    resize = function(self, w)
        windowData = w
        updateGridValues()
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
            widthBase = 60,
            heightBase = 60,
            onPress = function(self, UI)
                UI:goBack()
            end,
        },
    },
    goBack = function(self)
        setUIMode(require'ui.menu')
    end,
}
