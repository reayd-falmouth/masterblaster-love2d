-- core/controller.lua

local ControllerManager = {}
ControllerManager.__index = ControllerManager

function ControllerManager:new(mappingFile)
    local instance = {
        joysticks = {},
        mappingFile = mappingFile
    }
    setmetatable(instance, ControllerManager)
    return instance
end

function ControllerManager:loadMappings()
    local mappingsData, readErr = love.filesystem.read(self.mappingFile)
    if not mappingsData then
        print("Warning: Could not read mapping file:", readErr)
        return false
    end

    local success = love.joystick.loadGamepadMappings(mappingsData)
    if not success then
        print("Warning: Failed to parse joystick mappings.")
        return false
    end

    return true
end

function ControllerManager:addJoystick(joystick)
    table.insert(self.joysticks, {
        joystick = joystick,
        player = #self.joysticks + 1
    })
end

function ControllerManager:removeJoystick(joystick)
    for i, entry in ipairs(self.joysticks) do
        if entry.joystick == joystick then
            table.remove(self.joysticks, i)
            break
        end
    end
    self:reassignPlayers()
end

function ControllerManager:reassignPlayers()
    for i, entry in ipairs(self.joysticks) do
        entry.player = i
    end
end

function ControllerManager:getPlayerInputs()
    local inputs = {}
    for _, entry in ipairs(self.joysticks) do
        local joystick = entry.joystick
        if joystick:isGamepad() then  -- Make sure this is true
            table.insert(inputs, {
                player = entry.player,
                leftX = joystick:getGamepadAxis("leftx"),
                leftY = joystick:getGamepadAxis("lefty"),
                action = joystick:isGamepadDown("a")
            })
        else
            print("Joystick not recognized as gamepad:", joystick:getName())
        end
    end
    return inputs
end

return ControllerManager