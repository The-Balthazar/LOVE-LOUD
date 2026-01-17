local debug = {}

local white = {0.8, 0.8, 0.8}
local amber = {1, 0.6, 0.3}
local red = {0.7, 0, 0.3}

local errorMatches = {
    {msg = 'Debug message',                       colour = nil,   find  = '^debug: '},
    {msg = 'Indent on multi-line message',        colour = nil,   find  = '^ '},
    {msg = 'Alt-tabbing warning',                 colour = red,   find  = '^info: Minimized true'},
    {msg = 'OneDrive folder use warning',         colour = red,   find  = '^info:.*\\OneDrive\\'},
    {msg = 'Other log',                           colour = nil,   find  = '^info: '},
    {msg = 'Stack traceback indent',              colour = nil,   find  = '^warning:         [^ ]'},
    {msg = 'Stack traceback',                     colour = nil,   find  = '^warning: stack traceback:'},
    {msg = 'Surround sound warning',              colour = red,   find  = '^warning: Unknown DirectSound speaker configuration %d*%. Defaulting to Stereo%.'},
    {msg = 'Surround sound error',                colour = red,   find  = '^warning: SND: XACT3DApply failed%.'},
    {msg = 'Streaming/recording software error',  colour = red,   find  = '^warning: SofDec error: 1060102: Internal Error: adxm_goto_mwidle_border'},
    {msg = 'File load error',                     colour = amber, match = '^warning: SCR_LuaDoFileConcat: Loading .-([^\\"]*%.[lb][up]a?)%(%d*%):'},
    {msg = 'File import error',                   colour = amber, match = '^warning: .-Error importing .-([^\\/"]*%.[lb][up]a?):?'},
    {msg = 'Entity script error',                 colour = amber, match = '^warning: Error running .- script in Entity (.-) at '},
    {msg = 'Deleted object script error',         colour = amber, match = '^warning: Error running .- script in <deleted object>:'},
    {msg = 'Accessed nil global error',           colour = amber, match = '^warning: .-: access to nonexistent global variable ([%a%d_]*)'},
    {msg = 'Unknown unit error',                  colour = nil,   find  = '^warning: Problem Cant load unit:'},
    {msg = 'Unknown unit ID error',               colour = amber, match = '^warning: Unknown unit type: (.+)'},
    {msg = 'Error opening file',                  colour = red,   match = '^warning: Can\'t open lua file "([^"]+)"'},
    {msg = 'Error in file',                       colour = red,   match = '^warning: Error in file (.-) : '},
    {msg = 'Error running script',                colour = red,   match = '^warning: Error running lua script: (.+)'},
    {msg = 'Out of bounds flatten',               colour = nil,   find  = '^warning: Attempted to flatten terrain outside map boundary! Operation Failed!'},
    {msg = 'Nil resource warning',                colour = nil,   find  = '^warning: GetResource: Invalid name ""'},
    {msg = 'Prop count',                          colour = nil,   find  = '^warning:  NUM PROPS'},
    {msg = 'Search path found nothing',           colour = nil,   match = '^warning: Search path element "([^"]+)" does not match any files'},
    {msg = 'User trying to cheat',                colour = nil,   find  = '^warning: .- is trying to cheat!$'},
    {msg = 'AI debug warning',                    colour = white, find  = '^warning: %*AI DEBUG'},
    {msg = 'AI stuck warp',                       colour = white, find  = '^warning: WARP stuck'},
    {msg = 'WaveBank load error',                 colour = amber, match = '^warning: Error loading WaveBank (%b\'\')'},
    {msg = 'Hotbuild key action overwrite',       colour = nil,   match = '^warning: Overwriting user key action: (.*)'},
    {msg = 'Hotbuild key action removed',         colour = nil,   match = '^warning: Removed invalid key action (%b\'\')'},
    {msg = 'Missing sound',                       colour = nil,   match = '^warning: Error resolving cue \'([^\']+)\''},
    {msg = 'Unicode error',                       colour = nil,   find  = '^warning: Right edge of character .- is not black!'},
    {msg = 'FAF Debug load message',              colour = nil,   find  = '^Initializing '},
    {msg = 'FAF Override notification',           colour = nil,   find  = '^warning: Overriding '},
    {msg = 'FAF intel radius warning',            colour = nil,   find  = '^warning: Intel radius of '},
    {msg = 'FAF class initialisation error',      colour = nil,   find  = '^warning: [%a%d\\_.-~]*%(%d*%): Class initialisation:'},
    {msg = 'Unanalysed script error',             colour = red,   match = '^warning: Error running (.*)'},
    {msg = 'Config screen resolution warning',    colour = nil,   find  = '^warning: Unable to set requested size %d*,%d*.'},
    {msg = 'Unknown warning',                     colour = red,   match = '^warning: (.*)'},
    {msg = 'Unevaluated log line',                colour = red,   match = '.*'},
}

for i, set in ipairs(errorMatches) do
    if set.msg then
        errorMatches[set.msg] = set
    end
end

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
                if not data.colour then break end
                if not warns[data.msg] then table.insert(warns, data.msg) end
                warns[data.msg] = (warns[data.msg] or 0)+1
                break
            elseif line and data.match then
                local match = line:match(data.match)
                if match then
                    if not data.colour then break end
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
            local colour = errorMatches[msg].colour
            if type(count)=='number' then
                feedback:push{{1, 1, 1}, count, count==1 and ' instance of: ' or ' instances of: ', colour, msg, {1, 1, 1}, ' • \n'}
            elseif type(count)=='table' then
                local val = #count
                feedback:push{{1, 1, 1}, val, val==1 and ' unique instance of: ' or ' unique instances of: ', colour, msg, {1, 1, 1}, ' • \n'}
                if detail then
                    for i, key in ipairs(count) do
                        if i==6 and count[7] then
                            feedback:push{{1, 1, 1}, #count-5, ' more not depicted — \n'}
                            break
                        else
                            local val = count[key]
                            feedback:push{colour, key, {1, 1, 1}, ' ', val, val==1 and ' time' or ' times',' — \n'}
                        end
                    end
                end
            end
        end
    else
        feedback:push{{1, 1, 1}, 'No common errors identified\n'}
    end
end

return debug
