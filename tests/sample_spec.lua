local sample = require("sample")

describe("Sample Module", function()
    it("should return the correct sum", function()
        assert.are.equal(5, sample.add(2, 3))
    end)
end)
