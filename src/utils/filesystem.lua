function loadSaveFileData(filename)
    if not love.filesystem.getInfo(filename) then return end
    local saveData, message = love.filesystem.read( "string", filename)
    if 'string' == type(saveData) and saveData:find'^return %{' then
        local success, data = pcall(setfenv(loadstring(saveData, "saveData"), {}))
        if success then return data else return print(data) end
    end
end

function saveFileData(filename, saveData)
    love.filesystem.write(filename, table.serialize(saveData))
end

function saveUserConfig()
    if not userConfig then return end
    saveFileData('userConfig', userConfig)
end

function loadUpdatedLauncher(arg, argUnparsed)
    local feedback = love.thread.getChannel'log'
    if love.filesystem.getInfo'loud.love' and love.filesystem.mount('loud.love', '') then
        for k, v in pairs(package.loaded) do
            package.loaded[k] = nil
        end
        love.conf = nil
        love.init()
        love.load(arg, argUnparsed, true)
        return true
    end
end

function forEachFile(path, fun)
    if not (path and fun) then return end
    for i, name in ipairs(love.filesystem.getDirectoryItems(path)) do
        local thisPath = path..'/'..name
        local info = love.filesystem.getInfo(thisPath)
        if info.type=='directory' then
            fun(thisPath)
            forEachFile(thisPath, fun)
        else
            fun(path, name)
        end
    end
end
