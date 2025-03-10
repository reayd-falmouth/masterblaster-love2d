local helpers = {}

--- Draws an object sprite at a given position using the specified quad.
-- @param loveGraphics The Love2D graphics module (dependency injection)
-- @param theme The UITheme table containing colors
-- @param assets The Assets table containing sprites
-- @param quad The quad to draw
-- @param x X-coordinate
-- @param y Y-coordinate
function helpers.drawObjectSprite(loveGraphics, theme, assets, quad, x, y)
    loveGraphics.setColor(theme.fgColor)  -- Draw with foreground tint
    loveGraphics.draw(assets.objectSpriteSheet, quad, x, y)
    loveGraphics.setColor(theme.highlightColor)  -- Restore highlight tint
end

--- Reverses a table by creating a new reversed copy.
-- @param t The table to reverse
-- @return A new table with reversed elements
function helpers.reverseTable(t)
    local reversed = {}
    for i = #t, 1, -1 do
        table.insert(reversed, t[i])
    end
    return reversed
end

--- Reverses a table in place.
-- This modifies the original table instead of creating a new one.
-- @param t The table to reverse in place
function helpers.reverseTableInPlace(t)
    local i, j = 1, #t
    while i < j do
        t[i], t[j] = t[j], t[i]
        i = i + 1
        j = j - 1
    end
end

return helpers
