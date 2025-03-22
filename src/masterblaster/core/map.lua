-- map.lua
require("config.globals")
local Assets = require("core.assets")
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
-- Set up shrinking timers inside the map
map.shrinkTimer = 0
map.shrinkDelay = 1/5  -- or whatever value you want
map.tileQuads = {}  -- Initialize empty table
map.tilesPerRow = 20  -- Number of tiles per row
map.tilesPerCol = 3    -- Number of tiles per column
map.tileQuads = Assets.loadTileQuads(map.tileSize, map.tilesPerRow, map.tilesPerCol)
map.tileSheet = Assets.objectSpriteSheet

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
    LOG.debug("MAP CREATION START")
    self.tileMap = {}  -- Ensure it's a fresh table

    LOG.debug("  Getting safe zones...")
    local safeZones = self:getSafeZones()

    LOG.debug("  Generating walls...")
    for r = 1, self.rows do
        self.tileMap[r] = {}
        for c = 1, self.cols do
            -- Each cell is now a table that can hold both a block and an item.
            self.tileMap[r][c] = { block = nil, item = nil }

            if r == 1 or r == self.rows or c == 1 or c == self.cols then
                self.tileMap[r][c].block = Block:new(r, c, self.tileSize, self.tileIDs.WALL, false)
            elseif r % 2 == 1 and c % 2 == 1 then
                self.tileMap[r][c].block = Block:new(r, c, self.tileSize, self.tileIDs.WALL, false)
            end
        end
    end

    -- Place destructible blocks, avoiding safe zones.
    LOG.debug("  Placing destructibles...")
    self:placeDestructibles(safeZones)

    LOG.debug("MAP CREATION COMPLETE")
end

-- Place destructible blocks randomly, skipping safe zones.
function map:placeDestructibles(safeZones)
    for r = 2, self.rows - 1 do
        for c = 2, self.cols - 1 do
            local cell = self.tileMap[r][c]
            -- Only place a destructible block if there's no block already (and it isn’t in a safe zone).
            if not cell.block and not self:isTileInList(r, c, safeZones) then
                if math.random() < self.density then
                    cell.block = Block:new(r, c, self.tileSize, self.tileIDs.DESTRUCTIBLE, true)
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
    local cell = self.tileMap[gy] and self.tileMap[gy][gx]
    if cell then
        return cell.block == nil
    end
    return false
end

function map:getBlockAt(x, y)
    local col = math.floor(x / self.tileSize) + 1
    local row = math.floor(y / self.tileSize) + 1
    if self.tileMap[row] then
         local cell = self.tileMap[row][col]
         if cell then
              return cell.block
         end
    end
    return nil
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
    self.tileMap[r][c].block = Block:new(r, c, self.tileSize, self.tileIDs.WALL, false, true)

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

function map:load()

end

function map:update(dt, alarmActive)
    -- Go row-by-row, col-by-col
    for row = 1, #self.tileMap do
        for col = 1, #self.tileMap[row] do
            local cell = self.tileMap[row][col]
            if cell then
                if cell.block then
                    cell.block:update(dt)
                    if cell.block.toRemove then
                        cell.block = nil
                    end
                end
                if cell.item then
                    cell.item:update(dt)
                    if cell.item.toRemove then
                        cell.item = nil
                    end
                end
            end
        end
    end

    -- Only update shrinking if the settings are on and alarm has been triggered.
    if Settings.shrinking and alarmActive then
        LOG.debug("Alarm active, shrinking arena...")
        self.shrinkTimer = self.shrinkTimer + dt
        if self.shrinkTimer >= self.shrinkDelay then
            self.shrinkTimer = 0
            self:shrinkMapStep()
        end
    end
end

function map:draw()
    for r = 1, self.rows do
        for c = 1, self.cols do
            local cell = self.tileMap[r][c]
            -- Draw the floor tile first (if needed)
            local x, y = (c - 1) * self.tileSize, (r - 1) * self.tileSize
            love.graphics.draw(self.tileSheet, self.tileQuads[self.tileIDs.EMPTY], x, y)
            -- Then draw the block (if it exists)
            if cell.block then
                cell.block:draw(Game.tileQuads)
            end
            -- Finally, draw the item on top (if present)
            if cell.item then
                cell.item:draw()
            end
        end
    end
end

return map
