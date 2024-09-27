local types = {
    regular = {
        width = 190,
        height = 60,
    }
}

local colours = {
    up = {0,22/255,38/255},
    over = {0,38/255,66/255},
    upinactive = {0.07,0.07,0.07},
    overinactive = {0.13,0.13,0.13},
}

local buttonCore = {
    positional = true,
    mouse = true,
    update = function(self, UI, delta)
    end,
    draw = function(self, UI, w)
        local sType = types[self.type] or types.regular
        love.graphics.setColor(
                self.mouseOver and not self.inactive and colours.over or
            not self.mouseOver and not self.inactive and colours.up or
                self.mouseOver and                       colours.overinactive or
                                                         colours.upinactive
        )
        love.graphics.rectangle('fill', self.cornerX, self.cornerY, self.width, self.height, sType.rx, sType.ry, sType.segments)
        love.graphics.setColor(1,1,1)
        love.graphics.printf(self.text, self.cornerX, self.midY-8*w.scale, self.widthBase, 'center', 0, w.scale)
    end,
}
buttonCore.__index = buttonCore

return function(self)
    local sType = types[self.type] or types.regular
    self.widthBase = sType.width
    self.heightBase = sType.height
    return setmetatable(self, buttonCore)
end
