-- stats.lua
local Stats = {}

-- Table to hold persistent stats for each player.
-- Each player is stored by their player index.
Stats.players = {}

-- Initialize stats for the given number of players.
function Stats.init(numPlayers)
    -- Decide what the starting money should be
    local startingMoney = 0
    if GameSettings.startMoney == "ON" then
        startingMoney = GameSettings.startMoneyAmount or 0
    end

    for i = 1, numPlayers do
        Stats.players[i] = {
            purchased = {},
            wins  = 0,
            money = startingMoney -- if startMoney=ON, this is set above
        }
    end
end

-- Increment win count for a given player.
function Stats.addWin(playerIndex)
    if Stats.players[playerIndex] then
        Stats.players[playerIndex].wins = Stats.players[playerIndex].wins + 1
    end
end

-- Add money to a given player's persistent record.
function Stats.addMoney(playerIndex, amount)
    if Stats.players[playerIndex] then
        Stats.players[playerIndex].money = Stats.players[playerIndex].money + amount
    end
end

-- Optionally, a getter for a player's stats.
function Stats.getPlayerStats(playerIndex)
    return Stats.players[playerIndex]
end

return Stats
