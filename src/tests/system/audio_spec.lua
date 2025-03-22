-- Mock love.audio and love.sound before requiring Audio module
_G.love = {
    audio = {
        newSource = function(_)
            return {
                play = function() end,
                stop = function() end,
                setVolume = function() end,
                setLooping = function() end
            }
        end
    },
    sound = {
        newSoundData = function(_, _, _, _) return {} end
    },
    filesystem = {
        getInfo = function(_) return true end -- Assume all files exist
    }
}

local Audio = require("system.audio")

describe("Audio System", function()

    before_each(function()
        Audio.musicSources = {}
        Audio.sfxSources = {}
    end)

    it("should load all audio files without errors", function()
        assert.has_no_errors(function()
            Audio.load()
        end)
    end)

    it("should play music successfully", function()
        Audio.load()
        assert.has_no_errors(function()
            Audio.playMusic("arena")
        end)
    end)

    it("should warn when playing unknown music", function()
        spy.on(_G, "print")
        Audio.playMusic("unknown_track")
        assert.spy(_G.print).was.called_with("Warning: Attempt to play unknown music track:", "unknown_track")
    end)

    it("should play a sound effect successfully", function()
        Audio.load()
        assert.has_no_errors(function()
            Audio.playSFX("alarm")
        end)
    end)

    it("should warn when playing unknown SFX", function()
        spy.on(_G, "print")
        Audio.playSFX("unknown_sfx")
        assert.spy(_G.print).was.called_with("Warning: Attempt to play unknown SFX:", "unknown_sfx")
    end)

    it("should allow changing and retrieving music volume", function()
        Audio.setMusicVolume(0.5)
        assert.are.equal(0.5, Audio.getMusicVolume())
    end)

    it("should allow changing and retrieving SFX volume", function()
        Audio.setSFXVolume(0.2)
        assert.are.equal(0.2, Audio.getSFXVolume())
    end)

end)
