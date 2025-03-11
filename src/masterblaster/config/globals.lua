-- config/globals.lua
-- Load the logging utility
LOG = require("utils.logging")

-- Game version identifier
VERSION = "v1.0"

-- Virtual resolution settings (used for scaling the game window properly)
VIRTUAL_WIDTH = 640
VIRTUAL_HEIGHT = 512

-- Enable or disable background music
ENABLE_MUSIC = false

-- Debug mode toggle
DEBUG = true

-- Tile size (useful for grid-based positioning in the game world)
TILE_SIZE = 16

-- Set the default logging level
LOG_LEVEL = LOG.INFO

-- Adjust log level based on debug mode
-- If DEBUG mode is enabled, log more details for development
if DEBUG then
    LOG.LOG_LEVEL = LOG.DEBUG
else
    LOG.LOG_LEVEL = LOG.INFO
end
