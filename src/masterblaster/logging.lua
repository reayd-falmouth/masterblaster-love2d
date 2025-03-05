-- A simple logging module mimicking Python's logging module

local logging = {}

-- Log levels
logging.DEBUG = 10
logging.INFO = 20
logging.WARNING = 30
logging.ERROR = 40
logging.CRITICAL = 50

-- Global debug flag
local DEBUG = false
logging.LOG_LEVEL = DEBUG and logging.DEBUG or logging.LOG_LEVEL

-- Internal function to log messages
local function log(level, level_name, message)
    if level >= logging.LOG_LEVEL then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        print(string.format("[%s] [%s] %s", timestamp, level_name, message))
    end
end

-- Public logging functions
function logging.debug(message)
    log(logging.DEBUG, "DEBUG", message)
end

function logging.info(message)
    log(logging.INFO, "INFO", message)
end

function logging.warning(message)
    log(logging.WARNING, "WARNING", message)
end

function logging.error(message)
    log(logging.ERROR, "ERROR", message)
end

function logging.critical(message)
    log(logging.CRITICAL, "CRITICAL", message)
end

return logging
