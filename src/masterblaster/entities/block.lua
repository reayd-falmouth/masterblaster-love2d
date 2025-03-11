-- block.lua
local Assets = require("core.assets")
local Item = require("entities.item")  -- Require the new items module
local Block = {}
Block.__index = Block

local spriteSheet = Assets.objectSpriteSheet

-- Destruction animation for the block
local destructionAnimation = Assets.generateAnimation(
    10, 14,  -- start and end frame indices in the spritesheet
    16, 20,  -- source X, Y offset within sheet
    16, 16, -- width, height of each frame
    0,      -- spacing between frames (if any)
    spriteSheet
)

local createAnimation = Assets.generateAnimation(
    1, 5,  -- start and end frame indices in the spritesheet
    16, 20,  -- source X, Y offset within sheet
    16, 16, -- width, height of each frame
    0,      -- spacing between frames (if any)
    spriteSheet
)

local FRAME_DURATION = 0.05


function Block:new(row, col, tileSize, tileID, isDestructible, isShrinking)
    local self = setmetatable({}, Block)

    -- Basic tile data
    self.row = row
    self.col = col
    self.tileSize = tileSize
    self.tileID = tileID
    self.isDestructible = isDestructible
    self.isShrinking = isShrinking or false

    self.destructionAnimation = destructionAnimation
    self.frameDuration = FRAME_DURATION
    self.currentFrame = 1
    self.animationTimer = 0
    self.destroying = false
    self.toRemove = false

    -- If the block is created during shrinking, use createAnimation
    if self.isShrinking then
        self.createAnimation = createAnimation
        self.currentFrame = 1
        self.animationTimer = 0
    end

    -- Calculate actual (x,y) based on row/col and store as instance variables.
    self.x = (col - 1) * tileSize
    self.y = (row - 1) * tileSize

    -- Create Box2D collider using stored x and y
    self.collider = Game.world:newRectangleCollider(self.x, self.y, tileSize, tileSize)

    if self.isDestructible then
        self.collider:setCollisionClass("Block")
    else
        self.collider:setCollisionClass("Wall")
    end

    self.collider:setType("static")
    self.collider:setSensor(false)
    self.collider:setObject(self)

    return self
end

function Block:update(dt)
    if self.destroying then
        self.animationTimer = self.animationTimer + dt
        if self.animationTimer >= self.frameDuration then
            self.animationTimer = self.animationTimer - self.frameDuration
            self.currentFrame = self.currentFrame + 1

            if self.currentFrame > #self.destructionAnimation then
                self.toRemove = true
                -- Remove from the map (make sure to only clear the block property)
                if Game.map.tileMap[self.row] then
                    Game.map.tileMap[self.row][self.col].block = nil
                end
            end
        end
    elseif self.isShrinking then
        self.animationTimer = self.animationTimer + dt
        if self.animationTimer >= self.frameDuration then
            self.animationTimer = self.animationTimer - self.frameDuration
            if self.currentFrame < #self.createAnimation then
                self.currentFrame = self.currentFrame + 1
            else
                self.isShrinking = false
                self.tileID = Game.map.tileIDs.WALL  -- or Game.map.tileIDs.WALL if that’s how you reference it
            end
        end
    end

end

function Block:draw(tileQuads)
    if self.toRemove then return end

    local x = self.x
    local y = self.y

    if self.destroying then
        local frameQuad = self.destructionAnimation[self.currentFrame]
        if frameQuad then
            love.graphics.draw(spriteSheet, frameQuad, x, y)
        end
    elseif self.isShrinking then
        -- Draw the createAnimation if the block was created by shrinking
        local frameQuad = self.createAnimation[self.currentFrame]
        if frameQuad then
            love.graphics.draw(spriteSheet, frameQuad, x, y)
        end
    else
        local quad = Game.map.tileQuads[self.tileID]
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

        -- Spawn an item at this block's location using the new module.
        local newItem = Item:spawn(self.x, self.y)
        if newItem then
            LOG.debug("New item " .. newItem.key .. " spawned at " .. self.x .. ", " .. self.y)
            -- Instead of adding to a global list, find the cell for this block and assign the item.
            if Game.map.tileMap[self.row] and Game.map.tileMap[self.row][self.col] then
                Game.map.tileMap[self.row][self.col].item = newItem
            end
        end

        -- Remove collider so the block no longer obstructs movement
        if self.collider then
            self.collider:destroy()
            self.collider = nil
        end

        -- Clear the tile from the map data
        if Game.map.tileMap[self.row] then
            Game.map.tileMap[self.row][self.col].block = nil
        end
    end
end

return Block
