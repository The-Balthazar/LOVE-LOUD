local debug = {}

local errorMatches = {
    {msg = 'Surround sound warning', match = 'warning: Unknown DirectSound speaker configuration %d*%. Defaulting to Stereo%.'},
    {msg = 'Surround sound error', match = 'warning: SND: XACT3DApply failed%.'},
    {msg = 'Streaming/recording software error', match = 'warning: SofDec error: 1060102: Internal Error: adxm_goto_mwidle_border',},
    {msg = 'Alt-tabbing warning', match = 'info: Minimized true'},
    {msg = 'OneDrive folder use warning', match = 'info:.*\\OneDrive\\'},
}

function debug.logAnalyse(log)
    if not log then return end
    local warns = {}
    local feedback = love.thread.getChannel'log'
    if type(log)=='string' then
        feedback:push{{1, 1, 1}, 'Analysing string\n'}
    else
        feedback:push{{1, 1, 1}, 'Analysing ', log:getFilename(),'\n'}
    end
    for line in type(log)=='string' and log:gmatch'([^\r\n]+)' or log:lines() do
        for i, data in ipairs(errorMatches) do
            if line and line:find(data.match) then
                warns[data.msg] = (warns[data.msg] or 0)+1
            end
        end
    end
    if next(warns) then
        for msg, count in pairs(warns) do
            feedback:push{{1, 1, 1}, count, count==1 and ' instance of: ' or ' instances of: ', {0.7, 0, 0.3}, msg, '    \n'}
        end
    else
        feedback:push{{1, 1, 1}, 'No common errors identified\n'}
    end
end

return debug
