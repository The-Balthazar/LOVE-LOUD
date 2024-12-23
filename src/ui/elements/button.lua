local colours = {
    up = {0,22/255,38/255},
    over = {0,38/255,66/255},
    upinactive = {0.07,0.07,0.07},
    overinactive = {0.13,0.13,0.13},
    white = {1,1,1},
    midgrey = {0.5,0.5,0.5},
}

local buttonCore = {
    positional = true,
    mouse = true,
    update = function(self, UI, delta)
    end,
    draw = function(self, UI, w)
        love.graphics.setColor(
                self.mouseOver and not self.inactive and colours.over or
            not self.mouseOver and not self.inactive and colours.up or
                self.mouseOver and                       colours.overinactive or
                                                         colours.upinactive
        )
        love.graphics.rectangle('fill', self.cornerX, self.cornerY, self.width, self.height, self.rx, self.ry, self.segments)
        love.graphics.setColor(self.inactive and colours.midgrey or colours.white)
        if self.text and self.icon then
            love.graphics.draw(self.icon, self.cornerX+self.height/2, self.midY, self.iconAngle or 0, w.scale, w.scale, self.icon:getWidth()/2, self.icon:getHeight()/2)
            love.graphics.printf(self.text, self.cornerX+self.height, self.midY-9*w.scale, self.widthBase-self.heightBase, 'left', 0, w.scale)
        elseif self.text then
            love.graphics.printf(self.text, self.cornerX, self.midY-9*w.scale, self.widthBase, 'center', 0, w.scale)
        elseif self.icon then
            love.graphics.draw(self.icon, self.midX, self.midY, self.iconAngle or 0, w.scale, w.scale, self.icon:getWidth()/2, self.icon:getHeight()/2)
        end
        love.graphics.setColor(1,1,1)
    end,
}
buttonCore.__index = buttonCore

return function(self)
    return setmetatable(self, buttonCore)
end
