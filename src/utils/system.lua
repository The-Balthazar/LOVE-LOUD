function osCall(call, options)
    local OS = love.system.getOS()
    if OS=='Windows' then
        os.execute('start cmd /c call "'..call..'" '..(options or ''))
    elseif OS=='OS X' or OS=='Linux' then
        os.execute('chmod +x "'..call..'" '..(options or ''))
    end
end
