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

-- Define globals needed before requiring the Assets module
-- Extend love.math so it has newRandomGenerator and falls back to Lua's math functions.
_G.love = {
  graphics = stubLoveGraphics,
  math = setmetatable({
      newRandomGenerator = function(seed)
          -- Return a dummy random generator. This stub simply returns 0.5 for any random call.
          local rng = {
              seed = seed,
              random = function(self)
                  return 0.5
              end,
          }
          return rng
      end,
  }, { __index = math })
}
_G.Settings = { fastIgnition = true, shop = false }

local Overs = require("scenes.overs")


describe("Overs", function()
  local loveGraphicsCalls = {}
  local switchStateCalled = nil

  -- Set up fake love.graphics functions
  local function resetLoveGraphics()
    loveGraphicsCalls = {}
    love.graphics = {
      setBackgroundColor = function(r, g, b)
        table.insert(loveGraphicsCalls, { fn = "setBackgroundColor", args = { r, g, b } })
      end,
      setColor = function(...)
        table.insert(loveGraphicsCalls, { fn = "setColor", args = { ... } })
      end,
      printf = function(text, ...)
        table.insert(loveGraphicsCalls, { fn = "printf", args = { text, ... } })
      end,
      draw = function(...)
        table.insert(loveGraphicsCalls, { fn = "draw", args = { ... } })
      end,
    }
  end

  before_each(function()
    -- Reset our recorded graphics calls
    resetLoveGraphics()

    -- Stub Assets module with dummy values and a spy on getQuadWithOffset.
    Assets = {
      playerSpriteSheet = "dummySpriteSheet",
      getQuadWithOffset = function(frameNumber, baseYOffset, rowFrameCount, spriteWidth, spriteHeight, gap, spriteSheet)
        -- Record the computed baseYOffset for verification later.
        loveGraphicsCalls.baseYOffset = baseYOffset
        return "dummyQuad"
      end
    }
    package.loaded["core.assets"] = Assets

    -- Stub UITheme module with a dummy default theme.
    UITheme = {
      defaultTheme = {
        primaryColor = { 1, 0, 0 },   -- red
        foregroundColor = { 0, 1, 0 }   -- green
      }
    }
    package.loaded["core.theme"] = UITheme

    -- Stub Menu module.
    Menu = {}
    package.loaded["scenes.menu"] = Menu

    -- Setup globals used by overs.lua.
    PlayerStats = { players = {} }
    Settings = { winsNeeded = 3 }
    VIRTUAL_WIDTH = 200

    -- Stub switchState to capture its parameter.
    switchStateCalled = nil
    switchState = function(state)
      switchStateCalled = state
    end

    -- Clear overs from package.loaded to force reloading our test version.
    package.loaded["overs"] = nil
    Overs = require("overs")
  end)

  describe("load", function()
    it("should set winningPlayerIndex to the first player with wins >= winsNeeded", function()
      -- Set up players so that only the second meets the winsNeeded.
      PlayerStats.players = {
        { wins = 1 },
        { wins = 3 },
        { wins = 5 }
      }
      Overs.load()

      -- Since winningPlayerIndex is local and used by draw() to compute baseYOffset,
      -- we verify that by calling draw(). For a winningPlayerIndex of 2, the computed
      -- baseYOffset should be: (2 - 1) * (3 * SPRITE_HEIGHT + 3)
      -- where SPRITE_HEIGHT is 22, so baseYOffset = 1 * (66 + 3) = 69.
      Overs.draw()
      local expectedBaseYOffset = (2 - 1) * (3 * 22 + 3)
      assert.are.equal(expectedBaseYOffset, loveGraphicsCalls.baseYOffset)
    end)
  end)

  describe("update", function()
    it("should not produce errors when called", function()
      assert.has_no.errors(function() Overs.update(0.016) end)
    end)
  end)

  describe("draw", function()
    it("should call love.graphics functions with expected values", function()
      -- For testing draw we need to set a winning player.
      PlayerStats.players = { { wins = 4 } }
      Overs.load()

      -- Clear any previous graphics call records.
      resetLoveGraphics()

      Overs.draw()

      -- Check that love.graphics.setBackgroundColor was called with 0, 0, 0.
      local foundSetBackgroundColor = false
      for _, call in ipairs(loveGraphicsCalls) do
        if call.fn == "setBackgroundColor" and call.args[1] == 0 then
          foundSetBackgroundColor = true
          break
        end
      end
      assert.is_true(foundSetBackgroundColor)

      -- Verify that the "YOU WON !!!" and "PRESS ANY BUTTON TO RESTART" texts were printed.
      local foundYouWon, foundPressAny = false, false
      for _, call in ipairs(loveGraphicsCalls) do
        if call.fn == "printf" then
          if call.args[1] == "YOU WON !!!" then
            foundYouWon = true
          elseif call.args[1] == "PRESS ANY BUTTON TO RESTART" then
            foundPressAny = true
          end
        end
      end
      assert.is_true(foundYouWon)
      assert.is_true(foundPressAny)
    end)
  end)

  describe("keypressed", function()
    it("should switch state to Menu when any key is pressed", function()
      Overs.keypressed("space")
      assert.are.equal(Menu, switchStateCalled)
    end)
  end)
end)
