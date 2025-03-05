-- game.lua
local GameSettings = require("settings")
local UITheme = require("theme")  -- Import shared colors
local Spawns = require("spawns")
local windfield = require ("lib.windfield")
local Map = require("map")
local Player = require "player"
local Assets = require("assets")  -- Centralized assets module
local Block = require("block")
local Audio = require("audio")

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

-- Helper function to load the sprite sheet and generate tile quads.
-- Helper function to load assets from the centralized assets module.
local function loadAssets()
    tileSheet = Assets.objectSpriteSheet
    tileQuads = Assets.loadTileQuads(tileSize, tilesPerRow, tilesPerCol)
end

-- Helper function to generate and populate the game map.
local function loadMap()
    Game.map = Map -- Create a new empty tileMap
    Game.map:generateMap()  -- Now automatically uses safe zones based on map dimensions.
    -- If needed, you can also call map:placePowerUps(tileSheet) here.
end

-- Helper function to load audio assets.
local function loadAudio()
    -- Load game music if not already loaded.
    if not gameMusic then
        gameMusic = Audio.musicSources.arena
    end

    -- Load alarm sound if not already loaded.
    if not alarmSound then
        alarmSound = Audio.sfxSources.alarm
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
        p.collider:setPosition(p.x, p.y)
        table.insert(Game.players, p)
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

-- During spawnBlocks, build Game.blockMap[row][col]:
function Game.spawnBlocks()
    Game.blockMap = {}                   -- 2D array for block objects
    for row = 1, #Game.map.tileMap do
        Game.blockMap[row] = {}
        for col = 1, #Game.map.tileMap[row] do
            local tile = Game.map.tileMap[row][col]
            if tile ~= Game.map.tileIDs.EMPTY then
                local isDestructible = (tile == Game.map.tileIDs.DESTRUCTIBLE)
                local block = Block:new(row, col, tileSize, tile, isDestructible)
                Game.blockMap[row][col] = block
            else
                Game.blockMap[row][col] = nil
            end
        end
    end
end

-- Now getBlockAt can return the actual block object:
function Game:getBlockAt(x, y)
    local col = math.floor(x / tileSize) + 1
    local row = math.floor(y / tileSize) + 1
    if Game.blockMap and Game.blockMap[row] then
        return Game.blockMap[row][col]  -- The Block, or nil
    end
end

-- Function to reset game state
function Game.reset()
    -- Destroy existing colliders if you stored them in Game.colliders
    if Game.colliders then
        for _, collider in ipairs(Game.colliders) do
            collider:destroy()
        end
        Game.colliders = {}
    end

    -- (Optional) Destroy player colliders if needed, or simply reinitialize the world.
    -- Reinitialize the physics world:
    Game.world = windfield.newWorld(0, 0, true)
    Game.world:setQueryDebugDrawing(DEBUG)

    -- Register your collision classes
    Game.world:addCollisionClass('Player', { enters = {'Fireball'} })
    Game.world:addCollisionClass('Block', { enters = {'Fireball'} })
    Game.world:addCollisionClass('Fireball', { enters = {'Block'} })
    Game.world:addCollisionClass('Bomb', { enters = {'Fireball'} })

    -- Reset other game state variables:
    countdown = 3
    countdownTimer = 1
    gameStarted = false
    gameTime = 60
    alarmThreshold = gameTime / 3
    alarmTriggered = false
    playerResults = {}

    -- Rebuild map colliders and re-spawn players as needed
    Game.map:generateMap()
    Game.spawnBlocks()
    spawnPlayers()
end

-- Main load function for the Game module.
function Game.load()
    -- Load assets, map, and audio
    loadAssets()
    loadAudio()
    loadMap()
    -- Make sure to create/reset the world and add collision classes
    Game.reset()
end

