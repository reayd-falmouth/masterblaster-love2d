-- credits.lua
local Credits = {}
local Font = require("system.fonts")
local UITheme = require("core.theme")

-- The credits text lines
local creditsText = {
    "MASTERBLASTER V1.0",
    "(C) 1994 BY ALPHA BROTHERS",
    "",
    "---THE ULTIMATE MULTIPLAYER GAME---",
    "",
    "THIS PROGRAM IS --FREEWARE--",
    "BUT IF YOU LIKE IT, PLEASE SEND SOME",
    "MONEY OR A CHEQUE TO THIS ADDRESS :",
    "",
    "ALEXANDER IVANOF",
    "AM DORFANGER 2",
    "58644 ISELERLOHN",
    "GERMANY",
    "",
    "FOR SOME INSTRUCTIONS OR E-MAIL INFO",
    "PLEASE READ THE DOCUMENTATIONFILE !",
    "",
    "GOT A GOOD IDEA FOR THE GAME ?",
    "HAVE YOU FOUND A BUG ???",
    "THEN PLEASE REPORT IT TO ME !",
    "",
    "THANK YOU !",
}

function Credits.load()
    -- Load your fonts
    Font.load()

    -- Set background color (from your UI theme)
    love.graphics.setBackgroundColor(UITheme.defaultTheme.primaryColor)
end

function Credits.update(dt)
    -- No dynamic logic needed for static credits
end

function Credits.draw()
    local imageFont = Font.getImageFont()
    love.graphics.setFont(imageFont)
    love.graphics.setColor(UITheme.defaultTheme.secondaryColor)

    -- Use your virtual resolution or Love2D window size
    local windowWidth  = VIRTUAL_WIDTH
    local windowHeight = VIRTUAL_HEIGHT

    local fontScale = 1
    local lineHeight = imageFont:getHeight() * fontScale

    -- Adjust these values to increase/decrease padding or spacing
    local horizontalPadding = 20
    local verticalPadding   = 20
    local lineSpacing       = 2  -- extra spacing between lines

    -- Calculate total height of all text lines + spacing
    local totalHeight = #creditsText * (lineHeight + lineSpacing)

    -- Center vertically, respecting top/bottom padding
    local startY = verticalPadding + ((windowHeight - verticalPadding * 2) - totalHeight) / 2

    -- Draw each line, centered horizontally with padding
    for i, line in ipairs(creditsText) do
        local lineWidth = imageFont:getWidth(line) * fontScale
        local x = horizontalPadding
                + ((windowWidth - horizontalPadding * 2) - lineWidth) / 2
        local y = startY + (i - 1) * (lineHeight + lineSpacing)
        love.graphics.print(line, x, y, 0, fontScale, fontScale)
    end
end

function Credits.keypressed(key)
    -- Switch to your next state; for example, back to a title screen:
    switchState(require("scenes.menu"))
end

return Credits
