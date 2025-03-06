-- player.lua
local Assets = require("assets")  -- global asset reference
local Audio = require("audio")
local Bomb = require("bomb")
local Shaders = require("shaders")

local Player = {}
Player.__index = Player

local spriteSheet = Assets.playerSpriteSheet
local SPRITE_WIDTH, SPRITE_HEIGHT = 32, 22
local ROW_FRAME_COUNT = 10
local GAP = 1

local COLLIDER_RADIUS = 7

local deathSound = Audio.sfxSources.die

-- Helper function to clear the current buff's effects
function Player:clearBuff(buffType)
    if buffType == "yingyang" then
        self.yingyang = false
    elseif buffType == "ghost" then
        self.ghost = false
    end
    -- Add additional cases if you introduce more buff types
    self.collider:setCollisionClass("Player")
end

function Player:applyItemEffect(item)
     -- Apply the effect immediately.
    if item.type == "bomb" then
        self.bombs = self.bombs + 1
    elseif item.type == "power" then
        self.power = self.power + 1
    elseif item.type == "superman" then
        self.superman = true
    elseif item.type == "ghost" then
        self.ghost = true
    elseif item.type == "yingyang" then
        self.yingyang = true
    elseif item.type == "speed" then
        self.speed = self.speed + 20  -- Or adjust accordingly.
    elseif item.type == "fastIgnition" then
        self.fastIgnition = true
    elseif item.type == "stopped" then
        self.stopped = true
    elseif item.type == "money" then
        self.money = self.money + 1  -- Change value as needed.
    elseif item.type == "remote" then
        self.remote = true
    elseif item.type == "death" then
        self:die()  -- Call your death method.
    end
end

function Player:dropBomb()
    if not Game.bombs then Game.bombs = {} end

    -- Count how many bombs belong to this player
    local bombCount = 0
    for _, bomb in ipairs(Game.bombs) do
        if bomb.owner == self then
            bombCount = bombCount + 1
        end
    end

    -- Check if the player can drop more bombs
    if bombCount < self.bombs then
        if self.remote then
            print("Remote bomb activated: use cursor keys to move the bomb.")
            -- Implement remote bomb logic if needed
        else
            local bomb = Bomb:new(self)
            table.insert(Game.bombs, bomb)
            --LOGGER:debug("Bomb dropped at (" .. bomb.x .. ", " .. bomb.y .. ")")
        end
    else
        print("You have reached your bomb limit!")
    end
end

function Player:setAnimation(animName)
    if self.animations[animName] then
        self.currentAnimation = self.animations[animName]
        self.currentFrame = 1
        self.animationTimer = 0
        print("Animation set to " .. animName)
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
                                             SPRITE_WIDTH, SPRITE_HEIGHT, GAP, spriteSheet),
        ghost = Assets.generateAnimation(25,30, self.baseYOffset, ROW_FRAME_COUNT,
                                             SPRITE_WIDTH, SPRITE_HEIGHT, GAP, spriteSheet)
    }

    -- Default animation
    self.currentAnimation = self.animations.moveDown
    self.currentFrame = 1
    self.frameDuration = 0.1
    self.animationTimer = 0

    self.x = 100
    self.y = 100

    -- Power-ups & flags
    self.bombs = 1 -- the amount of bombs a player can drop
    self.power = 0 -- the additional blast distance of fireballs
    self.superman = false -- can push single blocks and bombs
    self.yingyang = false  -- protected against fireballs, sprite becomes solid white for limited time
    self.ghost = false  -- walk through walls, spirte becomes translucent, time limit
    self.ghost = false  -- ghost and can walk through walls, special sprite animation
    self.speed = 30 -- the speed the player moves at
    self.fastIgnition = false -- changes so that the user only drops a single bomb, which is ignited upon releasing the spacebar
    self.stopped = false -- temporarily causes the players movement to halt
    self.money = 0 -- how much money (coins)  they have. this carries over matches.
    self.remote = false -- allows the user to move bombs with the cursors, so when space is pressed movement is transffered to the bomb, player is stopped

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
    --self.collider:setUserData(self)

    -- Death / removal flags
    self.isDead = false
    self.toRemove = false

    return self
end

-- Helper method to check for an active buff
function Player:isBuffActive(buffName)
    return self.currentBuff == buffName and self.buffTimer and self.buffTimer > 0
end

-- Private helper functions:
local function updateBuff(self, dt)
    if self.buffTimer then
        self.buffTimer = self.buffTimer - dt
        if self.buffTimer <= 0 then
            self:clearBuff(self.currentBuff)
        end
    end
end

local function updateDeath(self, dt)
    self.animationTimer = self.animationTimer + dt
    if self.animationTimer >= self.frameDuration then
        self.animationTimer = self.animationTimer - self.frameDuration
        self.currentFrame = self.currentFrame + 1
        if self.currentFrame > #self.animations.die then
            self.toRemove = true
        end
    end
end

local function updateMovement(self, dt)
    local vx, vy = 0, 0
    self.moving = false

    if love.keyboard.isDown("up") then
        vy = vy - self.speed
        self.currentAnimation = self.animations.moveUp
        self.moving = true
    elseif love.keyboard.isDown("down") then
        vy = vy + self.speed
        self.currentAnimation = self.animations.moveDown
        self.moving = true
    end

    if love.keyboard.isDown("left") then
        vx = vx - self.speed
        self.currentAnimation = self.animations.moveLeft
        self.moving = true
    elseif love.keyboard.isDown("right") then
        vx = vx + self.speed
        self.currentAnimation = self.animations.moveRight
        self.moving = true
    end

    self.collider:setLinearVelocity(vx, vy)
    local cx, cy = self.collider:getPosition()
    self.x = cx
    self.y = cy + COLLIDER_RADIUS
end

local function updateAnimation(self, dt)
    if self.moving then
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

function Player:keypressed(key)
    if key == "space" then
        self:dropBomb()
    end
end

-- Public method: update
function Player:update(dt)
    if self.toRemove then return end

        -- Check collision with a Fireball if collider still exists
    if self.collider and self.collider:enter("Fireball") then
        self:die()  -- Switch to death logic
    end

    updateBuff(self, dt)

    if self.isDead then
        updateDeath(self, dt)
        return
    end

    if self.stopped then return end

    updateMovement(self, dt)
    updateAnimation(self, dt)
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

    if self.yingyang then
        love.graphics.setShader(Shaders.whiteShader)
    end

    love.graphics.draw(self.spriteSheet, quad, drawX, drawY)

    if self.yingyang then
        love.graphics.setShader()  -- Reset shader to default
    end
end

return Player
