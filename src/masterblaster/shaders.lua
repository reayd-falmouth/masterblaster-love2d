local shaders = {}

-- Load the shader from the file
local whiteShaderCode = love.filesystem.read("assets/shaders/white_shader.glsl")
shaders.whiteShader = love.graphics.newShader(whiteShaderCode)

return shaders
