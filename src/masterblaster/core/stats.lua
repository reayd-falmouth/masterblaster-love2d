-- core/stats.lua
local Stats = {}
Stats.__index = Stats

-- Create a new Stats instance.
-- Accepts an optional settings table.
function Stats.new(settings)
    local self = setmetatable({}, Stats)
    self.settings = settings or {}
    self.players = {}
    return self
end

-- Initialize stats for a given number of players.
function Stats:init(numPlayers)
    local startingMoney = 0
    if self.settings.startMoney then
        startingMoney = self.settings.startMoneyAmount or 0
    end

    for i = 1, numPlayers do
        self.players[i] = {
            purchased = {},
            wins = 0,
            money = startingMoney
        }
    end
end

-- Increment win count for a given player.
function Stats:addWin(playerIndex)
    if self.players[playerIndex] then
        self.players[playerIndex].wins = self.players[playerIndex].wins + 1
    end
end

-- Add money to a given player's persistent record.
function Stats:addMoney(playerIndex, amount)
    if self.players[playerIndex] then
        self.players[playerIndex].money = self.players[playerIndex].money + amount
    end
end

-- Getter for a player's stats.
function Stats:getPlayerStats(playerIndex)
    return self.players[playerIndex]
end

return Stats
