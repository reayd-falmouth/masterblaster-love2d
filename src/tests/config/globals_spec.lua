local Globals = require("config.globals")
local LOG = require("utils.logging")

describe("Global Configuration", function()

    it("should have the correct game version", function()
        assert.are.equal("v1.0", VERSION)
    end)

    it("should define correct virtual width and height", function()
        assert.are.equal(640, VIRTUAL_WIDTH)
        assert.are.equal(512, VIRTUAL_HEIGHT)
    end)

    it("should correctly set ENABLE_MUSIC", function()
        assert.are.equal(false, ENABLE_MUSIC)
    end)

    it("should correctly define debug mode", function()
        assert.is_boolean(DEBUG)
    end)

    it("should correctly define tile size", function()
        assert.are.equal(16, TILE_SIZE)
    end)

    it("should set LOG_LEVEL to ERROR by default", function()
        assert.are.equal(LOG.ERROR, LOG_LEVEL)
    end)

    it("should adjust LOG.LOG_LEVEL based on DEBUG mode", function()
        if DEBUG then
            assert.are.equal(LOG.DEBUG, LOG.LOG_LEVEL)
        else
            assert.are.equal(LOG_LEVEL, LOG.LOG_LEVEL)
        end
    end)

end)
