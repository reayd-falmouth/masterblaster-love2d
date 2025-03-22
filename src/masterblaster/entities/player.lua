-- player.lua
local Assets = require("core.assets")  -- global asset reference
local Audio = require("system.audio")
local Bomb = require("entities.bomb")
local Shaders = require("system.shaders")

local Player = {}
Player.__index = Player

local spriteSheet = Assets.playerSpriteSheet
local SPRITE_WIDTH, SPRITE_HEIGHT = 32, 22
local ROW_FRAME_COUNT = 10
local GAP = 1

local COLLIDER_RADIUS = 7

local deathSound = Audio.sfxSources.die

-- inside your player.lua or Player class definition
function Player:getGridPosition()
    local cx, cy = self.collider:getPosition()  -- Get the collider's center.
    local row = math.floor(cy / Game.map.tileSize) + 1
    local col = math.floor(cx / Game.map.tileSize) + 1
    log.debug("Player grid location (center): " .. row .. " " .. col)
    return row, col
end

-- Call this to start the 3-second countdown when hit during protection.
function Player:activateProtectionTimer()
    self.protectionTimer = 3
    self.flickerAccum = 0
    self.flickerState = false  -- Initial state (could be true if you prefer)
end

function Player:applyItemEffect(item)
    log.debug("Applying item " .. item.key .. " to player")

    if item.key == "bomb" then
        self.bombs = self.bombs + 1
    elseif item.key == "powerUp" then
        self.power = self.power + 2
    elseif item.key == "superman" then
        self.superman = true
    elseif item.key == "protection" then
        self.protection = true
        --log.debug("collision class set to PlayerInvincible")
        --self.collider:setCollisionClass('PlayerInvincible')
    elseif item.key == "ghost" then
        self.ghost = true
        self.ghostTimer = item.duration
        self.collider:setCollisionClass('PlayerGhost')
    elseif item.key == "speedUp" then
        self.speed = self.speed + 20  -- Or adjust accordingly.
    elseif item.key == "death" then
        self:die()  -- Call your death method.
    elseif item.key == "timebomb" then
        self.timebomb = true
        self.remote = false
    elseif item.key == "stopped" then
        self.stopped = true
        self.stoppedTimer = item.duration
    elseif item.key == "coin" then
        self.money = self.money + 1  -- Change value as needed.
        self.stats.money = self.stats.money + 1
    elseif item.key == "controller" then
        log.debug("Remote controller active")
        self.remote = true
        self.timebomb = true
    end
end


function Player:keyreleased(key)
    log.debug("Player:keyreleased received: " .. key)
    if self.keyMap and key == self.keyMap.bomb and self.timebomb then
        for _, bomb in ipairs(Game.bombs) do
            if bomb.owner == self and bomb.waiting then
                bomb.waiting = false
                log.debug("Bomb timer resumed")
            end
        end
    end
    if self.keyMap and key == self.keyMap.bomb and self.remote and self.stopped then
        self.stopped = false
    end
end

function Player:keypressed(key)
    if self.isDead then
        return
    end
    if self.keyMap and key == self.keyMap.bomb then
        self:dropBomb()
    end
end

function Player:dropBomb()
    -- Prevent dropping bombs if the player is dead or collider is missing
    if self.isDead or not self.collider then
        return
    end

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
        local bomb = nil
        if self.remote then
            log.debug("Remote bomb activated: use cursor keys to move the bomb.")
            bomb = Bomb:new(self, true)
            table.insert(Game.bombs, bomb)
            self.stopped = true
        else
            bomb = Bomb:new(self)
            table.insert(Game.bombs, bomb)
        end
        log.debug("Bomb dropped at (" .. bomb.x .. ", " .. bomb.y .. ")")
    else
        log.warning("You have reached your bomb limit!")
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

function Player:new(playerIndex, keyMap, assignedControllerGUID)
    local self = setmetatable({}, Player)
    self.index = playerIndex or 1
    self.keyMap = keyMap
    self.inputType = "gamepad"
    self.controllerIndex = assignedControllerGUID
    self.stats = PlayerStats.players[self.index]
    self.baseYOffset = (self.index - 1) * (3 * SPRITE_HEIGHT + 3)
    self.spriteSheet = spriteSheet
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
        ghost     = Assets.generateAnimation(25,30, self.baseYOffset, ROW_FRAME_COUNT,
                                             SPRITE_WIDTH, SPRITE_HEIGHT, GAP, spriteSheet)
    }
    self.currentAnimation = self.animations.moveDown
    self.currentFrame = 1
    self.frameDuration = 0.1
    self.animationTimer = 0
    self.colliderRadius = COLLIDER_RADIUS
    self.x = 100
    self.y = 100

    -- Set power-ups and flags
    self.bombs = 1 + (self.stats.purchased["bomb"] or 0)
    self.power = 0 + (self.stats.purchased["powerUp"] or 0)
    self.superman = false
    self.protection = false
    self.protectionTimer = nil
    self.phase = false
    self.ghost = false
    self.speed = 35
    self.timebomb = false
    self.stopped = false
    self.money = 0 + (self.stats.money or 0)
    self.remote = false

    -- Create physics collider
    self.collider = Game.world:newCircleCollider(
        self.x - (COLLIDER_RADIUS / 2),
        self.y - COLLIDER_RADIUS,
        COLLIDER_RADIUS
    )
    self.collider:setFixedRotation(true)
    self.collider:setObject(self)
    self.collider:setFriction(0)
    self.collider:setCollisionClass('Player')

    self.isDead = false
    self.toRemove = false

    return self
