-- src/config/settings.lua
local Settings = {}

-- Define default settings
Settings.DEFAULTS = {
    winsNeeded = 3,
    players = 2,
    shop = true,
    shrinking = true,
    fastIgnition = true,
    startMoney = true,
    normalLevel = true,
    gambling = true,
    startMoneyAmount = 1
}

-- Initialize current settings with the default values
for key, value in pairs(Settings.DEFAULTS) do
    Settings[key] = value
end

-- Function to validate settings values
function Settings.validate(settings)
    assert(type(settings.winsNeeded) == "number" and settings.winsNeeded > 0, "winsNeeded must be a positive number")
    assert(type(settings.players) == "number" and settings.players >= 1, "players must be at least 1")
    assert(type(settings.shop) == "boolean", "shop must be a boolean")
    assert(type(settings.shrinking) == "boolean", "shrinking must be a boolean")
    assert(type(settings.fastIgnition) == "boolean", "fastIgnition must be a boolean")
    assert(type(settings.startMoney) == "boolean", "startMoney must be a boolean")
    assert(type(settings.normalLevel) == "boolean", "normalLevel must be a boolean")
    assert(type(settings.gambling) == "boolean", "gambling must be a boolean")
    assert(type(settings.startMoneyAmount) == "number" and settings.startMoneyAmount >= 0, "startMoneyAmount must be non-negative")
    return true
end

return Settings
