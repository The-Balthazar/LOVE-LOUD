local maps = "-*(mount_contents[^\n\ra-zA-Z]*SHGetFolderPath[^\n\ra-zA-Z]*PERSONAL[^\n\ra-zA-Z]*My Games[^\n\ra-zA-Z]*Gas Powered Games[^\n\ra-zA-Z]*Supreme Commander Forged Alliance[^\n\ra-zA-Z]*maps[^\n\ra-zA-Z]*/maps[^\n\ra-zA-Z]*)"
local mods = "-*(mount_contents[^\n\ra-zA-Z]*SHGetFolderPath[^\n\ra-zA-Z]*PERSONAL[^\n\ra-zA-Z]*My Games[^\n\ra-zA-Z]*Gas Powered Games[^\n\ra-zA-Z]*Supreme Commander Forged Alliance[^\n\ra-zA-Z]*mods[^\n\ra-zA-Z]*/mods[^\n\ra-zA-Z]*)"
local stratReg = "mount_dir[^\n\ra-zA-Z]*InitFileDir[^\n\r]*BrewLAN.StrategicIcons[.*A-Za-z-]*scd[^\n\ra-zA-Z]*"
local stratForm = "mount_dir(InitFileDir .. '\\BrewLAN-StrategicIconsOverhaul-%s.scd', '/')"
local feedback = love.thread.getChannel'log'
local reps
require'utils.filesystem'

return function(stringData)
    local userConfig = userConfig or loadSaveFileData'userConfig' or {} -- this might be called from a thread that can't see globals.
    stringData, reps = stringData:gsub(maps, (not userConfig.docMaps and '--%1' or '%1'), 1)
    if reps~=1 then feedback:push{{0.7, 0, 0.3}, 'Failed to update LoudDataPath.lua with doc maps config\n'} end
    stringData, reps = stringData:gsub(mods, (not userConfig.docMods and '--%1' or '%1'), 1)
    if reps~=1 then feedback:push{{0.7, 0, 0.3}, 'Failed to update LoudDataPath.lua with doc mods config\n'} end
    stringData, reps = stringData:gsub(stratReg, stratForm:format(userConfig.iconSet or 'SMALL-classic'), 1)
    if reps~=1 then feedback:push{{0.7, 0, 0.3}, 'Failed to update LoudDataPath.lua with strategic icon config\n'} end
    return stringData
end
