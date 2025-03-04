local assets = {}

-- Load the object sprite sheet (if needed)
assets.objectSpriteSheet = love.graphics.newImage("assets/sprites/objects.png")
assets.objectSpriteSheet:setFilter("nearest", "nearest")

-- Load the player sprite sheet once
assets.playerSpriteSheet = love.graphics.newImage("assets/sprites/player.png")
assets.playerSpriteSheet:setFilter("nearest", "nearest")

function assets.loadTileQuads(tileSize, tilesPerRow, tilesPerCol)
    local tileQuads = {}
    local imgWidth, imgHeight = assets.objectSpriteSheet:getDimensions()
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
function assets.getQuadWithOffset(frame, baseYOffset, rowFrameCount, spriteWidth, spriteHeight, gap, spriteSheet)
    local x, y
    if frame <= rowFrameCount then
        x = (frame - 1) * spriteWidth
        y = baseYOffset
    else
        x = (frame - rowFrameCount - 1) * spriteWidth
        y = baseYOffset + spriteHeight + gap
    end
    return love.graphics.newQuad(x, y, spriteWidth, spriteHeight, spriteSheet:getDimensions())
end

-- Generic helper: Generate an animation sequence from startFrame to endFrame.
function assets.generateAnimation(startFrame, endFrame, baseYOffset, rowFrameCount, spriteWidth, spriteHeight, gap, spriteSheet)
    local anim = {}
    for frame = startFrame, endFrame do
        table.insert(anim, assets.getQuadWithOffset(frame, baseYOffset, rowFrameCount, spriteWidth, spriteHeight, gap, spriteSheet))
    end
    return anim
end

return assets
