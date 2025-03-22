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

-- In your ControllerManager module:
function ControllerManager:addJoystick(joystick)
    local guid = joystick:getGUID()
    if self.joysticks[guid] then
        print("Joystick with GUID " .. guid .. " is already mapped.")
        return  -- Avoid mapping the same joystick twice.
    end
    self.joysticks[guid] = { joystick = joystick, player = nil }
end


function ControllerManager:removeJoystick(joystick)
    for i, entry in ipairs(self.joysticks) do
        if entry.joystick == joystick then
            table.remove(self.joysticks, i)
            print(string.format("[INFO] Joystick removed from Player %d.", entry.player))
            break
        end
    end
end

function ControllerManager:reassignPlayers()
    local index = 1
    for guid, entry in pairs(self.joysticks) do
        entry.player = index
        index = index + 1
    end
end

function ControllerManager:getPlayerInputs()
    local inputs = {}
    for guid, entry in pairs(self.joysticks) do
        local joystick = entry.joystick
        if joystick:isGamepad() then
            inputs[guid] = {
                player = entry.player,
                leftX = joystick:getGamepadAxis("leftx"),
                leftY = joystick:getGamepadAxis("lefty"),
                action = joystick:isGamepadDown("a"),
                playerGUID = guid
            }
        end
    end
    return inputs
end


return ControllerManager
