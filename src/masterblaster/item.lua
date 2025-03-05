-- item.lua
local Assets = require("assets")
local Audio = require("audio")
local Item = {}
Item.__index = Item

-- Adjust these constants as needed for your sprite dimensions.
local TILE_SIZE = 16

-- Define the items.
-- The sprites are located in assets/sprites/icons.png.
-- In your case the sprites begin at row 2 column 20 and continue
-- from row 3 columns 1 to 13. Adjust the row/col values if your indexing differs.
local ITEM_DEFINITIONS = {
  { name = "bomb",        row = 2, col = 20, weight = 10 },
  { name = "power",       row = 3, col = 1,  weight = 10 },
  { name = "superman",    row = 3, col = 2,  weight = 3 },
  { name = "yingyang",    row = 3, col = 4,  weight = 5 },
  { name = "phase",       row = 3, col = 5,  weight = 5 },
  { name = "ghost",       row = 3, col = 6,  weight = 4 },
  { name = "speed",       row = 3, col = 7,  weight = 10 },
  { name = "death",       row = 3, col = 8,  weight = 5 },
  { name = "special",     row = 3, col = 9, weight = 2 },
  { name = "fastIgnition",row = 3, col = 10,  weight = 3 },
  { name = "stopped",     row = 3, col = 11,  weight = 2 },
  { name = "money",       row = 3, col = 12,  weight = 9 },
  { name = "remote",      row = 3, col = 13, weight = 3 },
  -- This entry means that sometimes nothing is spawned.
  { name = "none", weight = 50 }
}

-- Load the sprite sheet.
local spriteSheet = Assets.objectSpriteSheet

-- Load the explosion sound.
local bubbleSound = Audio.sfxSources.bubble
local cashSound = Audio.sfxSources.cash
local goSound = Audio.sfxSources.go
local warpSound = Audio.sfxSources.warp

-- Precompute quads for items that have a sprite (skip "none").
local quads = {}
for _, item in ipairs(ITEM_DEFINITIONS) do
    if item.name ~= "none" then
        local x = (item.col - 1) * TILE_SIZE
        local y = (item.row - 1) * TILE_SIZE
        quads[item.name] = love.graphics.newQuad(x, y, TILE_SIZE, TILE_SIZE, spriteSheet:getDimensions())
    end
end

-- Helper function: plays an items based sound on the name.
local function playItemSound(name)
    if name == "money" then
        cashSound:play()
    elseif name == "speed" then
        goSound:play()
    elseif name == "bomb" or "power" or "superman" or "special" then
        bubbleSound:play()
    elseif name == "yingyang" or "phase" or "ghost" then
        warpSound:play()
    end
end

-- Helper function: choose an item based on the defined weights.
local function chooseItem()
    local totalWeight = 0
    for _, item in ipairs(ITEM_DEFINITIONS) do
        totalWeight = totalWeight + item.weight
    end
    local rnd = math.random() * totalWeight
    for _, item in ipairs(ITEM_DEFINITIONS) do
        rnd = rnd - item.weight
        if rnd <= 0 then
            return item
        end
    end
    return ITEM_DEFINITIONS[#ITEM_DEFINITIONS] -- Fallback (should not occur)
end

-- Constructor for a new Item instance.
function Item:new(x, y, name)
    if not Game.items then Game.items = {} end
    local self = setmetatable({}, Item)

    self.x = x
    self.y = y
    self.type = name
    self.sprite = spriteSheet
    self.quad = quads[name]
    self.isSensor = true
    self.width = TILE_SIZE
    self.height = TILE_SIZE
    self.toRemove = false
    -- Create a Box2D collider for this item.
    self.collider = Game.world:newRectangleCollider(self.x, self.y, TILE_SIZE, TILE_SIZE)
    self.collider:setCollisionClass("Item")
    self.collider:setType("static")
    self.collider:setSensor(false)
    self.collider:setObject(self)
    --self.collider:setUserData(self)

    return self
end

-- Convenience spawn function (for when you want to call Item.spawn(x, y))
function Item:spawn(x, y)
    local itemDef = chooseItem()

    if itemDef.name == "none" then
        return nil
    end

    return Item:new(x, y, itemDef.name)
end

-- Called when a Fireball or bomb destroys this block
function Item:destroy()
    -- Remove collider so the block no longer obstructs movement
    if self.collider then
        self.collider:destroy()
        self.collider = nil
    end
    self.toRemove = true
end


function Item:update(dt)
    if self.toRemove then return end

    -- Check collision with a Fireball if collider still exists
    if self.collider and self.collider:enter("Fireball") then
        self:destroy()  -- Switch to death logic
    end

    if self.collider and self.collider:enter("Player") then
        playItemSound(self.name)
        local collision_data = self.collider:getEnterCollisionData('Player')
        ---- gets the reference to the player object, the player object must have
        ---- used :setObject(self) to attach itself to the collider otherwise this wouldn't work
        local player = collision_data.collider:getObject()
        player:applyItemEffect(self)
        self:destroy()  -- Switch to death logic
    end
end

-- Function to draw an item.
function Item:draw()
    love.graphics.draw(self.sprite, self.quad, self.x, self.y)
end

return Item

