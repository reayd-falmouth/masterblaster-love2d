-- Title.lua
require("config.globals")
local Title = {}
local titleImage

function Title:load()
    -- Load the Title screen graphic
    titleImage = love.graphics.newImage("assets/images/cover.png")
end

function Title:update(dt)
    -- You could add animations or other logic here if needed
end

function Title:draw()
    -- Calculate scaling factors so that the title image fills the virtual resolution.
    local imgWidth = titleImage:getWidth()
    local imgHeight = titleImage:getHeight()
    local scaleX = VIRTUAL_WIDTH / imgWidth
    local scaleY = VIRTUAL_HEIGHT / imgHeight

    -- Draw the image scaled to the full virtual resolution.
    love.graphics.draw(titleImage, 0, 0, 0, scaleX, scaleY)
end

function Title:keypressed(key)
    -- Switch state to credits.lua when any key is pressed.
    switchState(require("scenes.credits"))
end

return Title
