-- spawns.lua
local Spawns = {}

function Spawns:getSpawnPositions(numPlayers, map)
    local candidates = {}

    if numPlayers == 1 then
        candidates = {
            { name = "topLeft",     grid = {2, 2} },
        }
    elseif numPlayers == 2 then
        candidates = {
            { name = "topLeft",     grid = {2, 2} },
            { name = "bottomRight", grid = { map.cols - 1, map.rows - 1 } },
        }
    elseif numPlayers == 3 then
        candidates = {
            { name = "topLeft",     grid = {2, 2} },
            { name = "bottomRight", grid = { map.cols - 1, map.rows - 1 } },
            { name = "middle",      grid = { math.floor(map.cols / 2), math.floor(map.rows / 2) } },
        }
    elseif numPlayers == 4 then
        candidates = {
            { name = "topLeft",     grid = {2, 2} },
            { name = "bottomRight", grid = { map.cols - 1, map.rows - 1 } },
            { name = "topRight",    grid = { map.cols - 1, 2 } },
            { name = "bottomLeft",  grid = {2, map.rows - 1} },
        }
    elseif numPlayers == 5 then
        candidates = {
            { name = "topLeft",     grid = {2, 2} },
            { name = "bottomRight", grid = { map.cols - 1, map.rows - 1 } },
            { name = "topRight",    grid = { map.cols - 1, 2 } },
            { name = "bottomLeft",  grid = {2, map.rows - 1} },
            { name = "middle",      grid = { math.floor(map.cols / 2), math.floor(map.rows / 2) } },
        }
    end


    local spawnPositions = {}
    local tileSize = map.tileSize or 16  -- Ensure tile size is correctly defined

    log.debug("  Placing candidates ")
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
            log.debug("  is block free?")
            if not map:isBlockFree(gx, gy) then
                log.debug("  finding nearest neighbour... ")
                gx, gy = map:findNearestFreeBlock(gx, gy)
            end

            log.debug("  grid to world..")
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
