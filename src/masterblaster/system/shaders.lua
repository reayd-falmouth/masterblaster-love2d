-- masterblaster/system/shaders.lua
local Shaders = {}

-- Table to store loaded shaders
Shaders.loadedShaders = {}

--- Load a shader from a file
-- @param shaderPath (string) Path to the shader file
-- @return (Shader) The loaded shader object
function Shaders.loadShader(shaderPath)
    if not love.filesystem.getInfo(shaderPath) then
        error("Shader file not found: " .. shaderPath)
    end

    local shaderCode = love.filesystem.read(shaderPath)
    if not shaderCode then
        error("Failed to read shader file: " .. shaderPath)
    end

    local success, shader = pcall(love.graphics.newShader, shaderCode)
    if not success then
        error("Failed to compile shader: " .. shaderPath)
    end

    Shaders.loadedShaders[shaderPath] = shader
    return shader
end

--- Get a preloaded shader, or load if missing
-- @param shaderPath (string) Path to the shader file
-- @return (Shader) The requested shader
function Shaders.getShader(shaderPath)
    if not Shaders.loadedShaders[shaderPath] then
        return Shaders.loadShader(shaderPath)
    end
    return Shaders.loadedShaders[shaderPath]
end

-- Preload commonly used shaders
Shaders.whiteShader = Shaders.loadShader("assets/shaders/white_shader.glsl")

return Shaders
