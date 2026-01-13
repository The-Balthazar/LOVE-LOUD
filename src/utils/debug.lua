local debug = {}

local errorMatches = {
    {msg = 'Surround sound warning',             find = 'warning: Unknown DirectSound speaker configuration %d*%. Defaulting to Stereo%.'},
    {msg = 'Surround sound error',               find = 'warning: SND: XACT3DApply failed%.'},
    {msg = 'Streaming/recording software error', find = 'warning: SofDec error: 1060102: Internal Error: adxm_goto_mwidle_border'},
    {msg = 'Alt-tabbing warning',                find = 'info: Minimized true'},
    {msg = 'OneDrive folder use warning',        find = 'info:.*\\OneDrive\\'},
    {msg = 'File load error',                   match = 'warning: SCR_LuaDoFileConcat: Loading .-([^\\"]*%.[lb][up]a?)%(%d*%):'},
    {msg = 'Entity script error',               match = 'warning: Error running .- script in Entity (.-) at '},
    {msg = 'Unknown unit ID error',             match = 'warning: Unknown unit type: (.+)'},
    {msg = 'Error in file',                     match = 'warning: Error in file (.-) : '},
    {msg = 'Error running script',              match = 'warning: Error running lua script: (.+)'},
    -- {msg = 'Out of bounds flatten warning',      find = 'warning: Attempted to flatten terrain outside map boundary! Operation Failed!'},
    -- {msg = 'Nil resource warning',               find = 'warning: GetResource: Invalid name ""'},
}

function debug.logAnalyse(log, detail, nameOverwrite)
    if not log then return end
    local warns = {}
    local feedback = love.thread.getChannel'log'
    if nameOverwrite then
        feedback:push{{1, 1, 1}, 'Analysing ', nameOverwrite,':\n'}
    elseif type(log)=='string' then
        feedback:push{{1, 1, 1}, 'Analysing string:\n'}
    else
        feedback:push{{1, 1, 1}, 'Analysing ', log:getFilename(),':\n'}
    end
    for line in type(log)=='string' and log:gmatch'([^\r\n]+)' or log:lines() do
        for i, data in ipairs(errorMatches) do
            if line and (data.find and line:find(data.find) or not detail and data.match and line:find(data.match)) then
                if not warns[data.msg] then table.insert(warns, data.msg) end
                warns[data.msg] = (warns[data.msg] or 0)+1
                break
            elseif line and data.match then
                local match = line:match(data.match)
                if match then
                    if not warns[data.msg] then table.insert(warns, data.msg) end
                    warns[data.msg] = warns[data.msg] or {}
                    if not warns[data.msg][match] then table.insert(warns[data.msg], match) end
                    warns[data.msg][match] = (warns[data.msg][match] or 0)+1
                    break
                end
            end
        end
    end
    if warns[1] then
        for i, msg in ipairs(warns) do
            local count = warns[msg]
            if type(count)=='number' then
                feedback:push{{1, 1, 1}, count, count==1 and ' instance of: ' or ' instances of: ', {0.7, 0, 0.3}, msg, {1, 1, 1}, ' • \n'}
            elseif type(count)=='table' then
                local val = #count
                feedback:push{{1, 1, 1}, val, val==1 and ' unique instance of: ' or ' unique instances of: ', {0.7, 0, 0.3}, msg, {1, 1, 1}, ' • \n'}
                if detail then
                    for i, key in ipairs(count) do
                        local val = count[key]
                        feedback:push{{0.7, 0, 0.3}, key, {1, 1, 1}, ' ', val, val==1 and ' time' or ' times',' — \n'}
                    end
                end
            end
        end
    else
        feedback:push{{1, 1, 1}, 'No common errors identified\n'}
    end
end

return debug