function Game.update(dt)
    Game.world:update(dt)

    if not gameStarted then
        -- Countdown until game start
        countdownTimer = countdownTimer - dt
        if countdownTimer <= 0 then
            countdown = countdown - 1
            countdownTimer = 1
            if countdown < 0 then
                gameStarted = true
                gameMusic:play()
            end
        end

    elseif gameTime > 0 then
        -- Decrement game timer
        gameTime = gameTime - dt

        -- Alarm logic
        if gameTime <= alarmThreshold and not alarmTriggered then
            alarmTriggered = true
            alarmSound:play()
        end

        -- Speed up music
        local newPitch = gameMusic:getPitch() + (dt * tension)
        gameMusic:setPitch(math.min(newPitch, 2.0))

        if alarmTriggered and GameSettings.shrinking then
            shrinkTimer = shrinkTimer + dt
            if shrinkTimer >= shrinkDelay then
                shrinkTimer = 0
                Game.map:shrinkMapStep()
            end
        end

        -- 1) Update players
        for i = #Game.players, 1, -1 do
            local p = Game.players[i]
            p:update(dt)
            if p.toRemove then
                table.remove(Game.players, i)
            end
        end

        -- 2) Update bombs
        if Game.bombs then
            for i = #Game.bombs, 1, -1 do
                local bomb = Game.bombs[i]
                bomb:update(dt)
                if bomb.toRemove then
                    table.remove(Game.bombs, i)
                elseif bomb.state == "exploding" and bomb.timer <= 0 then
                    table.remove(Game.bombs, i)
                end
            end
        end

        -- 3) Update fireballs
        if Game.fireBalls then
            for i = #Game.fireBalls, 1, -1 do
                local fb = Game.fireBalls[i]
                fb:update(dt)
                if fb.timer <= 0 or fb.toRemove then
                    table.remove(Game.fireBalls, i)
                end
            end
        end

        -- CHANGED: 4) Update blocks directly from blockMap
        -- Go row-by-row, col-by-col
        for row = 1, #Game.blockMap do
            for col = 1, #Game.blockMap[row] do
                local block = Game.blockMap[row][col]
                if block then
                    block:update(dt)
                    if block.toRemove then
                        -- remove from blockMap
                        Game.blockMap[row][col] = nil
                    end
                end
            end
        end

    else
        -- Time up => game over
        Game.exitToStandings()
    end
end

function Game.draw()
    if alarmTriggered then
        local pulseIntensity = math.abs(math.sin(love.timer.getTime()))
        love.graphics.setBackgroundColor(pulseIntensity, 0, 0)
    else
        love.graphics.setBackgroundColor(0, 0, 0)
    end
    love.graphics.setColor(1, 1, 1)

    if not gameStarted and countdown > 0 then
        local countdownText = tostring(countdown)
        love.graphics.setColor(UITheme.highlightColor)
        love.graphics.printf(countdownText, 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, "center")
        love.graphics.setColor(1, 1, 1, 1)

    elseif gameTime > 0 then
        local minutes = math.floor(gameTime / 60)
        local seconds = math.floor(gameTime % 60)
        love.graphics.printf(
            string.format("TIME LEFT: %02d:%02d", minutes, seconds),
            0, 20, VIRTUAL_WIDTH, "center"
        )

        if gameStarted then
            local screenWidth = VIRTUAL_WIDTH
            local screenHeight = VIRTUAL_HEIGHT
            local arenaWidth = #Game.map.tileMap[1] * tileSize
            local arenaHeight = #Game.map.tileMap * tileSize
            local offsetX = (screenWidth - arenaWidth) / 2
            local offsetY = (screenHeight - arenaHeight) / 2

            love.graphics.push()
            love.graphics.translate(offsetX, offsetY)

            -- 1) Draw tile map
            for row = 1, #Game.map.tileMap do
                for col = 1, #Game.map.tileMap[row] do
                    local tile = Game.map.tileMap[row][col]
                    if tileQuads[tile] then
                        local worldX = (col - 1) * tileSize
                        local worldY = (row - 1) * tileSize
                        love.graphics.draw(tileSheet, tileQuads[tile], worldX, worldY)
                    end
                end
            end

            -- CHANGED: 2) Draw blocks from blockMap
            for row = 1, #Game.blockMap do
                for col = 1, #Game.blockMap[row] do
                    local block = Game.blockMap[row][col]
                    if block then
                        block:draw(tileQuads)
                    end
                end
            end

            -- 3) Draw bombs
            if Game.bombs then
                for _, bomb in ipairs(Game.bombs) do
                    bomb:draw()
                end
            end

            -- 4) Draw players
            for _, player in ipairs(Game.players) do
                player:draw(0, 0)
            end

            -- 5) Draw fireballs
            if Game.fireBalls then
                for _, fireball in ipairs(Game.fireBalls) do
                    fireball:draw()
                end
            end

            if DEBUG then
                Game.world:draw()
            end
            love.graphics.pop()
        end
    end
end


return Game
