require("globals")
LOGGER = require("logging")
local Audio = require("audio")
local Title = require("title")
local Menu = require("menu")
local currentState = Menu

-- These variables will be computed on window resize
local scale, offsetX, offsetY = 1, 0, 0

function love.load()
    -- Initialize all references
    Audio.load()

    -- Set initial volumes if you want
    Audio.setMusicVolume(0.8)
    Audio.setSFXVolume(1.0)

    if currentState.load then
        currentState.load()
    end
end

-- Recalculate the uniform scale and offsets when the window size changes
function love.resize(w, h)
    -- Use the smaller ratio to maintain aspect ratio
    local uniformScale = math.min(w / VIRTUAL_WIDTH, h / VIRTUAL_HEIGHT)

    -- Multiply by zoomFactor to zoom in/out
    scale = uniformScale

    -- Calculate offsets to center the content
    offsetX = (w - VIRTUAL_WIDTH * scale) / 2
    offsetY = (h - VIRTUAL_HEIGHT * scale) / 2
end

function love.update(dt)
    if currentState.update then
        currentState.update(dt)
    end
end

function love.draw()
    love.graphics.setDefaultFilter("nearest", "nearest")

    love.graphics.push()

    -- First, translate the coordinate system by the calculated offsets
    love.graphics.translate(offsetX, offsetY)

    -- Then apply the uniform scale (including zoom)
    love.graphics.scale(scale)

    if currentState.draw then
        currentState.draw()
    end

    love.graphics.pop()
end

function love.keypressed(key)
    -- Toggle music if 'm' is pressed
    if key == "m" then
        if Audio.getMusicVolume() > 0 then
            Audio.setMusicVolume(0)
        else
            Audio.setMusicVolume(1.0)
        end
    end

    -- Toggle SFX if 'n' is pressed
    if key == "n" then
        if Audio.getSFXVolume() > 0 then
            Audio.setSFXVolume(0)
        else
            Audio.setSFXVolume(1.0)
        end
    end

    if currentState.keypressed then
        currentState.keypressed(key)
    end
end

-- Function to switch states and manage music
function switchState(newState, musicFile)
    if currentMusic then
        currentMusic:stop()
        currentMusic = nil
    end

    currentState = newState
    if currentState.load then
        currentState.load()
    end

    if musicFile then
        currentMusic = love.audio.newSource(musicFile, "stream")
        currentMusic:setLooping(true)
        currentMusic:play()
    end
end
