function _U(key)
    if Locales[Config.locale] then
        if Locales[Config.locale][key] then
            return Locales[Config.locale][key]
        else
            return 'Translation [' .. key .. '] does not exist'
        end
    else
        return 'Locale [' .. Config.locale .. '] does not exist'
    end
end

function _UF(key, ...)
    local str = _U(key)
    return string.format(str, ...)
end
