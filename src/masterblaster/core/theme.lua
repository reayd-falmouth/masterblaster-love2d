-- core/theme.lua

local Theme = {}
Theme.__index = Theme

-- Create a new Theme.
-- Optional custom colors can be provided; otherwise defaults are used.
function Theme.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Theme)
    self.primaryColor   = opts.primaryColor   or {0, 0.2, 1, 1}         -- Blue (complementary color)
    self.secondaryColor = opts.secondaryColor or {0.333, 0, 0.733, 1}  -- Purple (main menu accent)
    self.backgroundColor= opts.backgroundColor or {0, 0, 0, 1}           -- Black
    self.foregroundColor= opts.foregroundColor or {1, 1, 1, 1}           -- White (text)
    return self
end

-- Retrieve a color by a key name.
function Theme:getColor(name)
    if name == "primary" then
        return self.primaryColor
    elseif name == "secondary" then
        return self.secondaryColor
    elseif name == "background" then
        return self.backgroundColor
    elseif name == "foreground" then
        return self.foregroundColor
    end
    return nil
end

-- A default theme instance
local defaultTheme = Theme.new()

return {
    Theme = Theme,
    defaultTheme = defaultTheme,
}
