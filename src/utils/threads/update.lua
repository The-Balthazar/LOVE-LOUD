local getChannel = love.thread.getChannel'get'
local feedback = love.thread.getChannel'log'
local writePath = love.filesystem.isFused() and 'SCFA/LOUD/' or ''
local threads = {}

feedback:push'Checking for updates'

local fileinfo = require'utils.network'.ftpGet('SCFA_FileInfo.txt')
local cleanFiles, checkEmpty = {}, {}
local toClean = {
    maps = 'usermaps',
    gamedata = 'gamedata.unsupported'
}

for folder, file, hash, size in (fileinfo):gmatch'([^\r\n]+)\\([^\r\n\\]+),0x([0-9A-F]+),([0-9]+)' do
    local remotePath = folder..'/'..file
    local localPath = writePath..remotePath:gsub('\\', '/')
    local hashLocal = love.filesystem.getInfo(localPath) and love.data.encode('string', 'hex', love.data.hash('string', 'sha1', love.filesystem.read(localPath))):upper()
    if hashLocal~=hash then
        getChannel:push(remotePath)
        feedback:push(1)
        if #threads<5 then
            table.insert(threads, love.thread.newThread'utils/threads/getWrite.lua')
            feedback:push('Starting FTP thread #'..#threads)
            threads[#threads]:start()
        end
    end
    if toClean[folder] or toClean[folder:match'^[^/\\]*'] then
        cleanFiles['/'..localPath] = folder
    end
end

function recursiveGetDirectoryItems(folder, list)
    list = list or {}
    for i, filename in ipairs(love.filesystem.getDirectoryItems(folder)) do
        local filePath = folder..'/'..filename
        local info = love.filesystem.getInfo(filePath)
        if info and info.type == 'file' then
            table.insert(list, filePath)
        elseif info and info.type == 'directory' then
            recursiveGetDirectoryItems(filePath, list)
        end
    end
    return list
end

function rename(path, newpath)
    if not path or not newpath then return print('Rename not given two paths') end
    if path==newpath then           return print('Rename given the same path twice:', path) end

    local file = love.filesystem.read(path)
    if not file then                return print("Rename: file not found:", path) end

    feedback:push(('Moving %s to %s'):format(path, newpath))

    love.filesystem.createDirectory(newpath:match'(.*)/[^/]*')
    if love.filesystem.write(newpath, file) then
        return love.filesystem.remove(path)
    end
end

for checkFolder, output in pairs(toClean) do
    for i, path in ipairs(recursiveGetDirectoryItems(writePath..'/'..checkFolder)) do
        if not cleanFiles[path] then
            if rename(path, (path:gsub(checkFolder, output, 1))) then
                checkEmpty[ path:match'(.*)/[^/]*' ] = true
            end
        end
    end
end

function removeFolderIfEmpty(folder)
    if not love.filesystem.getDirectoryItems(folder)[1] then
        return love.filesystem.remove(folder)
    end
end

for folder in pairs(checkEmpty) do
    while folder:find'/' do
        if not removeFolderIfEmpty(folder) then
            break
        end
        folder=folder:match'(.*)/[^/]*'
    end
    removeFolderIfEmpty(folder)
end
