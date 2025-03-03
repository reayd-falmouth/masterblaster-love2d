local GameSettings = require("settings")
local UITheme = require("theme")  -- Import shared colors
local Game = {}

local gameMusic -- Variable to store the music
local alarmSound -- Variable to store the alarm sound
local countdown
local countdownTimer
local gameStarted
local gameTime
local alarmThreshold
local alarmTriggered
local tension = 0.002
local playerResults = {} -- Store player standings

local tileSheet
local tileQuads = {}  -- Initialize empty table
local tileSize = 16  -- Each tile is 32x32 pixels
local tilesPerRow = 20  -- Number of tiles per row
local tilesPerCol = 3    -- Number of tiles per column
local tileMap -- The tile map and TILE constants
local rows -- Total rows from the map
local cols  -- Total columns from the first row

local shrinkStep = 0 -- Tracks how many layers have been converted
local shrinkTimer = 0 -- Timer to control shrinking speed
local shrinkDelay = 2 -- Time (in seconds) between each shrink step

-- Function to shrink the map clockwise
local function shrinkMapStep()
    if tileSheet.WALL == nil then
        error("ERROR: TILE.WALL is nil! Check map.lua.")
    end

    if shrinkStep >= math.min(math.floor(rows / 2), math.floor(cols / 2)) then
        return -- Stop shrinking once the center is reached
    end

    local startRow = shrinkStep + 1
    local startCol = shrinkStep + 1
    local endRow = rows - shrinkStep
    local endCol = cols - shrinkStep

    -- **Top row (left to right)**
    for c = startCol, endCol do
        if tileMap[startRow][c] ~= tileSheet.WALL then
            tileMap[startRow][c] = tileSheet.WALL
        end
    end

    -- **Right column (top to bottom)**
    for r = startRow, endRow do
        if tileMap[r][endCol] ~= tileSheet.WALL then
            tileMap[r][endCol] = tileSheet.WALL
        end
    end

    -- **Bottom row (right to left)**
    for c = endCol, startCol, -1 do
        if tileMap[endRow][c] ~= tileSheet.WALL then
            tileMap[endRow][c] = tileSheet.WALL
        end
    end

    -- **Left column (bottom to top)**
    for r = endRow, startRow, -1 do
        if tileMap[r][startCol] ~= tileSheet.WALL then
            tileMap[r][startCol] = tileSheet.WALL
        end
    end

    -- Move to the next layer
    shrinkStep = shrinkStep + 1
end


-- Function to reset game state
function Game.reset()
    countdown = 3  -- Countdown before game starts
    countdownTimer = 1  -- Countdown step timer (1 second)
    gameStarted = false  -- Game state flag
    gameTime = 30  -- Game duration in seconds (change this back if needed)
    alarmThreshold = gameTime / 3 -- Time at which to sound alarm
    alarmTriggered = false -- Flag to check if the alarm has played
    playerResults = {} -- Reset standings
end

function Game.load(players)
    -- Load tileMap and TILE definitions dynamically
    tileMap, tileSheet = require("map")

    -- Reinitialize tileQuads to avoid stale data
    tileQuads = {}

    -- Generate quads for all tiles in `icons.png`
    local imgWidth, imgHeight = tileSheet:getDimensions()

    for row = 0, tilesPerCol - 1 do
        for col = 0, tilesPerRow - 1 do
            local tileIndex = (row * tilesPerRow) + col + 1  -- Convert 2D index to 1D
            tileQuads[tileIndex] = love.graphics.newQuad(col * tileSize, row * tileSize, tileSize, tileSize, imgWidth, imgHeight)
        end
    end

    -- Load game music (only if not already loaded)
    if not gameMusic then
        gameMusic = love.audio.newSource("assets/music/game_music.ogg", "stream")
        gameMusic:setLooping(true)
    end

    -- Load alarm sound (single-play sound effect)
    if not alarmSound then
        alarmSound = love.audio.newSource("assets/sfx/alarm.ogg", "static")
        alarmSound:setLooping(true)
    end

    gameMusic:setPitch(1.5)  -- Initial music speed

    -- Store player data for standings screen
    if type(players) == "table" then
        playerResults = players
    else
        print("WARNING: No player data provided. Using test data.")
        playerResults = {
            { name = "Player 1", sprite = nil, score = 100 },
            { name = "Player 2", sprite = nil, score = 80 },
            { name = "Player 3", sprite = nil, score = 60 },
            { name = "Player 4", sprite = nil, score = 40 }
        }
    end

    -- Reset the game state variables when loading
    Game.reset()
end


