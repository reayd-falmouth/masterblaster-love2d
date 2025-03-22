local Assets = require("core.assets")
local Fireball = require("entities.fireball")
local Helpers = require("utils.helpers")
local Bomb = {}
Bomb.__index = Bomb

-- Bomb-specific constants.
local BOMB_FRAME_WIDTH    = 16
local BOMB_FRAME_HEIGHT   = 16
local BOMB_FRAMES_PER_ROW = 20  -- Adjust to match your objects sprite sheet layout.
local BOMB_GAP            = 0
local COLLIDER_RADIUS = 7.5

-- Use the objects sprite sheet for bomb animations.
local spriteSheet = Assets.objectSpriteSheet

local FRAME_DURATION = 0.1  -- Seconds per frame.
local MOVING_DURATION = 0.2

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

function Bomb:new(player, remoteControlled)
    local self = setmetatable({}, Bomb)

    -- Snap bomb to the center of the grid block.
    local row, col = player:getGridPosition()
    local gridX = (col - 1) * Game.map.tileSize + Game.map.tileSize / 2
    local gridY = (row - 1) * Game.map.tileSize + Game.map.tileSize / 2


    -- Default bomb power (if player.power is nil, default to 2)
    self.x = gridX
    self.y = gridY
    self.power = player.power + 2
    self.timer = 3              -- Countdown until explosion.
    self.state = "idle"         -- "idle", "moving", "exploding"
    self.owner = player
    self.speed = 40
    self.spriteSheet = spriteSheet

    -- Animations table
    self.animations = {
        idleAnimation = Assets.generateAnimation(15, 17, BOMB_FRAME_HEIGHT, BOMB_FRAMES_PER_ROW, BOMB_FRAME_WIDTH, BOMB_FRAME_HEIGHT, BOMB_GAP, spriteSheet),
        moveDown = Assets.generateAnimation(35, 38, BOMB_FRAME_HEIGHT, BOMB_FRAMES_PER_ROW, BOMB_FRAME_WIDTH, BOMB_FRAME_HEIGHT, BOMB_GAP, spriteSheet),
        moveUp = Helpers.reverseTable(Assets.generateAnimation(35, 38, BOMB_FRAME_HEIGHT, BOMB_FRAMES_PER_ROW, BOMB_FRAME_WIDTH, BOMB_FRAME_HEIGHT, BOMB_GAP, spriteSheet)),
        moveLeft = Helpers.reverseTable(Assets.generateAnimation(6, 9, BOMB_FRAME_HEIGHT, BOMB_FRAMES_PER_ROW, BOMB_FRAME_WIDTH, BOMB_FRAME_HEIGHT, BOMB_GAP, spriteSheet)),
        moveRight = Assets.generateAnimation(6, 9, BOMB_FRAME_HEIGHT, BOMB_FRAMES_PER_ROW, BOMB_FRAME_WIDTH, BOMB_FRAME_HEIGHT, BOMB_GAP, spriteSheet)
    }

    self.currentAnimation = self.animations.idleAnimation
    self.currentFrame = 1
    self.frameDuration = FRAME_DURATION
    self.animationTimer = 0
    self.activationDelay = 1    -- Time in seconds before bomb collision becomes active.
    self.toRemove = false
    self.remoteControlled = remoteControlled or false
    self.remoteControlledSound = Audio.sfxSources.effect

    -- Create the collider as a circle centered on the bomb.
    self.collider = Game.world:newCircleCollider(gridX, gridY, COLLIDER_RADIUS)
    self.collider:setSensor(false)  -- Disable collision initially.

    if not self.remoteControlled then
        LOG.info("Not remote controlled setting static collision")
        self.collider:setType("static")
    else
        LOG.info("Remote controlled friction set to 0")
        self.collider:setFriction(0)
    end
    self.collider:setCollisionClass("BombInactive")
    self.collider:setObject(self)


    -- Set waiting flag if player is in timebomb mode.
    if player.timebomb then
        self.waiting = true
        self.timer = 0
        LOG.info("Timebomb mode active: bomb waiting for key release")
    else
        self.waiting = false
    end

    return self
