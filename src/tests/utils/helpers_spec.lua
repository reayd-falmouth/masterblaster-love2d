local helpers = require("masterblaster.utils.helpers")

describe("Helpers Module", function()

    -- Mocking Love2D Graphics module
    local mockGraphics = {
        setColor = function() end,
        draw = function() end
    }

    it("should reverse a table correctly", function()
        local input = {1, 2, 3, 4}
        local expected = {4, 3, 2, 1}
        assert.are.same(expected, helpers.reverseTable(input))
    end)

    it("should not modify the original table when reversing", function()
        local input = {1, 2, 3, 4}
        local copy = {1, 2, 3, 4}  -- Copy to compare
        helpers.reverseTable(input)
        assert.are.same(copy, input)  -- Original should be unchanged
    end)

    it("should reverse a table in place correctly", function()
        local input = {1, 2, 3, 4}
        helpers.reverseTableInPlace(input)
        assert.are.same({4, 3, 2, 1}, input)  -- Original table should be reversed
    end)

    it("should call Love2D graphics functions correctly when drawing an object sprite", function()
        local theme = { fgColor = {1, 1, 1}, highlightColor = {0, 1, 0} }
        local assets = { objectSpriteSheet = {} }
        local quad = {}

        spy.on(mockGraphics, "setColor")
        spy.on(mockGraphics, "draw")

        helpers.drawObjectSprite(mockGraphics, theme, assets, quad, 10, 20)

        assert.spy(mockGraphics.setColor).was_called_with(theme.fgColor)
        assert.spy(mockGraphics.draw).was_called_with(assets.objectSpriteSheet, quad, 10, 20)
        assert.spy(mockGraphics.setColor).was_called_with(theme.highlightColor)
    end)

end)
