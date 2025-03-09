local Helpers = {}
Helpers.__index = Helpers

function Helpers.drawObjectSprite(quad, x, y)
    love.graphics.setColor(UITheme.fgColor)  -- Draw with the foreground tint
    love.graphics.draw(Assets.objectSpriteSheet, quad, x, y)
    love.graphics.setColor(UITheme.highlightColor)  -- Restore highlight tint
end

function Helpers.reverseTable(t)
    local reversed = {}
    for i = #t, 1, -1 do
        table.insert(reversed, t[i])
    end
    return reversed
end

function Helpers.reverseTableInPlace(t)
    local i, j = 1, #t
    while i < j do
        t[i], t[j] = t[j], t[i]
        i = i + 1
        j = j - 1
    end
end

return Helpers