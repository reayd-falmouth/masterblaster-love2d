-- shop.lua
local Assets = require("assets")
local UITheme = require("theme")
local Shop = {}

-- List of shop items
local shopItems = {
    { name = "EXTRA BOMB", cost = 1, key = "extraBomb",  row = 2, col = 20 },
    { name = "POWER-UP",   cost = 1, key = "powerUp",    row = 3, col = 1 },
    { name = "SUPERMAN",   cost = 2, key = "superman",   row = 3, col = 2 },
    { name = "GHOST",      cost = 3, key = "ghost",      row = 3, col = 5 },
    { name = "TIMEBOMB",   cost = 2, key = "timeBomb",   row = 3, col = 10 },
    { name = "PROTECTION", cost = 3, key = "protection", row = 3, col = 4 },
    { name = "CONTROLLER", cost = 4, key = "controller", row = 3, col = 13 },
    { name = "SPEED-UP",   cost = 4, key = "speedUp",    row = 3, col = 7  }
    -- Optionally, an 'Exit' item at the bottom if you like
}

local spriteSheet = Assets.objectSpriteSheet

-- Precompute quads for items that have a sprite (skip "none").
local quads = {}
for _, item in ipairs(shopItems) do
    if item.name ~= "none" then
        local x = (item.col - 1) * TILE_SIZE
        local y = (item.row - 1) * TILE_SIZE
        quads[item.name] = love.graphics.newQuad(x, y, TILE_SIZE, TILE_SIZE, spriteSheet:getDimensions())
    end
end

local function purchaseItem(item, pstats)
    if pstats.money >= item.cost then
        pstats.money = pstats.money - item.cost
        pstats.purchased[item.key] = pstats.purchased[item.key] + 1
        love.audio.play(cashSound) -- Or your equivalent
    else
        -- Not enough money sound or message
    end
end

function Shop:load()
    -- You can set currentPlayerIndex from outside or inside this function
    -- e.g. we start with the first player who has money
end

function Shop:update(dt)
    -- Any animations, etc. if needed
end

function Shop:draw()

end

function Shop:keypressed(key)
end

function Shop:goToNextPlayer()
end

return Shop