function Game.update(dt)
    if not gameStarted then
        -- Countdown logic before game starts
        countdownTimer = countdownTimer - dt
        if countdownTimer <= 0 then
            countdown = countdown - 1
            countdownTimer = 1  -- Reset timer for next step
            if countdown < 0 then
                gameStarted = true  -- Start the game
                gameMusic:play()  -- Play game music
            end
        end
    elseif gameTime > 0 then
        -- Decrease game time
        gameTime = gameTime - dt

        -- Trigger alarm at threshold mark
        if gameTime <= alarmThreshold and not alarmTriggered then
            alarmTriggered = true
            alarmSound:play()
        end

        -- Game logic and gradual music speed increase
        local newPitch = gameMusic:getPitch() + (dt * tension)  -- Slowly increase speed
        gameMusic:setPitch(math.min(newPitch, 2.0))  -- Cap at 2x speed

        -- Handle shrinking effect
        if alarmTriggered and GameSettings.shrinking then
            shrinkTimer = shrinkTimer + dt
            if shrinkTimer >= shrinkDelay then
                shrinkTimer = 0 -- Reset timer
                shrinkMapStep() -- Shrink the map
            end
        end
    else
        -- Game Over (time runs out)
        Game.exitToStandings()
    end
end

function Game.exitToMenu()
    gameStarted = false
    gameMusic:stop()
    alarmTriggered = false
    alarmSound:stop()
    Game.reset()  -- Ensure everything is reset before returning to the menu
    switchState(require("main_menu")) -- Return to menu
end

function Game.exitToStandings()
    gameStarted = false
    gameMusic:stop()
    alarmTriggered = false
    alarmSound:stop()
    Game.reset()  -- Ensure everything is reset before returning to the standings

    local standings = require("standings")
    if standings and standings.load then
        print("DEBUG: Passing player data to standings.load()")
        standings.load(playerResults) -- Pass player standings
        switchState(standings) -- Transition to standings screen
    else
        print("ERROR: standings.load() not found!")
    end
end

function Game.draw()
    -- Background color
    if alarmTriggered then
        -- Create a pulsing effect using a sine wave
        local pulseIntensity = math.abs(math.sin(love.timer.getTime())) -- Frequency of 5 Hz
        love.graphics.setBackgroundColor(pulseIntensity, 0, 0) -- Red pulsing effect
    else
        love.graphics.setBackgroundColor(0, 0, 0) -- Normal black background
    end
    love.graphics.setColor(1, 1, 1) -- White text

    if not gameStarted and countdown > 0 then
        -- Countdown text
        local countdownText = tostring(countdown)
        love.graphics.setColor(UITheme.highlightColor)
        love.graphics.printf(countdownText, 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
        love.graphics.setColor(1, 1, 1, 1)
    elseif gameTime > 0 then
        -- Display remaining game time
        local minutes = math.floor(gameTime / 60)
        local seconds = math.floor(gameTime % 60)
        love.graphics.printf(string.format("TIME LEFT: %02d:%02d", minutes, seconds), 0, 20, love.graphics.getWidth(), "center")

        -- Game logic UI
        --love.graphics.printf("GAME RUNNING...", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")

        -- **DRAW TILE MAP ONLY IF THE GAME HAS STARTED**
        if gameStarted then
            local screenWidth = love.graphics.getWidth()
            local screenHeight = love.graphics.getHeight()

            -- Get arena size in pixels
            local arenaWidth = #tileMap[1] * tileSize
            local arenaHeight = #tileMap * tileSize

            -- Calculate centered position
            local offsetX = (screenWidth - arenaWidth) / 2
            local offsetY = (screenHeight - arenaHeight) / 2

            -- Draw Tile Map Centered
            for row = 1, #tileMap do
                for col = 1, #tileMap[row] do
                    local tile = tileMap[row][col]
                    if tileQuads[tile] then  -- If it's a valid tile
                        love.graphics.draw(tileSheet, tileQuads[tile], offsetX + (col - 1) * tileSize, offsetY + (row - 1) * tileSize)
                    end
                end
            end
        end
    else
        -- Display "Time's Up!" message when time runs out
        love.graphics.printf("TIME'S UP!", 0, love.graphics.getHeight() / 2, love.graphics.getWidth(), "center")
    end
end


function Game.keypressed(key)
    if gameStarted and gameTime > 0 then
        if key == "escape" then
            Game.exitToMenu()  -- Use new function to properly reset and exit
        end
    elseif gameTime <= 0 then
        -- Return to menu when game ends
        Game.exitToMenu()
    end
end

return Game