end

-- In player.lua, add this function to encapsulate input handling:
function Player:handleMovementInput()
    local up, down, left, right = false, false, false, false
    if self.inputType == "gamepad" then
        -- Look up the controller inputs for this player.
        local input = ControllerInputs and ControllerInputs[self.controllerIndex]
        if input then
            -- Use thresholds for analog stick values.
            up    = input.leftY < -0.2
            down  = input.leftY > 0.2
            left  = input.leftX < -0.2
            right = input.leftX > 0.2
        end
    else
        up    = love.keyboard.isDown(self.keyMap.up)
        down  = love.keyboard.isDown(self.keyMap.down)
        left  = love.keyboard.isDown(self.keyMap.left)
        right = love.keyboard.isDown(self.keyMap.right)
    end
    return up, down, left, right
end

function Player:handleControllerInput(input)
    -- Check for the action/bomb input and drop a bomb.
    if input.action then
        self:dropBomb()
    end
end

function Player:update(dt)
    if self.toRemove then return end

    -- Update protection timer and flicker.
    if self.protectionTimer then
        self.protectionTimer = self.protectionTimer - dt
        self.flickerAccum = (self.flickerAccum or 0) + dt
        local totalDuration = 3
        local progress = (totalDuration - self.protectionTimer) / totalDuration
        self.flickerPeriod = 0.1 + progress * (0.5 - 0.1)
        if self.flickerAccum >= self.flickerPeriod then
            self.flickerState = not self.flickerState
            self.flickerAccum = self.flickerAccum - self.flickerPeriod
        end
        if self.protectionTimer <= 0 then
            self.protection = false
            self.protectionTimer = nil
            self.flickerAccum = nil
            self.flickerState = nil
        end
    end

    -- Update stopped timer.
    if self.stoppedTimer then
        self.stoppedTimer = self.stoppedTimer - dt
        if self.stoppedTimer <= 0 then
            self.stopped = false
            self.stoppedTimer = nil
        end
    end

    -- Update ghost timer.
    if self.ghostTimer then
        self.ghostTimer = self.ghostTimer - dt
        if self.ghostTimer <= 0 then
            self.ghost = false
            self.ghostTimer = nil
            self.collider:setCollisionClass('Player')
            -- Use our unified input handler when ghost expires.
            local upPressed, downPressed, leftPressed, rightPressed = self:handleMovementInput()
            if upPressed then
                self.currentAnimation = self.animations.moveUp
            elseif downPressed then
                self.currentAnimation = self.animations.moveDown
            elseif leftPressed then
                self.currentAnimation = self.animations.moveLeft
            elseif rightPressed then
                self.currentAnimation = self.animations.moveRight
            else
                self.currentAnimation = self.animations.moveDown
            end
            self.currentFrame = 1
        end
    end

    -- Get movement inputs.
    local upPressed, downPressed, leftPressed, rightPressed = self:handleMovementInput()

    local vx, vy = 0, 0
    local moving = false

    if upPressed then
        vy = vy - self.speed
        moving = true
    elseif downPressed then
        vy = vy + self.speed
        moving = true
    end
    if leftPressed then
        vx = vx - self.speed
        moving = true
    elseif rightPressed then
        vx = vx + self.speed
        moving = true
    end

    if self.stopped then
        vx, vy = 0, 0
    end

    self.collider:setLinearVelocity(vx, vy)
    local cx, cy = self.collider:getPosition()
    self.x = cx
    self.y = cy + COLLIDER_RADIUS

    -- Determine appropriate animation.
    local newAnimation = nil
    if self.ghost then
        newAnimation = self.animations.ghost
    elseif self.remote and self.stopped then
        newAnimation = self.animations.remote
    elseif upPressed then
        newAnimation = self.animations.moveUp
    elseif downPressed then
        newAnimation = self.animations.moveDown
    elseif leftPressed then
        newAnimation = self.animations.moveLeft
    elseif rightPressed then
        newAnimation = self.animations.moveRight
    end

    if newAnimation and newAnimation ~= self.currentAnimation then
        self.currentAnimation = newAnimation
        self.currentFrame = 1
        self.animationTimer = 0
    end

    if moving or self.ghost then
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


function Player:draw(offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    -- If flagged for removal, skip drawing
    if self.toRemove then return end

    local drawX = offsetX + (self.x - SPRITE_WIDTH / 2)
    local drawY = offsetY + (self.y - SPRITE_HEIGHT)

    -- Draw the current frame
    local quad = self.currentAnimation[self.currentFrame]

    if self.protection then
        if self.protectionTimer then
            if self.flickerState then
                love.graphics.setShader(Shaders.whiteShader)
            end
        else
            love.graphics.setShader(Shaders.whiteShader)
        end
    end

    love.graphics.draw(self.spriteSheet, quad, drawX, drawY)

    if self.protection then
        love.graphics.setShader()  -- Reset shader to default
    end
end

return Player
