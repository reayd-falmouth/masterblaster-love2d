-- scenes/menu.lua
local MainMenu = {}
local Font = require("system.fonts")
local UITheme = require("core.theme")  -- Import shared colors
local Game = require("core.game")
local Settings = require("config.settings")  -- Import settings module
local Stats = require("core.stats")

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
    { label = "WINS NEEDED", value = Settings.winsNeeded, choices = {1, 2, 3, 4, 5, 6, 7, 8, 9}, key = "winsNeeded" },
    { label = "PLAYERS", value = Settings.players, choices = {2, 3, 4, 5}, key = "players" },
    { label = "SHOP", value = Settings.shop, choices = getBooleanChoices(), key = "shop" },
    { label = "SHRINKING", value = Settings.shrinking, choices = getBooleanChoices(), key = "shrinking" },
    { label = "FASTIGNITION", value = Settings.fastIgnition, choices = getBooleanChoices(), key = "fastIgnition" },
    { label = "START MONEY", value = Settings.startMoney, choices = getBooleanChoices(), key = "startMoney" },
    { label = "NORMAL LEVEL", value = Settings.normalLevel, choices = getYesNoChoices(), key = "normalLevel" },
    { label = "GAMBLING", value = Settings.gambling, choices = getYesNoChoices(), key = "gambling" },

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
            for j = 2, basePlayers do  -- Adjusted to always have at least 2 players
                table.insert(newChoices, j)
            end
            item.choices = newChoices
            -- If current setting invalid, update it
            if not tableContains(newChoices, Settings.players) then
                item.value = newChoices[#newChoices]
                Settings.players = item.value
            end
        else
            -- IMPORTANT: Keep other settings synced
            item.value = Settings[item.key]
        end
    end
end

function MainMenu.load()
    Font.load()
    imageFont = Font.getImageFont()
    love.graphics.setBackgroundColor(UITheme.defaultTheme.backgroundColor)
    -- Update the PLAYERS menu item based on attached controllers.
    -- Determine the actual number of attached joysticks.
    joystickCount = #love.joystick.getJoysticks()

    -- Limit to a maximum of 5 players.
    basePlayers = math.min(joystickCount, 5)

    -- Rebuild the choices for PLAYERS.
    buildPlayerChoice(basePlayers, menuItems)
end

function MainMenu.update(dt)
    -- Static menu; no dynamic updates needed
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

    -- Draw menu items
    for i, item in ipairs(menuItems) do
        local y = menuStartY + (i - 1) * lineSpacing

        -- Highlight selected item
        if i == selectedIndex then
            love.graphics.setColor(UITheme.defaultTheme.secondaryColor)
            love.graphics.print(">", containerX - (10 * fontScale), y, 0, fontScale, fontScale)
        end

        love.graphics.setColor(UITheme.defaultTheme.primaryColor)

        -- Determine the proper display value for the item
        local valueToDisplay = item.value
        if type(valueToDisplay) == "table" then
            valueToDisplay = valueToDisplay.label
        elseif type(valueToDisplay) == "boolean" then
            -- Check the first choice's label to decide how to display the boolean
            local firstChoiceLabel = (item.choices[1] and item.choices[1].label) or ""
            if firstChoiceLabel == "ON" then
                valueToDisplay = valueToDisplay and "ON" or "OFF"
            elseif firstChoiceLabel == "YES" then
                valueToDisplay = valueToDisplay and "YES" or "NO"
            else
                valueToDisplay = tostring(valueToDisplay)
            end
        elseif valueToDisplay == nil then
            valueToDisplay = "N/A"
        else
            valueToDisplay = tostring(valueToDisplay)
        end

        local formattedText = string.format("  %-12s : %-3s", item.label, valueToDisplay)
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
        if Settings.players and Settings.players >= 2 then
            -- Apply settings and start game
            PlayerStats = Stats.new({ Settings.startMoney, Settings.startMoneyAmount })
            PlayerStats:init(Settings.players)
            switchState(Game)
        else
            LOG.warning("At least 2 players are required to start the game.")
        end
    end
end

return MainMenu
