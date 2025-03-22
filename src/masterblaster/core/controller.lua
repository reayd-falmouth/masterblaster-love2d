local ControllerManager = {}
ControllerManager.__index = ControllerManager

function ControllerManager:new(mappingFile)
    local instance = {
        joysticks = {},
        mappingFile = mappingFile,
        previousButtonStates = {} -- track previous button states
    }
    setmetatable(instance, ControllerManager)
    return instance
end

function ControllerManager:loadMappings()
    local mappingsData = love.filesystem.read(self.mappingFile)
    if mappingsData then
        love.joystick.loadGamepadMappings(mappingsData)
    else
        print("[INFO] No mapping file found. Using default mappings.")
    end
end

function ControllerManager:addJoystick(joystick)
    local guid = joystick:getGUID()
    if self.joysticks[guid] then
        print("Joystick with GUID " .. guid .. " is already mapped.")
        return  -- Avoid mapping the same joystick twice.
    end
    self.joysticks[guid] = { joystick = joystick, player = nil }
end

function ControllerManager:removeJoystick(joystick)
    local guid = joystick:getGUID()
    if self.joysticks[guid] then
        print(string.format("[INFO] Joystick removed from Player %d.", self.joysticks[guid].player))
        self.joysticks[guid] = nil
        self.previousButtonStates[guid] = nil  -- Clean up previous state
    else
        print("[WARN] Attempted to remove a joystick that was not registered.")
    end
end

function ControllerManager:reassignPlayers()
    local index = 1
    for _, entry in pairs(self.joysticks) do
        entry.player = index
        index = index + 1
    end
end

function ControllerManager:getPlayerInputs()
    local inputs = {}
    for guid, entry in pairs(self.joysticks) do
        local joystick = entry.joystick
        if joystick:isGamepad() then
            local currentAction = joystick:isGamepadDown("a")

            -- Fetch previous state, default to false if nil
            local previousAction = self.previousButtonStates[guid] or false

            inputs[guid] = {
                player = entry.player,
                leftX = joystick:getGamepadAxis("leftx"),
                leftY = joystick:getGamepadAxis("lefty"),
                action = currentAction,
                actionPressed = currentAction and not previousAction,
                actionReleased = not currentAction and previousAction,
                playerGUID = guid
            }

            -- Update previous state for the next frame
            self.previousButtonStates[guid] = currentAction
        end
    end
    return inputs
end

return ControllerManager