end


function Bomb:update(dt)
    -- If we've already flagged for removal, skip updates entirely
    if self.toRemove then return end

    -- Check collision with a Fireball if collider still exists
    if self.collider and self.collider:enter("Fireball") then
        self:explode()  -- Switch to death logic
        self.toRemove = true -- remove the bomb before animation completed
    end

    -- Only count down the timer if not waiting for space release.
    if not self.waiting then
        LOG.debug("Bomb counting down")
        self.timer = self.timer - dt
    end

    self.animationTimer = self.animationTimer + dt
    if self.animationTimer >= self.frameDuration then
        self.animationTimer = self.animationTimer - self.frameDuration
        self.currentFrame = (self.currentFrame % #self.currentAnimation) + 1
    end

    -- Handle collision class switching only if collider exists.
    if self.collider then
        local dx = self.x - self.owner.x
        local dy = self.y - self.owner.y
        local separation = math.sqrt(dx * dx + dy * dy)
        local safeDistance = self.owner.colliderRadius + COLLIDER_RADIUS + 2  -- add a small buffer

        if separation > safeDistance then
            self.collider:setCollisionClass("Bomb")
        else
            self.collider:setCollisionClass("BombInactive")
        end
    end

    if self.timer <= 0 and self.state ~= "exploding" and not self.waiting then
        self:explode()
    end

    if self.remoteControlled and self.state ~= "exploding" then
        LOG.debug("Moving remote controlled bomb...")
        local vx, vy = 0, 0
        local moving = false

        if love.keyboard.isDown(self.owner.keyMap.up) then
            if self.currentAnimation ~= self.animations.moveUp then
                self.currentAnimation = self.animations.moveUp
                self.currentFrame = 1
                self.animationTimer = 0
            end
            vy = vy - self.speed
            moving = true
            self.remoteControlledSound:play()
        elseif love.keyboard.isDown(self.owner.keyMap.down) then
            if self.currentAnimation ~= self.animations.moveDown then
                self.currentAnimation = self.animations.moveDown
                self.currentFrame = 1
                self.animationTimer = 0
            end
            vy = vy + self.speed
            moving = true
            self.remoteControlledSound:play()
        elseif love.keyboard.isDown(self.owner.keyMap.left) then
            if self.currentAnimation ~= self.animations.moveLeft then
                self.currentAnimation = self.animations.moveLeft
                self.currentFrame = 1
                self.animationTimer = 0
            end
            vx = vx - self.speed
            moving = true
            self.remoteControlledSound:play()
        elseif love.keyboard.isDown(self.owner.keyMap.right) then
            if self.currentAnimation ~= self.animations.moveRight then
                self.currentAnimation = self.animations.moveRight
                self.currentFrame = 1
                self.animationTimer = 0
            end
            vx = vx + self.speed
            moving = true
            self.remoteControlledSound:play()
        else
            if self.currentAnimation ~= self.animations.idleAnimation then
                self.currentAnimation = self.animations.idleAnimation
                self.currentFrame = 1
                self.animationTimer = 0
            end
        end

        -- Apply velocity to the collider if it exists.
        if self.collider then
            self.collider:setLinearVelocity(vx, vy)

            -- Update logical (x, y) from collider’s position.
            local cx, cy = self.collider:getPosition()
            self.x = cx
            self.y = cy
        end
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
            local block = Game.map:getBlockAt(tileX, tileY)
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
        self.currentAnimation[self.currentFrame],
        self.x,
        self.y,
        0,        -- rotation
        1, 1,     -- scaleX, scaleY
        BOMB_FRAME_WIDTH/2,   -- origin offset X
        BOMB_FRAME_HEIGHT/2   -- origin offset Y
    )
end

return Bomb

