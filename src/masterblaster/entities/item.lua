-- item.lua
local Assets = require("core.assets")
local Audio = require("system.audio")
local Item = {}
Item.__index = Item

local TILE_SIZE = 16
local COLLIDER_RADIUS = 7.5

-- Removed local ITEM_DEFINITIONS; using Assets.ITEM_DEFINITIONS instead.

-- Load sounds from Audio.
local pickupSound = Audio.sfxSources.bingo22
local ooLaLaSound = Audio.sfxSources.bingo
local bubbleSound = Audio.sfxSources.bubble
local cashSound = Audio.sfxSources.cash
local goSound = Audio.sfxSources.go
local warpSound = Audio.sfxSources.warp

-- Helper function: plays an item-based sound based on the item key.
local function playItemSound(key)
    if key == "coin" then
        cashSound:play()
    elseif key == "speedUp" then
        goSound:play()
    elseif key == "bomb" or key == "powerUp" then
        pickupSound:play()
    elseif key == "superman" then
        bubbleSound:play()
    elseif key == "timebomb" then
        bubbleSound:play()
    elseif key == "controller" then
        bubbleSound:play()
    elseif key == "stopped" then
        bubbleSound:play()
    elseif key == "ghost" then
        warpSound:play()
    elseif key == "protection" then
        ooLaLaSound:play()
    end
end

-- Helper function: choose an item based on the defined weights from Assets.
local function chooseItem()
    local validItems = {}
    for _, item in ipairs(Assets.ITEM_DEFINITIONS) do
        if item.enabled then
            table.insert(validItems, item)
        end
    end

    local totalWeight = 0
    for _, item in ipairs(validItems) do
        totalWeight = totalWeight + item.weight
    end

    local rnd = math.random() * totalWeight
    for _, item in ipairs(validItems) do
        rnd = rnd - item.weight
        if rnd <= 0 then
            return item
        end
    end
    return validItems[#validItems] -- Fallback (should not occur)
end

-- Constructor for a new Item instance.
function Item:new(x, y, itemDef)
    if not Game.items then Game.items = {} end
    local self = setmetatable({}, Item)

    -- Calculate the center of the tile.
    self.center_x = x + TILE_SIZE / 2
    self.center_y = y + TILE_SIZE / 2

    self.x = x
    self.y = y
    self.key = itemDef.key  -- Store the item key from the centralized definitions.
    self.name = itemDef.name
    self.sprite = Assets.objectSpriteSheet
    self.quad = Assets.getCachedQuad(itemDef.key)
    self.duration = itemDef.duration
    self.isSensor = true
    self.width = TILE_SIZE
    self.height = TILE_SIZE
    self.toRemove = false

    -- Create a Box2D collider for this item.
    self.collider = Game.world:newCircleCollider(self.center_x, self.center_y, COLLIDER_RADIUS)
    self.collider:setCollisionClass("Item")
    self.collider:setType("static")
    self.collider:setSensor(false)
    self.collider:setObject(self)

    return self
end

-- Convenience spawn function.
function Item:spawn(x, y)
    local itemDef = chooseItem()

    if itemDef.key == "none" then
        return nil
    end

    local item = Item:new(x, y, itemDef)

    -- If the chosen item is "random", choose an underlying effect but keep the sprite/quad unchanged.
    if itemDef.key == "random" then
        local validEffects = {}
        for _, def in ipairs(Assets.ITEM_DEFINITIONS) do
            -- Exclude "random" and "none" so that we don't override with invalid effects.
            if def.enabled and def.key ~= "random" and def.key ~= "none" then
                table.insert(validEffects, def)
            end
        end
        if #validEffects > 0 then
            local underlying = validEffects[math.random(#validEffects)]
            -- Override the item's effect properties with the underlying random effect,
            -- but keep the sprite and quad (the "?" appearance) from the "random" definition.
            item.key = underlying.key
            item.name = underlying.name
            item.duration = underlying.duration
            -- If there are additional properties to copy (like cost, etc.), add them here.
        end
    end

    return item
end

-- Called when a Fireball or bomb destroys this block.
function Item:destroy()
    if self.collider then
        self.collider:destroy()
        self.collider = nil
    end
    self.toRemove = true
end

function Item:update(dt)
    if self.toRemove then return end

    if self.collider and self.collider:enter("Fireball") then
        self:destroy()
    end

    local collision_type = nil
    if self.collider and self.collider:enter("Player") then
        log.debug("Item: " .. self.key .. " and player collided")
        collision_type = "Player"
    end

    if collision_type then
        playItemSound(self.key)
        local collision_data = self.collider:getEnterCollisionData(collision_type)
        local player = collision_data.collider:getObject()
        player:applyItemEffect(self)
        self:destroy()
    end
end

function Item:draw()
    love.graphics.draw(self.sprite, self.quad, self.x, self.y)
end

return Item
