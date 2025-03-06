-- map.lua
require("config.globals")
local Audio = require("system.audio")
local Block = require("entities.block")
local shrinkSound = nil
local map = {}

-- Map configuration
map.tileSize = 16
map.rows = 15
map.cols = 19
map.density = 0.7
map.shrinkStep = 0

-- Tile IDs (match your game.lua values)
map.tileIDs = {
  EMPTY = 43,
  WALL = 38,
  DESTRUCTIBLE = 39
}

-- The arena map (2D table)
map.tileMap = {}

-- Compute safe spawn zones based on current map dimensions.
-- These zones ensure players won't be trapped at spawn.
function map:getSafeZones()
  local safeZones = {}
  local centerRow = math.floor(self.rows / 2)
  local centerCol = math.floor(self.cols / 2)

  -- Top-left safe area
  table.insert(safeZones, {2,2})
  table.insert(safeZones, {2,3})
  table.insert(safeZones, {3,2})

  -- Top-right safe area
  table.insert(safeZones, {2, self.cols - 1})
  table.insert(safeZones, {2, self.cols - 2})
  table.insert(safeZones, {3, self.cols - 1})

  -- Bottom-left safe area
  table.insert(safeZones, {self.rows - 1, 2})
  table.insert(safeZones, {self.rows - 1, 3})
  table.insert(safeZones, {self.rows - 2, 2})

  -- Bottom-right safe area
  table.insert(safeZones, {self.rows - 1, self.cols - 1})
  table.insert(safeZones, {self.rows - 1, self.cols - 2})
  table.insert(safeZones, {self.rows - 2, self.cols - 1})

  -- Middle safe area (4 tiles)
  table.insert(safeZones, {centerRow, centerCol})
  table.insert(safeZones, {centerRow, centerCol + 1})
  table.insert(safeZones, {centerRow + 1, centerCol})
  table.insert(safeZones, {centerRow + 1, centerCol + 1})

  return safeZones
end

-- Generate the base arena map, then place destructible blocks.
function map:generateMap()
  local safeZones = self:getSafeZones()

  for r = 1, self.rows do
    self.tileMap[r] = {}
    for c = 1, self.cols do
      if r == 1 or r == self.rows or c == 1 or c == self.cols then
        self.tileMap[r][c] = self.tileIDs.WALL
      elseif r % 2 == 1 and c % 2 == 1 then
        self.tileMap[r][c] = self.tileIDs.WALL
      else
        self.tileMap[r][c] = self.tileIDs.EMPTY
      end
    end
  end

  -- Place destructible blocks, avoiding safe zones.
  self:placeDestructibles(safeZones)
end

-- Place destructible blocks randomly, skipping safe zones.
function map:placeDestructibles(safeZones)
  for r = 2, self.rows - 1 do
    for c = 2, self.cols - 1 do
      if self.tileMap[r][c] == self.tileIDs.EMPTY and not self:isTileInList(r, c, safeZones) then
        if math.random() < self.density then
          self.tileMap[r][c] = self.tileIDs.DESTRUCTIBLE
        end
      end
    end
  end
end

-- Utility: check if a tile (r, c) is in a list of positions.
function map:isTileInList(r, c, list)
  for _, pos in ipairs(list) do
    if pos[1] == r and pos[2] == c then
      return true
    end
  end
  return false
end

-- Convert grid coordinates (gx, gy) to world coordinates.
function map:gridToWorld(gx, gy)
  local x = (gx - 1) * self.tileSize
  local y = (gy - 1) * self.tileSize
  return x, y
end

-- Check if the block at grid position (gx, gy) is free.
function map:isBlockFree(gx, gy)
  if self.tileMap[gy] and self.tileMap[gy][gx] then
    return self.tileMap[gy][gx] == self.tileIDs.EMPTY
  end
  return false
end

-- Find the nearest free block (grid coordinates) if the desired block isn’t free.
function map:findNearestFreeBlock(gx, gy)
  local radius = 1
  while true do
    for dx = -radius, radius do
      for dy = -radius, radius do
        local nx = gx + dx
        local ny = gy + dy
        if nx >= 1 and ny >= 1 and nx <= self.cols and ny <= self.rows then
          if self:isBlockFree(nx, ny) then
            return nx, ny
          end
        end
      end
    end
    radius = radius + 1
  end
end

-- Shrink the map one layer clockwise.
function map:initShrink()
    -- Start shrinking from the second layer to preserve outer boundary
    self.shrinkLayer = 2
    self.shrinkSide = 'top'
    self.shrinkIndex = self.shrinkLayer
    shrinkSound = Audio.sfxSources.bubble
end

function map:shrinkMapStep()
    if not self.shrinkLayer then
        self:initShrink()
    end

    local layer = self.shrinkLayer
    local maxLayer = math.min(math.floor(self.rows / 2), math.floor(self.cols / 2))

    if layer > maxLayer then
        return
    end

    local r, c

    if self.shrinkSide == 'top' then
        r, c = layer, self.shrinkIndex
        self.shrinkIndex = self.shrinkIndex + 1
        if self.shrinkIndex > self.cols - layer + 1 then
            self.shrinkSide = 'right'
            self.shrinkIndex = layer + 1
        end

    elseif self.shrinkSide == 'right' then
        r, c = self.shrinkIndex, self.cols - layer + 1
        self.shrinkIndex = self.shrinkIndex + 1
        if self.shrinkIndex > self.rows - layer + 1 then
            self.shrinkSide = 'bottom'
            self.shrinkIndex = self.cols - layer
        end

    elseif self.shrinkSide == 'bottom' then
        r, c = self.rows - layer + 1, self.shrinkIndex
        self.shrinkIndex = self.shrinkIndex - 1
        if self.shrinkIndex < layer then
            self.shrinkSide = 'left'
            self.shrinkIndex = self.rows - layer
        end

    elseif self.shrinkSide == 'left' then
        r, c = self.shrinkIndex, layer
        self.shrinkIndex = self.shrinkIndex - 1
        if self.shrinkIndex <= layer then
            self.shrinkLayer = self.shrinkLayer + 1
            self.shrinkSide = 'top'
            self.shrinkIndex = self.shrinkLayer
        end
    end

    -- Set tile to WALL in tileMap
    self.tileMap[r][c] = self.tileIDs.WALL

    -- Add a new Block object to blockMap for collision
    Game.blockMap[r][c] = Block:new(r, c, self.tileSize, self.tileIDs.WALL, false, true)

    -- Check for players at this position and kill if necessary
    for _, player in ipairs(Game.players) do
        local playerRow = math.floor(player.y / self.tileSize) + 1
        local playerCol = math.floor(player.x / self.tileSize) + 1

        if playerRow == r and playerCol == c and not player.toRemove then
            player:die()
        end
    end

    -- Play shrinking sound
    shrinkSound:play()
end


-- Get the offsets for the map
function map:getDrawOffset()
    local screenWidth = VIRTUAL_WIDTH
    local screenHeight = VIRTUAL_HEIGHT
    local arenaWidth = self.cols * self.tileSize
    local arenaHeight = self.rows * self.tileSize
    local offsetX = (screenWidth - arenaWidth) / 2
    local offsetY = (screenHeight - arenaHeight) / 2
    return offsetX, offsetY
end

return map
