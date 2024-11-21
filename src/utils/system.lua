function osCall(call, options)
    local OS = love.system.getOS()
    if OS=='Windows' then
        os.execute('start "" "'..call:gsub('/', '\\')..'" '..(options or ''))
    elseif OS=='OS X' or OS=='Linux' then
        os.execute('chmod +x "'..call..'" '..(options or ''))
    end
end

function createShortcut(linkname, link)
    local OS = love.system.getOS()
    if OS=='Windows' then
        os.execute(('mklink /D "%s" "%s"'):format(linkname, link))
    elseif OS=='OS X' or OS=='Linux' then
        os.execute(('ln -s "%s" "%s"'):format(link, link))
    else
        love.thread.getChannel'log':push(('Unknown platform. Link would be to: %s'):format(link))
    end
end
