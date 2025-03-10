-- src/system/fonts.lua
local Fonts = {}

-- Table to store loaded fonts
Fonts.ImageFont = {}

-- Load fonts function
function Fonts.load()
    local fontPath = "assets/fonts/imagefont.png"
    local glyphs = " !\"§$%&/()*+.-,/0123456789:;" ..
                   "<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    -- Try to load the image font
    local success, font = pcall(love.graphics.newImageFont, fontPath, glyphs)

    if success then
        Fonts.ImageFont.default = font
        Fonts.ImageFont.default:setFilter("nearest", "nearest")
    else
        error("Failed to load font: " .. fontPath)
    end
end

-- Get image font (size is currently ignored, but can be extended)
function Fonts.getImageFont()
    if not Fonts.ImageFont.default then
        error("Font not loaded. Call Fonts.load() first.")
    end
    return Fonts.ImageFont.default
end

return Fonts
