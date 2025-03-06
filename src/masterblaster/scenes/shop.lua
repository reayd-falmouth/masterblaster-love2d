local Assets = require("core.assets")
local Audio = require("system.audio")
local UITheme = require("core.theme")
local Game = require("core.game")
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
    love.graphics.setColor(UITheme.fgColor)  -- Draw with the foreground tint
    love.graphics.draw(Assets.objectSpriteSheet, quad, x, y)
    love.graphics.setColor(UITheme.highlightColor)  -- Restore highlight tint
end

-- This function reinitializes the shop each time the shop state is entered.
function Shop.init()
    if GameSettings.shop == "OFF" then
        switchState(Game)
        return
    end

    -- Reset state variables to avoid stale data.
    Shop.selectedIndex = 1
    Shop.currentPlayerIndex = 1
    Shop.shopItems = {}
    Shop.quads = {}
    Shop.coinQuad = nil
    Shop.cashSound = nil

    -- Load assets
    Shop.coinQuad = Assets.getCachedQuad("coin")
    Shop.cashSound = Audio.sfxSources.cash

    -- Build shop items list based on item definitions.
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

    -- Isolate title drawing
    love.graphics.push()
    love.graphics.setColor(UITheme.highlightColor)
    local title = "PLAYER " .. Shop.currentPlayerIndex .. " ENTERS SHOP"
    local titleWidth = love.graphics.getFont():getWidth(title)
    love.graphics.print(title, (screenWidth - titleWidth) / 2, 20)
    love.graphics.pop()

    -- Isolate MONEY label and coins
    love.graphics.push()
    love.graphics.setColor(UITheme.highlightColor)
    local moneyLabelX, moneyLabelY = 50, 60
    love.graphics.print("MONEY", moneyLabelX, moneyLabelY)
    local coinSpacing = 16
    for j = 1, pStats.money do
        Shop.drawObjectSprite(Shop.coinQuad, moneyLabelX + 60 + (j - 1) * coinSpacing, moneyLabelY - 4)
    end
    love.graphics.pop()

    -- Isolate headers drawing
    love.graphics.push()
    love.graphics.setColor(UITheme.highlightColor)
    local headerY, extraX, prizeX = 110, 150, 320
    love.graphics.print("EXTRA", extraX, headerY)
    love.graphics.print("PRIZE", prizeX, headerY)
    love.graphics.pop()

    -- Draw shop items (each in its own isolated state)
    local startY, spacing = headerY + 20, 20
    for i, item in ipairs(Shop.shopItems) do
        love.graphics.push()
        Shop.drawItem(i, item, startY + (i - 1) * spacing, screenWidth, extraX, prizeX)
        love.graphics.pop()
    end
end


function Shop.drawItem(index, item, y, screenWidth, extraX, prizeX)
    if item.key == "exit" then
        -- Center the EXIT option and add an offset.
        local exitWidth = love.graphics.getFont():getWidth(item.name)
        local exitX = (screenWidth - exitWidth) / 2
        y = y + 20  -- Additional offset for clarity
        if index == Shop.selectedIndex then
            love.graphics.print(">", exitX - 20, y)
        end
        love.graphics.print(item.name, exitX, y)
    else
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
        -- Feedback for insufficient funds can be added here.
    end
end

function Shop.goToNextPlayer()
    local totalPlayers = #PlayerStats.players
    Shop.currentPlayerIndex = Shop.currentPlayerIndex + 1

    if Shop.currentPlayerIndex > totalPlayers then
        switchState(Game)
    else
        Shop.selectedIndex = 1
    end
end

return Shop
