local bg = love.graphics.newImage'graphics/acu-bg.png'
local bg2 = love.graphics.newImage'graphics/acu-bg-2.png'
local logo = love.graphics.newImage'graphics/loud-large-brushed.png'
local logo_shadow = love.graphics.newImage'graphics/loud-large-shadow.png'
local logo_flare = love.graphics.newImage'graphics/loud-large-highlight.png'

local timer, transition = 0, 0
local start

local logoX, logoY, logoS = 960, 90, 0.25
local seraAlpha = love.math.random(0,2)/2

return {
    update = function(self, delta)
        timer=timer+delta
        if not startDone and timer>0.1 then
            start = require'ui.menu'
            if start.update then
                start.update(0)
            end
            --[[if v.draw then
                v.draw()
            end]]
            startDone=true
        end
        if timer>0.5 then
            transition = math.min(1, transition+delta*2)
            if transition==1 then
                --setUIMode(start)
            end
        end
    end,
    draw = function(self)
        local scale = love.graphics.getWidth()/1920
        love.graphics.draw(bg, 0, 0, 0, scale)
        love.graphics.setColor(1,1,1,seraAlpha)
        love.graphics.draw(bg2, 0, 0, 0, scale)
        love.graphics.setColor(1,1,1,1)
        local x = math.lerp(love.graphics.getWidth()/2, logoX*scale, math.easeOutBack(transition, 2.7))
        local y = math.lerp(love.graphics.getHeight()/2, logoY*scale, math.easeOutBack(transition, 2.7))
        local lScale = math.lerp(scale, logoS*scale, math.easeBothElastic(transition, 2.7))
        love.graphics.draw(logo_shadow, x, y, 0, lScale, lScale, 821, 195)
        love.graphics.draw(logo_shadow, x, y, 0, lScale, lScale, 821, 195)
        love.graphics.draw(logo, x, y, 0, lScale, lScale, 768, 141)
        love.graphics.setColor(1,1,1, (1+math.sin(love.timer.getTime()))/2)
        love.graphics.draw(logo_flare, x, y, 0, lScale, lScale, 866, 240)
        love.graphics.setColor(1,1,1,1)
    end,
}
