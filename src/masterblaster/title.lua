-- Title.lua
require("globals")
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
    -- Draw the Title image at the top left (adjust coordinates as needed)
    love.graphics.draw(titleImage, 0, 0)
end

function Title:keypressed(key)
    -- Switch state to credits.lua when any key is pressed
        switchState(require("credits"))
end

return Title
