local Audio = require("system.audio")
local Title = require("scenes.title")
local currentState = Title

Settings = require("config.settings")
ControllerManager = require("core.controller")

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

-- Global fullscreen flag
local isFullscreen = true

-- These variables will be computed on window resize
local scale, offsetX, offsetY = 1, 0, 0

function love.joystickadded(joystick)
    controllerManager:addJoystick(joystick)
    LOG.info("[Joystick Added]:", joystick:getName(), joystick:isGamepad(), joystick:getGUID())
end

function love.joystickremoved(joystick)
    --controllerManager:removeJoystick(joystick)
    LOG.info("[Joystick Removed]:", joystick:getName())
end

-- Function to change resolution using the global fullscreen flag.
-- After setting the mode, we force a recalculation of the scale and offsets.
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

    -- Set the default resolution and fullscreen mode on load.
    local res = resolutions[currentResolutionIndex]
    changeResolution(res.width, res.height)

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
    local uniformScale = math.min(w / VIRTUAL_WIDTH, h / VIRTUAL_HEIGHT)
    scale = uniformScale
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
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale)
    if currentState.draw then
        currentState.draw()
    end
    love.graphics.pop()
end

function love.keypressed(key)
    -- If escape is pressed while in the menu (Title state), exit the game.
    if key == "escape" then
        love.event.quit()
        return
    end

    -- Toggle fullscreen mode when F11 is pressed.
    if key == "f11" then
        isFullscreen = not isFullscreen
        local res = resolutions[currentResolutionIndex]
        changeResolution(res.width, res.height)
        print("Fullscreen toggled: " .. tostring(isFullscreen))
    end

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

    -- Increase resolution using plus key ("=" or "kp+"), but only if not at max preset
    if not isFullscreen then
        if key == "kp+" or key == "=" then
            if currentResolutionIndex < #resolutions then
                currentResolutionIndex = currentResolutionIndex + 1
                local res = resolutions[currentResolutionIndex]
                changeResolution(res.width, res.height)
                print("Changed resolution to " .. res.width .. "x" .. res.height)
            end

            -- Decrease resolution using minus key ("-" or "kp-"), but only if not at min preset
        elseif key == "kp-" or key == "-" then
            if currentResolutionIndex > 1 then
                currentResolutionIndex = currentResolutionIndex - 1
                local res = resolutions[currentResolutionIndex]
                changeResolution(res.width, res.height)
                print("Changed resolution to " .. res.width .. "x" .. res.height)
            end
        end
    end

    if currentState.keypressed then
        currentState.keypressed(key)
    end
end

function love.keyreleased(key)
    LOG.debug("love.keyreleased: " .. key)
    if currentState.keyreleased then
        currentState.keyreleased(key)
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
        LOG.info("Going to title...")
        currentState.load()
    end

    if musicFile then
        currentMusic = love.audio.newSource(musicFile, "stream")
        currentMusic:setLooping(true)
        currentMusic:play()
    end
end
