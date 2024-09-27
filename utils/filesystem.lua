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
