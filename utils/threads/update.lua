local getChannel = love.thread.getChannel'get'
local feedback = love.thread.getChannel'log'
local threads = {}

feedback:push'Checking for updates'

local fileinfo = require'utils.network'.ftpGet('SCFA_FileInfo.txt')

for folder, file, hash, size in (fileinfo):gmatch'([^\r\n]+)\\([^\r\n\\]+),0x([0-9A-F]+),([0-9]+)' do
    local fullPath = folder..'/'..file
    local hashLocal = love.filesystem.getInfo((fullPath:gsub('\\', '/'))) and love.data.encode('string', 'hex', love.data.hash('sha1', love.filesystem.read((fullPath:gsub('\\', '/'))))):upper()

    if folder:match'[^\r\n\\]+'~='maps' and hashLocal~=hash then
        getChannel:push(fullPath)
        feedback:push(1)
        if #threads<5 then
            table.insert(threads, love.thread.newThread'utils/threads/getWrite.lua')
            feedback:push('Starting FTP thread #'..#threads)
            threads[#threads]:start()
        end
    end
end
