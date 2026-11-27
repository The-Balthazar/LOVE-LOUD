function osCall(call, options)
    local OS = love.system.getOS()
    if OS=='Windows' then
        os.execute('start "" "'..call:gsub('/', '\\')..'" '..(options or ''))
    elseif OS=='OS X' or OS=='Linux' then
        os.execute('chmod +x "'..call..'" '..(options or ''))
    end
end

-- Windows: starts the game with the 3 GB allocator fix applied in memory (utils/patch3gb.lua).
-- Falls back to osCall when the game could not be started that way.
function launchGame(call, options)
    if love.system.getOS()=='Windows' then
        local ok, patched, msg, pid = pcall(require'utils.patch3gb'.launch, call, options)
        if ok and pid then
            return
        end
    end
    osCall(call, options)
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
