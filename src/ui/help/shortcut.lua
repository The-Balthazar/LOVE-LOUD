--createShortcut('LOUD', 'bin/SupremeCommander.exe /log ..\\LOUD\\bin\\LOUD.log /init ..\\LOUD\\bin\\LoudDataPath.lua')
local launchCommand = '/log "..\\LOUD\\bin\\LOUD.log" /init "..\\LOUD\\bin\\LoudDataPath.lua"'
local copyText = 'Copy launch commands'

local launchRichText = {'Launch commands:    ', {0.7, 0, 0.3}, launchCommand, '    ', {1,1,1,0}, copyText}

local helptext = [[
LOUD functions by launching the original game with a command instructing it to load a custom init file that has it load LOUD assets instead of the default ones. These files will not be loaded without said init, and as such LOUD can be remain installed without affecting your ability to play vanilla or any other init-level mod like FAF.

You can create a custom shortcut to load LOUD with said launch command, shown above.
]]

local helptextWin = [[
To do this on Windows, right click SupremeCommander.exe > Create shortcut, then right click the shortcut that creates > Properties, then in the window that pops up, at the end of Target field after path to the exe, paste the launch commands and OK it. That shortcut will now load LOUD independant of this launcher.

If you wish to do this directly through Steam, right click Forged Alliance in Steam > Properties... > General and then in Launch options paste the launch commands.
]]

local win = love.graphics.newImage'graphics/help/win-shortcut.png'
local steam = love.graphics.newImage'graphics/help/steam-shortcut.png'

local offset = 36
return {
    draw = function(self, w)
        local scale = w.scale
        require'ui.intro'.draw(self, w, (-290+offset)*scale)
        love.graphics.printf(launchRichText, 100*scale, (50+offset)*scale, baseWindowWidth-200, 'center', 0, scale, scale)
        love.graphics.printf(helptext, 125*scale, (118+offset)*scale, baseWindowWidth-(125*2), 'left', 0, scale, scale)
        love.graphics.draw(win, 680*scale, (174+offset)*scale, 0, scale, scale)
        love.graphics.printf(helptextWin, 125*scale, (226+offset)*scale, 535, 'left', 0, scale, scale)
        love.graphics.draw(steam, 125*scale, (375+offset)*scale, 0, scale, scale)
    end,
    objects = {
        require'ui.elements.button'{
            text = copyText,
            posXN = 0.5,
            posYN = 0,
            offsetXN = 0.5,
            offsetXP = 190,
            offsetYN = 0.0,
            offsetYP = (50+offset)+9,
            widthBase = 150,
            heightBase = 30,
            onPress = function(self, UI)
                love.system.setClipboardText(launchCommand)
                self.text = 'Copied'
            end,
            onHover = function(self, UI)
                if not self.mouseOver then
                    self.text = copyText
                end
            end,
        },
        require'ui.elements.button'{
            icon = love.graphics.newImage'graphics/back.png',
            posXN = 0,
            posYN = 1,
            offsetXN = 0.5,
            offsetXP = 10,
            offsetYN = -0.5,
            offsetYP = -10,
            widthBase = 60,
            heightBase = 60,
            onPress = function(self, UI)
                UI:goBack()
            end,
        },
    },
    goBack = function(self)
        setUIMode(require'ui.menu')
    end,
}
