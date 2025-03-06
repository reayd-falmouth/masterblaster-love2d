local Assets = require("assets")
local Audio = require("audio")
local Fireball = require("fireball")
local Bomb = {}
Bomb.__index = Bomb

-- Bomb-specific constants.
local BOMB_FRAME_WIDTH    = 16
local BOMB_FRAME_HEIGHT   = 16
local BOMB_FRAMES_PER_ROW = 20  -- Adjust to match your objects sprite sheet layout.
local BOMB_GAP            = 0
local COLLIDER_RADIUS = 7

-- Use the objects sprite sheet for bomb animations.
local spriteSheet = Assets.objectSpriteSheet

-- Define animations using the generic helper.
-- Idle animation: row 2, frames 15–17.
local idleAnimation = Assets.generateAnimation(15, 17, BOMB_FRAME_HEIGHT, BOMB_FRAMES_PER_ROW, BOMB_FRAME_WIDTH, BOMB_FRAME_HEIGHT, BOMB_GAP, spriteSheet)

-- Remote left/right: two parts.
local remoteLR_part1 = Assets.generateAnimation(19, 20, 0, BOMB_FRAMES_PER_ROW, BOMB_FRAME_WIDTH, BOMB_FRAME_HEIGHT, BOMB_GAP, spriteSheet)
local remoteLR_part2 = Assets.generateAnimation(5, 8, BOMB_FRAME_HEIGHT, BOMB_FRAMES_PER_ROW, BOMB_FRAME_WIDTH, BOMB_FRAME_HEIGHT, BOMB_GAP, spriteSheet)
local remoteLRAnimation = {}
for _, quad in ipairs(remoteLR_part1) do table.insert(remoteLRAnimation, quad) end
for _, quad in ipairs(remoteLR_part2) do table.insert(remoteLRAnimation, quad) end

-- Remote up/down: row 3, frames 15–20.
local remoteUDAnimation = Assets.generateAnimation(15, 20, 2 * BOMB_FRAME_HEIGHT, BOMB_FRAMES_PER_ROW, BOMB_FRAME_WIDTH, BOMB_FRAME_HEIGHT, BOMB_GAP, spriteSheet)

-- For movement, we'll use remoteLRAnimation.
local movingAnimation = remoteLRAnimation

local FRAME_DURATION = 0.1  -- Seconds per frame.

-- Define a local cell size (should match your grid cell size)
local tileSize = 16

-- Load the explosion sound.
local explosionSound = Audio.sfxSources.explode

-- Local helper function to spawn a fireBall entity.
local function spawnFireBall(x, y, delay)
    Game.fireBalls = Game.fireBalls or {}
    local fb = Fireball:new(x, y, delay, Game.world)
    table.insert(Game.fireBalls, fb)
end

function Bomb:new(player)
    -- Snap bomb to the center of the grid block.
    local gridX = math.floor(player.x / tileSize) * tileSize + tileSize / 2
    local gridY = math.floor(player.y / tileSize) * tileSize + tileSize / 2

    -- Default bomb power (if player.power is nil, default to 1)
    local power = player.power + 2

    local bomb = {
        x = gridX,
        y = gridY,
        power = power,
        timer = 3,              -- Countdown until explosion.
        state = "idle",         -- "idle", "moving", "exploding"
        owner = player,
        spriteSheet = spriteSheet,
        animation = idleAnimation,
        currentFrame = 1,
        frameDuration = FRAME_DURATION,
        animationTimer = 0,
        -- Create the collider as a rectangle centered on the bomb.
        --collider = Game.world:newRectangleCollider(gridX - tileSize/2, gridY - tileSize/2, tileSize, tileSize),
        collider = Game.world:newCircleCollider(
            gridX,
            gridY,
            (COLLIDER_RADIUS / 2)
        ),
        activationDelay = 1,   -- Time in seconds before bomb collision becomes active.
        toRemove = false
    }
    bomb.collider:setSensor(true)  -- Disable collision initially.
    bomb.collider:setType("static")
    bomb.collider:setCollisionClass("Bomb")
    bomb.collider:setObject(bomb)
    --bomb.collider:setUserData(bomb)
    setmetatable(bomb, Bomb)
    return bomb
