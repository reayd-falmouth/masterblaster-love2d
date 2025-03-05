-- block.lua
local Assets = require("assets")
local Block = {}
Block.__index = Block

local spriteSheet = Assets.objectSpriteSheet

-- This is the set of quads for the destruction animation;
-- You could also call it "blockAnimation" if it's the same.
local destructionAnimation = Assets.generateAnimation(
    10, 14,  -- start and end frame indices in the spritesheet
    16, 20,  -- source X, Y offset within sheet
    16, 16, -- width, height of each frame
    0,      -- spacing between frames (if any)
    spriteSheet
)

local FRAME_DURATION = 0.05

function Block:new(row, col, tileSize, tileID, isDestructible)
    local self = setmetatable({}, Block)

    -- Basic tile data
    self.row = row
    self.col = col
    self.tileSize = tileSize
    self.tileID = tileID
    self.isDestructible = isDestructible

    -- Item setup
    self.item = Assets.getRandomItem()
    self.destructionAnimation = destructionAnimation
    self.frameDuration = FRAME_DURATION
    self.currentFrame = 1
    self.animationTimer = 0
    self.destroying = false
    self.toRemove = false

    -- Calculate actual (x,y) based on row/col
    local x = (col - 1) * tileSize
    local y = (row - 1) * tileSize

    -- Create Box2D collider
    self.collider = Game.world:newRectangleCollider(x, y, tileSize, tileSize)
    self.collider:setCollisionClass("Block")
    self.collider:setType("static")
    self.collider:setSensor(false)
    self.collider:setObject(self)

    return self
end

function Block:update(dt)
    -- If we are currently playing a destruction animation
    if self.destroying then
        self.animationTimer = self.animationTimer + dt
        if self.animationTimer >= self.frameDuration then
            self.animationTimer = self.animationTimer - self.frameDuration
            self.currentFrame = self.currentFrame + 1

            -- Once the last frame is reached, mark this block for removal
            if self.currentFrame > #self.destructionAnimation then
                self.toRemove = true

                -- Now remove from blockMap
                if Game.blockMap[self.row] and Game.blockMap[self.row][self.col] == self then
                    Game.blockMap[self.row][self.col] = nil
                end
            end
        end
    end
end

function Block:draw(tileQuads)
    -- If flagged to remove, don’t draw at all
    if self.toRemove then return end

    local x = (self.col - 1) * self.tileSize
    local y = (self.row - 1) * self.tileSize

    -- If we’re in the midst of a destruction animation:
    if self.destroying then
        local frameQuad = self.destructionAnimation[self.currentFrame]
        if frameQuad then
            love.graphics.draw(spriteSheet, frameQuad, x, y)
        end
    else
        -- Otherwise, just draw the regular tile
        local quad = tileQuads[self.tileID]
        if quad then
            love.graphics.draw(spriteSheet, quad, x, y)
        end
    end
end

-- Called when a Fireball or bomb destroys this block
function Block:destroyBlock()
    if self.isDestructible then
        -- Flag the block to play the destruction animation
        self.destroying = true
        self.currentFrame = 1
        self.animationTimer = 0

        -- Remove collider so we no longer block anything
        if self.collider then
            self.collider:destroy()
            self.collider = nil
        end

        -- Clear the tile from the map data
        if Game.map.tileMap[self.row] then
            Game.map.tileMap[self.row][self.col] = Game.map.tileIDs.EMPTY
        end

        -- Don't remove from blockMap here, we let the animation finish first.
    end
end

return Block
