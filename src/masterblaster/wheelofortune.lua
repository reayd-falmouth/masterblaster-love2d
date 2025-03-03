wheelOfFortune = {}

local players = {}  -- Player list
local arrowIndex = 1  -- Current arrow position
local spinSpeed = 0.05  -- Initial speed of arrow movement
local minSpeed = 0.5  -- Slowest speed before stopping
local slowdownRate = 0.02  -- Rate at which it slows down
local isSpinning = true  -- True while the wheel is spinning
local timer = 0
local selectionSound = nil

function wheelOfFortune.load(playerData)
    players = playerData or {}
    arrowIndex = 1
    spinSpeed = 0.05
    isSpinning = true
    timer = 0
    selectionSound = love.audio.newSource("assets/sfx/cash.ogg", "static")  -- Load sound effect
end

function wheelOfFortune.update(dt)
    if isSpinning then
        timer = timer + dt
        if timer >= spinSpeed then
            timer = 0  -- Reset timer
            arrowIndex = arrowIndex % #players + 1  -- Move arrow to next player
            love.audio.play(selectionSound)  -- Play tick sound

            -- Slow down gradually
            spinSpeed = spinSpeed + slowdownRate
            if spinSpeed >= minSpeed then
                isSpinning = false  -- Stop spinning when slow enough
            end
        end
    end
end

function wheelOfFortune.draw()
    love.graphics.setColor(0, 0, 1)  -- Blue text
    love.graphics.printf("WHEEL-O-FORTUNE", 0, 20, love.graphics.getWidth(), "center")

    local startY = 60
    for i, player in ipairs(players) do
        love.graphics.setColor(1, 1, 1)  -- Reset color
        love.graphics.draw(player.sprite, 100, startY + (i - 1) * 40)

        -- Draw arrow if it's pointing at this player
        if i == arrowIndex then
            love.graphics.setColor(1, 0, 1)  -- Purple for arrow
            love.graphics.print(">", 80, startY + (i - 1) * 40)
        end
    end
end

return wheelOfFortune
