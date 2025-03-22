-- test/core/stats_spec.lua
local Stats = require "core.stats"  -- Adjust path as needed

describe("Stats module", function()
    local stats

    before_each(function()
        -- Provide settings so that starting money is enabled and set to 100.
        local settings = { startMoney = true, startMoneyAmount = 100 }
        stats = Stats.new(settings)
        stats:init(2)  -- Initialize stats for 2 players.
    end)

    it("initializes player stats with starting money", function()
        local player1 = stats:getPlayerStats(1)
        local player2 = stats:getPlayerStats(2)
        assert.are.same(100, player1.money)
        assert.are.same(100, player2.money)
        assert.are.same(0, player1.wins)
        assert.are.same(0, player2.wins)
        assert.are.same({}, player1.purchased)
    end)

    it("increments win count for a player", function()
        stats:addWin(1)
        local player1 = stats:getPlayerStats(1)
        assert.are.same(1, player1.wins)
    end)

    it("adds money to a player's account", function()
        stats:addMoney(2, 50)
        local player2 = stats:getPlayerStats(2)
        assert.are.same(150, player2.money)
    end)

    it("ignores operations for non-existent players", function()
        -- Calling addWin or addMoney on an uninitialized player should do nothing.
        stats:addWin(3)
        stats:addMoney(3, 20)
        assert.is_nil(stats:getPlayerStats(3))
    end)
end)
