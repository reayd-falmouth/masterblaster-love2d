-- tests/theme_spec.lua

local themeModule = require("core.theme")
local Theme = themeModule.Theme
local defaultTheme = themeModule.defaultTheme

describe("Theme Module", function()

    describe("Default Theme", function()
        it("should have the correct default primary color", function()
            assert.are.same({0.333, 0, 0.733, 1}, defaultTheme.primaryColor)
        end)

        it("should have the correct default secondary color", function()
            assert.are.same({0, 0.2, 1, 1}, defaultTheme.secondaryColor)
        end)

        it("should have the correct default background color", function()
            assert.are.same({0, 0, 0, 1}, defaultTheme.backgroundColor)
        end)

        it("should have the correct default foreground color", function()
            assert.are.same({1, 1, 1, 1}, defaultTheme.foregroundColor)
        end)
    end)

    describe("Custom Theme", function()
        local customTheme

        before_each(function()
            customTheme = Theme.new({
                primaryColor   = {1, 0, 0, 1},
                secondaryColor = {0, 1, 0, 1},
                backgroundColor= {0, 0, 1, 1},
                foregroundColor= {1, 1, 0, 1},
            })
        end)

        it("should override the default primary color", function()
            assert.are.same({1, 0, 0, 1}, customTheme.primaryColor)
        end)

        it("should override the default secondary color", function()
            assert.are.same({0, 1, 0, 1}, customTheme.secondaryColor)
        end)

        it("should override the default background color", function()
            assert.are.same({0, 0, 1, 1}, customTheme.backgroundColor)
        end)

        it("should override the default foreground color", function()
            assert.are.same({1, 1, 0, 1}, customTheme.foregroundColor)
        end)
    end)

    describe("getColor method", function()
        it("should return the primary color when requested", function()
            local color = defaultTheme:getColor("primary")
            assert.are.same(defaultTheme.primaryColor, color)
        end)

        it("should return the secondary color when requested", function()
            local color = defaultTheme:getColor("secondary")
            assert.are.same(defaultTheme.secondaryColor, color)
        end)

        it("should return the background color when requested", function()
            local color = defaultTheme:getColor("background")
            assert.are.same(defaultTheme.backgroundColor, color)
        end)

        it("should return the foreground color when requested", function()
            local color = defaultTheme:getColor("foreground")
            assert.are.same(defaultTheme.foregroundColor, color)
        end)

        it("should return nil for an unknown key", function()
            local color = defaultTheme:getColor("nonexistent")
            assert.is_nil(color)
        end)
    end)
end)
