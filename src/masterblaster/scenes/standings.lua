-- standings.lua
local Audio = require("system.audio")
local Game = require("core.game")
local Assets = require("core.assets")
local PlayerStats = require("core.stats")  -- persistent stats module
local GameOver = require("scenes.overs")
local UITheme = require("core.theme")
local Shop = require("scenes.shop")
local WheelOFortune = require("scenes.wof")

local Standings = {}
Standings.__index = Standings

local standingsTime = 3  -- Time to display the standings screen
local timer = 0
local soundEffect = nil

-- Cache sprite sheet references from Assets:
local playerSpriteSheet = Assets.playerSpriteSheet
local objectsSpriteSheet = Assets.objectSpriteSheet

-- Constants (should match those used in assets.lua and player.lua):
local SPRITE_WIDTH, SPRITE_HEIGHT = 32, 22
local ROW_FRAME_COUNT = 10
local GAP = 1

-- Trophy quad from the objects sprite sheet:
-- Trophy is at row 1, column 14 in a 16x16 grid.
local trophyQuad = love.graphics.newQuad(
    (14 - 1) * 16,  -- x position: (column-1)*16
    (1 - 1) * 16,   -- y position: (row-1)*16
    16, 16,
    objectsSpriteSheet:getDimensions()
)

function Standings.load()
    timer = 0

    if not soundEffect then
        soundEffect = Audio.sfxSources.bingo
        soundEffect:setLooping(false)
    end

    soundEffect:play()
end

function Standings.update(dt)
    timer = timer + dt
    if timer >= standingsTime then
        if soundEffect then
            soundEffect:stop()
        end

        local tournamentWon = false
        for i, stats in ipairs(PlayerStats.players) do
            if stats.wins >= GameSettings.winsNeeded then
                tournamentWon = true
                break
            end
        end

        if tournamentWon then
            switchState(GameOver)
        elseif GameSettings.shop == "ON" then
            if GameSettings.gambling == "ON" then
                switchState(WheelOFortune)
            else
                switchState(Shop)
            end
        else
            switchState(Game)
        end
    end
end

function Standings.draw()
    love.graphics.setBackgroundColor(UITheme.bgColor)
    love.graphics.setColor(UITheme.normalColor)
    love.graphics.printf("STANDINGS", 0, 20, VIRTUAL_WIDTH, "center")

    -- Reset to white before drawing sprites
    love.graphics.setColor(UITheme.fgColor)

    local startY = 100         -- starting y position for the first row
    local rowSpacing = 40       -- vertical space between rows
    local playerSpriteX = 50    -- x position for player sprite
    local initialTrophyX = 150  -- starting x position for trophies
    local trophySpacing = 40    -- space between trophy icons

    for i, stats in ipairs(PlayerStats.players) do
        local y = startY + (i - 1) * rowSpacing

        -- Calculate the base Y offset (matching your player.lua logic)
        local baseYOffset = (i - 1) * (3 * SPRITE_HEIGHT + 3)
        local frameNumber = 1  -- try adjusting if needed
        local playerQuad = Assets.getQuadWithOffset(frameNumber, baseYOffset, ROW_FRAME_COUNT, SPRITE_WIDTH, SPRITE_HEIGHT, GAP, playerSpriteSheet)

        -- Draw the player's idle sprite:
        love.graphics.draw(playerSpriteSheet, playerQuad, playerSpriteX, y)

        -- Draw a trophy for each win:
        for j = 1, stats.wins do
            -- Optional: use push/pop to isolate state changes
            love.graphics.push()
            love.graphics.setColor(UITheme.fgColor)  -- ensure trophy is drawn with the correct tint
            local trophyX = initialTrophyX + (j - 1) * trophySpacing
            love.graphics.draw(objectsSpriteSheet, trophyQuad, trophyX, y)
            love.graphics.pop()
        end
    end
end

return Standings

