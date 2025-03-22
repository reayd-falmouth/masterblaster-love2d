-- spec/settings_spec.lua
local Settings = require("config.settings")

-- Helper function to create a fresh settings table from DEFAULTS
local function freshSettings()
  local t = {}
  for k, v in pairs(Settings.DEFAULTS) do
    t[k] = v
  end
  return t
end

describe("Settings Module", function()

  it("initializes with correct default values", function()
    for key, defaultVal in pairs(Settings.DEFAULTS) do
      assert.are.equal(defaultVal, Settings[key])
    end
  end)

  it("validates default settings successfully", function()
    local testSettings = freshSettings()
    assert.is_true(Settings.validate(testSettings))
  end)

  it("fails validation if winsNeeded is not a positive number", function()
    local testSettings = freshSettings()
    testSettings.winsNeeded = 0
    assert.has_error(function() Settings.validate(testSettings) end, "winsNeeded must be a positive number")
  end)

  it("fails validation if players is less than 1", function()
    local testSettings = freshSettings()
    testSettings.players = 0
    assert.has_error(function() Settings.validate(testSettings) end, "players must be at least 1")
  end)

  it("fails validation if shop is not a boolean", function()
    local testSettings = freshSettings()
    testSettings.shop = "yes"
    assert.has_error(function() Settings.validate(testSettings) end, "shop must be a boolean")
  end)

  it("fails validation if shrinking is not a boolean", function()
    local testSettings = freshSettings()
    testSettings.shrinking = "yes"
    assert.has_error(function() Settings.validate(testSettings) end, "shrinking must be a boolean")
  end)

  it("fails validation if fastIgnition is not a boolean", function()
    local testSettings = freshSettings()
    testSettings.fastIgnition = "yes"
    assert.has_error(function() Settings.validate(testSettings) end, "fastIgnition must be a boolean")
  end)

  it("fails validation if startMoney is not a boolean", function()
    local testSettings = freshSettings()
    testSettings.startMoney = "yes"
    assert.has_error(function() Settings.validate(testSettings) end, "startMoney must be a boolean")
  end)

  it("fails validation if normalLevel is not a boolean", function()
    local testSettings = freshSettings()
    testSettings.normalLevel = "yes"
    assert.has_error(function() Settings.validate(testSettings) end, "normalLevel must be a boolean")
  end)

  it("fails validation if gambling is not a boolean", function()
    local testSettings = freshSettings()
    testSettings.gambling = "yes"
    assert.has_error(function() Settings.validate(testSettings) end, "gambling must be a boolean")
  end)

  it("fails validation if startMoneyAmount is negative", function()
    local testSettings = freshSettings()
    testSettings.startMoneyAmount = -1
    assert.has_error(function() Settings.validate(testSettings) end, "startMoneyAmount must be non-negative")
  end)

end)
