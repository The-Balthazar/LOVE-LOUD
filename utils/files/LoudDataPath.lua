local maps = "-*(mount_contents[^\n\ra-zA-Z]*SHGetFolderPath[^\n\ra-zA-Z]*PERSONAL[^\n\ra-zA-Z]*My Games[^\n\ra-zA-Z]*Gas Powered Games[^\n\ra-zA-Z]*Supreme Commander Forged Alliance[^\n\ra-zA-Z]*maps[^\n\ra-zA-Z]*/maps[^\n\ra-zA-Z]*)"
local mods = "-*(mount_contents[^\n\ra-zA-Z]*SHGetFolderPath[^\n\ra-zA-Z]*PERSONAL[^\n\ra-zA-Z]*My Games[^\n\ra-zA-Z]*Gas Powered Games[^\n\ra-zA-Z]*Supreme Commander Forged Alliance[^\n\ra-zA-Z]*mods[^\n\ra-zA-Z]*/mods[^\n\ra-zA-Z]*)"
local feedback = love.thread.getChannel'log'
require'utils.filesystem'

return function(stringData)
    local userConfig = userConfig or loadSaveFileData'userConfig' or {} -- this might be called from a thread that can't see globals.
    stringData, reps = stringData:gsub(maps, (not userConfig.docMaps and '--%1' or '%1'), 1)
    if reps~=1 then feedback:push'Failed to update LoudDataPath.lua with doc maps config' end
    stringData, reps = stringData:gsub(mods, (not userConfig.docMods and '--%1' or '%1'), 1)
    if reps~=1 then feedback:push'Failed to update LoudDataPath.lua with doc mods config' end
    return stringData
end
