return function(iconType, oXN, oXP, oYN, oYP)
    local icon = love.graphics.newImage(('graphics/strategicicon/%s_icon_fighter3_antiair_rest.png'):format(iconType))
    icon:setFilter('nearest', 'nearest')
    return require'ui.elements.button'{
        showIf = function(self, UI, delta) return menuActiveTab=='config' end,
        posXN = 1,
        posYN = 1,
        offsetXN = oXN,
        offsetXP = oXP,
        offsetYN = oYN,
        offsetYP = oYP,
        widthBase = 30,
        heightBase = 30,
        icon = icon,
        inactive = userConfig.iconSet~=iconType,
        onPress = function(self, UI)
            userConfig.iconSet = iconType
            saveUserConfig()
            updateLoudDataPath()
        end,
        update = function(self, UI, delta)
            self.inactive = userConfig.iconSet~=iconType
        end,
    }
end
