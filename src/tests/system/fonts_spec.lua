-- Mock love.graphics before requiring Fonts module
_G.love = {
    graphics = {
        newImageFont = function(_, _)
            return {
                setFilter = function() end
            }
        end
    }
}

local Fonts = require("system.fonts")  -- Require after mocking

describe("Fonts System", function()

    before_each(function()
        -- Reset the module before each test
        Fonts.ImageFont = {}
    end)

    it("should load the image font without errors", function()
        assert.has_no_errors(function()
            Fonts.load()
        end)
    end)

    it("should return the image font after loading", function()
        Fonts.load()
        local font = Fonts.getImageFont()
        assert.is_not_nil(font)
    end)

    it("should throw an error if getting font before loading", function()
        assert.has_error(function()
            Fonts.getImageFont()
        end, "Font not loaded. Call Fonts.load() first.")
    end)

end)
