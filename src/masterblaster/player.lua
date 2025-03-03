local Player = {}
Player.__index = Player

local spriteSheet = love.graphics.newImage("assets/sprites/player.png")
local SPRITE_WIDTH, SPRITE_HEIGHT = 32, 22
local ROW1_FRAME_COUNT = 10  -- frames 1 to 10 on the first row
local GAP = 1  -- one pixel gap between rows

-- Returns the 16x16 collision box based on the player's bottom-center point.
function Player:getCollisionBox()
    return self.x - 8, self.y - 16, 16, 16 -- (x, y, width, height)
end

-- Checks for collision against the shared map's solid tiles from Game.map.
function Player:checkCollision(newX, newY)
    local bx, by, bw, bh = newX - 8, newY - 16, 16, 16  -- Future collision box

    if Game.map and Game.map.solidTiles then
        for _, obj in ipairs(Game.map.solidTiles) do
            local ox, oy, ow, oh = obj.x, obj.y, obj.width, obj.height
            if bx < ox + ow and bx + bw > ox and by < oy + oh and by + bh > oy then
                return true  -- Collision detected
            end
        end
    end

    return false  -- No collision
end

-- Example Player constructor including player-specific animation state
function Player:new(playerIndex)
    local self = setmetatable({}, Player)
    self.index = playerIndex or 1
    self.baseYOffset = (self.index - 1) * (3 * SPRITE_HEIGHT + 3)
    self.spriteSheet = spriteSheet

    local function getQuadWithOffset(frame)
        local x, y
        if frame <= ROW1_FRAME_COUNT then
            x = (frame - 1) * SPRITE_WIDTH
            y = self.baseYOffset
        else
            x = (frame - ROW1_FRAME_COUNT - 1) * SPRITE_WIDTH
            y = self.baseYOffset + SPRITE_HEIGHT + GAP
        end
        return love.graphics.newQuad(x, y, SPRITE_WIDTH, SPRITE_HEIGHT, spriteSheet:getDimensions())
    end

    local function generateAnimation(startFrame, endFrame)
        local anim = {}
        for frame = startFrame, endFrame do
            table.insert(anim, getQuadWithOffset(frame))
        end
        return anim
    end

    self.animations = {
        moveDown  = generateAnimation(1, 3),
        moveRight = generateAnimation(4, 6),
        moveLeft  = generateAnimation(7, 9),
        moveUp    = generateAnimation(10, 12),
        die       = generateAnimation(13, 21),
        remote    = generateAnimation(22, 24)
    }

    self.currentAnimation = self.animations.moveDown
    self.currentFrame = 1
    self.frameDuration = 0.1
    self.animationTimer = 0

    self.x = 100
    self.y = 100
    self.speed = 50

    self.fireBlastX = 1
    self.fireBlastY = 1
    self.superman = false
    self.yingyang = false
    self.ghost = false
    self.numberOfBombs = 1
    self.timedBombs = false
    self.stopped = false
    self.remote = false

    return self
end

-- Update the player's movement and animation while checking collisions against the shared map.
function Player:update(dt)
    if self.stopped then return end

    local moving = false
    local newX, newY = self.x, self.y  -- Predict new position

    if love.keyboard.isDown("up") then
        newY = self.y - self.speed * dt
        self.currentAnimation = self.animations.moveUp
        moving = true
    elseif love.keyboard.isDown("down") then
        newY = self.y + self.speed * dt
        self.currentAnimation = self.animations.moveDown
        moving = true
    elseif love.keyboard.isDown("left") then
        newX = self.x - self.speed * dt
        self.currentAnimation = self.animations.moveLeft
        moving = true
    elseif love.keyboard.isDown("right") then
        newX = self.x + self.speed * dt
        self.currentAnimation = self.animations.moveRight
        moving = true
    end

    -- Only update position if the new position does not collide with a wall.
    if moving and not self:checkCollision(newX, newY) then
        self.x, self.y = newX, newY
    end

    if moving then
        self.animationTimer = self.animationTimer + dt
        if self.animationTimer >= self.frameDuration then
            self.animationTimer = self.animationTimer - self.frameDuration
            self.currentFrame = (self.currentFrame % #self.currentAnimation) + 1
        end
    else
        self.currentFrame = 1
        self.animationTimer = 0
    end
end

-- Draw the current frame of the player.
function Player:draw()
    love.graphics.draw(self.spriteSheet, self.currentAnimation[self.currentFrame], self.x, self.y)
end

-- Handle key presses (e.g., to drop a bomb).
function Player:keypressed(key)
    if key == "space" then
        self:dropBomb()
    end
end

function Player:dropBomb()
    if self.remote then
        print("Remote bomb activated: use cursor keys to move the bomb.")
    else
        print("Bomb dropped at (" .. self.x .. ", " .. self.y .. ")")
    end
end

function Player:setAnimation(animName)
    if self.animations[animName] then
        self.currentAnimation = self.animations[animName]
        self.currentFrame = 1
        self.animationTimer = 0
    else
        print("Animation " .. animName .. " not found.")
    end
end

return Player