end

function Bomb:update(dt)
    -- If we've already flagged for removal, skip updates entirely
    if self.toRemove then return end

    -- Check collision with a Fireball if collider still exists
    if self.collider and self.collider:enter("Fireball") then
        self:explode()  -- Switch to death logic
        self.toRemove = true -- remove the bomb before animation completed
    end

    self.timer = self.timer - dt
    self.animationTimer = self.animationTimer + dt
    if self.animationTimer >= self.frameDuration then
        self.animationTimer = self.animationTimer - self.frameDuration
        self.currentFrame = (self.currentFrame % #self.animation) + 1
    end

    -- Handle activation delay: after a short delay, enable collision.
    if self.activationDelay > 0 then
        self.activationDelay = self.activationDelay - dt
        if self.activationDelay <= 0 then
            self.collider:setSensor(false)
        end
    end

    if self.timer <= 0 and self.state ~= "exploding" then
        self:explode()
    end

    if self.state == "idle" then
        -- Allow bomb movement if the player has remote or superman attributes.
        if self.owner.remote and love.keyboard.isDown("space") and self.owner:isStationary() then
            self.state = "moving"
            self.animation = remoteLRAnimation
            if love.keyboard.isDown("up") then
                self.y = self.y - tileSize
            elseif love.keyboard.isDown("down") then
                self.y = self.y + tileSize
            elseif love.keyboard.isDown("left") then
                self.x = self.x - tileSize
            elseif love.keyboard.isDown("right") then
                self.x = self.x + tileSize
            end
            self.collider:setPosition(self.x - tileSize/2, self.y - tileSize/2)
        elseif self.owner.superman then
            self.state = "moving"
            self.animation = movingAnimation
            if love.keyboard.isDown("up") then
                self.y = self.y - tileSize
            elseif love.keyboard.isDown("down") then
                self.y = self.y + tileSize
            elseif love.keyboard.isDown("left") then
                self.x = self.x - tileSize
            elseif love.keyboard.isDown("right") then
                self.x = self.x + tileSize
            end
            self.collider:setPosition(self.x - tileSize/2, self.y - tileSize/2)
        end
        -- If neither remote nor superman, the bomb remains static.
    end
end

function Bomb:explode()
    self.state = "exploding"
    explosionSound:play()

    -- Destroy this bomb's own collider
    if self.collider then
        self.collider:destroy()
        self.collider = nil
    end

    -- Spawn fire at the bomb's center
    spawnFireBall(self.x, self.y)

    local directions = {
        {dx = 1, dy = 0},   -- right
        {dx = -1, dy = 0},  -- left
        {dx = 0, dy = 1},   -- down
        {dx = 0, dy = -1}   -- up
    }

    local propagationDelay = 0.1

    for _, dir in ipairs(directions) do
        for i = 1, self.power do
            local tileX = self.x + dir.dx * i * tileSize
            local tileY = self.y + dir.dy * i * tileSize

            -- Look up a block at (tileX, tileY)
            local block = Game:getBlockAt(tileX, tileY)
            if block then
                -- If block exists, check destructibility
                if block.isDestructible then
                    block:destroyBlock()
                    break
                else
                    -- Indestructible block => stop fire spread
                    break
                end
            else
                -- No block => it's empty, so spawn a fireball and keep going
                spawnFireBall(tileX, tileY, i * propagationDelay)
            end
        end
    end
end

function Bomb:draw()
    love.graphics.draw(
        self.spriteSheet,
        self.animation[self.currentFrame],
        self.x,
        self.y,
        0,        -- rotation
        1, 1,     -- scaleX, scaleY
        BOMB_FRAME_WIDTH/2,   -- origin offset X
        BOMB_FRAME_HEIGHT/2   -- origin offset Y
    )
end

return Bomb
