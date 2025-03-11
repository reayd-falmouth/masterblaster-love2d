require("config.globals")
local Assets = require("core.assets")
local Audio = require("system.audio")
local UITheme = require("core.theme")
local Shop = require("scenes.shop")
local Game = require("core.game")

local WheelOfFortune = {}
WheelOfFortune.__index = WheelOfFortune

-- Cache sprite sheet references from Assets
local playerSpriteSheet = Assets.playerSpriteSheet

-- Constants (should match those used in assets.lua and player.lua)
local SPRITE_WIDTH, SPRITE_HEIGHT = 32, 22
local ROW_FRAME_COUNT = 10
local GAP = 1

-- Wheel-of-Fortune state
local arrowIndex = 1          -- Current arrow (pointer) position
local spinSpeed = 0.001       -- Initial speed of arrow movement (fast)
local minSpeed = 0.5          -- Slowest speed before stopping
local slowdownRate = 0.02     -- Rate at which it slows down
local isSpinning = true       -- True while the wheel is spinning
local timer = 0
local selectionSound = nil
local clickSound = nil

-- New variables for post-spin delay
local postSpinTimer = 0
local stateSwitched = false

function WheelOfFortune.load()
    arrowIndex = 1
    spinSpeed = 0.000000001  -- Extremely fast initial spin
    isSpinning = true
    timer = 0
    postSpinTimer = 0
    stateSwitched = false

    selectionSound = Audio.sfxSources.cash
    clickSound = Audio.sfxSources.cash
end

function WheelOfFortune.update(dt)
    if isSpinning and #PlayerStats.players > 0 then
        timer = timer + dt
        local updates = 0
        local maxUpdates = 20  -- Increase this to process more updates per frame

        while timer >= spinSpeed and updates < maxUpdates do
            timer = timer - spinSpeed

            -- Advance the pointer to the next player.
            arrowIndex = (arrowIndex % #PlayerStats.players) + 1

            -- Stop and replay the click sound for each update.
            if clickSound:isPlaying() then clickSound:stop() end
            clickSound:play()

            -- Gradually slow the pointer.
            spinSpeed = spinSpeed + slowdownRate

            updates = updates + 1

            -- Stop spinning if we've slowed down enough.
            if spinSpeed >= minSpeed then
                isSpinning = false

                -- Increase the winning player's coin count by one.
                local winningPlayer = PlayerStats.players[arrowIndex]
                winningPlayer.coins = (winningPlayer.coins or 0) + 1

                selectionSound:play()
                break
            end
        end
    end

    -- Once the spin is complete, wait 3 seconds before switching state.
    if not isSpinning and not stateSwitched then
        postSpinTimer = postSpinTimer + dt
        if postSpinTimer >= 3 then
            if Settings.shop == "ON" then
                switchState(Shop)
            else
                switchState(Game)
            end
            stateSwitched = true
        end
    end
end

function WheelOfFortune.draw()
    -- Title at top, centered horizontally
    love.graphics.setColor(UITheme.normalColor) -- e.g. Blue
    love.graphics.printf("WHEEL-O-FORTUNE", 0, 20, VIRTUAL_WIDTH, "center")
    love.graphics.setColor(UITheme.fgColor)

    -- We'll space each player row by this many pixels
    local rowSpacing = 40

    -- Total vertical space needed for all players
    local totalHeight = 300  -- You can adjust this if you want to calculate dynamically

    -- We'll center this block in the screen, but push it down a bit from the title
    local startY = (VIRTUAL_HEIGHT / 2) - (totalHeight / 2) + 40

    -- Center the sprite horizontally (by subtracting half the sprite width)
    local spriteX = (VIRTUAL_WIDTH / 2) - (SPRITE_WIDTH / 2)

    -- Pointer is drawn to the left of the sprite
    local pointerX = spriteX - 20

    for i, stats in ipairs(PlayerStats.players) do
        local y = startY + (i - 1) * rowSpacing

        -- Build the sprite quad
        local baseYOffset = (i - 1) * (3 * SPRITE_HEIGHT + 3)
        local frameNumber = 1
        local playerQuad = Assets.getQuadWithOffset(
            frameNumber,
            baseYOffset,
            ROW_FRAME_COUNT,
            SPRITE_WIDTH,
            SPRITE_HEIGHT,
            GAP,
            playerSpriteSheet
        )

        -- Draw the player's sprite at (spriteX, y)
        love.graphics.draw(playerSpriteSheet, playerQuad, spriteX, y)

        -- Draw ">" next to the player if they're currently selected
        if i == arrowIndex then
            love.graphics.setColor(UITheme.highlightColor)
            local pointerTextHeight = love.graphics.getFont():getHeight()
            love.graphics.print(">", pointerX, y + (SPRITE_HEIGHT - pointerTextHeight) / 2)
            love.graphics.setColor(UITheme.fgColor)
        end
    end
end

return WheelOfFortune
