local Assets = require("assets")
local Audio = require("audio")
local UITheme = require("theme")
local Game = require("game")
local Shop = {}

-- State variables
Shop.selectedIndex = 1
Shop.currentPlayerIndex = 1
Shop.shopItems = {}
Shop.quads = {}
Shop.coinQuad = nil
Shop.cashSound = nil

local TILE_SIZE = Assets.TILE_SIZE

function Shop.drawObjectSprite(quad, x, y)
    love.graphics.setColor(UITheme.fgColor)  -- ensure trophy is drawn with the correct tint
    love.graphics.draw(Assets.objectSpriteSheet, quad, x, y)
    love.graphics.setColor(UITheme.highlightColor)  -- ensure trophy is drawn with the correct tint
end

function Shop.load()
    if GameSettings.shop == "OFF" then
        switchState(Game)
        return
    end

    -- Initialize tables to avoid nil errors

    Shop.selectedIndex = 1
    Shop.currentPlayerIndex = 1
    Shop.shopItems = {}
    Shop.quads = {}
    Shop.coinQuad = nil
    Shop.cashSound = nil

    -- Load assets
    Shop.coinQuad = Assets.getCachedQuad("coin")
    Shop.cashSound = Audio.sfxSources.cash

    -- Build shop items list
    for _, item in ipairs(Assets.ITEM_DEFINITIONS) do
        if item.shopItem then
            table.insert(Shop.shopItems, item)
            local quad = Assets.getCachedQuad(item.key)
            if quad then
                Shop.quads[item.key] = quad
            end
        end
    end

    -- Append EXIT option manually
    local exitItem = { key = "exit", name = "EXIT", cost = 0, shopItem = true }
    table.insert(Shop.shopItems, exitItem)
end

function Shop.update(dt)
    -- Handle animations or updates here if needed
end

function Shop.draw()
    local pStats = PlayerStats.players[Shop.currentPlayerIndex]

    local screenWidth = love.graphics.getWidth()

    love.graphics.setColor(UITheme.highlightColor)

    -- 1) Title centered
    local title = "PLAYER " .. Shop.currentPlayerIndex .. " ENTERS SHOP"
    local titleWidth = love.graphics.getFont():getWidth(title)
    love.graphics.print(title, (screenWidth - titleWidth) / 2, 20)

    -- 2) Display "MONEY" label and coins
    local moneyLabelX, moneyLabelY = 50, 60
    love.graphics.print("MONEY", moneyLabelX, moneyLabelY)

    local coinSpacing = 16
    for j = 1, pStats.money do
        Shop.drawObjectSprite(Shop.coinQuad, moneyLabelX + 60 + (j - 1) * coinSpacing, moneyLabelY - 4)
    end

    -- 3) Column headers: "EXTRA" and "PRIZE"
    local headerY, extraX, prizeX = 110, 150, 320
    love.graphics.print("EXTRA", extraX, headerY)
    love.graphics.print("PRIZE", prizeX, headerY)

    -- 4) Draw shop items
    local startY, spacing = headerY + 20, 20

    for i, item in ipairs(Shop.shopItems) do
        Shop.drawItem(i, item, startY + (i - 1) * spacing, screenWidth, extraX, prizeX)
    end
end

-- Helper function to draw an individual item
function Shop.drawItem(index, item, y, screenWidth, extraX, prizeX)
    if item.key == "exit" then
        -- Special handling for EXIT: Center it and push it down a bit
        local exitWidth = love.graphics.getFont():getWidth(item.name)
        local exitX = (screenWidth - exitWidth) / 2
        y = y + 20  -- Offset to separate from regular items
        if index == Shop.selectedIndex then
            love.graphics.print(">", exitX - 20, y)
        end
        love.graphics.print(item.name, exitX, y)
    else
        -- Regular shop items
        if index == Shop.selectedIndex then
            love.graphics.print(">", extraX - 20, y)
        end
        love.graphics.print(item.name, extraX, y)

        local quad = Shop.quads[item.key]
        if quad then
            Shop.drawObjectSprite(quad, extraX + 110, y - 4)
        end

        love.graphics.print(tostring(item.cost), prizeX, y)
    end
end

function Shop.keypressed(key)
    print("DEBUG: Key pressed in Shop: " .. key)
    if key == "up" then
        Shop.selectedIndex = Shop.selectedIndex - 1
        if Shop.selectedIndex < 1 then
            Shop.selectedIndex = #Shop.shopItems
        end
    elseif key == "down" then
        Shop.selectedIndex = Shop.selectedIndex + 1
        if Shop.selectedIndex > #Shop.shopItems then
            Shop.selectedIndex = 1
        end
    elseif key == "return" or key == "kpenter" then
        local item = Shop.shopItems[Shop.selectedIndex]
        print("DEBUG: Selected item - " .. item.key)
        if item.key == "exit" then
            print("DEBUG: Exiting shop for Player " .. Shop.currentPlayerIndex)
            Shop.goToNextPlayer()
        else
            Shop.attemptPurchase(item)
        end
    end
end


function Shop.attemptPurchase(item)
    local pStats = PlayerStats.players[Shop.currentPlayerIndex]
    if pStats.money >= item.cost then
        pStats.money = pStats.money - item.cost
        pStats.purchased[item.key] = (pStats.purchased[item.key] or 0) + 1
        print("DEBUG: Item purchased: " .. item.key .. " Total items: " .. pStats.purchased[item.key])
        Shop.cashSound:play()
    else
        -- Provide feedback for insufficient funds (e.g., play sound or show message)
    end
end

function Shop.goToNextPlayer()
    local totalPlayers = #PlayerStats.players
    Shop.currentPlayerIndex = Shop.currentPlayerIndex + 1

    -- If we looped past the last player, switch state
    if Shop.currentPlayerIndex > totalPlayers then
        --Shop.currentPlayerIndex = 1  -- reset the index for next round
        switchState(Game)
    else
        Shop.selectedIndex = 1
    end
end

return Shop
