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

function Player:keypressed(key)
    if self.keyMap and key == self.keyMap.bomb then
        self:dropBomb()
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
        local bomb = nil
        if self.remote then
            log.debug("Remote bomb activated: use cursor keys to move the bomb.")
            -- Implement remote bomb logic if needed
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

function Player:new(playerIndex, keyMap)
    local self = setmetatable({}, Player)
    self.index = playerIndex or 1
    self.keyMap = keyMap
    self.stats = PlayerStats.players[self.index]

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
        ghost    = Assets.generateAnimation(25,30, self.baseYOffset, ROW_FRAME_COUNT,
                                             SPRITE_WIDTH, SPRITE_HEIGHT, GAP, spriteSheet)
    }

    -- Default animation
    self.currentAnimation = self.animations.moveDown
    self.currentFrame = 1
    self.frameDuration = 0.1
    self.animationTimer = 0
    self.colliderRadius = COLLIDER_RADIUS
    self.x = 100
    self.y = 100

    -- Power-ups & flags
    self.bombs = 1 + (self.stats.purchased["bomb"] or 0) -- the amount of bombs a player can drop
    self.power = 0 + (self.stats.purchased["powerUp"] or 0) -- the additional blast distance of fireballs
    self.superman = false -- can push single blocks and bombs
    self.protection = false  -- protected against fireballs, sprite becomes solid white for limited time
    self.protectionTimer = nil
    self.phase = false  -- walk through walls, spirte becomes translucent, time limit
    self.ghost = false  -- invisible and can walk through walls, special sprite animation
    self.speed = 35 -- the speed the player moves at
    self.timebomb = false -- changes so that the user only drops a single bomb, which is ignited upon releasing the spacebar
    self.stopped = false -- temporarily causes the players movement to halt
    self.money = 0 + (self.stats.money or 0) -- how much money (coins)  they have. this carries over matches.
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

    -- Death / removal flags
    self.isDead = false
    self.toRemove = false

    return self
end

function Player:update(dt)
    -- If we've already flagged for removal, skip updates entirely
    if self.toRemove then return end

    -- Update the protection timer and flicker if it’s running
    if self.protectionTimer then
        self.protectionTimer = self.protectionTimer - dt

        -- Increase the flicker accumulator by the elapsed time
        self.flickerAccum = (self.flickerAccum or 0) + dt

        -- Compute progress (0 at start, 1 when timer expires)
        local totalDuration = 3  -- seconds
        local progress = (totalDuration - self.protectionTimer) / totalDuration
        -- Linearly interpolate flicker period from fast (0.1 sec) to slow (0.5 sec)
        self.flickerPeriod = 0.1 + progress * (0.5 - 0.1)

        -- Toggle the flicker state if enough time has passed
        if self.flickerAccum >= self.flickerPeriod then
            self.flickerState = not self.flickerState
            self.flickerAccum = self.flickerAccum - self.flickerPeriod
        end

        -- Once the timer expires, remove protection
        if self.protectionTimer <= 0 then
            self.protection = false
            self.protectionTimer = nil
            self.flickerAccum = nil
            self.flickerState = nil
        end
    end

    -- Update the stopped timer if active.
    if self.stoppedTimer then
        self.stoppedTimer = self.stoppedTimer - dt
        if self.stoppedTimer <= 0 then
            self.stopped = false
            self.stoppedTimer = nil
        end
    end

    -- Update the stopped timer if active.
    if self.ghostTimer then
        self.ghostTimer = self.ghostTimer - dt
        if self.ghostTimer <= 0 then
            self.ghost = false
            self.ghostTimer = nil
            self.collider:setCollisionClass('Player')
            -- Optionally, reset to a default or re-run directional checks:
            if love.keyboard.isDown(self.keyMap.up) then
                self.currentAnimation = self.animations.moveUp
            elseif love.keyboard.isDown(self.keyMap.down) then
                self.currentAnimation = self.animations.moveDown
            elseif love.keyboard.isDown(self.keyMap.left) then
                self.currentAnimation = self.animations.moveLeft
            elseif love.keyboard.isDown(self.keyMap.right) then
                self.currentAnimation = self.animations.moveRight
            else
                self.currentAnimation = self.animations.moveDown  -- default if no input
            end
            self.currentFrame = 1
        end
    end

    -- Check collision with a Fireball if collider still exists
    if self.collider and self.collider:enter("Fireball") then
        if self.protection then
            -- Protection is already active.
            -- If the timer hasn’t started yet, activate it.
            if not self.protectionTimer then
                self:activateProtectionTimer()
            end
        else
            self:die()
        end
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

    -- Movement logic
    local vx, vy = 0, 0
    local moving = false

    if love.keyboard.isDown(self.keyMap.up) then
        vy = vy - self.speed
        self.currentAnimation = self.animations.moveUp
        moving = true
    elseif love.keyboard.isDown(self.keyMap.down) then
        vy = vy + self.speed
        self.currentAnimation = self.animations.moveDown
        moving = true
    end

    if love.keyboard.isDown(self.keyMap.left) then
        vx = vx - self.speed
        self.currentAnimation = self.animations.moveLeft
        moving = true
    elseif love.keyboard.isDown(self.keyMap.right) then
        vx = vx + self.speed
        self.currentAnimation = self.animations.moveRight
        moving = true
    end

    -- If the player is stopped, override any velocity to 0
    if self.stopped then
        vx, vy = 0, 0
    end

    -- Apply velocity
    self.collider:setLinearVelocity(vx, vy)

    -- Update logical (x, y) from collider’s position
    local cx, cy = self.collider:getPosition()
    self.x = cx
    self.y = cy + COLLIDER_RADIUS

    -- Advance animation if moving
    if self.remote and self.stopped then
        self.currentAnimation = self.animations.remote
    elseif self.ghost then
        self.currentAnimation = self.animations.ghost
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
