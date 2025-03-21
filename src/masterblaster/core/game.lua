-- game.lua
local UITheme = require("core.theme")  -- Import shared colors
local Spawns = require("core.spawns")
local windfield = require ("lib.windfield")
local Map = require("core.map")
local Player = require "entities.player"
local Assets = require("core.assets")  -- Centralized assets module
local Block = require("entities.block")
local Audio = require("system.audio")

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

local tileSize = 16  -- Tile size in pixels

-- At the top, rename your constants table:
local tileSheet

-- Helper function to load the sprite sheet and generate tile quads.
-- Helper function to load assets from the centralized assets module.
local function loadAssets()
    tileSheet = Assets.objectSpriteSheet
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
function spawnPlayers()
    LOG.debug("SPAWNING PLAYERS")
    local numPlayers = Settings.players
    local spawnPositions = Spawns:getSpawnPositions(numPlayers, Game.map)

    Game.players = {}
    local joysticks = love.joystick.getJoysticks()
    for i = 1, numPlayers do
        local joystick = joysticks[i]
        local guid = joystick and joystick:getGUID() or ("player" .. i)
        local p = Player:new(i, KeyMaps[i].keys, guid)
        p.x = spawnPositions[i].x
        p.y = spawnPositions[i].y
        p.collider:setPosition(p.x, p.y)
        Game.players[guid] = p  -- Store the player keyed by its GUID
    end

    LOG.debug("SPAWNING COMPLETE")
end

function Game.keypressed(key)
    if gameStarted and gameTime > 0 then
        if key == "escape" then
            Game.exitToMenu()  -- Use new function to properly reset and exit
        end
        -- Iterate over all players and pass the key event to each one.
        --for _, p in ipairs(Game.players) do
        --    p:keypressed(key)
        --end
    elseif gameTime <= 0 then
        -- Return to menu when game ends
        Game.exitToMenu()
    end
end

function Game.keyreleased(key)
    if gameStarted and gameTime > 0 then
        for _, p in ipairs(Game.players) do
            if p.keyreleased then
                p:keyreleased(key)
            end
        end
    end
end

function Game.exitToMenu()
    gameStarted = false
    gameMusic:stop()
    alarmTriggered = false
    alarmSound:stop()
    Game.reset()  -- Ensure everything is reset before returning to the menu
    switchState(require("scenes.menu")) -- Return to menu
end

function Game.exitToStandings()
    gameStarted = false
    gameMusic:stop()
    alarmTriggered = false
    alarmSound:stop()
    Game.reset()  -- Ensure everything is reset before returning to the standings

    local standings = require("scenes.standings")
    standings.load(playerResults) -- Pass player standings
    switchState(standings) -- Transition to standings screen
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

    Game.map = Map
    Game.items = {}
    Game.bombs = {}
    Game.fireballs = {}

    -- (Optional) Destroy player colliders if needed, or simply reinitialize the world.
    -- Reinitialize the physics world:
    Game.world = windfield.newWorld(0, 0, true)
    Game.world:setQueryDebugDrawing(DEBUG)

    -- Register your collision classes
    Game.world:addCollisionClass('Wall')
    Game.world:addCollisionClass('Player', { enters = {'Fireball', 'Item'} })
    Game.world:addCollisionClass('Fireball', { enters = {'Block', 'Item'} })
    Game.world:addCollisionClass('Block', { enters = {'Fireball'} })
    Game.world:addCollisionClass('Bomb', { enters = {'Fireball'} })
    Game.world:addCollisionClass('PlayerInvincible', { ignores = {'Fireball'}})
    Game.world:addCollisionClass('PlayerGhost', { ignores = {'Block', 'Bomb'}, enters = {'Fireball', 'Item'}})
    Game.world:addCollisionClass('BombInactive', { ignores = {'Player', 'PlayerGhost', 'PlayerInvincible'}, enters = {'Fireball'} })
    Game.world:addCollisionClass('Item', { enters = {'Player', 'Fireball', 'PlayerInvincible'} })

    -- Register the collision callbacks with the physics world.

    -- Reset other game state variables:
    countdown = 3
    countdownTimer = 1
    gameStarted = false
    gameTime = Settings.shrinking and 180 or 300
    alarmThreshold = gameTime / 3
    alarmTriggered = false
    playerResults = {}

    -- Rebuild map colliders and re-spawn players as needed
    Game.map:generateMap()

    spawnPlayers()
end

-- Main load function for the Game module.
function Game.load()
    -- Load assets, map, and audio
    loadAssets()
    loadAudio()
    -- Make sure to create/reset the world and add collision classes
    Game.reset()
end

function Game.update(dt)
    Game.world:update(dt)
    -- Update global ControllerInputs with the latest inputs.
    ControllerInputs = controllerManager:getPlayerInputs()

    for guid, input in pairs(ControllerInputs) do
        if Game.players then
            local player = Game.players[guid]
            if player then
                player:handleControllerInput(input)
            end
        end
    end

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
        if Settings.shrinking then
            if gameTime <= alarmThreshold and not alarmTriggered then
                alarmTriggered = true
                alarmSound:play()
            end
        end

        -- Speed up music
        local newPitch = gameMusic:getPitch() + (dt * tension)
        gameMusic:setPitch(math.min(newPitch, 2.0))

        Game.map:update(dt, alarmTriggered)

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

        -- Existing player, bomb, fireball, and block update loops...
        for guid, p in pairs(Game.players) do
            p:update(dt)
            if p.toRemove then
               Game.players[guid] = nil
            end
        end

        -- 3-second survival check for win condition:
        local activePlayers = {}
        for guid, p in pairs(Game.players) do
            if not p.toRemove then
                table.insert(activePlayers, p)
            end
        end

        if #activePlayers <= 1 then
            if not Game.winTimer then
                Game.winTimer = 0
            end
            Game.winTimer = Game.winTimer + dt

            if Game.winTimer >= 3 then
                if #activePlayers == 1 then
                    local winner = activePlayers[1]
                    PlayerStats:addWin(winner.index)
                end
                Game.exitToStandings()
            end
        else
            Game.winTimer = nil
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
        love.graphics.setColor(UITheme.defaultTheme.secondaryColor)
        love.graphics.printf(countdownText, 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, "center")
        love.graphics.setColor(1, 1, 1, 1)

    elseif gameTime > 0 then
        local minutes = math.floor(gameTime / 60)
        local seconds = math.floor(gameTime % 60)
        if DEBUG then
            love.graphics.printf(
                    string.format("TIME LEFT: %02d:%02d", minutes, seconds),
                    0, 20, VIRTUAL_WIDTH, "center"
            )
        end

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
            Game.map:draw()

            -- 3) Draw bombs
            if Game.bombs then
                for _, bomb in ipairs(Game.bombs) do
                    bomb:draw()
                end
            end

            -- 4) Draw players
            for _, player in pairs(Game.players) do
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
