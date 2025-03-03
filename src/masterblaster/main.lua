local MainMenu = require("menu")

local currentState = MainMenu  -- Start with the main menu
local currentMusic  -- Variable to track currently playing music

function love.load()
    currentState.load()
end

function love.update(dt)
    if currentState.update then
        currentState.update(dt)
    end
end

function love.draw()
    if currentState.draw then
        currentState.draw()
    end
end

function love.keypressed(key)
    if currentState.keypressed then
        currentState.keypressed(key)
    end
end

-- Function to switch states and manage music
function switchState(newState, musicFile)
    -- Stop current music if playing
    if currentMusic then
        currentMusic:stop()
        currentMusic = nil
    end

    -- Switch to the new state
    currentState = newState
    if currentState.load then
        currentState.load()
    end

    -- Only play new music if a file is provided (skip menu music)
    if musicFile then
        currentMusic = love.audio.newSource(musicFile, "stream")
        currentMusic:setLooping(true)
        currentMusic:play()
    end
end
