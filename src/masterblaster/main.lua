-- main.lua
local Audio = require("system.audio")
local Title = require("scenes.title")
local ControllerManager = require("core.controller")
local currentState = Title

GameSettings = require("config.settings")
PlayerStats = require("core.stats")

-- Controller manager instance
local controllerManager

-- Define players with unique control mappings
KeyMaps = {
    { name = "Player 1", keys = { up = "up", down = "down", left = "left", right = "right", bomb = "space" } },
    { name = "Player 2", keys = { up = "w", down = "s", left = "a", right = "d", bomb = "lctrl" } },
    { name = "Player 3", keys = { up = "i", down = "k", left = "j", right = "l", bomb = "rctrl" } },
    { name = "Player 4", keys = { up = "t", down = "g", left = "f", right = "h", bomb = "lshift" } },
    { name = "Player 5", keys = { up = "y", down = "h", left = "g", right = "j", bomb = "rshift" } },
}

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
        -- Optionally, you could set a flag to notify the user later in-game
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

    -- Get joystick inputs
    local inputs = controllerManager:getPlayerInputs()

    -- Map joystick inputs to your player logic
    for _, input in ipairs(inputs) do
        local playerIndex = input.player
        local playerControls = KeyMaps[player]

        -- Example logic: You need to define how your player objects move
        -- Replace this with your actual player movement/actions:
        if input.leftX < -0.2 then
            print(KeyMaps[input.player].name .. " moves left")
        elseif input.leftX > 0.2 then
            print(KeyMaps[input.player].name .. " moves right")
        end

        if input.leftY < -0.2 then
            print(KeyMaps[input.player].name .. " moves up")
        elseif input.leftY > 0.2 then
            print(KeyMaps[input.player].name .. " moves down")
        end

        if input.action then
            print(KeyMaps[input.player].name .. " pressed action/bomb button")
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
    controllerManager:removeJoystick(joystick)
    print("[Joystick Removed]:", joystick:getName())
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
