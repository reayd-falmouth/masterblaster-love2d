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
    local mappingsData = love.filesystem.read(self.mappingFile)
    if mappingsData then
        love.joystick.loadGamepadMappings(mappingsData)
    else
        print("[INFO] No mapping file found. Using default mappings.")
    end
end

function ControllerManager:addJoystick(joystick)
    local playerNumber = #self.joysticks + 1
    self.joysticks[playerNumber] = {
        joystick = joystick,
        player = playerNumber
    }
    print(string.format("[INFO] Joystick '%s' assigned to Player %d.", joystick:getName(), playerNumber))
end

function ControllerManager:removeJoystick(joystick)
    for i, entry in ipairs(self.joysticks) do
        if entry.joystick == joystick then
            table.remove(self.joysticks, i)
            print(string.format("[INFO] Joystick removed from Player %d.", entry.player))
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
        if joystick:isGamepad() then
            table.insert(inputs, {
                player = entry.player,
                leftX = joystick:getGamepadAxis("leftx"),
                leftY = joystick:getGamepadAxis("lefty"),
                action = joystick:isGamepadDown("a")
            })
        end
    end
    return inputs
end

return ControllerManager
