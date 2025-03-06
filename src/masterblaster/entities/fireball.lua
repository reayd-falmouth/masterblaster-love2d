local Assets = require("core.assets")
local Fireball = {}
Fireball.__index = Fireball

local tileSize = 2  -- Adjust if defined elsewhere

local spriteSheet = Assets.objectSpriteSheet
local fireBallAnimation = Assets.generateAnimation(1, 6, 0, 20, 16, 16, 0, spriteSheet)
local FRAME_DURATION = 0.05

function Fireball:new(x, y, delay)
    local self = setmetatable({}, Fireball)

    self.x = x
    self.y = y
    self.delay = delay or 0
    self.animation = fireBallAnimation
    self.currentFrame = 1
    self.frameDuration = FRAME_DURATION
    self.animationTimer = 0

    -- The total time the fireball remains active
    self.timer = self.frameDuration * #fireBallAnimation

    -- Create a collider for collision detection
    --self.collider = Game.world:newRectangleCollider(x, y, tileSize, tileSize)
    self.collider = Game.world:newCircleCollider(
        self.x,
        self.y,
        (tileSize / 2)
    )
    self.collider:setSensor(false)
    self.collider:setCollisionClass("Fireball")
    self.collider:setObject(self)  -- so getUserData() returns the Fireball

    return self
end

function Fireball:update(dt)
    -- Delay logic: don't animate or collide yet
    if self.delay > 0 then
        self.delay = self.delay - dt
        return
    end

    -- 2) Animate the fireball
    self.timer = self.timer - dt
    self.animationTimer = self.animationTimer + dt
    if self.animationTimer >= self.frameDuration then
        self.animationTimer = self.animationTimer - self.frameDuration
        self.currentFrame = (self.currentFrame % #self.animation) + 1
    end

    -- 3) Expire after its total timer
    if self.timer <= 0 and self.collider then
        self.collider:destroy()
        self.collider = nil
    end
end

function Fireball:draw()
    -- Don’t draw until the delay is up
    if self.delay > 0 then
        return
    end
    love.graphics.draw(
        spriteSheet,
        self.animation[self.currentFrame],
        self.x,
        self.y,
        0,   -- rotation
        1, 1,
        8, 8 -- offset so (x,y) is sprite center
    )
end

function Fireball:destroy()
    -- Destroy collider if still present
    if self.collider then
        self.collider:destroy()
        self.collider = nil
    end
    -- Mark for removal so your main update loop can remove it
    self.toRemove = true
end

return Fireball
