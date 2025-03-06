-- overs.lua
local Assets = require("assets")
local PlayerStats = require("stats")
local Menu = require("menu")
local UITheme = require("theme")
local Overs = {}
Overs.__index = Overs

local winningPlayerIndex = nil
local winSound = nil

function Overs.load()
    -- Find the winning player (the first with wins >= winsNeeded)
    for i, stats in ipairs(PlayerStats.players) do
        if stats.wins >= GameSettings.winsNeeded then
            winningPlayerIndex = i
            break
        end
    end
end

function Overs.update(dt)
    -- We wait here until a key is pressed.
end

function Overs.draw()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setColor(UITheme.normalColor)
    love.graphics.printf("YOU WON !!!", 0, 50, VIRTUAL_WIDTH, "center")

    -- Draw the winning player's sprite (using the idle frame)
    local playerSpriteSheet = Assets.playerSpriteSheet
    local SPRITE_WIDTH, SPRITE_HEIGHT = 32, 22
    local ROW_FRAME_COUNT = 10
    local GAP = 1

    -- Calculate baseYOffset the same way as in player.lua:
    local baseYOffset = (winningPlayerIndex - 1) * (3 * SPRITE_HEIGHT + 3)
    local frameNumber = 1  -- use the idle frame (adjust if needed)
    local quad = Assets.getQuadWithOffset(frameNumber, baseYOffset, ROW_FRAME_COUNT, SPRITE_WIDTH, SPRITE_HEIGHT, GAP, playerSpriteSheet)
    
    local spriteX = (VIRTUAL_WIDTH - SPRITE_WIDTH) / 2
    local spriteY = 100
    love.graphics.setColor(UITheme.fgColor)
    love.graphics.draw(playerSpriteSheet, quad, spriteX, spriteY)

    love.graphics.setColor(UITheme.normalColor)
    love.graphics.printf("PRESS ANY BUTTON TO RESTART", 0, spriteY + SPRITE_HEIGHT + 20, VIRTUAL_WIDTH, "center")
end

function Overs.keypressed(key)
    -- On key press, transition back to the menu screen.
    switchState(Menu)
end

return Overs
