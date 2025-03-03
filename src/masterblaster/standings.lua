standings = {}

local standingsTime = 3  -- Time to display the standings screen
local timer = 0
local standingsData = {}
local soundEffect = nil

function standings.load(players)
    if type(players) ~= "table" then
        print("Error: standings.load() received invalid player data")
        standingsData = {}  -- Prevent further errors
    else
        standingsData = players
    end
    timer = 0

    -- Play sound only if not already playing
    if not soundEffect then
        soundEffect = love.audio.newSource("assets/sfx/bingo.ogg", "stream")
        soundEffect:setLooping(false)
        soundEffect:play()
    end
end

function standings.update(dt)
    timer = timer + dt
    if timer >= standingsTime then
        -- Stop the sound before transitioning
        if soundEffect then
            soundEffect:stop()
        end
        print("loading wheel o fortune")
        local wheelOfFortune = require("wheel_of_fortune")
        if wheelOfFortune and wheelOfFortune.load then
            wheelOfFortune.load(standingsData)  -- Pass player data
            switchState(wheelOfFortune)
        else
            print("Error: wheelOfFortune.load() not found!")
        end
    end
end

function standings.draw()
    love.graphics.setBackgroundColor(0, 0, 0) -- Normal black background
    love.graphics.setColor(0, 0, 1)  -- Blue color for text
    love.graphics.printf("STANDINGS", 0, 20, love.graphics.getWidth(), "center")

    if type(standingsData) ~= "table" or #standingsData == 0 then
        love.graphics.setColor(1, 0, 0)  -- Red for error message
        love.graphics.printf("NO PLAYER DATA AVAILABLE!", 0, 60, love.graphics.getWidth(), "center")
        return
    end

    local startY = 60
    for i, player in ipairs(standingsData) do
        if player.sprite then
            love.graphics.setColor(1, 1, 1)  -- Reset color
            love.graphics.draw(player.sprite, 100, startY + (i - 1) * 40)
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf("PLAYER " .. i, 100, startY + (i - 1) * 40, 200, "left")
        end

        if i == 1 then
            love.graphics.setColor(1, 1, 0)  -- Yellow for trophy
            love.graphics.print("🏆", 150, startY + (i - 1) * 40)
        end
    end
end

return standings
