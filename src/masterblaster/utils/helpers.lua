local Helpers = {}
Helpers.__index = Helpers

function Helpers.drawObjectSprite(quad, x, y)
    love.graphics.setColor(UITheme.fgColor)  -- Draw with the foreground tint
    love.graphics.draw(Assets.objectSpriteSheet, quad, x, y)
    love.graphics.setColor(UITheme.highlightColor)  -- Restore highlight tint
end

return Helpers