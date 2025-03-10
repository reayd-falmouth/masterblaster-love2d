local logging = require("utils.logging")

describe("Logging Module", function()
    -- Capture stdout output for testing
    local original_output

    before_each(function()
        original_output = logging.log_output
        logging.log_output = {
            buffer = {},
            write = function(self, msg) table.insert(self.buffer, msg) end,
            flush = function() end,
        }
    end)

    after_each(function()
        logging.log_output = original_output
    end)

    it("logs messages at or above the set level", function()
        logging.set_log_level(logging.INFO)
        logging.debug("This should not appear")
        logging.info("This should appear")
        logging.error("This should also appear")

        local log_messages = table.concat(logging.log_output.buffer, "\n")
        assert.not_match("DEBUG", log_messages)
        assert.match("INFO", log_messages)
        assert.match("ERROR", log_messages)
    end)

    it("logs critical messages regardless of level", function()
        logging.set_log_level(logging.CRITICAL)
        logging.critical("Critical issue detected")

        local log_messages = table.concat(logging.log_output.buffer, "\n")
        assert.match("CRITICAL", log_messages)
    end)

    it("allows changing the log level dynamically", function()
        logging.set_log_level(logging.DEBUG)
        logging.debug("Debug message should appear")

        local log_messages = table.concat(logging.log_output.buffer, "\n")
        assert.match("DEBUG", log_messages)
    end)
end)
