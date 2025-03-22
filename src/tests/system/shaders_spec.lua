-- Mock love.graphics and love.filesystem before requiring Shaders
_G.love = {
    graphics = {
        newShader = function(_)
            return {
                getWarnings = function() return "" end
            }
        end
    },
    filesystem = {
        getInfo = function(_) return true end,  -- Ensure file exists by default
        read = function(_) return "valid shader code" end
    }
}

local Shaders = require("system.shaders")

describe("Shaders System", function()

    before_each(function()
        -- Reset shaders before each test
        Shaders.loadedShaders = {}
    end)

    it("should load a shader without errors", function()
        assert.has_no_errors(function()
            local shader = Shaders.loadShader("assets/shaders/white_shader.glsl")
            assert.is_not_nil(shader)
        end)
    end)

    it("should return a cached shader instead of reloading", function()
        local shader1 = Shaders.getShader("assets/shaders/white_shader.glsl")
        local shader2 = Shaders.getShader("assets/shaders/white_shader.glsl")
        assert.are.equal(shader1, shader2)  -- Should be the same instance
    end)

    it("should throw an error if shader file is missing", function()
        _G.love.filesystem.getInfo = function(_) return nil end  -- Simulate missing file

        assert.has_error(function()
            Shaders.loadShader("nonexistent_shader.glsl")
        end, "Shader file not found: nonexistent_shader.glsl")
    end)

    it("should throw an error if shader file cannot be read", function()
        _G.love.filesystem.getInfo = function(_) return true end  -- Ensure file exists
        _G.love.filesystem.read = function(_) return nil end  -- Simulate read failure

        assert.has_error(function()
            Shaders.loadShader("assets/shaders/corrupt_shader.glsl")
        end, "Failed to read shader file: assets/shaders/corrupt_shader.glsl")
    end)

    it("should throw an error if shader compilation fails", function()
        _G.love.filesystem.getInfo = function(_) return true end  -- Ensure file exists
        _G.love.filesystem.read = function(_) return "valid shader code" end  -- Ensure file reads
        _G.love.graphics.newShader = function(_) error("Shader compilation error") end  -- Simulate failure

        assert.has_error(function()
            Shaders.loadShader("assets/shaders/bad_shader.glsl")
        end, "Failed to compile shader: assets/shaders/bad_shader.glsl")
    end)

end)
