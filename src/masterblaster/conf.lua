-- conf.lua
require("globals")

function love.conf(t)
    t.window.title = "Master Blaster"
    t.window.width = VIRTUAL_WIDTH  -- Or set your preferred starting window size
    t.window.height = VIRTUAL_HEIGHT
    t.window.resizable = true       -- Allow window resizing if needed
end
