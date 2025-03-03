local tileSize = 16  -- Tile size in pixels
local rows = 15  -- Map height
local cols = 19  -- Map width
local density = 0.7

-- Define tile types
local tileSheet = {
    EMPTY = 43,
    WALL = 38,
    DESTRUCTIBLE = 39,
    BOMB = 50,
    EXPLOSION = 51,
    ITEM_SPEED = 52,
    ITEM_RANGE = 53,
    ITEM_EXTRA_BOMB = 54,
}

-- Create a new empty tileMap
local tileMap = {}

-- Generate map using loops
for r = 1, rows do
    tileMap[r] = {}
    for c = 1, cols do
        -- Outer Walls (Always WALL)
        if r == 1 or r == rows or c == 1 or c == cols then
            tileMap[r][c] = tileSheet.WALL
        -- Fixed Non-Destructible Blocks (Every Other Tile in a Grid)
        elseif r % 2 == 1 and c % 2 == 1 then
            tileMap[r][c] = tileSheet.WALL
        -- Default to Empty Space
        else
            tileMap[r][c] = tileSheet.EMPTY
        end
    end
end

-- **Define Safe Spawn Areas (Players should not be trapped)**
local centerRow = math.floor(rows / 2)
local centerCol = math.floor(cols / 2)

local safeZones = {
    -- Player Spawn Zones
    {2,2}, {2,3}, {3,2}, -- Top-left spawn
    {2,cols-1}, {2,cols-2}, {3,cols-1}, -- Top-right spawn
    {rows-1,2}, {rows-1,3}, {rows-2,2}, -- Bottom-left spawn
    {rows-1,cols-1}, {rows-1,cols-2}, {rows-2,cols-1}, -- Bottom-right spawn

    -- **4 Tiles in the Middle**
    {centerRow, centerCol},
    {centerRow, centerCol + 1},
    {centerRow + 1, centerCol},
    {centerRow + 1, centerCol + 1}
}

-- Function to check if a tile is in a given list
local function isTileInList(r, c, list)
    for _, pos in ipairs(list) do
        if pos[1] == r and pos[2] == c then
            return true
        end
    end
    return false
end

-- Function to randomly place destructible blocks
local function placeDestructibles()
    for r = 2, rows - 1 do
        for c = 2, cols - 1 do
            if tileMap[r][c] == tileSheet.EMPTY and
               not isTileInList(r, c, safeZones) then
                if math.random() < density then  -- 50% chance to place a destructible tile
                    tileMap[r][c] = tileSheet.DESTRUCTIBLE
                end
            end
        end
    end
end

-- Function to randomly place power-ups
local function placePowerUps()
    for r = 2, rows - 1 do
        for c = 2, cols - 1 do
            if tileMap[r][c] == tileSheet.EMPTY and math.random() < 0.02 then -- 2% chance
                local powerUpType = math.random(1, 3)
                if powerUpType == 1 then tileMap[r][c] = tileSheet.ITEM_SPEED
                elseif powerUpType == 2 then tileMap[r][c] = tileSheet.ITEM_RANGE
                else tileMap[r][c] = tileSheet.ITEM_EXTRA_BOMB end
            end
        end
    end
end

-- Apply Random Generation
math.randomseed(os.time())
placeDestructibles()
--placePowerUps() -- Uncomment if you want power-ups to be generated

return tileMap, tileSheet  -- Return TILE so other scripts can use it