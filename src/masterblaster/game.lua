require("globals")
local GameSettings = require("settings")
local UITheme = require("theme")  -- Import shared colors
local Spawns = require("spawns")
Game = {}

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

local tileQuads = {}  -- Initialize empty table
local tilesPerRow = 20  -- Number of tiles per row
local tilesPerCol = 3    -- Number of tiles per column
local shrinkTimer = 0 -- Timer to control shrinking speed
local shrinkDelay = 2 -- Time (in seconds) between each shrink step
local tileSize = 16  -- Tile size in pixels

-- At the top, rename your constants table:
local tileSheet

-- Create a new empty tileMap
local Map = require("map")
Game.map = Map

-- Require the player module
local Player = require "player"

-- Helper function to load the sprite sheet and generate tile quads.
local function loadTileSheetAndQuads()
    -- Load the sprite sheet image.
    tileSheet = love.graphics.newImage("assets/sprites/icons.png")

    -- This ensures no “bleeding” from adjacent tiles in the sheet.
    tileSheet:setFilter("nearest", "nearest")
    tileSheet:setWrap("clamp", "clamp")

    tileQuads = {}  -- Reset the quads table.

    -- Get the dimensions of the sprite sheet image.
    local imgWidth, imgHeight = tileSheet:getDimensions()

    -- Generate quads for all tiles in the sprite sheet.
    for row = 0, tilesPerCol - 1 do
        for col = 0, tilesPerRow - 1 do
            local tileIndex = (row * tilesPerRow) + col + 1  -- Convert 2D index to 1D.
            tileQuads[tileIndex] = love.graphics.newQuad(
                col * tileSize, row * tileSize, -- x, y position on the sheet.
                tileSize, tileSize,             -- Width and height of the quad.
                imgWidth, imgHeight             -- Full dimensions of the sprite sheet.
            )
        end
    end
end

-- Helper function to generate and populate the game map.
local function loadMap()
    Game.map:generateMap()  -- Now automatically uses safe zones based on map dimensions.
    -- If needed, you can also call map:placePowerUps(tileSheet) here.
end

-- Helper function to load audio assets.
local function loadAudio()
    -- Load game music if not already loaded.
    if not gameMusic then
        gameMusic = love.audio.newSource("assets/sounds/music.ogg", "stream")
        gameMusic:setLooping(true)
    end

    -- Load alarm sound if not already loaded.
    if not alarmSound then
        alarmSound = love.audio.newSource("assets/sounds/alarm.ogg", "static")
        alarmSound:setLooping(true)
    end

    -- Set the initial pitch for game music.
    gameMusic:setPitch(1.5)
end

-- Helper function to spawn players
local function spawnPlayers()
    local numPlayers = GameSettings.players
    local spawnPositions = Spawns:getSpawnPositions(numPlayers, Game.map)

    Game.players = {}
    for i = 1, numPlayers do
        local p = Player:new(i)
        p.x = spawnPositions[i].x
        p.y = spawnPositions[i].y
        table.insert(Game.players, p)
    end
end

-- Main load function for the Game module.
function Game.load()
    -- Load sprite sheet and generate quads.
    loadTileSheetAndQuads()
    -- Build the game map.
    loadMap()
    -- Load audio assets.
    loadAudio()
    -- Spawn the playuers
    spawnPlayers()
    -- Reset game state variables (countdown, game time, etc.).
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
                Game.map:shrinkMapStep() -- Shrink the map
            end
        end

        -- Update each player in Game.players
        for _, p in ipairs(Game.players) do
            p:update(dt)
        end
    else
        -- Game Over (time runs out)
        Game.exitToStandings()
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
        love.graphics.printf(countdownText, 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, "center")
        love.graphics.setColor(1, 1, 1, 1)
    elseif gameTime > 0 then
        -- Display remaining game time
        local minutes = math.floor(gameTime / 60)
        local seconds = math.floor(gameTime % 60)
        love.graphics.printf(string.format("TIME LEFT: %02d:%02d", minutes, seconds), 0, 20, VIRTUAL_WIDTH, "center")

        -- Game logic UI
        --love.graphics.printf("GAME RUNNING...", 0, love.graphics.getHeight() / 2, VIRTUAL_WIDTH, "center")

        -- **DRAW TILE MAP ONLY IF THE GAME HAS STARTED**
        if gameStarted then
            local screenWidth = VIRTUAL_WIDTH
            local screenHeight = VIRTUAL_HEIGHT

            -- Get arena size in pixels
            local arenaWidth = #Game.map.tileMap[1] * tileSize
            local arenaHeight = #Game.map.tileMap * tileSize

            -- Calculate centered position
            local offsetX = (screenWidth - arenaWidth) / 2
            local offsetY = (screenHeight - arenaHeight) / 2

            -- Draw Tile Map Centered
            for row = 1, #Game.map.tileMap do
                for col = 1, #Game.map.tileMap[row] do
                    local tile = Game.map.tileMap[row][col]
                    if tileQuads[tile] then  -- If it's a valid tile
                        love.graphics.draw(tileSheet, tileQuads[tile],
                            offsetX + (col - 1) * tileSize,
                            offsetY + (row - 1) * tileSize)
                    end
                end
            end
        end
        if gameStarted then
            -- Draw each player in Game.players
            for _, p in ipairs(Game.players) do
                p:draw()
            end
        end
    end
end

function Game.keypressed(key)
    if gameStarted and gameTime > 0 then
        if key == "escape" then
            Game.exitToMenu()  -- Use new function to properly reset and exit
        end
        -- Iterate over all players and pass the key event to each one.
        for _, p in ipairs(Game.players) do
            p:keypressed(key)
        end
    elseif gameTime <= 0 then
        -- Return to menu when game ends
        Game.exitToMenu()
    end
end

function Game.exitToMenu()
    gameStarted = false
    gameMusic:stop()
    alarmTriggered = false
    alarmSound:stop()
    Game.reset()  -- Ensure everything is reset before returning to the menu
    switchState(require("menu")) -- Return to menu
end

function Game.exitToStandings()
    gameStarted = false
    gameMusic:stop()
    alarmTriggered = false
    alarmSound:stop()
    Game.reset()  -- Ensure everything is reset before returning to the standings

    local standings = require("standings")
    standings.load(playerResults) -- Pass player standings
    switchState(standings) -- Transition to standings screen
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

return Game
