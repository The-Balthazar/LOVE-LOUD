local writePath = love.filesystem.isFused() and 'SCFA/LOUD/' or ''
local paths = {
    'bin',
    'doc',
    'gamedata',
    'maps',
    'sounds',
}

local SCFA_FileInfo = {}

local enumerate
function enumerate(path)
    for i, name in ipairs(love.filesystem.getDirectoryItems(path)) do
        local thisPath = path..'/'..name
        local info = love.filesystem.getInfo(thisPath)
        if info.type=='directory' then
            enumerate(thisPath)
        else
            local str = ('%s,0x%s,%d\n'):format(
                thisPath:gsub(writePath, '', 1):gsub('/', '\\'),
                love.data.encode('string', 'hex', love.data.hash('string', 'sha1', love.filesystem.read(thisPath))):upper(),
                info.size
            )
            table.insert(SCFA_FileInfo, str)
        end
    end
end

love.thread.getChannel'log':push('Generating CRC')
for i, path in ipairs(paths) do
    love.thread.getChannel'log':push('Enumerating: '..path)
    enumerate(writePath..path)
end

local infoPath = writePath..'SCFA_FileInfo.txt'
love.filesystem.write(infoPath, table.concat(SCFA_FileInfo))
love.thread.getChannel'log':push('SCFA_FileInfo.txt generated')
