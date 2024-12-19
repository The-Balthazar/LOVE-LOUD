local repo = 'The-Balthazar/LOVE-LOUD'
local headers = {headers = {['user-agent']='LOVE-LOUD'}}
local feedback = love.thread.getChannel'log'

local code, body = require'https'.request(('https://api.github.com/repos/%s/releases/latest'):format(repo), headers)
if code~=200 then
    feedback:push(('LÖVE-LOUD self updater query failed: %d: %s'):format(code, body))
    return
end

local zipball_url = body:match('"zipball_url"%s*:%s*(%b"")%s*,')
local update_id = body:match('"url"%s*:%s*"https://api.github.com/repos/'..repo:gsub('-', '.')..'/releases/(%d*)"')
local tag_name = body:match('"tag_name"%s*:%s*(%b"")%s*,')
local changes = body:match('"body"%s*:%s*(%b"")%s*')
if not (update_id and zipball_url) then
    feedback:push('LÖVE-LOUD update response parse fail')
    return
end

if love.filesystem.read('string', 'version')==update_id then
    feedback:push('LÖVE-LOUD client is up to date: '..tag_name:sub(2, -2))
    return
end

local code, body = require'https'.request(zipball_url:sub(2,-2), headers)
if code~=200 then
    feedback:push(('Failed to download latest LÖVE-LOUD release: %d: %s'):format(code, body))
    return
end

local function crc32(str)
    local crc = 4294967295
    for i=1, #str do
        crc = bit.bxor(crc, string.byte(str, i))
        for i=1, 8 do
            crc = bit.band(crc, 1)==0 and bit.rshift(crc, 1) or bit.bxor(bit.rshift(crc, 1), 0xEDB88320)
        end
    end
    crc = bit.bxor(crc, 0xFFFFFFFF)
    if crc<0 then
        crc = crc+4294967296
    end
    return crc
end

local tempName = update_id..'_temp'
local tempArchive = tempName..'.zip'
love.filesystem.write(tempArchive, body)
love.filesystem.mount(tempArchive, tempName)

local srcPath = tempName..'/'..love.filesystem.getDirectoryItems(tempName)[1]..'/src'

local zipData, zipDir, offset, dirLength = {}, {}, 0, 0
local folderData = love.data.pack('string', '<I2I2I4I2I2 I8I8I8', 10, 32, 0, 1, 24, 0, 0, 0)
require'utils.filesystem'
forEachFile(srcPath, function(path, name)
    local fullPath = path..'/'..(name or '')
    local relPath = fullPath:sub(#srcPath+2)
    if relPath=='' then return end
    local zipVersion = 20
    local lastModTime, lastModDate = 29000, 22900

    local data = (name and love.filesystem.read('string', fullPath) or '')
    local dataC = name and love.data.compress('string', 'deflate', data) or data
    local size = #data
    local sizeC = #dataC
    local crc32 = crc32(data)
    local compression = data==dataC and 0 or 8
    local externalFileAttribs = name and 32 or 16

    local directory = love.data.pack('string', '<c4I2I2I2I2 I2I2 I4I4I4 I2I2I2I2I2 I4I4',
        'PK\1\2', zipVersion, zipVersion, 0, compression,
        lastModTime, lastModDate,
        crc32, sizeC, size,
        #relPath, #(folderData or ''), 0, 0, 0,
        externalFileAttribs, offset
    )..relPath..(folderData or '')
    dirLength = dirLength+#directory

    local file = love.data.pack('string', '<c4I2I2I2 I2I2 I4I4I4 I2I2',
        'PK\3\4', zipVersion, 0, compression,
        lastModTime, lastModDate,
        crc32, sizeC, size,
        #relPath, 0 -- filename length, extra length
    )..relPath..dataC
    offset = offset+#file

    table.insert(zipData, file)
    table.insert(zipDir, directory)
end)

local footer = love.data.pack('string', '<c4I2I2 I2I2 I4I4 I2',
    'PK\5\6', 0, 0,
    #zipDir, #zipDir,
    dirLength, offset,
    0
)

love.filesystem.write('loud.love', table.concat{
    table.concat(zipData),
    table.concat(zipDir),
    footer
})

love.filesystem.write('version', update_id)
love.filesystem.unmount(tempArchive)
love.filesystem.remove(tempArchive)

feedback:push({{1,1,1}, 'Restart LÖVE-LOUD to apply the update: ', {0.7,0.0,0.3}, tag_name:sub(2, -2), '\n'})

if changes then
    changes = loadstring('return '..changes)()
end
if type(changes)=='string' then
    for line in changes:gmatch('[^\r\n]+') do
        if line:match'^[^:]*:%s*http' then
            local title, link = line:match'^([^:]*):%s*(http.*)'
            feedback:push{'weblink', link, title:gsub('%*', '')}
        else
            line = (line:gsub('^%*%s*(.*[^.]+)%.?$', '%1   •') or line):gsub('%*%*', '*')
            local t = {{1,1,1}, line:match'^[^*]*' or ''}
            for bold, notbold in line:sub(#t[2]+1):gmatch('(%b**)([^*]*)') do
                table.insert(t, {0.7,0.3,0.0})
                table.insert(t, bold:sub(2, -2))
                if notbold and notbold~='' then
                    table.insert(t, {1,1,1})
                    table.insert(t, notbold)
                end
            end
            table.insert(t, '\n')
            feedback:push(t)
        end
    end
end
