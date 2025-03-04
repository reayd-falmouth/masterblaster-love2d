-- player.lua
local Assets = require("assets")  -- global asset reference
local Player = {}
Player.__index = Player

local spriteSheet = Assets.playerSpriteSheet
local SPRITE_WIDTH, SPRITE_HEIGHT = 32, 22
local ROW_FRAME_COUNT = 10
local GAP = 1

local COLLIDER_RADIUS = 7

local deathSound = love.audio.newSource("assets/sounds/die.ogg", "static")

function Player:new(playerIndex)
    local self = setmetatable({}, Player)
    self.index = playerIndex or 1

    -- Calculate vertical offset for this player's row in the sheet.
    self.baseYOffset = (self.index - 1) * (3 * SPRITE_HEIGHT + 3)
    self.spriteSheet = spriteSheet

    -- Animations table
    self.animations = {
        moveDown  = Assets.generateAnimation(1, 3,  self.baseYOffset, ROW_FRAME_COUNT,
                                             SPRITE_WIDTH, SPRITE_HEIGHT, GAP, spriteSheet),
        moveRight = Assets.generateAnimation(4, 6,  self.baseYOffset, ROW_FRAME_COUNT,
                                             SPRITE_WIDTH, SPRITE_HEIGHT, GAP, spriteSheet),
        moveLeft  = Assets.generateAnimation(7, 9,  self.baseYOffset, ROW_FRAME_COUNT,
                                             SPRITE_WIDTH, SPRITE_HEIGHT, GAP, spriteSheet),
        moveUp    = Assets.generateAnimation(10,12, self.baseYOffset, ROW_FRAME_COUNT,
                                             SPRITE_WIDTH, SPRITE_HEIGHT, GAP, spriteSheet),
        die       = Assets.generateAnimation(13,21, self.baseYOffset, ROW_FRAME_COUNT,
                                             SPRITE_WIDTH, SPRITE_HEIGHT, GAP, spriteSheet),
        remote    = Assets.generateAnimation(22,24, self.baseYOffset, ROW_FRAME_COUNT,
                                             SPRITE_WIDTH, SPRITE_HEIGHT, GAP, spriteSheet)
    }

    -- Default animation
    self.currentAnimation = self.animations.moveDown
    self.currentFrame = 1
    self.frameDuration = 0.1
    self.animationTimer = 0

    self.x = 100
    self.y = 100
    self.speed = 50

    -- Power-ups & flags
    self.power = 0
    self.superman = false
    self.yingyang = false
    self.ghost = false
    self.numberOfBombs = 1
    self.timedBombs = false
    self.stopped = false
    self.remote = false

    -- Physics collider
    self.collider = Game.world:newCircleCollider(
        self.x - (COLLIDER_RADIUS / 2),
        self.y - COLLIDER_RADIUS,
        COLLIDER_RADIUS
    )
    self.collider:setFixedRotation(true)
    self.collider:setObject(self)
    self.collider:setFriction(0)
    self.collider:setCollisionClass('Player')

    -- Death / removal flags
    self.isDead = false
    self.toRemove = false

    return self
end

function Player:update(dt)
    -- If we've already flagged for removal, skip updates entirely
    if self.toRemove then return end

    -- Check collision with a Fireball if collider still exists
    if self.collider and self.collider:enter("Fireball") then
        self:die()  -- Switch to death logic
    end

    -- If the player is dead, just run the death animation
    if self.isDead then
        self.animationTimer = self.animationTimer + dt
        if self.animationTimer >= self.frameDuration then
            self.animationTimer = self.animationTimer - self.frameDuration
            self.currentFrame = self.currentFrame + 1

            -- If the death animation finishes, mark the player for removal
            if self.currentFrame > #self.animations.die then
                self.toRemove = true
            end
        end
        return
    end

    -- If the player is "stopped" for other reasons, skip movement
    if self.stopped then return end

    -- Only do movement if collider exists
    if self.collider then
        local vx, vy = 0, 0
        local moving = false

        if love.keyboard.isDown("up") then
            vy = vy - self.speed
            self.currentAnimation = self.animations.moveUp
            moving = true
        elseif love.keyboard.isDown("down") then
            vy = vy + self.speed
            self.currentAnimation = self.animations.moveDown
            moving = true
        end

        if love.keyboard.isDown("left") then
            vx = vx - self.speed
            self.currentAnimation = self.animations.moveLeft
            moving = true
        elseif love.keyboard.isDown("right") then
            vx = vx + self.speed
            self.currentAnimation = self.animations.moveRight
            moving = true
        end

        -- Apply velocity
        self.collider:setLinearVelocity(vx, vy)

        -- Update logical (x, y) from collider’s position
        local cx, cy = self.collider:getPosition()
        self.x = cx
        self.y = cy + COLLIDER_RADIUS

        -- Advance animation if moving
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
end

function Player:draw(offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    -- If flagged for removal, skip drawing
    if self.toRemove then return end

    local drawX = offsetX + (self.x - SPRITE_WIDTH / 2)
    local drawY = offsetY + (self.y - SPRITE_HEIGHT)

    -- Draw the current frame
    local quad = self.currentAnimation[self.currentFrame]
    love.graphics.draw(self.spriteSheet, quad, drawX, drawY)
end

function Player:keypressed(key)
    if key == "space" then
        self:dropBomb()
    end
end

function Player:dropBomb()
    if self.remote then
        print("Remote bomb activated: use cursor keys to move the bomb.")
        -- Implement remote bomb logic if needed
    else
        local Bomb = require("bomb")
        local bomb = Bomb:new(self)
        if not Game.bombs then Game.bombs = {} end
        table.insert(Game.bombs, bomb)
        print("Bomb dropped at (" .. bomb.x .. ", " .. bomb.y .. ")")
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

-- Called once when the player dies
function Player:die()
    -- Prevent re-running if already dead
    if self.isDead then return end

    self.isDead = true
    self.stopped = true
    deathSound:play()

    -- Switch to the "die" animation frames
    self.currentAnimation = self.animations.die
    self.currentFrame = 1
    self.animationTimer = 0

    -- Destroy the collider so the dead player won't collide anymore
    if self.collider then
        self.collider:destroy()
        self.collider = nil
    end
end

return Player
