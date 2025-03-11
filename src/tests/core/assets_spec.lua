-- test_assets.lua
local Assets = require "core.assets" -- Adjust the path as needed

-- Create a stub for love.graphics
local stubLoveGraphics = {}

stubLoveGraphics.newImage = function(filename)
    local img = { filename = filename }
    function img:setFilter(min, mag)
        self.filter = {min, mag}
    end
    function img:getDimensions()
        if filename:find("objects.png") then
            return 256, 256
        elseif filename:find("player.png") then
            return 128, 64
        else
            return 100, 100
        end
    end
    return img
end

stubLoveGraphics.newQuad = function(x, y, w, h, imgWidth, imgHeight)
    return { x = x, y = y, w = w, h = h, imgWidth = imgWidth, imgHeight = imgHeight }
end

describe("Assets module", function()
    local assets
    before_each(function()
        -- Pass in stubLoveGraphics and custom settings (for example, fastIgnition enabled, shop disabled)
        assets = Assets.new(stubLoveGraphics, { fastIgnition = true, shop = false })
    end)

    it("should create correct itemMapping", function()
        -- Check that items with row and col are mapped
        assert.are.same({ row = 2, col = 20 }, assets.itemMapping["bomb"])
        assert.are.same({ row = 3, col = 1 }, assets.itemMapping["powerUp"])
        -- Items without row/col (like "none") should not be in the mapping table.
        assert.is_nil(assets.itemMapping["none"])
    end)

    it("should return nil for getQuad with an invalid name", function()
        local quad = assets:getQuad("nonexistent")
        assert.is_nil(quad)
    end)

    it("should return a valid quad for a valid item", function()
        local quad = assets:getQuad("bomb")
        local expectedX = (20 - 1) * assets.TILE_SIZE  -- (20 - 1) * 16 = 304
        local expectedY = (2 - 1) * assets.TILE_SIZE   -- (2 - 1) * 16 = 16
        assert.are.same(expectedX, quad.x)
        assert.are.same(expectedY, quad.y)
        assert.are.same(assets.TILE_SIZE, quad.w)
        assert.are.same(assets.TILE_SIZE, quad.h)
        local imgWidth, imgHeight = assets.objectSpriteSheet:getDimensions()
        assert.are.same(imgWidth, quad.imgWidth)
        assert.are.same(imgHeight, quad.imgHeight)
    end)

    it("should cache quads in getCachedQuad", function()
        local quad1 = assets:getCachedQuad("bomb")
        local quad2 = assets:getCachedQuad("bomb")
        assert.are.equal(quad1, quad2)
    end)

    it("should load tile quads correctly", function()
        local tileSize = 16
        local tilesPerRow = 4
        local tilesPerCol = 4
        local quads = assets:loadTileQuads(tileSize, tilesPerRow, tilesPerCol)
        assert.are.equal(tilesPerRow * tilesPerCol, #quads)
        local imgWidth, imgHeight = assets.objectSpriteSheet:getDimensions()
        for row = 0, tilesPerCol - 1 do
            for col = 0, tilesPerRow - 1 do
                local index = row * tilesPerRow + col + 1
                local quad = quads[index]
                assert.are.same(col * tileSize, quad.x)
                assert.are.same(row * tileSize, quad.y)
                assert.are.same(tileSize, quad.w)
                assert.are.same(tileSize, quad.h)
                assert.are.same(imgWidth, quad.imgWidth)
                assert.are.same(imgHeight, quad.imgHeight)
            end
        end
    end)

    it("should compute quad with offset correctly", function()
        local fakeSpriteSheet = {
            getDimensions = function() return 200, 200 end
        }
        local frame = 5
        local baseYOffset = 10
        local rowFrameCount = 4
        local spriteWidth = 32
        local spriteHeight = 32
        local gap = 2
        local quad = Assets.getQuadWithOffset(frame, baseYOffset, rowFrameCount, spriteWidth, spriteHeight, gap, fakeSpriteSheet, stubLoveGraphics)
        local expectedRow = math.ceil(frame / rowFrameCount)  -- ceil(5/4) = 2
        local expectedColumn = (frame - 1) % rowFrameCount       -- (5 - 1) % 4 = 0
        local expectedX = expectedColumn * spriteWidth           -- 0 * 32 = 0
        local expectedY = baseYOffset + (expectedRow - 1) * (spriteHeight + gap)  -- 10 + 1*(32+2) = 44
        assert.are.same(expectedX, quad.x)
        assert.are.same(expectedY, quad.y)
        assert.are.same(spriteWidth, quad.w)
        assert.are.same(spriteHeight, quad.h)
        local imgWidth, imgHeight = fakeSpriteSheet:getDimensions()
        assert.are.same(imgWidth, quad.imgWidth)
        assert.are.same(imgHeight, quad.imgHeight)
    end)

    it("should generate an animation sequence correctly", function()
        local fakeSpriteSheet = {
            getDimensions = function() return 300, 300 end
        }
        local startFrame = 1
        local endFrame = 3
        local baseYOffset = 5
        local rowFrameCount = 3
        local spriteWidth = 20
        local spriteHeight = 20
        local gap = 1
        local anim = Assets.generateAnimation(startFrame, endFrame, baseYOffset, rowFrameCount, spriteWidth, spriteHeight, gap, fakeSpriteSheet, stubLoveGraphics)
        assert.are.equal(3, #anim)
        -- Check first frame values
        local expectedRow = math.ceil(startFrame / rowFrameCount)
        local expectedColumn = (startFrame - 1) % rowFrameCount
        local expectedX = expectedColumn * spriteWidth
        local expectedY = baseYOffset + (expectedRow - 1) * (spriteHeight + gap)
        assert.are.same(expectedX, anim[1].x)
        assert.are.same(expectedY, anim[1].y)
    end)
end)
