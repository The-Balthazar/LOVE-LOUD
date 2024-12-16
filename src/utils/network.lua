local ftp = require'socket.ftp' --https://lunarmodules.github.io/luasocket/ftp.html
local ltn12 = require'ltn12'
local feedback = love.thread.getChannel'log'
local writePath = love.filesystem.isFused() and 'SCFA/LOUD/' or ''
require'utils.filesystem'

local network = {}

function network.ftpGet(path)
    local sink = {}
    local good, err = ftp.get{
        host    = 'ftp.theloudproject.org',
        path    = '/LOUD/'..(path:gsub('\\', '/')),
        sink    = ltn12.sink.table(sink),
        user    = 'ftploud',
        password= 'ftploud123',
        port    = 21,
    }
    if not good then return feedback:push((path or 'no path')..': '..(err or 'no error')) end
    return table.concat(sink)
end

local fileHanders = {
    ['LoudDataPath.lua'] = require'utils.files.LoudDataPath',
}

function network.ftpGetWrite(path)
    local folder = path:match'^([^/]*)':gsub('\\', '/')
    path = path:gsub('\\', '/')
    feedback:push{path, 'downloading'}
    local fileData = network.ftpGet(path)
    if fileData then
        love.filesystem.createDirectory(writePath..folder)
        feedback:push{path, 'writing'}
        local handler = fileHanders[path:match'([^/\\]*)$']
        love.filesystem.write(writePath..path, handler and handler(fileData) or fileData)
        feedback:push{path, 'done'}
    end
end

function network.getMapLibData()
    local code, body, headers = require'https'.request'https://theloudproject.org:8081/maps/'
    if code~=200 then return 'Communication error' end
    local mapsData = {}
    for mapJsonRaw in body:gmatch'%b{}' do
        local data = {}
        for key, numberStr in mapJsonRaw:gmatch'(%b"")%s*:%s*(%d*)%s*,' do
            data[key:sub(2,-2)] = tonumber(numberStr)
        end
        for key, str in mapJsonRaw:gmatch'(%b"")%s*:%s*(%b"")%s*,' do
            data[key:sub(2,-2)] = str:sub(2,-2)
        end
        if data.image then
            data.thumbnail = data.image:gsub('marked_preview', 'marked_preview_thumb', 1)  -- NOTE: Temporary until the value is fetched correctly
        end
        data.localScenarioPath = data.identifier and findMapScenarioLua(writePath..'usermaps/'..data.identifier)
        table.insert(mapsData, data)
    end
    return mapsData
end

function network.getMapLibFile(file)
    local code, body, headers = require'https'.request('https://theloudproject.org:8081/'..file)
    if code~=200 then return file, 'Communication error' end
    return file, body
end

function network.getMap(data)
    feedback:push(1)
    feedback:push{data.name, 'downloading'}
    local code, body, headers = require'https'.request('https://theloudproject.org:8081/'..data.file)
    if code~=200 then
        feedback:push{data.name, 'done'}
        feedback:push(('%s map download failed: code %s: %s'):format(data.name, tostring(code), body))
        return
    end
    feedback:push{data.name, 'writing'}
    local path, filename = data.file:match'(.*)(/[^/]*)'
    love.filesystem.createDirectory('temp/'..path)
    local SCDWritePath = 'temp/'..data.file
    love.filesystem.write(SCDWritePath, body)
    local mountPath = data.file:gsub('/', '-')
    love.filesystem.mount(SCDWritePath, mountPath)

    forEachFile(mountPath, function(path, name)
        local inputPath = path..'/'..(name or '')
        local outputPath = writePath..'usermaps'..path:sub(#mountPath+1)..'/'..(name or '')
        if not name then
            love.filesystem.createDirectory(outputPath)
            return
        end
        love.filesystem.write(outputPath, (love.filesystem.read(inputPath)))
    end)
    love.filesystem.unmount(SCDWritePath)
    love.filesystem.remove(SCDWritePath)
    feedback:push{data.name, 'done'}
    feedback:push(('Map "%s" downloaded.'):format(data.name))
end

return network
