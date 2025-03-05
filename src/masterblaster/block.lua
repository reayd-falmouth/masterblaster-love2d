-- block.lua
local Assets = require("assets")
local Item = require("item")  -- Require the new items module
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

local FRAME_DURATION = 0.05

function Block:new(row, col, tileSize, tileID, isDestructible)
    local self = setmetatable({}, Block)

    -- Basic tile data
    self.row = row
    self.col = col
    self.tileSize = tileSize
    self.tileID = tileID
    self.isDestructible = isDestructible

    self.destructionAnimation = destructionAnimation
    self.frameDuration = FRAME_DURATION
    self.currentFrame = 1
    self.animationTimer = 0
    self.destroying = false
    self.toRemove = false

    -- Calculate actual (x,y) based on row/col and store as instance variables.
    self.x = (col - 1) * tileSize
    self.y = (row - 1) * tileSize

    -- Create Box2D collider using stored x and y
    self.collider = Game.world:newRectangleCollider(self.x, self.y, tileSize, tileSize)
    self.collider:setCollisionClass("Block")
    self.collider:setType("static")
    self.collider:setSensor(false)
    self.collider:setObject(self)
    --self.collider:setUserData(self)

    return self
end

function Block:update(dt)
    -- Play destruction animation if active
    if self.destroying then
        self.animationTimer = self.animationTimer + dt
        if self.animationTimer >= self.frameDuration then
            self.animationTimer = self.animationTimer - self.frameDuration
            self.currentFrame = self.currentFrame + 1

            -- Once the last frame is reached, mark this block for removal
            if self.currentFrame > #self.destructionAnimation then
                self.toRemove = true

                -- Remove from blockMap
                if Game.blockMap[self.row] and Game.blockMap[self.row][self.col] == self then
                    Game.blockMap[self.row][self.col] = nil
                end
            end
        end
    end
end

function Block:draw(tileQuads)
    if self.toRemove then return end

    -- Use stored coordinates for drawing
    local x = self.x
    local y = self.y

    if self.destroying then
        local frameQuad = self.destructionAnimation[self.currentFrame]
        if frameQuad then
            love.graphics.draw(spriteSheet, frameQuad, x, y)
        end
    else
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

        -- Spawn an item at this block's location using the new module.
        local newItem = Item:spawn(self.x, self.y)
        if newItem then
            print("New item spawned: ", newItem.type)
            table.insert(Game.items, newItem)
        end

        -- Remove collider so the block no longer obstructs movement
        if self.collider then
            self.collider:destroy()
            self.collider = nil
        end

        -- Clear the tile from the map data
        if Game.map.tileMap[self.row] then
            Game.map.tileMap[self.row][self.col] = Game.map.tileIDs.EMPTY
        end
    end
end

return Block
