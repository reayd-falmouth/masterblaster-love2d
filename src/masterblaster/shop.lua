-- shop.lua
local Assets = require("assets")
local UITheme = require("theme")
local PlayerStats = require("stats")
local Shop = {}
local selectedIndex = 1
local currentPlayerIndex = 1
local coinQuad = nil  -- if you have a coin sprite, set it up in Shop:load()

-- List of shop items
local shopItems = {
    { name = "EXTRA BOMB", cost = 1, key = "extraBomb",  row = 2, col = 20 },
    { name = "POWER-UP",   cost = 1, key = "powerUp",    row = 3, col = 1 },
    { name = "SUPERMAN",   cost = 2, key = "superman",   row = 3, col = 2 },
    { name = "GHOST",      cost = 3, key = "ghost",      row = 3, col = 5 },
    { name = "TIMEBOMB",   cost = 2, key = "timeBomb",   row = 3, col = 10 },
    { name = "PROTECTION", cost = 3, key = "protection", row = 3, col = 4 },
    { name = "CONTROLLER", cost = 4, key = "controller", row = 3, col = 13 },
    { name = "SPEED-UP",   cost = 4, key = "speedUp",    row = 3, col = 7  },
    { name = "EXIT",       cost = 0, key = "exit",       row = 0, col = 0 }
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
    local GameSettings = require("settings")
    if GameSettings.shop == "OFF" then
        -- If the shop is off, skip or exit:
        switchState(NextState) -- placeholder for your next state
        return
    end
    
    -- Example coin setup if you have a coin sprite in Assets
    -- coinQuad = love.graphics.newQuad(0, 0, 16, 16, Assets.coin:getDimensions())
end

function Shop:update(dt)
    -- Any animations, etc. if needed
end

function Shop:draw()
    local pstats = PlayerStats[currentPlayerIndex]
    love.graphics.setColor(UITheme.highlightColor)
    -- Show player money
    love.graphics.print("Player " .. currentPlayerIndex .. " Money: " .. pstats.money, 50, 50)

    -- Draw each item
    local startY = 100
    local spacing = 20
    for i, item in ipairs(shopItems) do
        local y = startY + (i - 1) * spacing
        if i == selectedIndex then
            love.graphics.print(">", 30, y)
        end
        love.graphics.print(item.name .. " (cost: " .. item.cost .. ")", 50, y)
    end
end

function Shop:keypressed(key)
    if key == "up" then
        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then
            selectedIndex = #shopItems
        end
    elseif key == "down" then
        selectedIndex = selectedIndex + 1
        if selectedIndex > #shopItems then
            selectedIndex = 1
        end
    elseif key == "return" or key == "kpenter" then
        local item = shopItems[selectedIndex]
        local pstats = PlayerStats[currentPlayerIndex]

        if item.key == "exit" then
            self:goToNextPlayer()
            return
        end

        -- Attempt purchase
        if pstats.money >= item.cost then
            pstats.money = pstats.money - item.cost
            pstats.purchased[item.key] = (pstats.purchased[item.key] or 0) + 1
            love.audio.play(cashSound)
        else
            -- Not enough money beep
        end
    end
end

function Shop:goToNextPlayer()
    local totalPlayers = #PlayerStats
    currentPlayerIndex = currentPlayerIndex + 1

    -- If we run out of players, exit the shop:
    if currentPlayerIndex > totalPlayers then
        switchState(NextState) -- placeholder for your next state
    else
        -- If next player has no money, skip them
        if PlayerStats[currentPlayerIndex].money <= 0 then
            self:goToNextPlayer()
        else
            -- Reset selection
            selectedIndex = 1
        end
    end
end

return Shop
