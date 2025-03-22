-- src/ui/menu.lua
local MainMenu = {}
local Font = require("system.fonts")
local UITheme = require("core.theme")  -- Import shared colors
local Settings = require("config.settings")  -- Import settings module

-- Function to retrieve boolean choices in a structured format
local function getBooleanChoices()
    return { { label = "ON", value = true }, { label = "OFF", value = false } }
end

-- Function to retrieve Yes/No choices in a structured format
local function getYesNoChoices()
    return { { label = "YES", value = true }, { label = "NO", value = false } }
end

-- Menu item definitions
local menuItems = {
    { label = "WINS NEEDED", value = Settings.DEFAULTS.winsNeeded, choices = {1, 2, 3, 4, 5, 6, 7, 8, 9}, key = "winsNeeded" },
    { label = "PLAYERS", value = Settings.DEFAULTS.players, choices = {2, 3, 4, 5}, key = "players" },
    { label = "SHOP", value = Settings.DEFAULTS.shop, choices = getBooleanChoices(), key = "shop" },
    { label = "SHRINKING", value = Settings.DEFAULTS.shrinking, choices = getBooleanChoices(), key = "shrinking" },
    { label = "FASTIGNITION", value = Settings.DEFAULTS.fastIgnition, choices = getBooleanChoices(), key = "fastIgnition" },
    { label = "START MONEY", value = Settings.DEFAULTS.startMoney, choices = getBooleanChoices(), key = "startMoney" },
    { label = "NORMAL LEVEL", value = Settings.DEFAULTS.normalLevel, choices = getYesNoChoices(), key = "normalLevel" },
    { label = "GAMBLING", value = Settings.DEFAULTS.gambling, choices = getYesNoChoices(), key = "gambling" },

}

-- Selected menu index
local selectedIndex = 1

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
    Font.load()
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
    local windowWidth, windowHeight = VIRTUAL_WIDTH, VIRTUAL_HEIGHT
    local fontScale, scaledPadding = 1, 3
    local lineSpacing = (imageFont:getHeight() + scaledPadding) * fontScale
    local menuWidth = imageFont:getWidth("      MAIN MENU      ") * fontScale
    local totalMenuHeight = (#menuItems * lineSpacing) + (imageFont:getHeight() * fontScale * 4)

    -- Center menu
    local containerX = (windowWidth / 2) - (menuWidth / 2)
    local titleY = (windowHeight / 2) - (totalMenuHeight / 2)
    local separatorY = titleY + (imageFont:getHeight() * fontScale)
    local menuStartY = titleY + (imageFont:getHeight() * fontScale * 2) + (5 * fontScale)

    -- Draw title
    love.graphics.setFont(imageFont)
    love.graphics.setColor(UITheme.defaultTheme.primaryColor)
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
        selectedIndex = (selectedIndex - 1 < 1) and #menuItems or selectedIndex - 1
    elseif key == "down" then
        selectedIndex = (selectedIndex + 1 > #menuItems) and 1 or selectedIndex + 1
    elseif key == "left" or key == "right" then
        local item = menuItems[selectedIndex]
        if item.choices then
            local idx = 1
            for i, choice in ipairs(item.choices) do
                if (type(choice) == "table" and choice.value == item.value) or choice == item.value then
                    idx = i
                    break
                end
            end

            if key == "left" and idx > 1 then
                item.value = (type(item.choices[idx - 1]) == "table") and item.choices[idx - 1].value or item.choices[idx - 1]
            elseif key == "right" and idx < #item.choices then
                item.value = (type(item.choices[idx + 1]) == "table") and item.choices[idx + 1].value or item.choices[idx + 1]
            end

            -- Apply changes dynamically
            Settings[item.key] = item.value
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
