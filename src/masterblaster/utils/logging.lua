-- Enhanced logging module
local logging = {}

-- Log levels
logging.DEBUG = 10
logging.INFO = 20
logging.WARNING = 30
logging.ERROR = 40
logging.CRITICAL = 50

-- Default log level
logging.log_level = logging.ERROR

-- Default log output (console)
logging.log_output = io.stdout

--- Sets the log level dynamically
-- @param level One of logging.DEBUG, logging.INFO, etc.
function logging.set_log_level(level)
    logging.log_level = level
end

--- Sets the log output destination
-- @param output_file (optional) Path to a log file, nil for console
function logging.set_log_output(output_file)
    if output_file then
        local file, err = io.open(output_file, "a")
        if file then
            logging.log_output = file
        else
            error("Failed to open log file: " .. tostring(err))
        end
    else
        logging.log_output = io.stdout
    end
end

-- Internal function to log messages
local function log(level, level_name, message)
    if level >= logging.log_level then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local formatted_message = string.format("[%s] [%s] %s\n", timestamp, level_name, message)
        logging.log_output:write(formatted_message)
        logging.log_output:flush()
    end
end

-- Public logging functions
function logging.debug(message) log(logging.DEBUG, "DEBUG", message) end
function logging.info(message) log(logging.INFO, "INFO", message) end
function logging.warning(message) log(logging.WARNING, "WARNING", message) end
function logging.error(message) log(logging.ERROR, "ERROR", message) end
function logging.critical(message) log(logging.CRITICAL, "CRITICAL", message) end

return logging
