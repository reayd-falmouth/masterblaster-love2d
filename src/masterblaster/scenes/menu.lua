-- src/ui/menu.lua
local MainMenu = {}
local Font = require("system.fonts")
local UITheme = require("core.theme")  -- Import shared colors
local Game = require("core.game")
local Shop = require("scenes.shop")
local WheelOFortune = require("scenes.wof")

-- A list of menu items that can be navigated and toggled
local menuItems = {
    { label = "WINS NEEDED", value = GameSettings.winsNeeded, choices = {1, 2, 3, 4, 5, 6, 7, 8, 9}, key = "winsNeeded" },
    { label = "PLAYERS", value = GameSettings.players, choices = {2, 3, 4, 5}, key = "players" },
    { label = "SHOP", value = GameSettings.shop, choices = {"ON", "OFF"}, key = "shop" },
    { label = "SHRINKING", value = GameSettings.shrinking, choices = {"ON", "OFF"}, key = "shrinking" },
    { label = "FASTIGNITION", value = GameSettings.fastIgnition, choices = {"ON", "OFF"}, key = "fastIgnition" },
    { label = "STARTMONEY", value = GameSettings.startMoney, choices = {"ON", "OFF"}, key = "startMoney" },
    { label = "NORMALLEVEL", value = GameSettings.normalLevel, choices = {"YES", "NO"}, key = "normalLevel" },
    { label = "GAMBLING", value = GameSettings.gambling, choices = {"YES", "NO"}, key = "gambling" },
}

local selectedIndex = 1

-- Layout parameters for fixed-width container
local containerX = 0 -- Will be calculated in draw() to center container

-- Font variables (set in load)
local imageFont

local joystickCount = 0
local basePlayers = 1

-- Helper function to check for an element in a table
local function tableContains(tbl, element)
    for _, value in ipairs(tbl) do
        if value == element then return true end
    end
    return false
end

-- Modified: buildPlayerChoice now always updates the players count to reflect the maximum available.
function buildPlayerChoice(basePlayers, menuItems)
    for i, item in ipairs(menuItems) do
        if item.key == "players" then
            local newChoices = {}
            -- For multiple controllers, offer choices from 2 up to basePlayers.
            for j = 0, basePlayers do
                table.insert(newChoices, j)
            end
            item.choices = newChoices
            -- Automatically update the player's count to the highest valid value.
            item.value = newChoices[#newChoices]
            GameSettings.players = item.value
        end
    end
end

function MainMenu.load()
    -- Load custom fonts from your font module
    Font.load()

    -- Use your fonts: m6x11 for title and m6x11plus for menu items
    imageFont = Font.getImageFont()

    -- Set background color
    love.graphics.setBackgroundColor(UITheme.bgColor)

    -- Update the PLAYERS menu item based on attached controllers.
    -- Determine the actual number of attached joysticks.
    joystickCount = #love.joystick.getJoysticks()

    -- Limit to a maximum of 5 players.
    basePlayers = math.min(joystickCount, 5)

    -- Rebuild the choices for PLAYERS.
    buildPlayerChoice(basePlayers, menuItems)
end

function MainMenu.update(dt)
    joystickCount = #love.joystick.getJoysticks()
    basePlayers = math.min(joystickCount, 5)
    buildPlayerChoice(basePlayers, menuItems)
end

function MainMenu.draw()
    -- Get window size
    local windowWidth = VIRTUAL_WIDTH
    local windowHeight = VIRTUAL_HEIGHT

    -- Define scale factors
    local fontScale = 1
    local scaledPadding = 3 * fontScale -- Scale padding dynamically
    local lineSpacing = (imageFont:getHeight() + scaledPadding) * fontScale

    -- Calculate text width dynamically
    local menuWidth = imageFont:getWidth("      MAIN MENU      ") * fontScale

    -- Calculate total menu height dynamically
    local totalMenuHeight = (#menuItems * lineSpacing) + (imageFont:getHeight() * fontScale * 4)

    -- Calculate center positions
    containerX = (windowWidth / 2) - (menuWidth / 2) -- Perfect horizontal centering
    local titleY = (windowHeight / 2) - (totalMenuHeight / 2) -- Perfect vertical centering
    local separatorY = titleY + (imageFont:getHeight() * fontScale)
    local menuStartY = separatorY + (imageFont:getHeight() * fontScale) + (5 * fontScale) -- Adjusted for balance

    -- Draw the title
    love.graphics.setFont(imageFont)
    love.graphics.setColor(UITheme.normalColor)
    love.graphics.print("      MAIN MENU      ", containerX, titleY, 0, fontScale, fontScale)
    love.graphics.print("      ---------      ", containerX, separatorY, 0, fontScale, fontScale)

    -- Draw each menu item using monospaced text alignment
    love.graphics.setFont(imageFont)

    for i, item in ipairs(menuItems) do
        local y = menuStartY + (i - 1) * lineSpacing
        -- Draw the marker '>' in highlight color for the selected item
        if i == selectedIndex then
            love.graphics.setColor(UITheme.highlightColor)
            love.graphics.print(">", containerX - (10 * fontScale), y, 0, fontScale, fontScale)
        end

        -- Draw the menu text in normal color
        love.graphics.setColor(UITheme.normalColor)
        local formattedText = string.format("  %-12s : %-3s", item.label, tostring(item.value))
        love.graphics.print(formattedText, containerX, y, 0, fontScale, fontScale)
    end
end

function MainMenu.keypressed(key)
    if key == "up" then
        selectedIndex = selectedIndex - 1
        if selectedIndex < 1 then selectedIndex = #menuItems end
    elseif key == "down" then
        selectedIndex = selectedIndex + 1
        if selectedIndex > #menuItems then selectedIndex = 1 end
    elseif key == "left" or key == "right" then
        local item = menuItems[selectedIndex]
        if item.choices then
            local idx = 1
            for i, choice in ipairs(item.choices) do
                if choice == item.value then
                    idx = i
                    break
                end
            end

            if key == "left" and idx > 1 then
                item.value = item.choices[idx - 1]
            elseif key == "right" and idx < #item.choices then
                item.value = item.choices[idx + 1]
            end

            -- Update GameSettings dynamically
            GameSettings[item.key] = item.value
        end
    elseif key == "return" or key == "kpenter" then
        if GameSettings.players and GameSettings.players >= 2 then
            PlayerStats.init(GameSettings.players)
            switchState(Game) -- Switch to game state
        else
            log.warning("At least 2 players are required to start the game.")
        end
    end
end

return MainMenu
