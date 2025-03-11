-- assets.lua (in the core directory)
local Assets = {}
Assets.__index = Assets

-- Constructor: Create an instance of Assets with injected loveGraphics and settings.
-- This makes it easier to stub out dependencies in tests.
function Assets.new(loveGraphics, settings)
    local self = setmetatable({}, Assets)
    settings = settings or {}
    local fastIgnition = (settings.fastIgnition ~= nil) and settings.fastIgnition or false
    local shop = (settings.shop ~= nil) and settings.shop or true

    self.loveGraphics = loveGraphics

    -- Load the object sprite sheet
    self.objectSpriteSheet = loveGraphics.newImage("assets/sprites/objects.png")
    self.objectSpriteSheet:setFilter("nearest", "nearest")
    self.TILE_SIZE = 16

    -- Item definitions (using settings for configurable items)
    self.ITEM_DEFINITIONS = {
      {
        enabled = true,
        key = "bomb",
        name = "BOMB",
        cost = 1,
        row = 2, col = 20,
        weight = 10,
        shopItem = true,
      },
      {
        enabled = true,
        key = "powerUp",
        name = "POWER-UP",
        cost = 1,
        row = 3, col = 1,
        weight = 10,
        shopItem = true
      },
      {
        enabled = false,
        key = "superman",
        name = "SUPERMAN",
        cost = 2,
        row = 3, col = 2,
        weight = 3,
        shopItem = true
      },
      {
        enabled = true,
        key = "protection",
        name = "PROTECTION",
        cost = 3,
        row = 3, col = 4,
        weight = 3,
        shopItem = true
      },
      {
        enabled = true,
        key = "ghost",
        name = "GHOST",
        cost = 3,
        row = 3, col = 5,
        weight = 70,
        duration = 10,
        shopItem = true
      },
      {
        enabled = true,
        key = "speedUp",
        name = "SPEED-UP",
        cost = 4,
        row = 3, col = 7,
        weight = 10,
        shopItem = true
      },
      {
        enabled = true,
        key = "death",
        name = "DEATH",
        cost = 0,  -- Not available in shop
        row = 3, col = 8,
        weight = 5,
        shopItem = false
      },
      {
        enabled = true,
        key = "random",
        name = "RANDOM",
        cost = 0,  -- Not available in shop
        row = 3, col = 9,
        weight = 5,
        shopItem = false
      },
      {
        enabled = fastIgnition,
        key = "timebomb",
        name = "TIMEBOMB",
        cost = 2,
        row = 3, col = 10,
        weight = 5,
        shopItem = true
      },
      {
        enabled = true,
        key = "stopped",
        name = "STOPPED",
        cost = 0,  -- Not available in shop
        row = 3, col = 11,
        weight = 3,
        duration = 10,
        shopItem = false
      },
      {
        enabled = shop,
        key = "coin",
        name = "COIN",
        cost = 1,
        row = 3, col = 12,
        weight = 10,
        shopItem = false
      },
      {
        enabled = true,
        key = "controller",
        name = "CONTROLLER",
        cost = 4,
        row = 3, col = 13,
        weight = 5,
        shopItem = true
      },
      {
        enabled = true,
        key = "none",
        name = "NONE",
        cost = 0,
        weight = 50,
        shopItem = false
      }
    }

    -- Convert item definitions to a mapping table (only items with row & col)
    self.itemMapping = {}
    for _, item in ipairs(self.ITEM_DEFINITIONS) do
        if item.row and item.col then
            self.itemMapping[item.key] = { row = item.row, col = item.col }
        end
    end

    -- Load the player sprite sheet
    self.playerSpriteSheet = loveGraphics.newImage("assets/sprites/player.png")
    self.playerSpriteSheet:setFilter("nearest", "nearest")
    self.SPRITE_WIDTH = 32
    self.SPRITE_HEIGHT = 22
    self.ROW_FRAME_COUNT = 10
    self.GAP = 1

    -- Cache for quads
    self.quadCache = {}

    return self
end

-- Get a quad for an asset by name.
function Assets:getQuad(name)
    local mapping = self.itemMapping[name]
    if not mapping then return nil end
    local x = (mapping.col - 1) * self.TILE_SIZE
    local y = (mapping.row - 1) * self.TILE_SIZE
    return self.loveGraphics.newQuad(
      x, y,
      self.TILE_SIZE, self.TILE_SIZE,
      self.objectSpriteSheet:getDimensions()
    )
end

-- Return a cached quad (or create and cache it if not present).
function Assets:getCachedQuad(name)
    if not self.quadCache[name] then
        self.quadCache[name] = self:getQuad(name)
    end
    return self.quadCache[name]
end

-- Load a grid of tile quads from the object sprite sheet.
function Assets:loadTileQuads(tileSize, tilesPerRow, tilesPerCol)
    local tileQuads = {}
    local imgWidth, imgHeight = self.objectSpriteSheet:getDimensions()
    for row = 0, tilesPerCol - 1 do
        for col = 0, tilesPerRow - 1 do
            local tileIndex = (row * tilesPerRow) + col + 1
            tileQuads[tileIndex] = self.loveGraphics.newQuad(
                col * tileSize, row * tileSize,
                tileSize, tileSize,
                imgWidth, imgHeight
            )
        end
    end
    return tileQuads
end

-- Static helper: Create a quad for a given frame with a base Y offset.
function Assets.getQuadWithOffset(frame, baseYOffset, rowFrameCount, spriteWidth, spriteHeight, gap, spriteSheet, loveGraphics)
    local row = math.ceil(frame / rowFrameCount)
    local column = (frame - 1) % rowFrameCount
    local x = column * spriteWidth
    local y = baseYOffset + (row - 1) * (spriteHeight + gap)
    return love.Graphics.newQuad(x, y, spriteWidth, spriteHeight, spriteSheet:getDimensions())
end

-- Static helper: Generate an animation sequence from startFrame to endFrame.
function Assets.generateAnimation(startFrame, endFrame, baseYOffset, rowFrameCount, spriteWidth, spriteHeight, gap, spriteSheet, loveGraphics)
    local anim = {}
    for frame = startFrame, endFrame do
        table.insert(anim, Assets.getQuadWithOffset(frame, baseYOffset, rowFrameCount, spriteWidth, spriteHeight, gap, spriteSheet, loveGraphics))
    end
    return anim
end

return Assets
