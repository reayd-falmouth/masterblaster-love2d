-- spawns.lua
local Spawns = {}

function Spawns:getSpawnPositions(numPlayers, map)
    local candidates = {}

    if numPlayers == 1 then
        candidates = {
            { name = "topLeft",     grid = {1, 1} },
        }
    elseif numPlayers == 2 then
        candidates = {
            { name = "topLeft",     grid = {1, 1} },
            { name = "bottomRight", grid = { map.cols, map.rows } },
        }
    elseif numPlayers == 3 then
        candidates = {
            { name = "topLeft",     grid = {1, 1} },
            { name = "bottomRight", grid = { map.cols, map.rows } },
            { name = "middle",      grid = { math.floor(map.cols / 2), math.floor(map.rows / 2) } },
        }
    elseif numPlayers == 4 then
        candidates = {
            { name = "topLeft",     grid = {1, 1} },
            { name = "bottomRight", grid = { map.cols, map.rows } },
            { name = "topRight",    grid = { map.cols, 1 } },
            { name = "bottomLeft",  grid = { 1, map.rows } },
        }
    elseif numPlayers == 5 then
        candidates = {
            { name = "topLeft",     grid = {1, 1} },
            { name = "bottomRight", grid = { map.cols, map.rows } },
            { name = "topRight",    grid = { map.cols, 1 } },
            { name = "bottomLeft",  grid = { 1, map.rows } },
            { name = "middle",      grid = { math.floor(map.cols / 2), math.floor(map.rows / 2) } },
        }
    end

    local spawnPositions = {}
    local tileSize = map.tileSize or 16  -- Ensure tile size is correctly defined

    for i, candidate in ipairs(candidates) do
        local gx, gy = candidate.grid[1], candidate.grid[2]

        -- Special handling for the middle spawn (always at the exact center)
        if candidate.name == "middle" then
            local centerX, centerY = map:gridToWorld(math.floor(map.cols / 2), math.floor(map.rows / 2))
            spawnPositions[i] = {
                x = centerX + (tileSize / 2),
                y = centerY + (tileSize / 2)
            }
        else
            -- For all other players, check if the tile is occupied
            if not map:isBlockFree(gx, gy) then
                gx, gy = map:findNearestFreeBlock(gx, gy)
            end

            local worldX, worldY = map:gridToWorld(gx, gy)

            -- Apply centering only for non-middle players
            spawnPositions[i] = {
                x = worldX + (tileSize / 2),
                y = worldY + (tileSize / 2)
            }
        end
    end

    return spawnPositions
end

return Spawns
