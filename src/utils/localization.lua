-- Localization system for LOVE-LOUD
local localization = {}

-- Default language
local currentLanguage = 'en'
local translations = {}

-- Available languages
local availableLanguages = {
    {code = 'en', name = 'English', nativeName = 'English'},
    {code = 'fr', name = 'French', nativeName = 'Français'},
}

-- Load translation file for a language
function localization.loadLanguage(langCode)
    local filePath = 'utils/localization/' .. langCode .. '.lua'
    
    -- Check if file exists
    local info = love.filesystem.getInfo(filePath)
    if info then
        -- Load the translation file
        local success, result = pcall(love.filesystem.load, filePath)
        if success and result then
            local langData = result()
            if langData then
                translations[langCode] = langData
                return true
            end
        end
    end
    
    -- Fallback: create empty translation table
    translations[langCode] = {}
    return false
end

-- Get translated text
function localization.getText(key)
    if translations[currentLanguage] and translations[currentLanguage][key] then
        return translations[currentLanguage][key]
    elseif translations['en'] and translations['en'][key] then
        -- Fallback to English
        return translations['en'][key]
    else
        -- Return key
        return key
    end
end

-- Shorthand function for getting text
function localization.t(key)
    return localization.getText(key)
end

-- Set current language
function localization.setLanguage(langCode)
    for _, lang in ipairs(availableLanguages) do
        if lang.code == langCode then
            currentLanguage = langCode
            
            -- Load the language if not already loaded
            if not translations[langCode] then
                localization.loadLanguage(langCode)
            end
            
            return true
        end
    end
    return false
end

-- Get current language
function localization.getCurrentLanguage()
    return currentLanguage
end

-- Get available languages
function localization.getAvailableLanguages()
    return availableLanguages
end

-- Get language info by code
function localization.getLanguageInfo(langCode)
    for _, lang in ipairs(availableLanguages) do
        if lang.code == langCode then
            return lang
        end
    end
    return nil
end

-- Initialize localization system
function localization.init(userLang)
    -- Load English as base language
    localization.loadLanguage('en')
    
    -- Set user's preferred language or default to English
    local lang = userLang or 'en'
    localization.setLanguage(lang)
end

return localization
