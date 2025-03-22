local Assets = {}
Assets.__index = Assets

-- Load the object sprite sheet (if needed)
Assets.objectSpriteSheet = love.graphics.newImage("assets/sprites/objects.png")
Assets.objectSpriteSheet:setFilter("nearest", "nearest")

Assets.TILE_SIZE = 16

-- Your original item definitions.
Assets.ITEM_DEFINITIONS = {
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
    duration = 3,
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
    weight = 3,
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
    enabled = Settings.fastIgnition,
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
    duration = 3,
    shopItem = false
  },
  {
    enabled = Settings.shop,
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
    weight = 3,
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


-- Convert item definitions to a mapping table.
Assets.itemMapping = {}
for _, item in ipairs(Assets.ITEM_DEFINITIONS) do
  if item.row and item.col then
    -- Use the item name as the key and store row/col.
    Assets.itemMapping[item.key] = { row = item.row, col = item.col }
  end
end
-- Now you can access, for example:
-- assets.itemMapping["bomb"] returns { row = 2, col = 20 }
-- assets.itemMapping["power-up"] returns { row = 3, col = 1 }

-- Load the player sprite sheet once
Assets.playerSpriteSheet = love.graphics.newImage("assets/sprites/player.png")
Assets.playerSpriteSheet:setFilter("nearest", "nearest")

Assets.SPRITE_WIDTH = 32
Assets.SPRITE_HEIGHT = 22
Assets.ROW_FRAME_COUNT = 10
Assets.GAP = 1

-- Generic function to get a quad for an asset by name.
function Assets.getQuad(name)
  local mapping = Assets.itemMapping[name]
  if not mapping then return nil end
  local x = (mapping.col - 1) * Assets.TILE_SIZE
  local y = (mapping.row - 1) * Assets.TILE_SIZE
  return love.graphics.newQuad(x, y, Assets.TILE_SIZE, Assets.TILE_SIZE, Assets.objectSpriteSheet:getDimensions())
end

-- Optionally, cache quads to avoid recreating them
Assets.quadCache = {}
function Assets.getCachedQuad(name)
  if not Assets.quadCache[name] then
    Assets.quadCache[name] = Assets.getQuad(name)
  end
  return Assets.quadCache[name]
end

function Assets.loadTileQuads(tileSize, tilesPerRow, tilesPerCol)
    local tileQuads = {}
    local imgWidth, imgHeight = Assets.objectSpriteSheet:getDimensions()
    for row = 0, tilesPerCol - 1 do
        for col = 0, tilesPerRow - 1 do
            local tileIndex = (row * tilesPerRow) + col + 1
            tileQuads[tileIndex] = love.graphics.newQuad(
                col * tileSize, row * tileSize,
                tileSize, tileSize,
                imgWidth, imgHeight
            )
        end
    end
    return tileQuads
end

-- Generic helper: Create a quad for a given frame with a base Y offset.
-- Now the spriteSheet is passed in as a parameter.
function Assets.getQuadWithOffset(frame, baseYOffset, rowFrameCount, spriteWidth, spriteHeight, gap, spriteSheet)
    -- Determine row and column based on the frame number
    local row = math.ceil(frame / rowFrameCount) -- Row index (starting from 1)
    local column = (frame - 1) % rowFrameCount   -- Column index (starting from 0)

    -- Calculate x and y positions
    local x = column * spriteWidth
    local y = baseYOffset + (row - 1) * (spriteHeight + gap) -- Adjust y for multiple rows

    -- Return the quad
    return love.graphics.newQuad(x, y, spriteWidth, spriteHeight, spriteSheet:getDimensions())
end


-- Generic helper: Generate an animation sequence from startFrame to endFrame.
function Assets.generateAnimation(startFrame, endFrame, baseYOffset, rowFrameCount, spriteWidth, spriteHeight, gap, spriteSheet)
    local anim = {}
    for frame = startFrame, endFrame do
        table.insert(anim, Assets.getQuadWithOffset(frame, baseYOffset, rowFrameCount, spriteWidth, spriteHeight, gap, spriteSheet))
    end
    return anim
end

return Assets
