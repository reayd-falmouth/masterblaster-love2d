-- src/ui/font.lua
local Font = {}

function Font.load()
    -- Load image font
    Font.ImageFont = {
        default = love.graphics.newImageFont("assets/fonts/imagefont.png",
            " !\"§$%&/()*+.-,/0123456789:;" ..
            "<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
    }

    -- Apply nearest-neighbor filtering to prevent blurriness
    Font.ImageFont.default:setFilter("nearest", "nearest")
end

-- Getter for the image font
function Font.getImageFont(size)
    return Font.ImageFont.default
end

return Font
