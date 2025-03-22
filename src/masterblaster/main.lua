-- main.lua
Audio = require("system.audio")
Audio.load()
ControllerManager = require("core.controller")
GameSettings = require("config.settings")
Game = require("core.game")

PlayerStats = require("core.stats")

-- scenes
Title = require("scenes.title")
Credits = require("scenes.credits")
Shop = require("scenes.shop")


currentState = Title

-- Preset resolutions to cycle through (in ascending order)
local resolutions = {
    { width = 640, height = 512 },
    { width = 800, height = 600 },
    { width = 1024, height = 768 },
    { width = 1280, height = 960 },
}
local currentResolutionIndex = 1
local isFullscreen = true
local scale, offsetX, offsetY = 1, 0, 0

function changeResolution(newWidth, newHeight)
    local success, err = love.window.setMode(newWidth, newHeight, {
        resizable = true,
        vsync = true,
        fullscreen = isFullscreen,
        fullscreentype = isFullscreen and "desktop" or nil
    })
    if not success then
        print("Failed to change resolution: " .. err)
    else
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        love.resize(w, h)
    end
end

function love.load()
    -- Load controller mappings gracefully
    controllerManager = ControllerManager:new("gamecontrollerdb.txt")
    local status, err = pcall(function()
        controllerManager:loadMappings()
    end)
    if not status then
        print("[WARNING] Joystick mappings failed to load:", err)
    end

    -- Initialize joysticks already connected
    for _, joystick in ipairs(love.joystick.getJoysticks()) do
        controllerManager:addJoystick(joystick)
    end

    local iconData = love.image.newImageData("assets/images/icon_32x.png")
    love.window.setIcon(iconData)

    local res = resolutions[currentResolutionIndex]
    changeResolution(res.width, res.height)

    Audio.load()
    Audio.setMusicVolume(0.8)
    Audio.setSFXVolume(1.0)

    if currentState.load then
        currentState.load()
    end
end

function love.resize(w, h)
    local uniformScale = math.min(w / VIRTUAL_WIDTH, h / VIRTUAL_HEIGHT)
    scale = uniformScale
    offsetX = (w - VIRTUAL_WIDTH * scale) / 2
    offsetY = (h - VIRTUAL_HEIGHT * scale) / 2
end

function love.update(dt)
    if currentState.update then
        currentState.update(dt)
    end

    -- Update global ControllerInputs with the latest inputs.
    ControllerInputs = controllerManager:getPlayerInputs()

    -- Process each input for in-game actions.
    for _, input in ipairs(ControllerInputs) do
        if Game.players then
            local player = Game.players[input.playerGUID]  -- Use the GUID as the key.
            if player then
                player:handleControllerInput(input)
            end
        end
    end
end

function love.draw()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.push()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale)
    if currentState.draw then
        currentState.draw()
    end
    love.graphics.pop()
end

function love.joystickadded(joystick)
    controllerManager:addJoystick(joystick)
    print("[Joystick Added]:", joystick:getName(), joystick:isGamepad(), joystick:getGUID())
end

function love.joystickremoved(joystick)
    --controllerManager:removeJoystick(joystick)
    print("[Joystick Removed]:", joystick:getName())
end

-- New: Map player 1 controller input for menu navigation.
function love.gamepadpressed(joystick, button)
    if currentState.gamepadpressed then
        currentState.gamepadpressed(joystick, button)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        return
    elseif key == "f11" then
        isFullscreen = not isFullscreen
        local res = resolutions[currentResolutionIndex]
        changeResolution(res.width, res.height)
        print("Fullscreen toggled: " .. tostring(isFullscreen))
    elseif key == "m" then
        Audio.setMusicVolume(Audio.getMusicVolume() > 0 and 0 or 1.0)
    elseif key == "n" then
        Audio.setSFXVolume(Audio.getSFXVolume() > 0 and 0 or 1.0)
    elseif (key == "kp+" or key == "=") and currentResolutionIndex < #resolutions then
        currentResolutionIndex = currentResolutionIndex + 1
        local res = resolutions[currentResolutionIndex]
        changeResolution(res.width, res.height)
        print("Changed resolution to " .. res.width .. "x" .. res.height)
    elseif (key == "kp-" or key == "-") and currentResolutionIndex > 1 then
        currentResolutionIndex = currentResolutionIndex - 1
        local res = resolutions[currentResolutionIndex]
        changeResolution(res.width, res.height)
        print("Changed resolution to " .. res.width .. "x" .. res.height)
    end

    if currentState.keypressed then
        currentState.keypressed(key)
    end
end

function love.keyreleased(key)
    log.debug("love.keyreleased: " .. key)
    if currentState.keyreleased then
        currentState.keyreleased(key)
    end
end

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
